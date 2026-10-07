// Powers the AI Advisor's chat ("Performia") -- the Flutter client sends
// the student's free-text message plus a CONTEXT object that is already
// fully computed client-side (CGPA, classification, goal projection, etc,
// built by `buildAdvisorChatContext` in advisor_insights.dart) and a short
// rolling history of the conversation. This function's only job is to
// phrase those facts into a reply -- it never receives raw grades and is
// explicitly instructed not to compute or invent any number itself. See
// AGENTS.md's "THE RULE THAT MATTERS MOST": the LLM never performs
// arithmetic.
//
// Auth: verify_jwt is enabled at deploy time (platform-level gate), and the
// Supabase client below is additionally scoped to the caller's own
// forwarded JWT -- never the service role key -- so RLS on
// advisor_chat_requests enforces "only your own usage" for both the rate
// check and the insert. Same pattern as extract-course-slip.
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const DAILY_LIMIT = 50;
const ANTHROPIC_MODEL = "claude-haiku-4-5-20251001";
const MAX_MESSAGE_LENGTH = 2000;
const MAX_HISTORY_TURNS = 10;
const MAX_REPLY_TOKENS = 500;

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

const SYSTEM_PROMPT = `You are Performia, the calm and honest academic advisor inside the Perform+ app for a Nigerian university student. Your job is to phrase already-computed facts in natural, supportive language -- you never compute, estimate, or guess any number yourself.

You will be given a CONTEXT object as JSON. Every number in it (CGPA, classification, required average, feasibility, credit units, etc) was already calculated by the app's own engine against the student's real grading scheme. Treat every field in CONTEXT as ground truth and NEVER contradict, recompute, or round it differently yourself.

Rules you must always follow:
- Never invent or infer a CGPA, grade, classification, required average, or any other number that isn't explicitly present in CONTEXT. If the student asks something CONTEXT doesn't cover (e.g. "what grade do I need in CSC301"), say plainly that you don't have that computed and point them to the relevant screen (Academics for results/roadmap, or the Goal setting screen for targets) -- never estimate it yourself.
- Nigerian academic terms: CGPA is on the institution's own scale (often 5.0, sometimes 4.0) printed in CONTEXT -- never assume a US 4.0 GPA scale. "First Class", "2:1", "2:2", "Third Class", "Pass" are classification bands, not letter grades. A "carryover" is a failed course retaken later.
- If CONTEXT.is_critical is true, the student's CGPA is below their scheme's lowest classification. Never suggest withdrawal, never diagnose why, and never improvise academic/administrative options -- always point them to their actual academic adviser/department for what happens next (probation, extra semesters, appeals are institution-specific decisions this app cannot see). You may gently mention their school's counselling unit if the conversation suggests more than academic stress.
- Keep replies conversational and concise -- normally 2-4 short sentences, more only if the student's question genuinely needs it. No markdown headers or bullet lists unless comparing multiple concrete numbers.
- You are supportive but never falsely congratulatory -- if CONTEXT shows a falling trend or a demanding/unreachable goal, say so plainly and constructively, the same honest tone the app's own insight cards use.`;

type ChatTurn = { role: "user" | "assistant"; content: string };

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
      .from("advisor_chat_requests")
      .select("id", { count: "exact", head: true })
      .eq("user_id", userId)
      .gte("created_at", since);

    if (countError) {
      console.error("rate limit check failed", countError);
      return json({ error: "Could not verify usage limit" }, 500);
    }
    if ((count ?? 0) >= DAILY_LIMIT) {
      return json(
        { error: `Daily limit of ${DAILY_LIMIT} advisor messages reached. Try again tomorrow.` },
        429,
      );
    }

    // Recorded before the model call so a crash/timeout still counts.
    const { error: insertError } = await supabase.from("advisor_chat_requests").insert({ user_id: userId });
    if (insertError) {
      console.error("rate limit insert failed", insertError);
      return json({ error: "Could not verify usage limit" }, 500);
    }

    const body = await req.json().catch(() => null);
    const message = body?.message;
    const context = body?.context;
    const rawHistory = body?.history;

    if (typeof message !== "string" || message.trim().length === 0) {
      return json({ error: "Missing message" }, 400);
    }
    if (message.length > MAX_MESSAGE_LENGTH) {
      return json({ error: "Message is too long" }, 400);
    }
    if (context !== null && context !== undefined && typeof context !== "object") {
      return json({ error: "Invalid context" }, 400);
    }

    const history: ChatTurn[] = Array.isArray(rawHistory)
      ? rawHistory
          .filter(
            (t): t is ChatTurn =>
              !!t &&
              typeof t === "object" &&
              (t.role === "user" || t.role === "assistant") &&
              typeof t.content === "string",
          )
          .slice(-MAX_HISTORY_TURNS)
      : [];

    const anthropicKey = Deno.env.get("ANTHROPIC_API_KEY");
    if (!anthropicKey) {
      console.error("ANTHROPIC_API_KEY is not set");
      return json({ error: "The advisor isn't configured yet." }, 500);
    }

    const systemWithContext = `${SYSTEM_PROMPT}\n\nCONTEXT:\n${JSON.stringify(context ?? {})}`;

    const anthropicRes = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "x-api-key": anthropicKey,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: ANTHROPIC_MODEL,
        max_tokens: MAX_REPLY_TOKENS,
        system: systemWithContext,
        messages: [
          ...history.map((t) => ({ role: t.role, content: t.content })),
          { role: "user", content: message },
        ],
      }),
    });

    if (!anthropicRes.ok) {
      const detail = await anthropicRes.text();
      console.error("Anthropic error", anthropicRes.status, detail);
      return json({ error: "The advisor couldn't respond just now. Try again." }, 502);
    }

    const anthropicJson = await anthropicRes.json();
    const reply: string = anthropicJson?.content?.[0]?.text ?? "";

    if (!reply.trim()) {
      return json({ error: "Didn't get a clear answer back. Try asking again." }, 502);
    }

    return json({ reply: reply.trim() }, 200);
  } catch (error) {
    console.error("ai-advisor unexpected error", error);
    return json({ error: "Unexpected error reaching the advisor" }, 500);
  }
});
