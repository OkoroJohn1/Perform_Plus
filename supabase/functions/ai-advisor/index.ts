// Powers the AI Advisor's chat ("Performia") -- the Flutter client sends
// the student's free-text message plus a CONTEXT object that is already
// fully computed/resolved client-side (CGPA, classification, goal
// projection, plus a per-course breakdown -- grade, credit unit, pass/fail,
// carryover status for every attempt on record -- all built by
// `buildAdvisorChatContext` in advisor_insights.dart) and a short rolling
// history of the conversation. This function's only job is to phrase those
// facts into a reply -- it is never asked to compute a CGPA/GPA/projection
// itself, even though it now sees individual course grades. See AGENTS.md's
// "THE RULE THAT MATTERS MOST": the LLM never performs arithmetic.
//
// Streams the reply back token-by-token (Anthropic's own streaming API,
// re-emitted as a simple newline-delimited `data: {"delta": "..."}` feed --
// not Anthropic's raw SSE event shape, so the client never has to track
// Anthropic's wire format). Before this, the function buffered the ENTIRE
// reply before responding -- the student saw nothing at all for however
// long the full generation took, often several seconds. Every
// auth/rate-limit/validation failure below still happens BEFORE the stream
// starts and returns a normal single JSON error response; only the actual
// model reply is streamed.
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
- Never invent or infer a CGPA, grade, classification, required average, or any other number that isn't explicitly present in CONTEXT. CONTEXT.course_breakdown lists every course attempt on the student's real record (code, title, level/term, credit unit, grade, grade point, pass/fail, carryover status), already sorted weakest grade point first -- CONTEXT.weakest_courses is a convenience top-5 slice of it, and CONTEXT.outstanding_carryovers lists only the courses still unresolved. Use these by name when asked "what am I doing poorly in", "how am I doing in <course>", or "what's still outstanding" -- that is exactly what they are for. If a specific question genuinely isn't covered by anything in CONTEXT (e.g. a course that never appears in course_breakdown at all), say plainly that you don't have that and point them to the relevant screen (Academics for results/roadmap, or Goal setting for targets) -- never estimate it yourself.
- When asked how to improve a weak course, you may suggest general, honest study strategies (revisiting foundational/prerequisite material, attending tutorials or office hours, forming a study group, prioritising that course's credit-weight relative to others, asking the course lecturer or department for past question patterns) -- framed as reasonable things to try, never as a guaranteed fix, since you have no visibility into that course's actual syllabus, lecturer, or exam style. Keep this to one or two concrete suggestions, not an exhaustive study-skills lecture.
- Nigerian academic terms: CGPA is on the institution's own scale (often 5.0, sometimes 4.0) printed in CONTEXT -- never assume a US 4.0 GPA scale. "First Class", "2:1", "2:2", "Third Class", "Pass" are classification bands, not letter grades. A "carryover" is a failed course retaken later.
- If CONTEXT.is_critical is true, the student's CGPA is below their scheme's lowest classification (below even a Pass). Tell them directly and plainly that they should withdraw or discuss repeating the year with their department right away -- do not soften this into a vague "talk to someone" and do not avoid the word withdraw. You may still mention that their department handles the actual process (probation, repeat, appeal), but the advice itself -- withdraw or repeat -- is yours to give here, not something to defer entirely. You may gently mention their school's counselling unit if the conversation suggests more than academic stress.
- Never suggest, excuse, or go quiet on illegal or academic-malpractice shortcuts. Whenever you're advising a student on what to do next -- recovering from a low CGPA, catching up on carryovers, or handling academic difficulty generally -- include a brief, natural reminder not to pursue things like bribing staff, buying leaked exam questions, forging results or documents, or paying someone to sit an exam for them. Keep it short and supportive, not a lecture, and only when the conversation is actually about what to do, not on every unrelated message.
- Keep replies conversational and concise -- normally 2-4 short sentences, more only if the student's question genuinely needs it. No markdown headers or bullet lists unless comparing multiple concrete numbers.
- You are supportive but never falsely congratulatory -- if CONTEXT shows a falling trend or a demanding/unreachable goal, say so plainly and constructively, the same honest tone the app's own insight cards use.`;

type ChatTurn = { role: "user" | "assistant"; content: string };

function sseLine(payload: unknown): Uint8Array {
  return new TextEncoder().encode(`data: ${JSON.stringify(payload)}\n\n`);
}

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
        stream: true,
        messages: [
          ...history.map((t) => ({ role: t.role, content: t.content })),
          { role: "user", content: message },
        ],
      }),
    });

    if (!anthropicRes.ok || !anthropicRes.body) {
      const detail = await anthropicRes.text().catch(() => "");
      console.error("Anthropic error", anthropicRes.status, detail);
      return json({ error: "The advisor couldn't respond just now. Try again." }, 502);
    }

    // Re-parse Anthropic's own SSE stream and re-emit just the text deltas
    // in our own small, stable shape -- the client (`advisor_chat_service
    // .dart`) only ever needs to know "here's more text" or "done", never
    // Anthropic's internal event/block bookkeeping.
    const stream = new ReadableStream<Uint8Array>({
      async start(controller) {
        const reader = anthropicRes.body!.getReader();
        const decoder = new TextDecoder();
        let buffer = "";
        let sawAnyText = false;

        try {
          while (true) {
            const { done, value } = await reader.read();
            if (done) break;
            buffer += decoder.decode(value, { stream: true });

            const lines = buffer.split("\n");
            buffer = lines.pop() ?? "";

            for (const line of lines) {
              const trimmed = line.trim();
              if (!trimmed.startsWith("data:")) continue;
              const payload = trimmed.slice(5).trim();
              if (!payload || payload === "[DONE]") continue;

              let event: Record<string, unknown>;
              try {
                event = JSON.parse(payload);
              } catch {
                continue;
              }

              if (
                event.type === "content_block_delta" &&
                (event.delta as Record<string, unknown> | undefined)?.type === "text_delta"
              ) {
                const text = (event.delta as Record<string, unknown>).text as string;
                if (text) {
                  sawAnyText = true;
                  controller.enqueue(sseLine({ delta: text }));
                }
              } else if (event.type === "error") {
                console.error("Anthropic stream error event", event);
                controller.enqueue(sseLine({ error: "The advisor couldn't finish responding. Try again." }));
              }
            }
          }
        } catch (streamError) {
          console.error("ai-advisor stream read error", streamError);
          if (!sawAnyText) {
            controller.enqueue(sseLine({ error: "The advisor couldn't respond just now. Try again." }));
          }
        } finally {
          if (!sawAnyText) {
            // Anthropic returned a 200 with a stream that never produced any
            // text (e.g. immediately hit a content filter) -- the student
            // must still see something rather than a permanently blank bubble.
            controller.enqueue(sseLine({ error: "Didn't get a clear answer back. Try asking again." }));
          }
          controller.enqueue(sseLine({ done: true }));
          controller.close();
        }
      },
    });

    return new Response(stream, {
      status: 200,
      headers: {
        "Content-Type": "text/event-stream; charset=utf-8",
        "Cache-Control": "no-cache",
        Connection: "keep-alive",
        ...corsHeaders,
      },
    });
  } catch (error) {
    console.error("ai-advisor unexpected error", error);
    return json({ error: "Unexpected error reaching the advisor" }, 500);
  }
});
