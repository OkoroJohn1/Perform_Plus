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

test/engine/                   24 tests, pure Dart, no device needed
```

**`lib/domain/` must stay pure.** No `package:flutter` imports, no async, no
network, no database. This is what makes the app work offline and the tests
run in milliseconds. If you need I/O, it belongs in `data/`.

---

## Current state

| Area | Status |
|---|---|
| Domain models | Complete |
| CGPA engine | Complete, 24 tests passing. `GradingScheme.cgpaAggregation` (`CgpaAggregationMode`) is a second, opt-in scheme-level setting alongside repeat policy -- the default `creditWeighted` method is unchanged and is what every seeded institution uses; a `recursiveSemesterAverage` method (`CGPA_n = (CGPA_{n-1} + GPA_n) / 2`, credit-unit-blind) exists only because a second institution's registry confirmed it uses that method, not as a guess. Never set it on a new scheme without the same registry confirmation -- see `CgpaAggregationMode`'s doc comment and section 4.4/Appendix C.2 of `report/Perform_Plus_Project_Report.docx` for a worked example of the two methods resolving an identical transcript to different classifications (2:2 vs 2:1) |
| Carryover / repeat policy | Complete, tested across all 3 variants |
| Recalculation cascade | Complete |
| Projection solver | Complete. `solveForTarget`/`simulate` branch on `cgpaAggregation`: the default method's projections stay linear (unchanged), but under `recursiveSemesterAverage` a semester's influence on the cumulative figure decays geometrically (`2^k`), not linearly, so both the backward (required-average) and forward (what-if) formulas were re-derived rather than reused |
| Grading scheme validation | Complete |
| Seeded institutions | 16 wired into the institution picker, FUTO pre-selected; every scheme except FUTO's is `isVerified: false` — **content unverified**, see `GradingScheme.isVerified` |
| Routing, theme, 5-tab shell | Complete — `GradientScaffold`/`GlassCard`/`GradientButton` still exist and are used by institution setup and a few cards, but every tab screen (Home/Academics/Study/Me) now paints its own light `#F7F7FB` surface via the shared `AppScaffold`, with the dark gradient confined to those remaining `GradientScaffold` call sites. `AppTheme.light()`/`.dark()` take an `AppAccent` (see the Me tab's Theme colour picker) and register a `core/theme/app_palette.dart` `AppPalette` `ThemeExtension` (read via `context.palette`) computed per brightness+accent — genuinely distinct light/dark `ThemeData`s now (previously both silently built the dark theme regardless of brightness). **Retrofit status**: every tab's own Scaffold background and the bottom nav's gradient now read `context.palette`, so toggling Dark or the accent picker visibly changes the whole app's background/nav. The mechanical per-screen sweep of `OnboardingLightPalette.primary` -> `context.palette.primary` is now done across every post-auth screen that has an accent-following purpose (Dashboard incl. its avatar/menu icon/Next Action/quick-stats icons, Academics' shell/results/roadmap/reports, AI's shell/advisor-chat-sheet, Study's shell/upload-note-sheet, Me's shell incl. its "First Steps" badge, and the Notifications panel incl. its bell/segmented-tabs/mark-all-read) — each conversion required un-`const`ing the widget it sits inside, since `context.palette.primary` is a runtime value, and two call sites (`ai_shell.dart`'s `Insight`, `notifications_panel.dart`'s `AppNotification`) had their `Color get color` extension getters turned into `colorFor(AppPalette)` methods since a plain Dart extension has no `BuildContext` to read the palette from. Onboarding/auth screens (`add_first_results_screen.dart`, `backfill_screen.dart`, `goal_setting_screen.dart`, `gpa_reveal_screen.dart`, `institution_setup_screen.dart`, `sign_in_screen.dart`, `profile_setup_screen.dart`) are deliberately excluded — they predate any accent choice and stay permanently on `OnboardingLightPalette`/Blue by design |
| Act 1 screens | Working (splash → institution setup → add results → GPA reveal), completing at 100% on its own 4-step counter |
| GPA reveal | Working, light theme — shows the just-committed semester's own GPA (never a CGPA; that only appears once 2+ semesters exist, elsewhere). No fabricated cohort ranking, overall-average percentage, subject-area breakdown, or "Excellent" label — the mockup's four fabricated metrics are gone. Classification pill colour/label/icon are derived from `GradingScheme.classify(gpa)`'s position in `bandsDescending`, never hardcoded. Confetti (`_Confetti`, custom-painted, no package) is gated to the top two bands and to `!MediaQuery.disableAnimationsOf`. "How this was calculated" (`ExpansionTile`) itemises every counted course's quality points down to the total, and any `SemesterComputation.excluded` row surfaces its own reason plus a "Fix" action back to add-results — never a silent drop. "Add another semester" advances level/term (`_nextSemester`) and returns to add-results; the draft's rows are NOT cleared between commits (pre-existing behaviour, unchanged by this screen) |
| Act 2 screens | Sign-in/sign-up, profile setup, backfill and goal setting all working (all 4 of Act 2's own restarted 4-step counter — see `OnboardingHeader`/`AccountSetupStep`). **Fixed a real regression**: `AuthState.profileComplete` only ever tracked step 2 (Profile Setup), not the full sequence — a student who backgrounded/killed the app between Profile Setup and Goal Setting landed straight in the tab shell on next launch and never saw Backfill/Goal Setting again, since `splash_screen.dart` routes any signed-in user to `Routes.home` and nothing else re-checked onboarding progress. Fixed with a separately persisted `AuthState.onboardingComplete` (new `local_settings` key `onboardingComplete`, set by `AuthNotifier.markOnboardingComplete()` when Goal Setting is saved OR skipped) and a router `redirect` rule that sends `profileComplete && !onboardingComplete` back to `Routes.backfill` (which self-skips to Goal Setting if nothing's left to backfill) |
| Sign-up/sign-in resolution | **Fixed a real data-integrity bug**: `AuthNotifier`'s `onAuthStateChange` listener silently ignored a `null`-session event (a genuine sign-out), leaving this provider's state stuck on stale "signed in" data; and `_stateFor` unconditionally called `reassignProfile` on every resolution, moving whatever sat under the pre-auth placeholder profile (`AppConstants.localProfileId`) onto the real uid even when that uid already had its own semesters on this device — which is exactly what happened to a student who lost their session (e.g. a cold-start race) and got routed back through onboarding: their freshly re-entered results landed *beside* their existing ones instead of being recognised as a duplicate. Fixed with `AcademicRecordRepository.hasSemestersForProfile`/`discardProfile`: `_stateFor` now checks whether the signing-in uid already has real data first — if so, the stray pre-auth draft is deleted instead of merged in. The institution setup screen also gained an "Already have an account? Sign in" link (`alreadyHaveAccountTap`) so a student who realises they're re-onboarding can jump straight to sign-in instead of finishing the flow first |
| Goal setting | Working, light theme — target picker options and required-average/feasibility/nearest-achievable figures all come from `ProjectionSolver.allBandProjections`/`solveForTarget`, nothing computed in the widget layer. All six `Feasibility` states have distinct copy/colour (`FeasibilityPalette`); `unreachable` is grey, not red, and pivots in-card to `nearestAchievable` via "Set this instead". Live target changes recalculate everything with a 250ms crossfade and a 400ms eased number animation. Skip/Save both reach the dashboard — goal setting never blocks it. **Known issue, not fixed here**: `Feasibility.comfortable` is unreachable dead code in `ProjectionSolver._assess()` — whenever `target <= currentCgpa` (required for "comfortable"), `required <= currentCgpa` is also always true, so the earlier `secured` check always fires first. Out of scope for this screen task since it's shared engine logic; worth a follow-up |
| Backfill | Working — the expected semester set is derived from the profile (`domain/models/backfill_plan.dart`), never a fixed 100–600 range, so a 300L student is asked for 4–6 semesters, not twelve. Term names come from the active scheme (`GradingScheme.termLabel`); level noun from `Institution.levelNoun`. Writes straight to `academicRecordProvider` (persistent), skips itself entirely on entry if there's nothing left to backfill |
| Profile setup | Working — faculty (filtering department options where known) and an optional local profile photo added to `StudentProfile`; entry year prefills from the reg number via each institution's own `RegNumberFormat` (see below), expected graduation defaults from it, and a live "N semesters remaining" line surfaces a bad year combination before it reaches `ProjectionSolver`. Saves local Drift first, then best-effort UPDATEs the Supabase `profiles` row (never insert — the trigger already created it) via `ProfileRemoteSync`; `faculty` and the photo are NOT in that remote payload yet — the live schema was last confirmed (Supabase paused/unreachable at time of writing) to have neither column |
| Institution setup screen | Working — light theme (see `AppTheme.onboardingLight`/`OnboardingLightPalette`, shared with add-results); search, "Other (Add Manually)", unverified-scheme warning. Scheme "Change"/"Review" opens a read-only viewer — no scheme editor yet. `LettermarkAvatar` renders a real logo instead of the abbreviation when `Institution.logoAsset` is set — currently only FUTO's, a plain gradient wordmark verified as `{{PD-textlogo}}` on Wikimedia Commons (below the threshold of copyright originality, not the university's actual pictorial seal). A background research pass checked all other 15 seeded institutions for a similarly clearable logo and found none: no file at all, an unrelated same-name match (a Wikimedia fan-club badge, a UK engineering company, an industrial band), or an elaborate pictorial crest mislabeled "own work"/CC-BY-SA that isn't credible given the artwork's complexity. Do not add another `logoAsset` entry without the same license verification — see `Institution.logoAsset`'s doc comment |
| Add-results screen | Working — session/level/term picker (term names read from `GradingScheme.termLabel`, e.g. FUTO's Harmattan/Rain), slip-photo upload with a full state machine (selected/uploading/failure/offline), manual course-code entry, then an in-place "grades" phase for one grade per course. Slip extraction has no backend yet (see "Backend" below) — every real upload attempt resolves to failure/offline, never a fabricated success; the photo is kept only as a local reference (`OnboardingDraft.slipImageBytes`) |
| Manual result entry | Working — two-step: list courses (code + credit unit), then a dedicated grades step |
| OCR import | **Shipped for course registration slips** (see "Add a semester" row below) — a real Edge Function, not a stub. Result-slip OCR (`add_first_results_screen.dart`, onboarding) is still explicitly out of scope until tested against a real slip — its slip photo remains a visual reference only, never parsed. The two are different documents (a registration slip lists courses before results exist, so extraction there never produces a grade) and were deliberately not unified into one pipeline this pass |
| Auth | Working — Supabase email/password + Google OAuth (Google gated off on Android until its own OAuth client exists, see `AppConstants.enableGoogleSignInOnAndroid`); sign-up is the default mode, sign-in only when this device has signed in before (`lastAccountEmailProvider`, via `flutter_secure_storage`). On sign-up, the pre-auth draft semester is reassigned from the placeholder local profile to the real auth uid (`AcademicRecordRepository.reassignProfile`) |
| Local DB (Drift) | Working — `profiles`/`semesters`/`course_results`/`grading_schemes`/`goals`, one DAO each, repository interfaces in `lib/domain/repositories/` |
| Dashboard | Rebuilt — its own tinted `#F7F7FB` scaffold (`DashboardPalette`), the one screen that isn't the dark gradient or onboarding's flat white; nested `Scaffold`+drawer inside the shared `AppScaffold` bottom nav. Hero CGPA card, goal progress ring, required-pace strip, trend chart (classification-band backdrop, dashed goal line, pulsing latest dot), a pseudo-3D per-semester bar view (`widgets/trend_3d_chart.dart`, front/top/side faces via `CustomPainter`, needs 2+ semesters — below that it shows an explicit `_Trend3DPlaceholder` explaining why, matching the sibling `TrendCard`'s empty state, rather than silently vanishing via `SizedBox.shrink()`), "GPA by Semester" bars (renamed from "Semester by semester"), credit-load split (3+ semesters), next-action card — every figure from `CgpaEngine`/`ProjectionSolver`/`academicRecordProvider`/`goalProvider`, nothing computed in the widget layer. The CGPA hero shows a red "Below 3.50" badge when applicable (`core/theme/performance_flag.dart`'s shared `performanceColor`/`lowPerformanceThreshold`, reused identically on Academics' Results/Roadmap and the Me tab's stat strip). The goal ring's progress is deliberately NOT `currentCgpa/targetCgpa` — see `goalRingProgress` in `widgets/cgpa_card.dart` for the band-floor-relative formula, and `resolveNextAction` in `widgets/next_action_card.dart` for the 4-priority next-action logic. Empty/partial (1 semester)/full (2+) states all render; credit split additionally needs 3+. The greeting is a single line ("Good evening, {first name}"); the four quick stats float as one frosted-glass bar (`BackdropFilter` blur, `QuickStatsRow`) overlapping the bottom edge of the gradient hero card — the one place a glass treatment earns its keep on this screen, since it's the one card with something colourful behind it to blur. App-wide type is now Plus Jakarta Sans via `google_fonts`, applied once in `app_theme.dart`'s two `ThemeData`s (`onboardingLight` and the legacy dark `_build()`) — it cascades to every screen's hardcoded `TextStyle` calls through `DefaultTextStyle` inheritance, not by editing each screen. The bottom nav (`shared/widgets/glass_nav_bar.dart`) is a frosted-glass bar over a visibly drifting semi-transparent gradient (an animated-gradient stand-in for a literal video background — no video asset exists and one would cost real APK size/battery for a bottom bar; colours are deliberately alpha ~0.68, not opaque, since an opaque fill over `BackdropFilter` defeats the blur entirely) with filled/outline icon pairs and an animated pill behind the selected tab; "AI" is labelled "Advisor", "Profile" is labelled "Me". The outer `AppScaffold` (`shared/widgets/app_scaffold.dart`) paints a plain light `#F7F7FB` background, not `GradientScaffold` — the latter's permanent dark gradient used to show through the nav bar's rounded top corners since `ClipRRect` clips those corners away from everything else |
| Academics tab | Shell, Results, Roadmap and Reports all rebuilt on the same `#F7F7FB` surface as the dashboard (`academics_shell.dart`/`results_view.dart`/`roadmap_view.dart`/`reports_view.dart`). Segmented control is Results/Roadmap/Reports (Reports locked until a semester exists). Standing card's CGPA hero uses the same gradient as the dashboard's, with a frosted-glass mini-stat bar (semesters/courses/credit units) floating over its bottom edge — the one glass moment on this screen, since it's the one part with something colourful behind it to blur; the credit-split-by-grade bar stays plain white below it for legibility. Each semester row shows its own GPA AND the running "CGPA then" as two distinct, separately-labelled numbers — the classification-band colour system moved out of the dashboard into a shared `ClassificationPalette` (`app_theme.dart`) so this screen, the dashboard, and the GPA reveal pill can't disagree on what a colour means. A new "Grade Breakdown" card gives each semester its own collapsible row (`_SemesterAccordion`, `AnimatedSize`) that reveals a per-grade table (letter/courses/units/points) on tap, rather than only the whole-record aggregate bar. Carryover section groups by course code across the whole raw record (an unretaken single failing attempt still counts). Editing a grade or deleting a course/semester goes through `_showRecalculationSnackBar` — every mutation shows the CGPA before/after with an Undo |
| Results CRUD | Working from the Academics tab's semester detail sheet — edit a course's grade, delete a course, or delete a whole semester, each via the recalculation-cascade + Undo snackbar above. No standalone results-management screen beyond that |
| Roadmap | Rebuilt. **Fixed a real bug**: it used to read `Theme.of(context)`/`GlassCard`, which resolve to the app's old dark-glass `ThemeData` (white text) — sitting on the Academics shell's light background, that rendered as invisible white-on-white text. Now hardcoded to `OnboardingLightPalette` like every other rebuilt screen. A level's timeline dot only shows fully complete (green check) once BOTH terms of that level have a semester on record — one term alone shows as an amber "partial" state (`Icons.adjust`, "1 of 2 semesters uploaded"), not a premature tick. "Simulate future" now uses the student's real remaining-semester count (`semestersRemainingFor`) as its default instead of a hardcoded single semester, lets picking 1/2/4/"rest of programme" via chips, and shows a two-bar now-vs-projected comparison plus the landing classification — `ProjectionSolver.simulate` already supported all of this, the screen just wasn't using it |
| Reports | Rebuilt onto the same light surface, same `Theme.of(context)` bug fixed the same way. PDF export is still an honest "isn't available yet" stub (see pubspec's unused-so-far `pdf`/`printing` packages) — not a fabricated feature |
| Study tab | Rebuilt around e-notes (`study_shell.dart`) — the mockup's course-catalogue framing was dropped since no syllabus taxonomy exists; everything here is built on notes the student actually uploads. New Drift tables `notes`/`note_pages`/`reading_sessions` (schema v5) plus a `study_streak` singleton row (a 4th table beyond the three named in the brief — the streak's own "never infer from session history" rule needs somewhere to live; see `study_streak_table.dart`'s doc comment). `note_reader_screen.dart` renders PDF pages via `pdfx`, with a per-page dwell timer (`domain/engine/study_engine.dart`'s `PageDwellState`/`tickDwell`/`pauseDwell` — pure and unit-tested) that pauses on backgrounding and after 45s idle, and is honestly labelled "Pages read," never "mastered." PDF text extraction isn't wired up yet, so every PDF page currently uses the 8s floor rather than a fabricated word count — see `requiredDwellSeconds`'s doc comment. DOCX/PPTX are rejected with a concrete message (`unsupportedFileMessage`), never a silent failure. Performance stays visibly locked (needs the AI backend). Flashcards and Past Questions are both now real upload entry points into the same `notes` table (`NoteCategory.flashcards`/`.pastQuestion`, stored as text via `textEnum` so adding `flashcards` needed no schema migration) via `showUploadNoteSheet(context, category: ...)` — this is student-uploaded document storage, not an AI-generated interactive deck; the "Flashcards" tile's original AI-drilling vision stays unbuilt until that backend exists, and this upload path is a deliberately smaller, honestly-scoped substitute rather than a claim that the AI feature shipped. Today's Plan is in-memory only (not one of the schema's tables, so it resets on restart). A real month-grid calendar (`widgets/study_calendar_card.dart`, new `calendar_marks` table, schema v10) lets a student tap a day to mark it studied and long-press to attach a note -- local-only like the rest of this tab (no remote calendar to sync against), "realtime" in the sense that a tap updates the Drift-backed `calendarMarksProvider` immediately, not via a network round trip |
| Note/flashcard/past-question durability | **Real gap closed**: uploaded files used to live only in this app's local sandboxed storage -- an uninstall or new device lost them permanently, same as any locally-stored file. `data/repositories/note_remote_sync.dart`'s `SupabaseNoteRemoteSync` now best-effort backs up each note's file plus a small JSON metadata sidecar (title/category/courseCode/examYear/etc, everything needed to rebuild the `Note` row) to a new private Storage bucket `note-files` (`<uid>/<noteId>.<ext>` + `<uid>/<noteId>.json`, RLS-scoped so a student can only ever touch their own folder) on every `uploadNote()`/`deleteNote()` call. `Note.storagePath` (schema v10) tracks whether/where a note landed. On a device with zero local notes but a signed-in account that has backups in Storage, `NotesController._restoreFromBackupIfPossible` downloads and rebuilds them automatically -- the same "does this account already have real data on this device" pattern as the semesters reassign/discard fix above, applied to uploads. Reading progress (which pages were read, streak) is NOT restored -- the document itself is the durability win that matters here; re-establishing exact reading history on a genuinely new device is a smaller, deliberately out-of-scope loss. `noteRemoteSyncProvider` swallows a missing Supabase session into `null` rather than throwing -- a widely-depended-on provider like `notesProvider` must never break a test (or a screen) that has no reason to care about Supabase at all. Notes' `authUid` is read via `authStateProvider.select((s) => s.valueOrNull?.userId)`, not a bare `.watch` -- watching the raw `AsyncValue` would recreate `NotesController` (destroying an in-flight `_load()`) on every loading/error transition, not just when who's actually signed in changes. **Same pattern extended to the profile photo**: `data/repositories/profile_photo_remote_sync.dart`'s `SupabaseProfilePhotoRemoteSync` best-effort backs up the one local profile photo (always `<uid>/photo.jpg`, since there's only ever one) to a new private Storage bucket `profile-photos` (RLS-scoped identically to `note-files`, applied live via the `profile_photos_storage_bucket` migration) on every `ProfileController.save()` that has a photo, and deletes the backup if the photo is removed. On load, if the persisted profile's `photoPath` points at a file that no longer exists on disk (storage cleared, partial restore, etc.) it's re-downloaded and rewritten to that same path -- this deliberately does NOT attempt to conjure a whole profile row out of just a photo backup, since a genuinely new device has no local profile row to restore into at all (there's no pull-sync for the rest of the profile yet, only the existing local-to-remote `ProfileRemoteSync` UPDATE) |
| AI advisor | Rebuilt (`ai_shell.dart`) — six template-generated insight cards (`features/ai/services/advisor_insights.dart`'s pure `buildAdvisorState`), never LLM-generated: goal pace (uses `TargetProjection.requiredAverage`, never the classification threshold), trend, weakest credit load, carryovers, next entry, insufficient-data. A critical-standing state (CGPA below the scheme's lowest floor — below even a Pass) pre-empts all of them except carryovers — grey not red, states the fact once. **Deliberate reversal, explicit product decision**: this card and the chat system prompt used to never say the word "withdraw," routing everything through the academic adviser instead; both now directly tell the student they should withdraw or discuss repeating the year with their department right away (the adviser still handles the actual process — probation/repeat/appeal — but the withdraw-or-repeat advice itself is no longer withheld). The chat system prompt also now always pairs any "what should I do" advice with a reminder not to pursue illegal or academic-malpractice shortcuts (bribing staff, buying leaked exam questions, forging documents, paying someone to sit an exam). `AdvisorMark` (`shared/widgets/advisor_mark.dart`) is a custom-painted face reused by the greeting card, the global FAB, and the chat sheet header; it goes neutral (flat mouth, no sparkles) whenever the critical card is active. Global chat entry point: `AdvisorFab` on Home/Academics/Study only (`AppScaffold.showAdvisorFab`, auto-suppressed on AI/Me via the shell's own route), opening `advisor_chat_screen.dart` (`AppConstants.enableAdvisorChat`, now `true` — see "Streaming advisor chat" below for the real, shipped chat). `buildAdvisorChatContext`'s payload now includes a per-course breakdown (`course_breakdown`/`weakest_courses`/`outstanding_carryovers` — grade, credit unit, pass/fail, carryover status for every attempt on record, sorted weakest-first) alongside the record-wide aggregates it always sent — added because the chat previously had no course-level facts at all and could only answer "I don't have that" to "what am I doing poorly in", which is a real, reported gap, not the intended behaviour. Still never arithmetic: every number in `course_breakdown` is a scheme letter-to-point lookup or an engine-flagged exclusion reason, never something the model computes — the "weakest" ordering and carryover grouping happen in `_courseBreakdown` (pure Dart), not in the prompt |
| Notifications panel | Rebuilt (`features/home/screens/notifications_panel.dart`) — pushed as `Routes.notifications`, nested inside the tab `ShellRoute` (not a tab itself) so the bottom nav stays mounted and (`AppScaffold._lastTabIndex`) keeps highlighting whichever tab it was opened from. All/Unread segmented control, permission-aware hero banner (`NotificationPermissionChecker`, shown only when the OS permission isn't granted — independent of whether the inbox has any notifications yet), grouped-by-recency list with swipe-to-dismiss+Undo, mark-all-read. 7 real trigger types generated by `NotificationsController` (`data/repositories/notification_provider.dart`) reacting via `ref.listen` to `academicRecordProvider`/`targetProjectionProvider`/`achievementsProvider` — a falling CGPA renders as a neutral "Your CGPA changed", never a misapplied congratulation. New Drift table `notifications` (schema v7), 90-day retention pruned on init. The four tab header bells (`_NotificationBell` in dashboard/academics/ai/study screens) read `notificationsProvider`'s real unread state; the old boolean `notificationsReadProvider` stub is gone |
| Me tab | Rebuilt and merged (`me_shell.dart`) — there is no separate Settings screen/route any more; every settings section that used to live behind a single "Settings" push is now inline in the Me tab's own scrollable body, right below the identity card/stat strip/achievements grid. Same `#F7F7FB`/white-card surface as the other rebuilt tabs; no header bell (Me is the one tab the notifications panel isn't reachable from, see `routes.dart`). Gradient identity card (photo-or-initials 92dp avatar, camera badge routes to `ProfileSetupScreen.isEditMode`), phone row dropped (never collected), department falls back to the institution abbreviation when unset. Stat strip is CGPA/semesters/courses/day-streak (`notesProvider.displayStreak`), with the CGPA cell coloured via the shared `performanceColor` (`core/theme/performance_flag.dart`, red below 3.5) — the mockup's fabricated "Courses Enrolled" and dashboard-duplicate "Goal Progress" are gone. Achievements grid renders all 4 badges LOCKED (grey, 60% opacity, lock icon, criteria text shown) for a day-one user — `BadgeShield` only pulses a badge unlocked since the screen's own `initState` (`_seenAtMount`), never replaying an old unlock. Badge evaluation (`domain/engine/achievement_engine.dart`'s pure `evaluateEarnedBadges`, wired via `AchievementsController`'s `ref.listen` on `standingProvider`/`notesProvider`) also re-runs on app resume via a `WidgetsBindingObserver` at the app root (`app.dart`), not scoped to this tab, since a badge can be earned while any tab is open. Row/section icons use `Theme.of(context).colorScheme.primary` (tracks the Theme colour picker below) rather than a hardcoded purple, except the Destructive section, where `#DC2626` always means the same thing regardless of accent. **Academic is the section that matters**: Grading scheme opens a real repeat-policy editor (read-only grade points/classification bands, but the repeat/carryover policy itself is genuinely editable) — changing it shows the before/after CGPA from `CgpaEngine.recalculate` in the confirmation dialog itself, then applies via `AcademicRecordController.updateScheme`. The same sheet now also has a "CGPA calculation method" radio pair (`_GradingSchemeSheet`'s `_aggregation` state) for `CgpaAggregationMode` — switching to the recursive method shows the same before/after recalculation preview and surfaces an explicit warning that it's credit-unit-blind, since the dialog now covers two independent scheme-level settings rather than one (hence its title changed from "Change repeat policy?" to the more general "Change grading policy?"). Institution row re-resolves the scheme the same way, with the same recalculation-delta confirmation. Entry/graduation year editor shows a live remaining-semesters count via `remainingSemestersFromLevel`. Change password (`AuthNotifier.changePassword`) is hidden for a Google-only account via `AuthState.provider`/`isGoogleOnly` (sourced from Supabase's `app_metadata.provider`). Appearance is a real, Drift-persisted 3-way Light/Dark/System picker (`themeModeProvider`, backed by the generic `local_settings` key-value table, schema v8, via `ThemeModeController`) — `AppTheme.light()`/`.dark()` used to both build the same hardcoded-dark `ThemeData` regardless of which was requested; fixed so brightness genuinely branches surface/text/card/app-bar/nav-bar colours. Theme colour is a swatch picker (`core/theme/theme_accent_provider.dart`'s `AppAccent`, persisted under `local_settings` key `themeAccent`) — Blue/Red/Green/Beige at launch, since grown to seven with Light Blue, Purple, and White (see the "White accent" row below for the contrast work White specifically required) — see the retrofit note in "What's next" for its scope limit. Export uses `share_plus` to hand a JSON file (via the pure, unit-tested `buildExportPayload` in `features/me/services/data_export_service.dart`) to the system share sheet. Help and support is a real multi-question FAQ with an "Ask the Advisor" button (routes to `Routes.ai`) for anything beyond it, replacing the old 3-bullet placeholder. Privacy policy and Delete account are both honestly scoped rather than overclaiming: no hosted privacy policy exists yet (never fabricate a URL for one), and there is no server-side capability to delete the Supabase auth user (no Edge Function/admin API exists in this project) — Delete account requires typing `DELETE`, enumerates exactly what's lost, wipes local data and signs out, and says plainly that removing the account from the server isn't automated yet. Sign-out is a REQUIRED two-tier confirmation (`AppDatabase.wipeLocalData`, a scoped multi-table delete; dialogs live in `features/me/widgets/sign_out_dialogs.dart`): the first dialog's "also remove my data" checkbox is unchecked by default and a plain sign-out never touches local data; checking it opens a second dialog naming exactly what's lost ("N semesters, M results and P notes") before anything is deleted. New Drift table `achievements` (schema v6) |
| Backend | Live Supabase project ("Perform Plus", `ttlesvruldwjnwqtkqvo`) with `profiles`/`grading_schemes`/`semesters`/`course_results`/`goals` (RLS on all). First Edge Function shipped: `extract-course-slip` (`supabase/functions/extract-course-slip/`) — see "Add a semester" row |
| Add a semester (`add_semester_sheet.dart`) | Shared sheet used by both Backfill and Academics/Results, manual entry (course/units/grade/optional title) plus a real "Scan registration slip" action. Client (`features/academics/services/course_slip_extraction_service.dart`) downscales the photo (`processRegistrationSlip`, longest side ≤1600px, JPEG q82 -- preserves aspect ratio, unlike the profile-photo pipeline, since a document must never be cropped) and calls the `extract-course-slip` Edge Function, which does the actual vision-model call (Anthropic, `claude-haiku-4-5-20251001` -- a cheap model, per the cost-discipline constraint below) server-side; the API key is an Edge Function secret, never shipped in the client. The function enforces a 20-scans/24h per-user cap via the new `extraction_requests` table (RLS: insert/select own rows only; a row is written before the model call so a broken photo still counts). Extracted rows land as `CourseResult(source: ResultSource.ocrImport, extractionConfidence: ...)` with **no grade** -- a registration slip doesn't have one; the student fills that field in once results are out. Rows below 0.85 confidence show an inline "double-check this row" flag in `_RowEditor`, the same threshold as `CourseResult.needsReview`. **Manual step required outside this codebase**: the `ANTHROPIC_API_KEY` secret must be set on the live project (Dashboard → Edge Functions → `extract-course-slip` → Secrets, or `supabase secrets set ANTHROPIC_API_KEY=...` once the CLI is linked) before extraction actually works -- there is no tool available in this environment that can set a secret, so it was never attempted silently. **Not yet covered by a widget test**: the scan flow calls a live network dependency (`Supabase.instance.client.functions.invoke`) with no injectable seam yet, unlike `add_first_results_screen.dart`'s testable `pickImage`/`checkOnline` overrides -- adding that seam is real follow-up work if this needs test coverage |
| App-lock PIN | Real feature, local-only (no server round trip needed to check a PIN). `features/auth/services/pin_service.dart` hashes with a random salt (SHA-256 of `salt:pin`, `package:crypto`) -- never stored or compared in plaintext. `pin_provider.dart`'s `PinController` keeps the salt+hash in secure storage (Keystore/Keychain-backed, not Drift) and tracks `unlocked` in memory only, reset by `app.dart`'s `WidgetsBindingObserver` on every backgrounding (`AppLifecycleState.paused`), not just a cold start. `app.dart`'s `MaterialApp.router.builder` overlays `PinLockScreen` in front of the whole router (no route-stack involvement, no back-gesture escape) whenever `PinState.shouldLock` is true. A one-time "Add a PIN?" dialog (`pin_prompt_dialog.dart`) fires from the Dashboard once real data exists and stays suppressed forever once dismissed (`local_settings` key `pinPromptDismissed`) -- the PIN stays reachable afterwards from Me's App section ("App lock" row) or the drawer's "More settings". Changing or turning off an existing PIN both require re-entering the current one first (`_verifyPinThenAct` in `me_shell.dart`) -- otherwise anyone holding an already-unlocked phone, the exact scenario the PIN guards against, could disable it without ever knowing the code. **Fingerprint/face unlock added alongside the PIN, never instead of it**: `features/auth/services/biometric_service.dart` wraps `local_auth` (device-capability check + the system prompt), both swallowed to `false` on any failure so the PIN pad is always the fallback. `PinState.biometricAvailable` (device capability, checked once at load) and `.biometricEnabled` (the student's own opt-in, persisted under `local_settings` key `pinBiometricEnabled`) are independent -- `canUseBiometrics` requires `isSet && biometricAvailable && biometricEnabled`. Turning the PIN off also disables biometrics (`clearPin()` calls `setBiometricEnabled(false)`), since biometrics only ever unlock the PIN gate, never replace having one. The toggle lives in the same "App lock" bottom sheet as Change/Turn-off PIN (`me_shell.dart`, only shown when `biometricAvailable`). `PinLockScreen` auto-fires the system prompt via `addPostFrameCallback` in `initState` (so a fresh cold start/resume doesn't need a button tap first) and offers a manual "Use fingerprint" retry button underneath the PIN pad for when it's cancelled. Android requires `FlutterFragmentActivity` (not the default `FlutterActivity`) for `local_auth`'s biometric prompt, and the `android.permission.USE_BIOMETRIC` manifest permission. **Auto-lock grace period added**: the PIN used to re-lock instantly on ANY backgrounding (`AppLifecycleState.paused`), including a momentary trip to the system camera/share sheet/file picker -- which cost `profile_setup_screen.dart`'s in-flight photo pick its result the moment the student returned, since they landed on the lock screen instead. `PinController.handlePause`/`handleResume` (replacing the old unconditional `lock()`) now only re-lock if the background actually lasted `PinState.autoLockMinutes` (student-configurable 1-60 via a "Lock after" row in the App lock sheet, persisted under `local_settings` key `pinAutoLockMinutes`, defaulting to 1). For the harder case -- a low-RAM device killing the app process outright while the camera is foregrounded, losing the pending `pickImage()` future entirely -- `profile_photo_store.dart`'s `retrieveLostProfilePhotoBytes` (called once, early, in `ProfileSetupScreen.initState`) recovers the photo via `image_picker`'s own lost-data-retrieval mechanism instead of silently dropping it |
| Crash/error reporting | `sentry_flutter` wired in `main.dart`, inert until `SENTRY_DSN` is set in `.env` (no such account/DSN exists yet -- creating one needs the user's own Sentry account, which this environment has no way to do). `tracesSampleRate` is deliberately low (0.1); errors are always sent uncapped since Nigerian mobile connectivity issues are already treated as routine everywhere else in this app, not something a crash-reporting sample rate should also have to filter |
| Nav drawer | Unified: every tab shell (Home/Academics/Advisor/Study) now opens the same `shared/widgets/app_drawer.dart` `AppDrawer` instead of five near-identical private copies. Adds Home/Academics/Advisor/Study/Me navigation plus quick-access **Appearance** and **Theme colour** rows (calling the same `shared/widgets/quick_settings_sheets.dart` functions the Me tab's own rows call -- one implementation, not a duplicate that could drift) and a "More settings" row to Me. Deliberately duplicated for reachability, not moved out of Me: a student on Home/Academics shouldn't have to detour through Me just to flip Light/Dark |
| Movable chat button | `AdvisorFab` now takes optional `onDragUpdate`/`onDragEnd` merged into its own single `GestureDetector` (a tap and a pan recognizer coexist fine there; a second wrapping `GestureDetector` would risk capturing the arena before the tap ever gets a chance to open the chat sheet). `AppScaffold` positions it via `Positioned` fraction-of-screen coordinates (not raw pixels, so it survives a rotation/different device size), persisted through `shared/providers/advisor_fab_position_provider.dart` once a drag ends. `Positioned` must be `Stack`'s *direct* child -- an earlier draft nested it one `LayoutBuilder` too deep and threw "Incorrect use of ParentDataWidget"; the working version wraps the whole `Stack` in `LayoutBuilder` instead of the reverse. **Magnet edge-snap added on release**: `Positioned` became `AnimatedPositioned` with `duration: Duration.zero` while actively dragging (so the FAB tracks the finger with zero lag, via the same 1:1 `details.delta` math as before) and a 260ms `easeOutCubic` duration only for the post-release snap, driven by a `_snapping` flag flipped true in `onDragEnd` and back to false at the start of the next `onDragUpdate`. `onDragEnd` compares the FAB's centre x against the screen's horizontal midpoint and snaps its stored fraction to whichever of left (`0.0`) or right (`maxLeft`) is closer, keeping the vertical drop position unchanged |
| Sign-up/sign-in session-restore race | **Fixed a second real bug in the same area as the reassign/discard fix above**: `Supabase.initialize()` kicks off session recovery from local storage via a `recoverSession()` call it explicitly does NOT await (wrapped in a `CancelableOperation` instead) -- confirmed by reading `supabase_flutter`'s own source. A cold app start whose very first `authStateProvider` read landed before that recovery finished would see `currentUser == null` and route to onboarding despite a valid persisted session. Combined with the discard-vs-reassign fix, a student hitting this now only sees a rare spurious sign-in prompt rather than duplicated academic records |
| Deleted-account handling | **New**: Supabase never pushes a "your account was deleted" event -- it's only ever discovered the next time a refresh token is rejected, which `gotrue` surfaces as an `AuthChangeEvent.signedOut` with `signOutReason: SignOutReason.sessionExpired` on `onAuthStateChange` (covers both a genuinely expired token and a deleted user, since the server can no longer resolve either). `AuthNotifier._handleAccountNoLongerExists` (`auth_provider.dart`) is the dedicated handler for that specific reason, told apart from an explicit `signOut()` (`SignOutReason.userInitiated`, unaffected). It never touches local Drift data -- a student's results are theirs and may be all that's left of that account -- only: a defensive local-only `signOut()` (no network call reaches it, since the SDK already dropped the access token before this fires), clearing the remembered last-account email (so the sign-in screen doesn't default to a "Welcome back" form for an account that can never sign in again), remembering the outgoing uid under `local_settings` key `perform_plus.orphaned_local_data_uid` if `hasSemestersForProfile` finds real data there, and flipping `accountDeletedProvider` so `sign_in_screen.dart` shows "This account no longer exists. Your results are still on this device — sign up to save them again." (read once in `initState`, not via `ref.listen`, which only fires on a change AFTER it starts listening and would miss a flag already flipped before this screen mounts). On the next successful sign-up, `AuthNotifier.checkForOrphanedLocalData` checks for that stashed uid and surfaces it via `pendingLocalDataAttachProvider`; `profile_setup_screen.dart` (sign-up's fixed landing screen) offers an "Attach them to this new account?" dialog before Backfill ever runs, so an accepted reattach (`AuthNotifier.attachOrphanedLocalData`, the same `reassignProfile` mechanism the pre-auth draft handoff already uses, just with a different source id) is picked up immediately rather than the student re-entering results that already exist. `AuthNotifier.authChangeStream()`/`currentUserSeam()` are `@protected` test seams (`auth_provider_test.dart`) standing in for a real `SupabaseClient`/`GoTrueClient`, which has no way to trigger a rejected-refresh-token event on demand |
| Profile-load race on a cold start | **Fixed a real bug**: `studentProfileProvider`'s `ProfileController` loaded the persisted Drift profile asynchronously in its constructor (fire-and-forget, no way to await it) while `ProfileSetupScreen.initState` read it with a plain synchronous `ref.read` to pre-fill the edit form -- on a fresh cold start, if the screen was reached before that async Drift read resolved, `ref.read` returned `null` even though a real profile row existed, rendering the form blank and letting the student unknowingly overwrite their real data by saving over it (results were never affected, since `academicRecordProvider`'s own load path already handled this correctly). Fixed by giving `ProfileController` the same `ready` future its sibling controllers (`AcademicRecordController`, `NotesController`) already have, and having `ProfileSetupScreen` await it before reading or rendering |
| Layout/overflow fixes | The Study tab's calendar header (`study_calendar_card.dart`) overflowed on a narrow screen -- an unconstrained title plus a fixed 120px month label plus two full-size `IconButton`s left no room to shrink; now `Expanded`/`Flexible` with ellipsis and compact icon buttons. Every tab's custom app bar (`_DashboardAppBar`/`_AcademicsAppBar`/`_StudyAppBar`/`_AiAppBar`/`_MeAppBar`) was a raw `Container` with a fixed `height: 64` and no top safe-area handling -- unlike the real Material `AppBar` (which internally wraps itself in `SafeArea(bottom: false, ...)`), so the menu icon/notification bell rendered right at the edge of, sometimes under, the status bar. Fixed identically across all 5 by wrapping the row in `SafeArea(bottom: false, ...)` inside the `Container`, keeping the row itself at 64dp. Me tab's section headers (Account/Academic/App/Your data/About) now each carry a matching `context.palette.primary`-coloured icon (`_SectionHeader`'s new optional `icon` param) |
| Performance pass | Several continuous, always-on costs found and fixed: the Dashboard's CGPA trend chart (`trend_chart.dart`) rebuilt its ENTIRE `LineChartData` object graph (every band's `RangeAnnotation`/`HorizontalLine`, label-resolver closures, tooltip closures included) on every tick of its 900ms pulse-dot `AnimationController`, forever, for as long as the Dashboard was on screen -- the config pieces that don't depend on the pulse value are now hoisted out of the `AnimatedBuilder` and computed once per actual data change instead. The bottom nav bar's (`glass_nav_bar.dart`) and Dashboard's quick-stats bar's (`quick_stats_row.dart`) `BackdropFilter` blurs were lowered from sigma 34/20 to 18/12 (cost scales roughly with sigma²; both sit over content that's continuously animating or scrolling, so this is an ongoing per-frame GPU cost, not a one-off). `note_reader_screen.dart`'s rendered-page image cache (`_imageCache`) only ever grew, keeping every visited page's decoded bitmap resident for the whole reading session -- now evicts anything outside the current page's immediate neighbours. Profile photo avatars (`dashboard_screen.dart`/`me_shell.dart`) now decode via `ResizeImage` at roughly display resolution instead of the full stored file |
| Security-questions PIN flow, round two | **Fixed the other half of a bug already fixed once**: the first pass (above) caught `me_shell.dart`'s `_showAppLockSheet`'s inner `Consumer` shadowing the outer, longer-lived `_showAppLockSheet(BuildContext context, WidgetRef ref, ...)`'s `context` parameter, but missed that its `ref` param shadowed the SAME outer `ref` -- entering a PIN after tapping "Set up security questions" called `_verifyPinThenAct` against the Consumer's own short-lived `ref`, already invalid once its sheet popped, so the PIN screen just sat there with no visible error. Fixed by renaming the Consumer's param to `localRef` (used only for its own reactive `.watch(securityQuestionsProvider.select(...))`), leaving `onTap` pointed at the outer `context`/`ref` pair. Alongside this: two more theme accents (Light Blue, Purple -- see the Me tab row above), a corrected Study tab "Performance" locked-tile message (used to say it needed "the AI service," which now exists; says "not built yet" instead), and a new Study tab **Study time breakdown** card (`study_time_breakdown_card.dart`) listing every uploaded document with its total reading time (0m for an untouched one), ranked most-time-spent-first, deliberately styled distinctly from the "My Notes" list so it doesn't read as a duplicate |
| Streaming advisor chat, full-screen chart details | **Fixed a real latency complaint**: the `ai-advisor` Edge Function used to buffer Anthropic's entire reply before responding at all, so a multi-second generation looked frozen with no feedback. It now streams the model's own SSE response token-by-token, re-emitted in a small stable `{"delta": "..."}` shape; the client (`advisor_chat_service.dart`) reads it via a raw streamed `http` POST rather than `supabase_flutter`'s `functions.invoke` (which buffers the whole response before returning). `advisor_chat_provider.dart`'s `AdvisorChatHistoryController` also now persists the whole conversation to `local_settings` (so leaving and returning to the chat, or restarting the app, doesn't lose it) and exposes a "clear conversation" action. Separately, tapping the Dashboard's CGPA trend card or the "Performance View" 3D-bar card now opens a full-screen, background-blurred breakdown (`trend_detail_view.dart`/`performance_detail_view.dart`, both built on a shared `shared/widgets/spin_pop_dialog.dart` spin+pop transition) -- `TapToExpand`'s `Stack`+opaque `GestureDetector` layered ON TOP of the card's own chart is what makes this a tap-only gesture rather than also firing on a drag-to-inspect across the card's chart, since a plain wrapping `InkWell`/`GestureDetector` around a chart with its own touch handling sits in the same gesture arena and can let a drag resolve as a tap too |
| White accent, Result slip wallet, daily reminders, lock-screen polish | **White added to the theme picker, which broke things structurally, not cosmetically**: `ColorScheme.fromSeed` derives every Material role from the seed colour's HCT hue, and a zero-chroma (white) seed has no real hue to derive from, so Flutter's algorithm fell back to an arbitrary pale blue for `colorScheme.primary` -- several Me tab widgets read that ambient scheme directly rather than `context.palette.primary`, so picking White visibly showed pale blue instead. Fixed at the source in `app_theme.dart` by overriding the generated scheme's `primary`/`onPrimary` with the exact values `AppPalette` already computes, so every reader of either API agrees for every accent. `AppPalette.resolve` also now derives `primary` (contrast-checked against `surface`, falls back to a darkened tone only when the raw accent and surface are nearly indistinguishable -- today, only White in light mode) and `onPrimary` (luminance-checked against the gradient) instead of hardcoding white-always, since a literal white accent otherwise makes text/icons drawn on it invisible. **Result slip wallet**: every photo run through either slip-extraction path (`add_semester_sheet.dart`'s `_scanSlip`/`_scanResultSlip`) is now saved locally regardless of extraction's own success (`slip_wallet_provider.dart`, new `slip_uploads` table, schema v11) and browsable from a new card on the Results screen (`slip_wallet_card.dart` → `slip_wallet_screen.dart`), rather than being discarded the moment OCR finishes. **Daily reminders**: `NotificationsController.maybeGenerateDailyReminder` (checked on Dashboard mount and on app resume) generates 1-3 study/CGPA-standing reminders per calendar day -- the first always fires, later ones in the same day are a shrinking probability -- and delivers each one as both an in-app `notifications` row AND a real OS notification via the newly-wired `flutter_local_notifications`/`timezone` (already-declared but previously unused dependencies; see `core/notifications/local_notification_service.dart`). Since this app has no backend push server, a day's reminders are only ever scheduled once the app has actually been opened or resumed that day -- disclosed in-code rather than silently implied to be a true background alarm. A new one-time glass-card prompt (`notification_prompt_dialog.dart`, shown once real data exists, dismissal persisted like the PIN prompt) asks permission up front and, on "Allow," calls `Permission.notification.request()` directly -- the real inline OS dialog, never a redirect to the Settings app. **Lock screen**: gained an entrance fade/rise animation, a glow + small lock badge behind the avatar, tactile per-key shadows and a smoother animated PIN-dot fill (`pin_pad.dart`). **Follow-up fix, same batch**: the White/Light Blue accents also broke `AdvisorMark`'s eyes (drawn in the exact same colour as the head whenever the head defaulted to `palette.primary` and that accent was light enough to equal its own "light head" fallback colour -- fixed with a guaranteed-dark final fallback) and left several gradient-button labels (Results' "Add semester results", the AI tab's "Ask about your results", Study's "Upload e-note", a few Me tab spots) hardcoding `Colors.white` instead of `context.palette.onPrimary` |

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
the mean of semester GPAs, under the default `creditWeighted` aggregation
mode.** A 5.0 over 6 units then 3.0 over 18 units is 3.50, not 4.00. A
second, opt-in `recursiveSemesterAverage` mode exists for institutions whose
registry confirms they actually compute it as a running semester-to-semester
average instead (`CGPA_n = (CGPA_{n-1} + GPA_n) / 2`) — see
`CgpaAggregationMode`. Under that mode the same 6-then-18-unit example
above resolves to 3.50 rather than 3.29, which is a full classification band
apart (2:1 vs 2:2) on an identical transcript. Never assume the default for
a new institution — confirm which method its registry actually uses.

**Carryover** — a failed course retaken in a later semester. See below.

**Classification** — First Class (4.50+), 2:1 (3.50), 2:2 (2.40), Third
(1.50), Pass (1.00). Boundaries vary by institution.

---

## Grading schemes: five separable concerns

Do not collapse these. `GradingScheme` keeps them apart deliberately:

1. **Score → letter** — is an A 70+ or 75+?
2. **Letter → grade point** — 5.0 scale vs 4.0
3. **Classification bands** — the 2:2 floor is 2.40 at some schools, 2.50 at others
4. **Repeat / carryover policy** — the one everyone forgets
5. **CGPA aggregation method** — credit-weighted (default) vs recursive
   semester-to-semester average (`CgpaAggregationMode`, opt-in, added once a
   second institution's registry confirmed it) — see "Domain concepts" above

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

**Act 1 — pre-account, no login.** Splash → **institution & scheme setup** →
add results → **GPA reveal**. Value arrives before signup. The student then
has data to lose, which converts far better than a toll gate. The
institution picker (see "Open questions") is the first step, so the grading
scheme is resolved before any grade is typed — sixteen institutions are
seeded, FUTO first as the launch/pre-selected one, plus "Other (Add
Manually)" for anyone else.

**Act 2 — commitment.** Auth → profile → backfill → **goal setting**.
Goal setting is a first-class step; every later screen is framed against the
answer. Without it, the app is a calculator. By the time a student reaches
this screen they already have at least one semester of results from Act 1,
so the projections shown here are real, not aspirational — the no-data
`_NoResultsYet` state in `goal_setting_screen.dart` is a defensive fallback,
not the expected path. A separate, expected path is the *one-semester*
case: the feasibility card is replaced with an honest "add more semesters"
prompt rather than a feasibility verdict drawn from a single data point.

**Act 3 — return loop.** Five tabs. Grouped by what the student is *doing*:

| Tab | Contains | Answers |
|---|---|---|
| Home | Dashboard, trend, next action, notifications bell | — |
| Academics | Results, Roadmap, Reports, Strength Analysis | "where do I stand" |
| AI | Advisor (V1), Chat (V2) | — |
| Study | Notes, Flashcards, Reading, Exams, Planner | "what do I do about it" |
| Me | Identity, Achievements, Account/Academic/App/Your data/Destructive/About (inline, no separate Settings screen) | — |

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
- **IDs:** UUID v4 via `uuid`.
- **Money:** Naira. **Never floats.** Integer kobo.
- **Dates:** ISO 8601 in storage, `intl` for display.
- **Naming:** files `snake_case.dart`, classes `PascalCase`, private `_prefixed`.

---

## Testing

```bash
flutter test              # 24 tests, no device needed
```

Engine tests are pure Dart — no emulator, no Android SDK, no network.
**They must always pass before a commit.**

When adding engine behaviour, add a test that would fail without it. The
carryover bug above was caught this way in shipped code, before any user saw
a wrong CGPA.

Widget tests are not yet set up.

---

## Google sign-in setup

`auth_provider.dart` uses native Google sign-in (`google_sign_in` package)
on Android/iOS — the OS account picker, not a browser redirect. This is
what avoids Google's "unverified app" security-challenge screen ("get a
code to sign in, go to g.co/sc"), which is a Google account-risk behaviour
tied to the OAuth consent screen's publishing status, not anything
Supabase or this app controls directly. Web keeps the existing
browser-redirect flow, which already works.

To turn on native sign-in on Android:

1. In Google Cloud Console (the same project as the existing web OAuth
   client), create an **Android** OAuth client:
   - Package name: `com.perform.perform_plus`
   - SHA-1 (debug keystore, for local testing): generate with
     `keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android`
     and read the `SHA1:` line. A release build needs the SHA-1 from the
     real release keystore instead — never the debug one.
2. In Supabase Dashboard → Authentication → Providers → Google, confirm
   the existing **Web application** client ID/secret are set (this is the
   one from before native sign-in existed).
3. Copy that Web application client ID into `.env` as
   `GOOGLE_WEB_CLIENT_ID` (see `.env.example`) — native sign-in needs it as
   `serverClientId` so the ID token's audience matches what Supabase
   verifies against, regardless of platform.
4. Flip `AppConstants.enableGoogleSignInOnAndroid` to `true`.

iOS needs its own OAuth client (bundle id) plus `GIDClientID` configured in
`ios/Runner/Info.plist` — out of scope until iOS scaffolding exists (see
"Roadmap").

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
4. **Wire up real account deletion and a hosted privacy policy.** Google Play
   requires both for an app with user accounts. The Me tab's Delete account
   row (`features/me/screens/me_shell.dart`) currently only wipes local Drift
   data and signs out — there is no Edge Function or admin-API capability yet
   to actually delete the Supabase `auth.users` row, and the Privacy policy
   row honestly says no policy is hosted yet rather than link to one that
   doesn't exist. Both block store review as written.
5. **Retrofit the ~150 hardcoded `OnboardingLightPalette.primary` references**
   across already-built tab screens to read `Theme.of(context).colorScheme`
   instead. The "Theme colour" picker (`core/theme/theme_accent_provider.dart`,
   `AppAccent` enum: Blue/Red/Green/Beige/Light Blue/Purple/White, persisted via
   `local_settings` key `themeAccent`) is real and live everywhere it's reachable — generic
   Material widgets, the auth/onboarding flow, and the Me tab's own newly
   written content — but does NOT retint the pre-existing hardcoded purple in
   Dashboard/Academics/Roadmap/Study, since those references are `const` and
   changing that cascades into their enclosing `const` widget trees. Scoped
   out of the pass that introduced the picker; not silently dropped.

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

1. ~~One institution or nine at launch?~~ **Resolved: institution picker is
   back**, with FUTO pre-selected as the launch institution (see
   `institution_setup_screen.dart`). `OnboardingDraftNotifier` still defaults
   to `defaultSchemes['futo']` so the rest of Act 1 has a scheme even if a
   screen is reached before setup runs, but the picker can change it before
   any result is entered. 16 institutions are seeded; only FUTO's scheme is
   registry-verified — see "Grading schemes" below.
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
- Do not call `MediaQuery.of(context)`/`MediaQuery.disableAnimationsOf(context)` (or any
  `dependOnInheritedWidgetOfExactType`) from `initState()` — it must only be called from
  `didChangeDependencies()`/`didUpdateWidget()`, even indirectly through a shared helper method.
  This exact bug recurred independently in `AdvisorMark` and `NoteIllustration` (both crashed
  the Advisor/Study screens in production) before being fixed the same way in both.
- Do not build a `DropdownButtonFormField`'s `items` from a computed range (e.g. "current year
  ± N") without folding the field's current/initial value into that range — a previously saved
  value that later falls outside a time-relative window trips Flutter's "exactly one item with
  this value" assertion. See `profile_setup_screen.dart`'s `_entryYearOptions`/`_gradYearOptions`.
