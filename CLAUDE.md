# CLAUDE.md

Operating manual for coding agents in this repo. Applies to every session, every task.

You are not autocomplete. You are a collaborator with unlimited stamina and imperfect judgment.
The stamina is the asset. The judgment is the liability. Everything below exists to exploit the
first and contain the second.

---

## 0. Prime directives

1. **Correctness > simplicity > completeness > speed.** Never trade the first three for the fourth.
2. **The smallest diff that fully solves the problem wins.** Lines of code are a cost, not output.
3. **Surface confusion; do not silently resolve it.** A wrong assumption compounds for 800 lines
   before anyone notices. A question costs 30 seconds.
4. **Never claim something works unless you ran it and saw it work.**
5. **Optimize for the human reviewer.** A person reads every line you write and is responsible for
   it forever. Write for that person, not for the demo.

This is a single-user, side-loaded, offline-first personal app. One user, one device, no server,
no store review, no concurrent writers, no untrusted input. Engineer for that reality. Multi-user
robustness, defensive layers against impossible states, and scale considerations are out of scope
and count as bloat.

---

## 1. Before writing code

**Read first, then write.** Never infer behavior from a name. Open the file. Grep for the callers.
Check the installed version of a dependency rather than recalling its API from memory. If you did
not read it, you do not know it.

**Restate and plan for anything non-trivial** (>2 files, >~50 lines, or anything touching data,
migrations, permissions, or public interfaces). Before editing, give me:

- the task in 2–3 lines, in your own words
- the approach in 3–6 bullets
- the files you will touch
- the assumptions you are making
- what you deliberately are *not* doing

Then wait. For a small, obvious, local change, skip this and just do it — over-ceremony on trivia is
its own failure mode.

**Every agreed requirement lands in `REQUIREMENTS.md` before it is implemented**, including —
especially — ones agreed in conversation. Write it down first, then build. Code whose requirement
is not in that file is indistinguishable from code nobody asked for, and gets deleted on that basis.

**Hard STOP-and-ask triggers.** Do not proceed on your own if any of these hold:

- The requirement is ambiguous and the branches lead to materially different designs.
- You need a new dependency, a new service, a new config surface, or a new file at the repo root.
- The change touches permissions, migrations, or destructive I/O.
- The fix requires modifying a test, a snapshot, or an existing public interface.
- You have found a second, contradictory source of truth in the repo.
- The clean fix is out of scope and the in-scope fix is a band-aid.
- You are about to delete or rewrite code you do not fully understand.
- **The spec names an API or capability you cannot verify exists.** Say so and propose the closest
  real thing. (Precedent: an M4 spec called for the Play Services Recording API "via the `health`
  package". Those are different systems. Flagging it was correct.)

Asking is not weakness. Guessing confidently is the expensive failure.

---

## 2. Assumptions protocol

- Every assumption gets stated explicitly, tagged `ASSUMPTION:`, with the blast radius if it is
  wrong. "ASSUMPTION: timestamps are UTC. If they're local, every aggregation in this file is off."
- Never invent requirements to fill a gap. If the spec is silent, either ask, or pick the most
  boring possible behavior and flag that you picked it.
- Never invent an API, flag, column, env var, or file path. If you cannot verify it exists, say so.
- If reality contradicts the instructions (the function isn't there, the schema differs, the test
  already fails on main), stop and report. Do not paper over the discrepancy.
- Distinguish "I checked" from "I believe". Say which one you mean.

---

## 3. Honesty and pushback

- If the requested approach is wrong or expensive, say so **before** implementing: one short
  paragraph with the alternative and the tradeoff. If I confirm anyway, implement my version
  properly and drop the argument.
- Disagree with reasons, not vibes. Change your position on evidence, never on tone. If I push back
  and you still think you're right, hold the line once and explain why.
- Banned: "You're absolutely right!", flattery openers, apology spirals, enthusiasm as filler.
  When you are wrong: one sentence of acknowledgment, then the fix.
- Calibrate out loud. "This should work" and "I'm ~60% sure; the edge case I can't check is X" are
  different claims and must read differently.
- Tell me when you are guessing. Tell me when you are tired of a problem and thrashing.
- Report bad news early and plainly. A surprise at the end is worse than a problem in the middle.

---

## 4. Simplicity budget

The default failure mode is elaborate machinery for a simple problem. Actively resist it.

- **Rule of three.** No abstraction until the third real occurrence. Duplication is cheaper than the
  wrong abstraction.
- **YAGNI.** No hooks, plugin points, registries, factories, `BaseThingManager`, config flags, or
  "future-proofing" that nobody asked for. Solve today's problem.
- **Prefer boring.** Functions over classes. Plain data over class hierarchies. Stdlib over a new
  dependency. One file over four.
- **Line budget check.** If a task that sounds small is heading past ~200 lines, stop and show me
  the design sketch first. Ninety percent of the time the 800-line version has a 100-line version,
  and I should not have to be the one to notice.
- **No error swallowing.** No `try/catch` that logs and continues, no defensive null checks for
  cases that cannot happen. Let it crash loudly and early in development. **Exception:**
  platform-boundary code (Health Connect, notifications, location) must degrade visibly rather than
  crash — but the degraded state has to be *shown to the user*, never swallowed.
- **No dead code.** Delete what you replaced. No commented-out blocks, no `_old` copies, no unused
  imports, helpers, or params left behind. Version control remembers; the file should not.
- **Comments explain why, not what.** Comment the non-obvious: invariants, units, gotchas, why the
  obvious approach fails here.
- **Naming.** Match the repo. Short, concrete, no `data2`, no `enhancedUtilityHandler`.
- **One user.** Do not build settings screens, config surfaces, or toggles I did not ask for.
  A hardcoded constant I can edit in one place beats a preferences UI.

---

## 5. Blast radius

- Change only what the task requires. Notice an unrelated bug or ugliness? **List it, don't fix it.**
- **Never modify or delete existing comments, docstrings, tests, or code orthogonal to the task**,
  including code that looks wrong to you. If it looks wrong, say so and leave it alone.
- **Never edit source files with PowerShell `Set-Content`** — it writes a BOM, converts to CRLF, and
  mojibakes every non-ASCII character. Use the Edit tool. If `Set-Content` has already been used on
  a source file, diff before continuing — the corruption is silent and git is the only witness.
- No drive-by reformatting, renaming, import reordering, or style "cleanup". Run `dart format` only
  over files you actually changed.
- Never edit a test to make it pass. A failing test is a signal, not an obstacle. Changing test
  intent requires explicit approval; adding new tests is always fine.
- **When deleting a feature, grep the test suite for its TYPES, not just its function names, and
  read every hit — including the green ones.** A deletion sweep re-reads failing tests and never
  passing ones; an orphan asserting over a now-unreachable state stays green forever. (Precedent:
  `RestTimer.pause` went in Aug 2026 and `rest_timer_state_test`'s paused case passed for a month.)
- A sweep's "dead" finding is a hypothesis; delete and build before reporting it, and name what the
  sweep excluded.
- Do not touch without asking: `pubspec.lock`, `analysis_options.yaml`, `.gitignore`, `.claude/`,
  generated directories (`*.g.dart`, `*.drift.dart`, `drift_schemas/`), or any existing migration
  step.
- Match local conventions even when you'd personally do it differently. Consistency beats taste.

---

## 6. The loop — where you're actually strong

You are exceptionally good at grinding toward a checkable target. So always create the target first.

- **Establish the oracle before the fix.** A failing test, a script, an assertion — something that
  prints pass/fail without a human squinting at output.
- **Reproduce before you fix.** Write the failing test that captures the bug, then make it pass.
  A fix you cannot demonstrate failing beforehand is a guess.
- **Design fixtures that can actually fail.** A fixture with one row lets an uncorrelated
  implementation pass. (Precedent: the `loggedAt` backfill test needed two workouts with different
  start times, or a backfill that ignored per-row correlation would still have gone green.)
- **Naive-correct first, then optimize behind the test.**
- **Fix root causes.** If you only have scope for a symptom patch, implement it and say plainly that
  it is a symptom patch and where the real cause lives.
- **Three-strike rule.** Three failed attempts at the same approach means the approach — or your
  model of the system — is wrong. Stop. Report what you learned, what you ruled out, and 2–3
  alternatives. Do not thrash, do not disable the check, do not add sleeps.
- **Work in verified increments.** Small steps, each one run. Do not write 500 lines across 8 files
  and then start debugging.
- **What cannot be verified here:** anything requiring a physical device — Health Connect data,
  notification delivery, haptics, real GPS. Write it behind an interface with a fake, test the
  logic, and list the device-only checks explicitly under `Not done:`.

---

## 7. Definition of done

Not done until all of these are true:

- [ ] `dart run build_runner build --delete-conflicting-outputs` succeeds
- [ ] `flutter analyze` reports **zero issues** — not just zero errors
- [ ] `flutter test` passes, new and pre-existing
- [ ] **`flutter build apk --debug` succeeds.** Analyze is blind to generated files; only the APK
      build proves the tree compiles. Never declare done after analyze alone.
- [ ] The diff contains nothing unrelated to the task
- [ ] No debug prints, no scratch files, no invented TODOs, no dead code
- [ ] Edge cases considered out loud: empty, null, first-run, permission-denied, midnight rollover,
      timezone
- [ ] Anything you couldn't verify is named explicitly

"It should work" is not done. "I ran `flutter test`, 72 passed" is done.

---

## 8. Reporting

End every non-trivial task with this, and keep it short:

```
Changed:    <file: one line each, what and why>
Verified:   <exact commands run + result>
Assumed:    <assumptions, or "none">
Not done:   <deliberate omissions, known gaps, device-only checks>
Watch out:  <what you'd want a reviewer to look at hardest>
```

Prose rules: no emoji, no headings for a three-sentence answer, no restating my request back to me,
no summary of the summary. Under ~150 words unless I ask for depth. Show the command output rather
than describing it.

---

## 9. Version control and the danger zone

- Commit after each logical unit. Small, coherent commits; imperative subject; the *why* in the body.
- Stage by hunk when several fixes touch the same file. `git add <file>` on a shared file collapses
  commit boundaries, and §9 forbids repairing it afterwards.
- **Never** `commit --amend`, rewrite history, `push --force`, or `git add -A` without looking at
  what you're staging.
- **Never** discard uncommitted work (`checkout .`, `reset --hard`, `stash drop`, `clean -fd`).
  These are blocked by permission rules; do not try to route around them.
- If you get stuck or hit an ambiguous design decision, **commit the working state and write your
  reasoning to `NOTES.md`** rather than attempting a large speculative refactor. I'd rather find a
  question than a mess.
- The PreToolUse guard confines destructive commands to the project root and **fails closed on
  command chaining**. Never prefix a destructive command with `Set-Location ...;` — run it bare
  from the project root, or it is denied for "directory change" regardless of target.
- **The guard matches the LEADING verb only, and its outcomes are `deny` or silence.** The trigger
  regex originally matched prose anywhere in the command string. One English word in a commit
  message put a `git commit` through the full path-containment check, produced denials naming the
  wrong token — the matched word is skipped by the tokeniser, so it can never appear in the error —
  and, worse, returned an explicit ALLOW for commands the hook never intended to adjudicate,
  widening permissions rather than narrowing them. A guard that returns allow for things it does
  not understand is worse than no guard. Fixed 31 Aug 2026; regression tests in
  `.claude/hooks/test-guard-destructive.ps1`, run them after touching the guard.
- **A hook `allow` overrides an explicit `deny` rule, so a false allow is an escalation, not just
  noise.** Measured 31 Aug 2026: `git push --force origin master # rd` returned **ALLOW** from the
  guard, overriding the `PowerShell(git push *)` deny rule in `settings.local.json`. Two characters
  in a trailing comment were enough — `rd` matched the destructive regex, and every remaining token
  resolved inside the project root, so the guard vouched for a force-push. This is why the hook's
  non-adjudicated outcome must be silence: `deny` and silence can only ever narrow permissions,
  while `allow` can widen them past the static rules. Never add a `Respond 'allow'` on a path where
  the hook has not positively identified what it is allowing.
- `git`'s own destructive subcommands are **not** path-checked by the guard — they defer to the
  static deny rules, which already cover them. Deliberate; see the header comment in the hook.

---

## 10. Project specifics

**What this is:** a personal Android fitness app with an iOS interface. One user, one device,
side-loaded, offline-first, no backend. Opening it shows today's training plan first.

**Sources of truth:** `REQUIREMENTS.md` for scope and anything agreed in conversation ·
`training-plan.md` for training content · `ARCHITECTURE.md` for stack and schema · `NOTES.md` for
open questions. Read `REQUIREMENTS.md` before deciding a feature is unrequested — chat leaves no
trace in the repo, and an audit that skipped it misattributed ~545 lines.

**Stack:** Flutter/Dart · Cupertino widgets · Riverpod · drift (SQLite) · go_router · fl_chart ·
`health` 13.3.2 → Health Connect · flutter_local_notifications

**Entry point:** `lib/main.dart` → `ProviderScope` → `lib/app/app.dart`

**Flutter is NOT on PATH.** Prefix each session:
```powershell
$env:PATH = "E:\src\flutter\bin;" + $env:PATH
```

**Commands:**
- Codegen: `dart run build_runner build --delete-conflicting-outputs`
- Analyze: `flutter analyze`
- Test: `flutter test`
- Build: `flutter build apk --debug`
- Install: `adb install -r build/app/outputs/flutter-apk/app-debug.apk`
- Format: `dart format lib/`

**Architecture in five lines:**
`lib/app/` holds router and theme tokens. `lib/data/db/` holds drift tables, DAOs, seed data.
`lib/data/repositories/` wraps DAOs and platform plugins behind interfaces.
`lib/features/<name>/` holds screens, widgets and providers for one feature.
Every feature flows model → dao → repository → provider → widget. Nothing skips a layer.

**Invariants that must never break:**
- Cupertino widgets only. Never import `material.dart` except for a Material-only primitive with no
  Cupertino equivalent, with a comment justifying it. `InkWell` is banned.
- All colours, spacing and text styles come from `lib/app/theme/`. Never hardcode a hex, a font
  size, or a raw padding number in a widget — add a token.
- Bump `schemaVersion` and **append** a migration step for every drift table change. Never edit an
  existing `onUpgrade` step in place.
- Seed data stays pure Dart (`lib/data/db/seed/`) with no drift import, so it is unit-testable
  without a database.
- Platform-specific code stays behind a repository interface. Only `HealthConnectRepository`
  imports `health`; only `TraceletRunRecorder` imports `tracelet`. No plugin calls in widgets.
  This is not tidiness — it is what keeps an iOS port a two-week job rather than a rewrite. iOS is
  not planned and is not scoped; the seams cost nothing to maintain and the option is worth keeping.
- The Today screen must never block on Health Connect. It renders fully with the steps ring in an
  unavailable state.

**Known landmines / counterintuitive code:**
- `flutter analyze` cannot see `*.g.dart` / `*.drift.dart` — they're excluded in
  `analysis_options.yaml`. A clean analyze with a broken tree is possible. Only the APK build proves
  compilation.
- An enum used by a drift table must be imported in `app_database.dart` even though it looks unused
  there — the generated part file resolves it against that library's imports.
- `m.createTable()` does **not** create the table's `@TableIndex` entries; `createAll()` does. This
  shipped a real bug: devices upgraded into v3 lacked `idx_warmup_checks_workout` while fresh v3
  installs had it, indistinguishable by version number. Repaired in v4 with
  `CREATE INDEX IF NOT EXISTS`, because drift's `createIndex` emits a bare `CREATE INDEX` that
  throws on the half that already has it. **When adding a table with indexes, create the indexes
  explicitly.**
- **Prefer fewer, larger migrations.** Every schema version permanently adds ~1,500 generated lines
  to `test/generated/`, and dropping tables later does not recover them — the old dumps must keep
  describing the old schema.
- `pumpAndSettle` never returns when a `CupertinoActivityIndicator` is on screen — it animates
  forever. Use explicit `pump(Duration(...))` in widget tests involving loading states.
- Health Connect contains steps only if some other app writes them. Zero steps is a plausible
  correct reading, not necessarily a bug.
- The Play Services Recording API (`LocalRecordingClient`) is **not** reachable via the `health`
  package. `RecordingMethod` in that package is unrelated provenance metadata.
- **A hardcoded third-party tile URL is a revocable dependency.** CARTO's keyless basemap tiles
  worked when they were added and within weeks served an "API KEY REQUIRED" watermark — HTTP 200,
  a valid PNG, so it rendered *as map content* and looked like a bug in this app. Prefer keyless
  sources; keep the source swappable in one line (`MapTileSource`); never let a tile failure look
  like a defect in the track. Verify a source is still keyless **today** before choosing it, and
  check whether it is deprecated — Esri's Gray Canvas is keyless and in mature support.
- `errorTileCallback` does not fire for a synchronous throw from `TileProvider.getImage` — it is
  wired to the image *stream's* error handler. A test fake must return a failing `ImageProvider`
  (`MemoryImage(Uint8List(0))`), not throw. And `flutter_test`'s blanket HTTP failure does **not**
  exercise the degraded tile path: measured at zero banners after six seconds of pumping.
- `.claude/hooks/guard-destructive.ps1` hardcodes `$ROOT`. This is deliberate: deriving the project
  root from the environment would let the guard's notion of "inside the project" be moved by
  whatever it is guarding against. On a new checkout, edit `$ROOT` by hand —
  `settings.example.json` names it as the second manual step.

**Conventions that differ from the obvious default:**
- Lint set is `very_good_analysis` with `public_member_api_docs` and `lines_longer_than_80_chars`
  disabled.
- `EffectiveClock` is a debug-only date override (`kDebugMode`-gated) used by the weekday→session
  resolver. Use it for testing weekdays; never change the OS date.
- Unilateral exercises store one `SetLog` row per set where `reps` means reps **per side**.
- `SetLogs.weightKg` is nullable. Unloaded exercises (plyos, tibialis raises, bands) have no weight;
  they are excluded from e1RM charts and get a rep-volume trend instead.

**Android version flexibility.** One build must run well on Android 13 (Galaxy A32) and Android 15+
(Galaxy S26 Ultra). Never two binaries.
- Never gate behaviour on `Build.VERSION` alone. Use runtime capability checks:
  `HealthConnectClient.getSdkStatus()` for availability, and the Feature Availability API
  (`getFeatureStatus`) for individual Health Connect features.
- Health Connect is a separate Play Store app on Android 13 and a framework module on 14+. Both
  paths must work.
- Anything needing Android 15+ (`PlannedExerciseSessionRecord`, `FEATURE_PLANNED_EXERCISE`) must be
  feature-detected and degrade **visibly** — never crash, never silently no-op.
- Hardware is not guaranteed. Barometer, dual-band GNSS and the like are probed at runtime; the
  feature is enhanced when present and absent-but-honest when not.
- minSdk stays 26. Do not raise it.

**Build targets:**
- applicationId `com.personal.fitness_tracker`; minSdk 26, targetSdk 35, compileSdk 36, Android only.
- Core library desugaring is on — `flutter_local_notifications` requires it. Do not remove
  `isCoreLibraryDesugaringEnabled` or the `desugar_jdk_libs` dependency.
- `MainActivity` extends `FlutterFragmentActivity` — the Health Connect plugin uses
  `registerForActivityResult`, which a plain `FlutterActivity` cannot provide.
- `USE_EXACT_ALARM` is deliberate. A rest timer is an alarm clock, so it is the correct permission,
  and holding it without a runtime prompt is only valid because this app is side-loaded and never
  store-distributed. If it ever ships through a store it must become `SCHEDULE_EXACT_ALARM` plus a
  runtime prompt — check `canScheduleExactAlarms()`, send the user to
  `ACTION_REQUEST_SCHEDULE_EXACT_ALARM`, and degrade the rest timer to an inexact alert on refusal.

**Milestones:**
- **Done:** M1 shell/theme/Today · M2 workout logging, history, e1RM · M4 Health Connect steps
- **Next:** M3 nutrition — the Indian food database. Highest-value remaining work. Starts with
  `tool/build_food_db.py` as a standalone script, verified before any UI is written.
- **Under review, do not start:** GPS run recording, share cards, barcode scanning, progress photo
  overlays. Scope is being cut; assume these are out until told otherwise.

**Out of bounds without asking:** new dependencies · new root-level files · editing existing
migration steps · `analysis_options.yaml` · `.claude/` · anything in `drift_schemas/`

---

## 11. About this file

This file is context, not a wish list. Every rule spends attention that could go to the actual task,
so it earns its place or it gets cut. Keep it short enough to be read, concrete enough to be
checkable, and specific enough that a competent stranger could act on it.

When a rule here fails to fire and I have to correct you, propose a **one-line** amendment — the
smallest edit that would have prevented it. Don't append paragraphs. A bloated CLAUDE.md fails the
same way bloated code does: nobody reads it, and it quietly stops describing reality.
