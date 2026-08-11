# AGENTS.md

Context for AI coding agents working on this repository.

## What this is

**Perform+** — a Flutter app for Nigerian university students. Tracks CGPA,
projects graduation outcomes, and provides AI academic advice grounded in
computed facts.

Target users: undergraduates at Nigerian institutions on the 5.0 grade-point
scale, in levels 100–600, often on unreliable mobile data.

Platform: Flutter (Android primary, iOS later). Backend: Supabase.
Local-first with Drift/SQLite as the source of truth.

---

## THE RULE THAT MATTERS MOST

```
Results ──► CGPA Engine ──► computed facts ──► AI ──► prose
             (pure Dart)      (function call)   (LLM)
```

**The LLM never performs arithmetic.**

It receives a computed payload — see `TargetProjection.toAdvisorPayload()` —
and phrases it in natural language. It is never handed raw grades and asked
a mathematical question, because it will confidently invent an answer that
looks right.

If you are adding an AI feature and find yourself putting grade data in a
prompt so the model can "figure out" a GPA, stop. Add a method to the engine
instead and pass its output.

This is enforced structurally, not by prompt instruction. Do not weaken it.

---

## Directory map

```
lib/
├── main.dart                  Entry point
├── app.dart                   MaterialApp.router
├── core/
│   ├── constants/             App-wide constants, thresholds, limits
│   ├── router/                go_router config + route table
│   ├── theme/                 Material 3 theme, single seed colour
│   ├── errors/                Failure types
│   └── utils/                 Formatters
├── domain/                    ← PURE. No I/O, no async, no Flutter imports.
│   ├── models/
│   │   ├── grading_scheme.dart    Scheme, grades, bands, repeat policy
│   │   └── course_result.dart     CourseResult, Semester
│   ├── engine/
│   │   ├── cgpa_engine.dart       GPA, CGPA, classification, cascades
│   │   └── projection_solver.dart Forward + backward projection
│   └── repositories/          Abstract interfaces only
├── data/
│   ├── local/                 Drift DB, DAOs (NOT YET BUILT)
│   ├── remote/                Supabase clients (NOT YET BUILT)
│   ├── repositories/          Concrete implementations
│   └── seed/                  Institutions + default grading schemes
├── features/                  One folder per feature
│   └── <feature>/
│       ├── screens/
│       ├── widgets/
│       └── providers/         Riverpod
└── shared/widgets/            AppScaffold, EmptyState

test/engine/                   23 tests, pure Dart, no device needed
```

**`lib/domain/` must stay pure.** No `package:flutter` imports, no async, no
network, no database. This is what makes the app work offline and the tests
run in milliseconds. If you need I/O, it belongs in `data/`.

---

## Current state

| Area | Status |
|---|---|
| Domain models | Complete |
| CGPA engine | Complete, 23 tests passing |
| Carryover / repeat policy | Complete, tested across all 3 variants |
| Recalculation cascade | Complete |
| Projection solver | Complete |
| Grading scheme validation | Complete |
| Seeded institutions | FUTO only wired into the flow for now; the other 9 in `nigerian_institutions.dart` are unused but kept for a future re-expansion — **content unverified** |
| Routing, theme, 5-tab shell | Complete — dark gradient/glass design system (`GradientScaffold`/`GlassCard`/`GradientButton`) applied app-wide |
| Act 1 screens | Working (splash → add results → GPA reveal); no institution picker |
| Manual result entry | Working — two-step: list courses (code + credit unit), then a dedicated grades step |
| OCR import | Explicitly out of scope until a real result slip is tested against a real service — see "Grading schemes" section below. Slip photo is a visual reference only, never parsed |
| Auth | Stub, returns fake local user |
| Local DB (Drift) | Working — `profiles`/`semesters`/`course_results`/`grading_schemes`/`goals`, one DAO each, repository interfaces in `lib/domain/repositories/` |
| Dashboard | Wired to `CgpaEngine.computeStanding()`; empty/partial/full states |
| Results CRUD | Not started |
| Roadmap / Reports / PDF | Not started |
| Study tab (notes, reading, exams) | Not started |
| AI advisor | Payload contract exists, nothing calls it |
| Backend | Not started |

Roughly 20–25% of V1. Every stub carries a `TODO(v1)` or `TODO(v2)` comment
naming what belongs there.

---

## Domain concepts

**Level** — 100 to 600. Two semesters each. Roughly equals year of study.

**Session** — academic year written as `2024/2025`, running Sept–Aug.

**Credit unit** — 1–12, typically 2–4. Weights each course in the average.

**Quality points** — grade point × credit unit.

**GPA** — one semester. `Σ(quality points) / Σ(credit units)`

**CGPA** — cumulative across all semesters. **Weighted by credit unit, not
the mean of semester GPAs.** A 5.0 over 6 units then 3.0 over 18 units is
3.50, not 4.00.

**Carryover** — a failed course retaken in a later semester. See below.

**Classification** — First Class (4.50+), 2:1 (3.50), 2:2 (2.40), Third
(1.50), Pass (1.00). Boundaries vary by institution.

---

## Grading schemes: four separable concerns

Do not collapse these. `GradingScheme` keeps them apart deliberately:

1. **Score → letter** — is an A 70+ or 75+?
2. **Letter → grade point** — 5.0 scale vs 4.0
3. **Classification bands** — the 2:2 floor is 2.40 at some schools, 2.50 at others
4. **Repeat / carryover policy** — the one everyone forgets

Schemes are **versioned and effective-dated** because universities revise
their scales. A 2019 entrant may be graded differently from a 2024 entrant,
and both must remain computable.

### Carryover is the highest-risk area in the codebase

`RepeatPolicy` has three variants. Same transcript, three outcomes:

| Policy | CGPA | Units counted |
|---|---|---|
| `countBothAttempts` | 3.00 | 9 |
| `replaceOriginal` | 4.50 | 6 |
| `replaceWithCap` (3.0) | 2.67 | 9 |

That is the difference between 2:2 and First Class on one transcript.

A wrong policy produces a **plausible-looking wrong number**, which is worse
than an obvious error — the student has no reason to question it. Never guess
a policy when adding an institution. Confirm with the registry.

**Supersession points FORWARD in time.** The failure sits in 100L, the
retake sits in 200L. `_supersededResultIds()` scans the whole record before
any semester is computed. An earlier version looked only at prior semesters
and silently never dropped anything — the tests caught it. Do not reintroduce
per-semester supersession logic.

---

## Rules for the engine

- **Never silently zero an unrecognised grade.** Exclude it, record a
  `CalculationIssue`, and surface it. A silent zero corrupts the CGPA with
  no visible cause.
- **Never throw during calculation.** Collect issues and return them. One
  bad row must not blank the entire dashboard.
- **Always show what changed.** `recalculate()` returns a
  `RecalculationResult` with the before/after delta. Editing a 200L grade
  cascades through every downstream semester; the student must see it.
- **Round to 2 decimal places** via `CgpaEngine.round2()`. Matches printed
  transcripts.
- **Every excluded result carries a human-readable reason.** A student must
  always be able to answer "why isn't this course in my CGPA?" without
  contacting support.

---

## No fabricated probabilities

`Feasibility` is an enum, not a percentage. "68% likely to make First Class"
would be invented — there is no cohort baseline and no honest way to derive
one from a single transcript.

Instead, feasibility compares the required average against the student's own
demonstrated best:

> First Class needs 4.75 across your remaining 4 semesters. Your best
> semester so far is 4.31.

Defensible, and it motivates better than a made-up number.

**If you add an ML prediction feature, it needs real institutional grade
distribution data first.** Do not approximate it with an LLM guess.

### The impossible case is designed, not error-handled

A 400L student at 3.10 asking about First Class must be told once, plainly,
then immediately pivoted to `nearestAchievable`. Never a red error state.
This is the most emotionally loaded moment in the app.

---

## UX architecture

Three acts. This structure is deliberate — do not gate Act 1 behind auth.

**Act 1 — pre-account, no login.** Splash → add results → **GPA reveal**.
Value arrives before signup. The student then has data to lose, which
converts far better than a toll gate. No institution picker — the app is
FUTO-only for now (see "Open questions"), so onboarding skips straight from
splash to results entry.

**Act 2 — commitment.** Auth → profile → backfill → **goal setting**.
Goal setting is a first-class step; every later screen is framed against the
answer. Without it, the app is a calculator. By the time a student reaches
this screen they already have at least one semester of results from Act 1,
so the projections shown here are real, not aspirational — the no-data
`EmptyState` in `goal_setting_screen.dart` is a defensive fallback, not the
expected path.

**Act 3 — return loop.** Five tabs. Grouped by what the student is *doing*:

| Tab | Contains | Answers |
|---|---|---|
| Home | Dashboard, trend, next action, notifications bell | — |
| Academics | Results, Roadmap, Reports, Strength Analysis | "where do I stand" |
| AI | Advisor (V1), Chat (V2) | — |
| Study | Notes, Flashcards, Reading, Exams, Planner | "what do I do about it" |
| Me | Profile, Achievements, Settings | — |

New features go in the tab matching their *question*, not their technology.

Notifications are a **bell in the Home header**, not a tab. Nobody navigates
to notifications; they respond to a badge.

---

## Every screen needs an empty state

Every mockup showed a populated account: 5 semesters, 4.32 CGPA, 18-day
streak. **A day-one user sees none of that.**

Use `shared/widgets/empty_state.dart`. Locked features show their unlock
condition — locked-but-visible motivates, hidden does not.

Partial states matter too: Roadmap with one semester can't draw a trend;
Reading analytics at zero hours looks broken unless framed as an invitation.

---

## Constraints specific to this project

**Offline-first is non-negotiable.** Nigerian students on 3G in lecture
halls must open the app and see a working dashboard. The engine is pure
computation and runs with zero network. Only AI calls require connectivity,
and they must degrade gracefully.

**Never ship API keys in the Flutter binary.** It decompiles trivially. All
AI calls proxy through the backend, which is also where per-user rate
limiting lives.

**Never request university portal credentials.** Credential-theft liability,
breaks on every portal redesign, likely violates institutional terms. Result
slip **screenshot import** is the sanctioned path.

**Manual entry is the PMF problem.** A 400L student has ~40 courses behind
them. Forty rows of typing before value appears is where every Nigerian CGPA
app has died. OCR import ranks above the chatbot in priority.

**Cost discipline.** "Unlimited AI" at NGN pricing loses money. Cap by
credits. Route cheap models for summarisation, frontier only for advisory.
Hash-dedupe uploaded documents — fifty students in CSC 301 upload the *same*
lecture PDF; generate the summary once.

**Payments are Paystack or Flutterwave, priced in Naira.** Not Stripe.

---

## Conventions

- **State:** Riverpod. `StateNotifierProvider` for mutable, `Provider` for derived.
- **Routing:** go_router. Paths in `core/router/routes.dart`, never inline strings.
- **Style:** `flutter_lints`, single quotes, trailing commas.
- **Visual design:** dark blue-black gradient + frosted glass, applied via
  `shared/widgets/gradient_scaffold.dart`, `glass_card.dart`,
  `gradient_button.dart` — use these instead of bare `Scaffold`/`Card`/
  `FilledButton` everywhere. `AppTheme.light`/`.dark` both resolve to the
  same dark-appropriate `ColorScheme` since the backdrop is permanently
  dark now; there is no flat light theme left in the app.
- **IDs:** UUID v4 via `uuid`.
- **Money:** Naira. **Never floats.** Integer kobo.
- **Dates:** ISO 8601 in storage, `intl` for display.
- **Naming:** files `snake_case.dart`, classes `PascalCase`, private `_prefixed`.

---

## Testing

```bash
flutter test              # 23 tests, no device needed
```

Engine tests are pure Dart — no emulator, no Android SDK, no network.
**They must always pass before a commit.**

When adding engine behaviour, add a test that would fail without it. The
carryover bug above was caught this way in shipped code, before any user saw
a wrong CGPA.

Widget tests are not yet set up.

---

## Before you ship

1. **Verify every seeded grading scheme** against the institution's current
   student handbook. `data/seed/nigerian_institutions.dart` contains
   reasonable defaults, not transcribed policy. UI's 7-point scale is
   currently approximated as 5.0 and is wrong as written.
2. **Test OCR on a real result slip** from the target institution before
   planning around it. If accuracy is poor on actual portal output, the
   Add Results screen collapses back into manual typing and the flow needs
   rethinking.
3. **Enable Supabase Row Level Security** from day one. Academic records are
   sensitive.

---

## Roadmap

**V1** — Auth, profile, scheme engine, result-slip import, dashboard,
goal-setting with feasibility math, PDF report, reading timer + streak.
No chatbot.

**V2** — Notes upload → summary, flashcards, quiz generation. Advisor chat
grounded in engine output. Study planner. Payments. Strength analysis.

**V3** — Voice, community, multi-university at scale, course difficulty DB.

Community and difficulty DB are deferred deliberately: both are cold-start
dependent, useless at 50 users, valuable at 5,000 in one school. That argues
for launching one institution deep rather than nine shallow.

---

## Open questions

1. ~~One institution or nine at launch?~~ **Resolved: FUTO only.** The
   institution picker is removed; `OnboardingDraftNotifier` defaults straight
   to `defaultSchemes['futo']`. The other 9 seeded institutions stay in
   `nigerian_institutions.dart`, unused, for a cheap future re-expansion.
2. **Does the reading timer belong in V1?** It is the only daily hook — the
   CGPA loop fires twice a year, which is uninstall territory — but it is
   unrelated to the core value proposition.
3. **What is "Focus Score"?** Appears on the Reading Analytics mockup with
   no definition. Define the formula or remove it. Invented metrics are cheap
   to display and expensive to credibility.

---

## Things not to do

- Do not let the LLM compute grades, GPAs, or projections.
- Do not add `package:flutter` imports to `lib/domain/`.
- Do not guess a carryover policy.
- Do not gate Act 1 behind authentication.
- Do not fabricate probability scores.
- Do not add portal credential scraping.
- Do not put API keys in the client.
- Do not use floats for currency.
- Do not build screens without empty states.
- Do not commit with failing engine tests.
