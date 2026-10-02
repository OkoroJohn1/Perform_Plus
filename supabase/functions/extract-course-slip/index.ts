// Extracts course rows from a photo of a Nigerian university COURSE
// REGISTRATION slip (courses registered for a semester -- not a result
// slip, and not expected to carry grades). The Flutter client uploads a
// compressed base64 image; this function calls Anthropic's vision model to
// read it and returns a draft list of {courseCode, courseTitle, creditUnit,
// confidence} rows for the student to review/correct before saving --
// never a grade, and never a computed CGPA/classification. See
// AGENTS.md's "THE RULE THAT MATTERS MOST": the model only ever proposes
// text it can see on the slip; CgpaEngine/GradingScheme own all arithmetic
// client-side, and this function performs none.
//
// Auth: verify_jwt is enabled at deploy time (platform-level gate), and the
// Supabase client below is additionally scoped to the caller's own
// forwarded JWT -- never the service role key -- so RLS on
// extraction_requests enforces "only your own usage" for both the rate
// check and the insert.
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const DAILY_LIMIT = 20;
const ANTHROPIC_MODEL = "claude-haiku-4-5-20251001";
const MAX_BASE64_LENGTH = 20_000_000; // ~15MB decoded -- generous for a compressed phone photo
const ALLOWED_MIME_TYPES = ["image/jpeg", "image/png", "image/webp"];

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", ...corsHeaders },
  });
}

const EXTRACTION_PROMPT = `You are reading a photo of a Nigerian university COURSE REGISTRATION slip (it lists courses a student registered for -- it is NOT a result slip and does not carry grades). Extract every course row you can clearly read into a JSON array. For each course return an object with exactly these fields:
- "courseCode": the course code exactly as printed (e.g. "CSC201"), uppercase, no spaces
- "courseTitle": the course title exactly as printed, or null if not legible/present
- "creditUnit": the credit unit as a whole number, or null if not legible/present
- "confidence": your own confidence in this row's accuracy, a number from 0 to 1

Rules:
- Never invent a course that is not visibly printed on the slip.
- Never output a grade, class of degree, or any computed/derived number -- only transcribe what is printed for the three fields above.
- If the image is not a course registration/result slip at all, or nothing on it is legible, return an empty array.
- Return ONLY the JSON array. No markdown fences, no other text.`;

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return json({ error: "Missing authorization" }, 401);
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: userData, error: userError } = await supabase.auth.getUser();
    if (userError || !userData.user) {
      return json({ error: "Invalid session" }, 401);
    }
    const userId = userData.user.id;

    const since = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();
    const { count, error: countError } = await supabase
      .from("extraction_requests")
      .select("id", { count: "exact", head: true })
      .eq("user_id", userId)
      .gte("created_at", since);

    if (countError) {
      console.error("rate limit check failed", countError);
      return json({ error: "Could not verify usage limit" }, 500);
    }
    if ((count ?? 0) >= DAILY_LIMIT) {
      return json(
        { error: `Daily limit of ${DAILY_LIMIT} slip scans reached. Try again tomorrow, or enter courses manually.` },
        429,
      );
    }

    // Recorded before the model call so a crash/timeout still counts.
    const { error: insertError } = await supabase.from("extraction_requests").insert({ user_id: userId });
    if (insertError) {
      console.error("rate limit insert failed", insertError);
      return json({ error: "Could not verify usage limit" }, 500);
    }

    const body = await req.json().catch(() => null);
    const imageBase64 = body?.imageBase64;
    const mimeType = body?.mimeType;

    if (typeof imageBase64 !== "string" || typeof mimeType !== "string") {
      return json({ error: "Missing imageBase64 or mimeType" }, 400);
    }
    if (!ALLOWED_MIME_TYPES.includes(mimeType)) {
      return json({ error: "Unsupported image type" }, 400);
    }
    if (imageBase64.length > MAX_BASE64_LENGTH) {
      return json({ error: "Image is too large" }, 400);
    }

    const anthropicKey = Deno.env.get("ANTHROPIC_API_KEY");
    if (!anthropicKey) {
      console.error("ANTHROPIC_API_KEY is not set");
      return json({ error: "Extraction is not configured" }, 500);
    }

    const anthropicRes = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "x-api-key": anthropicKey,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: ANTHROPIC_MODEL,
        max_tokens: 2048,
        messages: [
          {
            role: "user",
            content: [
              { type: "image", source: { type: "base64", media_type: mimeType, data: imageBase64 } },
              { type: "text", text: EXTRACTION_PROMPT },
            ],
          },
        ],
      }),
    });

    if (!anthropicRes.ok) {
      const detail = await anthropicRes.text();
      console.error("Anthropic error", anthropicRes.status, detail);
      return json({ error: "Extraction service failed" }, 502);
    }

    const anthropicJson = await anthropicRes.json();
    const text: string = anthropicJson?.content?.[0]?.text ?? "";

    let parsed: unknown;
    try {
      parsed = JSON.parse(text);
    } catch {
      // The model occasionally wraps output in prose despite instructions --
      // salvage a JSON array substring before giving up entirely.
      const match = text.match(/\[[\s\S]*\]/);
      parsed = match ? tryParse(match[0]) : null;
    }

    if (!Array.isArray(parsed)) {
      return json({ error: "Could not read the slip clearly. Try a clearer photo or enter courses manually." }, 422);
    }

    const courses = parsed
      .filter((c): c is Record<string, unknown> => !!c && typeof c === "object")
      .map((c) => ({
        courseCode: typeof c.courseCode === "string" ? c.courseCode.trim().toUpperCase().slice(0, 20) : "",
        courseTitle:
          typeof c.courseTitle === "string" && c.courseTitle.trim().length > 0
            ? c.courseTitle.trim().slice(0, 200)
            : null,
        creditUnit:
          typeof c.creditUnit === "number" && Number.isFinite(c.creditUnit)
            ? Math.max(0, Math.min(30, Math.round(c.creditUnit)))
            : null,
        confidence:
          typeof c.confidence === "number" && Number.isFinite(c.confidence)
            ? Math.max(0, Math.min(1, c.confidence))
            : 0.5,
      }))
      .filter((c) => c.courseCode.length > 0);

    return json({ courses }, 200);
  } catch (error) {
    console.error("extract-course-slip unexpected error", error);
    return json({ error: "Unexpected error during extraction" }, 500);
  }
});

function tryParse(s: string): unknown {
  try {
    return JSON.parse(s);
  } catch {
    return null;
  }
}
