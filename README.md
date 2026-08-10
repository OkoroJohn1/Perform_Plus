# Perform+

Academic performance tracking and AI advisory for Nigerian university students.

## Getting started

```bash
flutter pub get
flutter test          # engine tests should pass with zero setup
flutter run
```

Open the folder in VS Code. Install the recommended extensions when prompted
(`.vscode/extensions.json`). Three launch configs are pre-set in
`.vscode/launch.json`.

You can run the tests before touching any backend — the engine is pure Dart
with no I/O, no async, and no Flutter dependency.

---

## What is actually implemented

| Area | Status |
|---|---|
| CGPA engine (GPA, CGPA, classification) | **Complete + tested** |
| Carryover / repeat policy handling | **Complete + tested** |
| Recalculation cascade with before/after delta | **Complete + tested** |
| Projection solver (forward + backward) | **Complete + tested** |
| Grading scheme model + validation | **Complete** |
| Seeded Nigerian institutions | **Complete** (needs verification — see below) |
| Routing, 5-tab shell, theme | **Complete** |
| Act 1 screens (splash → institution → results → GPA reveal) | **Working** |
| Manual result entry | **Working** |
| OCR import | **Stubbed** — UI present, service not wired |
| Auth | **Stubbed** — returns a local dev user |
| Local DB (Drift) | **Not started** |
| Dashboard, Academics, Study, Me | **Empty-state stubs** |
| AI advisor / chat | **Not started** |

Every stub carries a `TODO(v1)` or `TODO(v2)` comment explaining what goes
there and why.

---

## Architecture: the one rule that matters

```
  Results ──► CGPA Engine ──► computed facts ──► AI Advisor ──► prose
                (pure)          (function call)      (LLM)
```

**The AI never performs arithmetic.** It receives a computed payload
(`TargetProjection.toAdvisorPayload()`) and phrases it. It is never handed
raw grades and asked a maths question, because it will confidently invent an
answer.

Enforce this structurally, not by prompt instruction. If you later add open
chat, it inherits this plumbing via function calling rather than guessing.

`lib/domain/engine/` is pure: no I/O, no async, no Flutter imports, no
network. Keep it that way — it is what makes the app work offline and what
makes the tests trivial.

---

## Things that will bite you

**1. Carryover policy is not optional.**
Three institutions, same transcript, three different CGPAs — 3.00, 4.50, and
2.67. See the `carryover policy` test group. Guessing here produces a
*plausible-looking wrong number*, which is worse than an obvious error
because the student will not know to question it. Confirm the policy with
each registry before adding an institution.

**2. The seeded schemes are unverified.**
`lib/data/seed/nigerian_institutions.dart` contains reasonable defaults, not
transcribed policy. Check each against the current student handbook. The 2:2
floor in particular is 2.40 at some schools and 2.50 at others. UI's 7-point
scale is currently approximated as 5.0 and is wrong as written.

**3. Manual entry is the product-market-fit problem.**
A 400-level student has ~40 courses behind them. Forty rows of typing before
any value appears is where every Nigerian CGPA app has died. Result-slip
import is the highest-leverage feature in the codebase — rate it above the
chatbot.

Before planning around it, **grab one real result slip from your target
institution and test extraction on it.** If accuracy is poor on the actual
portal output format, Act 1 collapses back into manual typing and the flow
needs rethinking.

Do **not** add portal-credential scraping. It is a credential-theft
liability, it breaks on every portal redesign, and it likely violates the
institution's terms.

**4. The core loop fires twice a year.**
CGPA updates when results drop. An app opened twice a year is uninstalled.
The reading timer is the only daily hook in V1 — that is deliberate.

**5. Never ship API keys in the binary.**
Flutter decompiles trivially. All AI calls proxy through your backend, which
is also where per-user rate limiting lives.

**6. "Unlimited AI" at NGN 3–5k/month loses money.**
Cap by credits (200 actions/month reads as generous and bounds cost). Route
cheap models for summarisation, frontier only for advisory. Hash-dedupe
uploaded documents — fifty students in CSC 301 upload the *same* lecture
PDF; generate the summary once.

---

## Deliberate omissions

**No probability scores.** "68% likely to make First Class" would be
fabricated — there is no cohort baseline and no honest way to derive it from
one transcript. `Feasibility` compares the required average against the
student's own demonstrated best instead:

> First Class needs 4.75 across your remaining 4 semesters. Your best
> semester so far is 4.31.

Defensible, and it lands harder than a made-up number.

**The impossible case is designed, not error-handled.** A 400L student at
3.10 asking about First Class gets told once, then immediately pivoted to
`nearestAchievable`. It is the most emotionally loaded moment in the app and
must never be a red error state.

**Community and course-difficulty DB are deferred.** Both are cold-start
dependent: useless at 50 users, valuable at 5,000 in one school. That argues
for launching one institution deep rather than nine shallow.

---

## Roadmap

**V1** — Auth, profile, scheme engine, result-slip import, dashboard,
goal-setting with feasibility math, PDF report, reading timer + streak.
No chatbot.

**V2** — Notes upload → summary, flashcards, quiz generation. Advisor chat
grounded in engine output. Study planner. Payments.

**V3** — Voice, community, multi-university at scale, difficulty database.

---

## Open questions

1. **One institution or nine at launch?** Determines whether the
   result-import investment pays off, and whether the community features
   ever reach critical mass.
2. **Does the reading timer belong in V1?** It is the only daily hook, but
   it is unrelated to the core value proposition.
3. **What is "Focus Score"?** It appears on the Reading Analytics mockup
   with no definition. Define the formula or remove it — invented metrics
   are cheap to display and expensive to credibility.
