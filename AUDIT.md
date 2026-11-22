# Codebase audit

**Status: executed.** Audited 2026-08-18 against commit `61d5b11`; deletions
carried out 2026-08-18/19 across eight commits, ending at the fl_chart removal.
All numbers below are **post-deletion**, with the pre-deletion figure shown
alongside as `was N`. Two things the audit got wrong are corrected in place and
flagged: the generated-line saving from dropping tables (§2 item 1) and the
scope attribution of four features (§4).

Every file under `lib/`, `test/` and `android/app/src/` was opened and read;
line counts are `wc -l`. Symbol reachability was established by grep across
`lib/` and `test/` excluding generated files, and `flutter test` was run (72
passed at audit time, 61 now).

**Bias disclosure up front:** `git log` shows every commit in this repo is mine.
This is an audit of my own work, and the failure mode is justifying it. Where
you had a prior (e1RM chart, 24-hour auto-close) I agree with you on both, and
in the second case the code's own justifying comment is factually wrong — see
§4. I flag the places where I am defending a decision rather than reporting one.

**The audit's own blind spot:** requirements agreed in conversation leave no
trace in the repo, so an audit that reads only the repo cannot see them. Four
features were filed "no traceable requirement" that had in fact been asked for
— see §4. That is what `REQUIREMENTS.md` now exists to prevent.

---

## 1. Inventory

### Totals

| Group | Hand-written | Generated | Total |
|---|---:|---:|---:|
| `lib/` M1 — shell, theme, router, Today | 1,171 *(was 1,222)* | — | |
| `lib/` M2 — workout logging, history | 3,757 *(was 4,514)* | — | |
| `lib/` M4 — Health Connect, steps | 1,134 *(was 1,377)* | — | |
| `lib/` shared — db wiring, M3 tables | 280 *(was 332)* | — | |
| **`lib/` subtotal** | **6,342** *(was 7,445)* | **12,594** *(was 16,135)* | **18,936** |
| `test/` | 1,692 *(was 1,671)* | 8,971 *(was 7,742)* | 10,663 |
| `android/app/src/` | 197 | 49 | 246 |
| **Overall** | **8,231** *(was 9,313)* | **21,614** *(was 23,926)* | **29,845** *(was 33,239)* |

Generated is **72%** of the tree — unchanged, because the deletions cut
hand-written and generated code in similar proportion.
`lib/data/db/app_database.g.dart` is 10,576 lines *(was 13,734)*, still 35% of
the repository, and `test/generated/migrations/` is 8,971 *(was 7,742)* — it
**grew**; see §2 item 1.

### `lib/` — M1 (1,171)

| File | Lines |
|---|---:|
| `features/today/today_screen.dart` | 259 |
| `app/router/app_router.dart` | 119 |
| `app/theme/app_colors.dart` | 113 |
| `app/theme/app_typography.dart` | 103 |
| `app/router/tab_shell.dart` | 92 |
| `features/today/widgets/plan_item_row.dart` | 89 |
| `app/app.dart` | 62 |
| `shared/widgets/inset_card.dart` | 49 |
| `app/theme/app_theme.dart` | 47 |
| `features/progress/progress_screen.dart` | 46 |
| `app/theme/app_spacing.dart` | 40 |
| `features/today/providers/today_providers.dart` | 38 |
| `shared/widgets/section_header.dart` | 34 |
| `shared/widgets/centered_message.dart` | 30 |
| `core/weekday_session.dart` | 27 |
| `main.dart` | 23 |

`shared/widgets/placeholder_screen.dart` (54) was inlined into
`progress_screen.dart`; `centered_message.dart` replaced two duplicated
private widgets in M2 screens.

### `lib/` — M2 (3,757)

| File | Lines |
|---|---:|
| `data/db/seed/phase1_seed.dart` | 469 |
| `features/workout/exercise_log_screen.dart` | 365 |
| `features/workout/widgets/stepper_controls.dart` | 295 |
| `features/workout/session_screen.dart` | 256 |
| `data/db/dao/workout_dao.dart` | 231 |
| `features/workout/providers/rest_timer_provider.dart` | 195 |
| `data/repositories/workout_repository.dart` | 179 |
| `features/today/widgets/warmup_checklist.dart` | 148 |
| `features/workout/workout_history_screen.dart` | 147 |
| `features/workout/services/rest_alerts.dart` | 140 |
| `features/workout/widgets/rest_timer_bar.dart` | 138 |
| `features/workout/widgets/set_log_row.dart` | 110 |
| `data/db/tables/training_tables.dart` | 109 |
| `data/models/workout_models.dart` | 106 |
| `features/workout/workout_detail_screen.dart` | 103 |
| `data/models/session_plan.dart` | 102 |
| `features/workout/providers/set_draft_provider.dart` | 89 |
| `features/workout/widgets/last_session_card.dart` | 80 |
| `data/db/seed/seed_runner.dart` | 74 |
| `data/db/seed/seed_models.dart` | 71 |
| `features/workout/providers/workout_providers.dart` | 66 |
| `data/db/dao/plan_dao.dart` | 65 |
| `app/debug/effective_clock.dart` | 65 |
| `data/repositories/plan_repository.dart` | 56 |
| `data/models/training_enums.dart` | 43 |
| `core/formatters.dart` | 28 |
| `core/one_rep_max.dart` | 27 |

Gone: `exercise_detail_screen.dart` (266) and `widgets/one_rep_max_chart.dart`
(168).

### `lib/` — M4 (1,134)

| File | Lines |
|---|---:|
| `features/today/widgets/steps_card.dart` | 221 |
| `data/repositories/health_connect_repository.dart` | 201 |
| `features/settings/settings_screen.dart` | 177 |
| `features/today/widgets/steps_ring.dart` | 109 |
| `features/today/providers/steps_providers.dart` | 106 |
| `data/repositories/steps_repository.dart` | 105 |
| `data/models/health_models.dart` | 89 |
| `data/repositories/health_repository.dart` | 42 |
| `data/db/dao/steps_dao.dart` | 37 |
| `data/db/dao/preferences_dao.dart` | 29 |
| `data/db/tables/settings_tables.dart` | 18 |

Gone: `data/repositories/settings_repository.dart` (70).

### `lib/` — shared (280)

| File | Lines |
|---|---:|
| `data/db/app_database.dart` | 118 |
| `data/providers/database_providers.dart` | 57 |
| `data/db/tables/food_tables.dart` | 59 |
| `data/db/tables/progress_tables.dart` | 19 |
| `data/db/foods_fts.drift` | 15 |
| `data/db/tables/activity_tables.dart` | 12 |

`app_database.dart` grew by 9 lines: the v6 migration step. The activity and
progress table files shrank to `DailySteps` and `Measurements`.

### `lib/` — generated (12,594)

| File | Lines |
|---|---:|
| `data/db/app_database.g.dart` | 10,576 *(was 13,734)* |
| `features/workout/providers/workout_providers.g.dart` | 700 *(was 956)* |
| `data/providers/database_providers.g.dart` | 377 *(was 466)* |
| `features/today/providers/today_providers.g.dart` | 255 |
| `features/workout/providers/set_draft_provider.g.dart` | 153 |
| `features/today/providers/steps_providers.g.dart` | 132 *(was 170)* |
| `app/debug/effective_clock.g.dart` | 128 |
| `features/workout/providers/rest_timer_provider.g.dart` | 79 |
| `app/router/app_router.g.dart` | 58 |
| `features/workout/services/rest_alerts.g.dart` | 51 |
| `data/db/dao/workout_dao.g.dart` | 31 |
| `data/db/dao/plan_dao.g.dart` | 22 |
| `data/db/dao/{preferences,steps}_dao.g.dart` | 32 |

### `test/`

| File | Lines | Kind |
|---|---:|---|
| `migration_test.dart` | 648 *(was 418)* | hand |
| `steps_card_test.dart` | 202 | hand |
| `workout_repository_test.dart` | 200 *(was 285)* | hand |
| `warmup_checks_test.dart` | 165 | hand |
| `steps_repository_test.dart` | 137 *(was 236)* | hand |
| `rest_timer_state_test.dart` | 127 | hand |
| `support/fake_health_repository.dart` | 75 | hand |
| `weekday_session_test.dart` | 59 | hand |
| `effective_clock_test.dart` | 45 | hand |
| `support/test_database.dart` | 34 | hand |
| `generated/migrations/schema_v5.dart` | 1,618 | generated |
| `generated/migrations/schema_v3.dart` | 1,570 | generated |
| `generated/migrations/schema_v4.dart` | 1,570 | generated |
| `generated/migrations/schema_v2.dart` | 1,480 | generated |
| `generated/migrations/schema_v1.dart` | 1,471 | generated |
| `generated/migrations/schema_v6.dart` | 1,226 | generated |
| `generated/migrations/schema.dart` | 36 | generated |

Hand-written tests came out 21 lines *up*: the v5→v6 migration test (230 lines,
because it populates every surviving table plus every dropped one) more than
paid for the 184 lines of deleted tests.

### `android/app/src/`

| File | Lines | Kind |
|---|---:|---|
| `main/AndroidManifest.xml` | 111 | hand |
| `main/res/values{,-night}/styles.xml` | 36 | hand (Flutter template) |
| `main/res/drawable{,-v21}/launch_background.xml` | 24 | hand (Flutter template) |
| `{debug,profile}/AndroidManifest.xml` | 14 | hand (Flutter template) |
| `main/kotlin/.../MainActivity.kt` | 12 | hand |
| `main/java/io/flutter/plugins/GeneratedPluginRegistrant.java` | 49 | generated |
| `main/res/mipmap-*/ic_launcher.png` | — | binary (5 files) |

Of the 197 hand-written Android lines, only the manifest (111) and
`MainActivity.kt` (12) were written for this app; the rest is untouched Flutter
scaffold.

---

## 2. Bloat analysis

### Ranked table

Ranked by lines saved × confidence. "Lines" counts hand-written lines only
unless noted.

| # | Target | Lines | Conf. | What it does | Minimum | The difference |
|---|---|---:|---|---|---:|---|
| 1 | Unbuilt-milestone tables: `activity_tables.dart` (Runs, RunPoints, Splits), `progress_tables.dart` (Photos). **Measurements kept** — weight and waist survived the scope cut. | 102 hand + **~3,160 generated, less ~1,260 added back** = **~2,300 net** | high | Declared 4 tables for GPS runs and progress photos. Nothing read or wrote them. | 0 | The stated rationale — "keeps schema version 1 complete so later milestones add behaviour rather than migrations" — was falsified in practice: the schema reached v5 through four migrations anyway, none touching these. **Done in v6.** |
| 2 | e1RM trend feature: `exercise_detail_screen.dart:1-266`, `one_rep_max_chart.dart:1-168`, `one_rep_max.dart:1-44`, `workout_models.dart:71-80,92-113`, `workout_repository.dart:197-210`, `workout_providers.dart:62-70` | ~543 | high | Plots estimated 1RM (or rep volume) per session on a time axis, with latest/best/change stats and a session list. | 0 for the chart; ~60 for a plain session list | ARCH §8 puts M2 at "history, PR tracking" and `fl_chart` trends at M6. A time-axis chart with touch tooltips, lone-point windowing and a curved gradient fill is M6 work pulled into M2. See §4 — I agree with your prior. |
| 3 | `settings_screen.dart:56-135` step-goal picker + `settings_repository.dart:36-47,60-69` + `steps_providers.dart:41-44` | ~120 | high | Lets you pick a daily step goal from a wheel between 1,000 and 30,000 in 500s, clamped and persisted. | 1 (`const stepsTarget = 8000;`) | CLAUDE.md §4, verbatim: "Do not build settings screens, config surfaces, or toggles I did not ask for. A hardcoded constant I can edit in one place beats a preferences UI." The training plan says "8,000+ steps/day" — a constant. This rule fired and I built it anyway. |
| 4 | `settings_screen.dart:137-213` + `effective_clock.dart:1-65` (debug date override) | ~175 | medium | Debug-only date override so a Thursday session can be tested without moving the OS clock. | ~40 (provider + a raw text field, or a test-only override) | Genuinely useful and now blessed in CLAUDE.md §10 as a convention — but it is 175 lines of shipped-source tooling for something two widget tests could pin. The `_DateOverrideSection` alone (110 lines) is a full settings UI with pickers and explanatory copy. **This is me defending my own tooling; discount accordingly.** |
| 5 | `rest_alerts.dart:1-140` + manifest receivers/permissions (`AndroidManifest.xml:2-10,70-84`) + `main.dart:20-22` | ~170 | medium | Schedules an OS notification at the rest deadline and double-buzzes at zero. | 0, or ~25 for a haptic on `_tick` reaching zero | No requirement names notifications. It pulled in `flutter_local_notifications`, `timezone`, core library desugaring, `USE_EXACT_ALARM`, `RECEIVE_BOOT_COMPLETED` and a boot receiver — a large platform surface for one buzz. The gym argument (phone in pocket) is real; the cost is one dependency and three permissions, and it is undiscussed. |
| 6 | `stepper_controls.dart:10-94` (`RepeatButton`) + `:117-159` (`_editExact`) | ~110 | medium | Hold-to-repeat on ±buttons, and a dialog for typing an exact weight. | ~20 for a plain `GestureDetector` | Both are quality-of-life inventions with no requirement. The hold-repeat is 60 lines of timer state for "adding 40 kg without sixteen taps"; the dialog is 43 lines for "the rare jump". Defensible, but they are the two most elaborate parts of the file. |
| 7 | `steps_repository.dart:46-52,106-125` (30-day backfill) + `settings_repository.dart:49-58` + `steps_dao.dart:33-54` | ~80 | high | Reads 30 days of Health Connect history once, ever, and stores it. | 0 | **Nothing reads the history.** `StepsDao.inRange` (the only range query) is dead — see §3. The ring shows today only. This is 80 lines plus a settings key plus a schema version plus 5 tests serving a consumer that does not exist. |
| 8 | `workout_repository.dart:47-75` + `workout_dao.dart:66-74,116-124,126-135` + `main.dart:14-18` | ~66 | high | On launch, closes unfinished workouts older than 24 h at their last set, deleting setless ones. | 0 | The doc comment's primary justification — "its stale row is what the next session would try to resume" — is **wrong**. `WorkoutDao.openWorkoutFor` (`:47-64`) already filters `w.date.equals(day)`, so a workout from a previous day can never be resumed. See §4; I agree with your prior and the code agrees with you too. |
| 9 | `steps_card.dart:43-115` (four degraded states) | ~65 of 235 | medium | Renders unsupported / not-installed / needs-update / no-permission / no-data / summary. | ~35 (two states: a figure, or an explanation with one action) | CLAUDE.md permits platform-boundary code to degrade visibly, and this is the sanctioned exception. But one user, one phone: `unsupported` and `needsUpdate` are mutually exclusive with your actual device and you will see at most two of these six branches, ever. |
| 10 | Domain models mirroring drift rows: `session_plan.dart:1-104` + `plan_repository.dart:1-75` | ~100 of 179 | low | Restates `PlanItem`/`Exercise`/`PlanDay` as `PlannedItem`/`PlannedExercise`/`SessionPlan`, field for field, plus `prescription` and `restFor`. | ~75 (extensions on the drift rows) | **This is required by your own rules** — ARCH §7 and CLAUDE.md §10: "Every feature flows model → dao → repository → provider → widget. Nothing skips a layer." I am listing it as a cost, not recommending it be cut. |
| 11 | `seed_models.dart:1-85` | 85 | medium | A third representation of the plan (`SeedExercise`/`SeedPlanItem`/`SeedPlanDay`), stated to exist so the seed is "unit-testable without a database". | ~30, or 0 | **There is no seed unit test.** The purity is real (no drift import) and the invariant is in CLAUDE.md, but the benefit it was built for has not been collected, and 4 of its 6 members are dead (§3). |
| 12 | `phase1_seed.dart:1-469` | 469 | low | Transcribes Phase 1 of `training-plan.md` into constants. | ~300 | Data, not logic. Could be ~35% shorter with a terser literal shape, at a real cost in diffability against the plan. **Do not touch.** |
| 13 | Duplicated leaf widgets: `session_screen.dart:257-277` vs `exercise_log_screen.dart:374-394`; `today_screen.dart:227-235` wrapping `:237-267` | ~40 | high | Two byte-identical centred-message widgets in two files; a 9-line class that only calls another class. | ~20 | Straight duplication. `_CenteredMessage` and `_Message` are the same widget under two names. |

**Correction — the audit oversold item 1 by more than half.** I estimated
~5,600 generated lines saved. Measured: `lib/` generated fell 3,541 (of which
~3,160 is the dropped tables and the rest follows from deleted providers), but
`test/generated/` **rose 1,229**. Net saving across the repo is **~2,300**, not
~5,600.

The reason is structural and worth remembering. `test/generated/migrations/`
holds one file per schema version, and each describes the schema *as it was at
that version*. v1–v5 still contain `runs`, `run_points`, `splits` and `photos`
at full size, permanently — they have to, or the migration tests could not build
an old database to migrate from. Dropping tables therefore does not shrink
history; it only stops the newest version carrying them, and it *adds* a version
(v6, 1,226 lines). Every schema bump costs ~1,500 generated test lines that no
later deletion recovers.

The practical consequence, now recorded in CLAUDE.md §10: prefer fewer, larger
migrations, and do not treat "drop the table later" as a cheap undo.

### Abstractions with exactly one implementation

| Abstraction | Implementations | Earns its keep? |
|---|---|---|
| `HealthRepository` (`health_repository.dart:15`) | `HealthConnectRepository` + `FakeHealthRepository` | **Yes.** Per your note, and the evidence supports it: all 8 `steps_card_test` cases and 11 `steps_repository_test` cases are unreachable without the fake. |
| `PlanRepository` over `PlanDao` | one | Marginal — `_hydrate` does real row→domain mapping, but `sessionForKey`/`sessionById`/`exerciseById` are pass-throughs. Mandated by the layering rule, so it stays. |
| `WorkoutRepository` over `WorkoutDao` | one | **Yes.** It owns real logic that must not live in a DAO: set-index derivation, session grouping, warm-up key mapping. Not a pass-through. |
| `SettingsRepository` over `PreferencesDao` | one | Half-earns it. The typing/defaults layer exists mostly for the step goal (item 3). With the goal hardcoded, only `stepsBackfillCompleted` remains, and that is two lines. |
| `PlaceholderScreen` (`placeholder_screen.dart:7`) | one caller, `ProgressScreen` (18 lines) | **No.** 72 lines across two files for one placeholder screen. Inline it. |
| `_StepperFrame` (`stepper_controls.dart:219`) | 2 (`WeightStepper`, `RepStepper`) | **Yes** — rule of three not met, but the two are genuinely the same layout and it is 77 lines shared. |
| `AppTheme.light()/dark()/_build` | one `_build` | Trivial (3 lines of indirection); harmless. |
| `LinearProgressBar` (`rest_timer_bar.dart:110`) | one caller, same file | Fine as a widget; should be private (`_LinearProgressBar`). |
| Seed model trio | one producer, one consumer | See item 11. |

### Defensive code for states that cannot occur

| Location | Guard | Verdict |
|---|---|---|
| `health_connect_repository.dart:123` | `if (lastDay.isBefore(firstDay)) return const [];` | Cannot fire. Both call sites pass `from <= to`. |
| `one_rep_max.dart:12` | `weightKg <= 0` | Cannot fire. `WeightStepper._nudge` maps 0 to null (`stepper_controls.dart:114`), and `_editExact` does the same (`:157`). Null is checked separately. |
| `steps_card.dart:33-36` | Two successive null/loading guards | The second is reachable only via an `AsyncError`, which `StepsPanel.build` is documented never to produce. |
| `settings_repository.dart:60-69` | Parse + clamp on read, "a corrupt or hand-edited value must not stop the app rendering" | Single-user, offline; the only writer is `setStepsTarget`, which already clamps. Defensive against a hand-edited SQLite file. |
| `workout_dao.dart:166-173` | `InsertMode.insertOrIgnore` so "double-tapping cannot throw" | A double tap toggles to unchecked, so the duplicate path needs a race that a single-threaded UI does not produce. |
| `steps_repository.dart:128` | `if (totals.isEmpty) return Future.value();` | Harmless, but `upsertAll` on an empty iterable is already a no-op. |
| `health_connect_repository.dart:46-115` | `try/catch` on every plugin call, logging via `debugPrint` and returning a value | **Keep.** This is CLAUDE.md §4's explicit platform-boundary exception, and every failure resolves to a state the UI renders. |
| `rest_alerts.dart:134-140` | `initializeRestAlerts` swallows and `debugPrint`s | Same exception, correctly applied — a failed notification channel must not stop launch. |
| `rest_alerts.dart:34,78,81,110,119` | `_ready` gate on every call | Necessary for tests; keep. |

### Error handling that logs and continues

Two sites: `health_connect_repository.dart:199-200` and `rest_alerts.dart:137`.
Both are the sanctioned platform-boundary exception, and both degrade to a state
the user can see (`steps_card.dart` renders every one). No unsanctioned
swallow-and-continue exists in the codebase.

### Widgets that could be functions

Private, leaf, no state, rebuilt with their parent — each is a class where a
returned `Widget` would do:

`today_screen.dart:73` `_DateLine`, `:227` `_RestDayCard`, `:237` `_MessageCard`;
`session_screen.dart:257` `_CenteredMessage`;
`exercise_log_screen.dart:230` `_TargetLine`, `:341` `_SaveBar`, `:374` `_Message`;
`exercise_detail_screen.dart:156` `_Stat`, `:247` `_EmptyTrend`;
`workout_history_screen.dart:120` `_EmptyHistory`;
`steps_card.dart:187` `_StepsMessage`.

Roughly 11 classes × ~8 lines of ceremony ≈ **90 lines**. Counter-argument I
should state rather than hide: keeping them as widgets preserves const
construction and rebuild scoping, which is idiomatic Flutter. Low value, low
risk — I would not spend a change on this.

### Parallel code paths that could be one

1. `exercise_detail_screen.dart:78-98` — loaded (e1RM) vs unloaded (rep-volume)
   branches carried through `_TrendSection`, the stat row, the chart unit and
   the footnote. Two units, two labels, two formats, one chart. If the chart
   goes (item 2) this goes with it.
2. `steps_card.dart:50-114` — six render branches (§2 item 9).
3. `today_screen.dart:155-185` and `session_screen.dart:122-158` — warm-up /
   plyo / main block rendering, near-identical in two screens with different
   card wrappers. ~35 lines duplicated. Genuine rule-of-two; leave it.
4. `_CenteredMessage` / `_Message` — literal duplication.

### Built "for later", nothing calls it today

- Runs / RunPoints / Splits / Photos / Measurements tables (item 1).
- Foods / Servings / RecipeItems / FoodLogs / `foods_fts.drift` — 74 lines. Same
  category, but M3 is Next in CLAUDE.md, so this is weeks from having a
  consumer. **Keep.**
- `StepsDao.inRange` / `upsert` — the range reader and single-day writer for a
  history nothing displays.
- `PreferencesDao.remove` — no setting is ever removed.
- `PlanRepository.allSessions` — a "browse the whole plan" screen that does not
  exist.
- `RestTimer.pause` / `resume` — the timer bar (`rest_timer_bar.dart:74-94`)
  offers only +30s and dismiss.
- 30-day backfill (item 7).
- `ActivitySource` as an `abstract final class` with one constant — built for a
  second provider that NOTES.md correctly declined to build.

---

## 3. Dead and unreachable code

**All resolved.** Every symbol below was deleted, except: the FOOD tables and
`foods_fts` (M3 lands next), `Measurements` (kept — see §4), and
`seedTrainingData`, which was not dead but over-exposed and is now private.
One symbol the audit missed, `LoggedSet.estimatedOneRepMax`, was found during
the deletion and removed with the trend feature.

Defined and never referenced anywhere outside its own definition. Verified by
grep across `lib/` and `test/`, excluding `*.g.dart` and `test/generated/`.

| Symbol | Location |
|---|---|
| `AppColors.secondaryBackground` | `lib/app/theme/app_colors.dart:16` |
| `AppColors.tertiaryBackground` | `lib/app/theme/app_colors.dart:21` |
| `AppColors.opaqueSeparator` | `lib/app/theme/app_colors.dart:73` |
| `AppSpacing.xxxl` | `lib/app/theme/app_spacing.dart:14` |
| `AppTypography.resolveFor` | `lib/app/theme/app_typography.dart:106` |
| `SectionHeader.trailing` (param, never passed) | `lib/shared/widgets/section_header.dart:8` |
| `SeedPlanItem.isLoggable` | `lib/data/db/seed/seed_models.dart:57` |
| `SeedPlanItem.hasFixedReps` | `lib/data/db/seed/seed_models.dart:60` |
| `SeedPlanDay.itemsIn` | `lib/data/db/seed/seed_models.dart:79` |
| `SeedPlanDay.exercises` | `lib/data/db/seed/seed_models.dart:83` |
| `PlannedItem.isLoggable` | `lib/data/models/session_plan.dart:52` |
| `ExerciseSession.isEmpty` | `lib/data/models/workout_models.dart:69` |
| `MovementPattern.carry` (enum value, never constructed) | `lib/data/models/training_enums.dart:41` |
| `WorkoutDao.workoutById` | `lib/data/db/dao/workout_dao.dart:33` |
| `StepsDao.inRange` | `lib/data/db/dao/steps_dao.dart:34` |
| `StepsDao.upsert` (single-day; only `upsertAll` is used) | `lib/data/db/dao/steps_dao.dart:41` |
| `PreferencesDao.remove` | `lib/data/db/dao/preferences_dao.dart:30` |
| `PlanRepository.allSessions` | `lib/data/repositories/plan_repository.dart:23` |
| `RestTimer.pause` | `lib/features/workout/providers/rest_timer_provider.dart:136` |
| `RestTimer.resume` | `lib/features/workout/providers/rest_timer_provider.dart:147` |
| `seedTrainingData` (public; only caller is `seedTrainingDataIfEmpty` in the same file) | `lib/data/db/seed/seed_runner.dart:26` |
| `Runs`, `RunPoints`, `Splits` tables | `lib/data/db/tables/activity_tables.dart:5,22,46` |
| `Photos`, `Measurements` tables, `PhotoPose` enum | `lib/data/db/tables/progress_tables.dart:4,8,17` |
| `Foods`, `Servings`, `RecipeItems`, `FoodLogs`, `FoodSource`, `Meal`, `foods_fts` | `lib/data/db/tables/food_tables.dart`, `lib/data/db/foods_fts.drift` (M3 lands next — not for deletion) |

**Total dead hand-written code: ~120 lines excluding tables, ~240 including the
scope-cut tables.**

**Providers never watched:** none. All 20 Riverpod providers have at least one
`ref.watch`/`ref.read` consumer. Checked individually.

**DAO methods never called:** the four listed above (`workoutById`, `inRange`,
`upsert`, `remove`). Every other DAO method has a repository or test caller.

**Theme tokens never used:** the four listed above. Every other colour, spacing
and type token is referenced at least once — including `plyo`, `warmup`, `steps`,
`warning` (`set_log_row.dart:43`), `quaternaryLabel` (empty states) and
`groupedCardElevated` (`last_session_card.dart:25`).

**Tests asserting something no code path can produce:** see §5.

---

## 4. Scope audit

Requirement sources: `ARCHITECTURE.md` (the spec), `training-plan.md`, `CLAUDE.md`.

### Explicitly requested

| Feature | Traces to |
|---|---|
| Cupertino shell, tab scaffold, theme tokens | ARCH §8 M1: "Cupertino shell, tab scaffold, theme tokens, Today screen with hardcoded plan" |
| Today as landing screen, weekday → `PlanDays.dayKey` | ARCH §6: "Today screen (landing). Resolves the current weekday → `PlanDays.dayKey` → renders today's session at the top" |
| drift schema, workout logging, set-by-set entry, history | ARCH §8 M2: "drift schema, workout logging, set-by-set entry, history, PR tracking" |
| Training tables as specified, `rir?`, nullable `weightKg` | ARCH §3 TRAINING block |
| Health Connect steps + active energy, daily ring | ARCH §8 M4: "Health Connect steps, daily rings"; §6: "Request `READ_STEPS` and `READ_ACTIVE_CALORIES_BURNED`" |
| Graceful not-available handling | ARCH §6: "Health Connect must be installed… handle the not-available case gracefully" |
| `daily_steps.source` column | ARCH §3: `DailySteps: date (PK), steps, activeKcal, source` |
| Seeded Phase 1 plan, four sessions, warm-up/plyo/lift blocks | `training-plan.md` §PHASE 1 |
| Rest durations 3 min / 90 s | `training-plan.md`: "Rest: 3 min on the first two exercises of each day, 90 sec on the rest" |
| Last-session numbers in front of you while logging | `training-plan.md`: "Double progression… Log everything. Weight, sets, reps, every session. This is non-negotiable" |
| 8,000 steps/day target (as a number, not a setting) | `training-plan.md`: "Plus 8,000+ steps/day" |
| Cupertino-only, tokens-only, drift-only, layered architecture | ARCH §7, CLAUDE.md §10 |

### Implied

| Feature | Implied by |
|---|---|
| Rest **timer** with countdown bar | The plan prescribes rest durations; a timer is the obvious rendering. Nothing asks for a countdown UI. |
| Warm-up prescriptions rendered on Today and in-session | The plan lists warm-ups per day; showing them follows from "renders today's session". |
| Set delete with confirmation | Correcting a mistyped set is implicit in "log everything". |
| Resume an unfinished session; one workout per (day, plan day) | Not specified, but a logger that forks its own log is broken. This was the P0 fix. |
| Per-exercise set index correctness | Same. |
| Pre-filling the draft from last session's heaviest set | Double progression: "repeat the weight and try to add a rep". |
| Workout detail / history list | ARCH M2 says "history"; the shape is mine. |
| `WarmupChecks` table + tick persistence | The plan lists warm-ups; **ticking them is invented**. Small, and I would defend it, but it is not implied by anything written down. |

### Requested in conversation — the audit got these wrong

These four were filed "no traceable requirement" because the repo held no
record of them. They had been asked for. The fault is the audit's method, not
the code: a repo-only audit cannot see a chat requirement, and I should have
said "no traceable requirement **in the repo**" and asked, rather than implying
they were invented. All four stay, and all four are now in `REQUIREMENTS.md`.

| Feature | Lines | Where it actually came from |
|---|---:|---|
| Hold-to-repeat buttons, exact-weight dialog | ~110 | Requested: the steppers must be usable one-handed, standing at a machine, breathing hard. |
| Rest-over notifications, exact alarms, boot receiver, `timezone`, haptics | ~170 | Requested: the phone is in a pocket between sets, so the rest has to announce itself off-screen. |
| Debug date override (provider + settings section) | ~175 | Requested: testing a Thursday session must not mean moving the OS clock. |
| Warm-up tick persistence (`WarmupChecks` + UI) | ~90 | Requested: a warm-up list you cannot tick is unusable halfway through. |

### No traceable requirement

| Feature | Lines | Note | Status |
|---|---:|---|---|
| e1RM trend chart, Epley helpers, `ExerciseTrendPoint`, rep-volume alternative | ~543 | ARCH §8 assigns `fl_chart` trends to **M6**. M2's word is "PR tracking", which a chart is not. | deleted |
| 24-hour auto-close of unfinished workouts | ~66 | See below. | deleted |
| 30-day Health Connect backfill | ~80 | Nothing displayed history. | deleted |
| Step-goal settings UI | ~120 | Directly contradicted CLAUDE.md §4. | deleted, now a constant |
| Runs / RunPoints / Splits / Photos tables | ~102 | ARCH §3 listed them; CLAUDE.md §10 says GPS runs and photos are out. | dropped in v6 |
| Dead code (§3) | ~120 | | deleted |
| Measurements table | ~19 | Listed as cut in the audit. **Wrong** — weight and waist are tracked weekly, broad jump every 4 weeks (`training-plan.md` §WHAT TO TRACK). It was in the plan all along. | **kept** |

**On the two you already suspected:**

**e1RM trend chart — I agree, and would go further.** ARCH §8 puts M2 at
"history, PR tracking" and `fl_chart` trends at M6, three milestones later. What
got built is not a PR readout: it is a time-axis line chart with touch tooltips,
a gradient area fill, curve-overshoot suppression, a lone-point window
(`one_rep_max_chart.dart:36-61`), and a **second parallel trend** for unloaded
exercises that nothing asked for at all. The part of it that earns its place is
`LastSessionCard` (80 lines) — last session's numbers next to the entry
controls, which is the actual mechanism of double progression and is on the
right screen. `bestOneRepMax` feeding that card is worth ~15 lines. The other
~500 are M6.

**24-hour auto-close — I agree, and the code's own justification is wrong.** The
doc comment at `workout_repository.dart:47-56` gives two reasons. The second —
"its stale row is what the next session would try to resume" — is false:
`WorkoutDao.openWorkoutFor` (`workout_dao.dart:47-64`) already filters on
`w.date.equals(day)`, so a workout from any previous day is unreachable by the
resume path regardless. The only surviving effect is that the history list shows
an old session as "in progress", which is cosmetic and arguably *more* honest
than silently backdating an end time. Worse, the test that supposedly proves the
feature's value — `workout_repository_test.dart:263-283`, "frees the next
session from resuming an abandoned one" — **passes with the entire feature
deleted**, because the two workouts are on different dates. It is a test that
cannot fail, guarding behaviour that is already guaranteed elsewhere.

That is the sharpest single finding in this audit and it argues your way, not mine.

---

## 5. Test audit

72 tests at audit time; **61 now**, all passing. Nine were deleted with the
features they covered, two were dropped as trivially true, and one was added for
the v6 migration. Per file now: `workout_repository_test` 11,
`rest_timer_state_test` 10, `steps_card_test` 8, `migration_test` 7,
`warmup_checks_test` 7, `steps_repository_test` 7, `weekday_session_test` 6,
`effective_clock_test` 5.

The table below is the audit-time assessment, kept as the record of why each
test was judged as it was.

| File | Tests | Real regression value | Framework / trivially true |
|---|---:|---|---|
| `migration_test.dart` | 6 | **All 6.** The highest-value tests in the repo. The v3→v4 pair (`:323-354`) encodes a bug that actually shipped: `createTable` not creating `@TableIndex`, with fresh-v3 and upgraded-v3 databases indistinguishable by version. The v1→v5 `loggedAt` backfill test uses two workouts with different start times specifically so an uncorrelated backfill fails. | 0 |
| `steps_card_test.dart` | 8 | **All 8.** Every degraded Health Connect state is unreachable on a dev machine; these are the only proof the card renders them. The "does not wait on the steps check" case (`:191-205`) guards a stated invariant. | 0 |
| `workout_repository_test.dart` | 14 | 9 — the 5 `openOrStartWorkout` fork/resume cases (the P0 bug) and the 4 set-indexing cases (delete-then-collide). | 5: the `reconcileStaleWorkouts` group. 4 test a feature I recommend deleting; the 5th (`:263-283`) **passes with the feature removed**. |
| `warmup_checks_test.dart` | 7 | 7. `checklistLines` blank-line dropping guards a real index-shift corruption; the cascade-delete case (`:146-163`) verifies `PRAGMA foreign_keys = ON` is actually on. | 0 |
| `steps_repository_test.dart` | 11 | 6 — the `syncToday` group (date keying, upsert-not-append, revocation) and `watchDate`. | 5 backfill tests: correct, well-written, and testing a feature with no consumer. |
| `rest_timer_state_test.dart` | 10 | 4 — `remainingAt` derived from the deadline, the no-ticks gap, the round-up, the paused hold. These encode the drift bug fixed in P1. | 6: `progress` (3), `copyWith` (1), lifecycle flags (2) — one-line getters. |
| `weekday_session_test.dart` | 7 | 4 — the weekday map, the null days, the concrete-date resolution, the "all four exactly once" invariant. | 3, notably `:20-24` "returns null for out-of-range weekdays" — asserts 0, 8 and −1, values `DateTime.weekday` cannot produce. |
| `effective_clock_test.dart` | 6 | 2 — date override with real time-of-day, and the weekday it resolves to. | 4, notably `:10-16` "is the real clock", which asserts `DateTime.now()` ≈ `DateTime.now()`. |

**Outcome:** the suite landed at 61 rather than the ~46 minimum, because the
getter-level tests in `rest_timer_state_test` and the remaining
`effective_clock_test` cases were left alone — they cost nothing to keep and
the features they cover are staying. The v5→v6 migration test was added on top.

**Minimum suite preserving the real coverage: ~46 tests** (~40 if the
reconcile and backfill features are deleted along with their tests):

- `migration_test` — all 6, untouched
- `steps_card_test` — all 8, untouched
- `workout_repository_test` — 9 (drop the reconcile group)
- `warmup_checks_test` — all 7
- `steps_repository_test` — 6 (drop the backfill group)
- `rest_timer_state_test` — 4 (keep the `remainingAt` group; drop getter tests)
- `weekday_session_test` — 4 (drop out-of-range weekdays)
- `effective_clock_test` — 2 (drop the real-clock and midnight-of-real-date cases)

The support files (`test_database.dart`, `fake_health_repository.dart`, 115
lines) stay in full — they are what makes the rest possible.

---

## 6. Recommended deletions — outcome

Items 1–7 were executed, one commit each, with codegen → analyze → test → APK
run after every one. Items 8–10 were **rejected**: all three had been requested
in conversation (see §4). Item 11 was rejected on merit — const construction is
worth more than the lines.

| # | Item | Recommended | Outcome |
|---|---|---:|---|
| 1 | Runs / RunPoints / Splits / Photos tables | 121 hand, ~5,600 gen | **done in v6**, Measurements kept; real saving ~2,300 net |
| 2 | e1RM trend feature | ~543 | **done** — 878 deletions incl. generated |
| 3 | 30-day steps backfill | ~80 + ~90 test | **done** — 203 deletions |
| 4 | 24-hour auto-close | ~66 + ~85 test | **done** — 157 deletions |
| 5 | Step-goal settings UI | ~120 | **done** — 319 deletions, now `const stepsTarget = 8000` |
| 6 | Dead symbols (§3) | ~120 | **done** — 92 deletions |
| 7 | Duplicated leaf widgets | ~90 | **done** — 121 deletions, 75 insertions |
| 8 | Hold-to-repeat, exact-weight dialog | ~110 | **rejected** — requested |
| 9 | Rest-over notifications | ~170 | **rejected** — requested |
| 10 | Debug date override | ~175 | **rejected** — requested |
| 11 | Widget classes → functions | ~90 | **rejected** — const construction wins |

Two things had to change outside the plan, both forced:
`warmup_checks_test`'s cascade test reached the cascade through
`reconcileStaleWorkouts` and now calls `deleteWorkout` directly (same
assertion); and `migration_test`'s existing groups now migrate to 6 rather
than 5, which the version bump requires.

The original recommendations, for the record. Highest value first.

| # | Delete | Lines saved | What breaks | Confidence |
|---|---|---:|---|---|
| 1 | `Runs`, `RunPoints`, `Splits`, `Photos`, `Measurements` tables + `PhotoPose`, and their entries in `@DriftDatabase` | 121 hand, **~5,600 generated** (≈3,660 in `app_database.g.dart`, ≈2,000 across `test/generated/`) | Nothing at runtime. **But**: this needs a v6 migration appending `DROP TABLE`, a fresh `drift_dev schema dump`, and regenerated per-version schemas — a migration and generated-directory change, both of which are STOP-and-ask territory per CLAUDE.md §5/§9. Re-adding them for M5/M6 costs another migration. | High that they are unused; **medium** that deleting is net-positive, because of the migration churn. Ask me before this one. |
| 2 | e1RM trend feature: `exercise_detail_screen.dart`, `one_rep_max_chart.dart`, `one_rep_max.dart` (keep `bestOneRepMax`), `ExerciseTrendPoint`, `WorkoutRepository.trendForExercise`, `exerciseTrend`/`exerciseSessions` providers, and the chart-icon nav buttons in `exercise_log_screen.dart:50-55` and `workout_detail_screen.dart:83-104` | ~543 + regenerated `workout_providers.g.dart` shrinkage (~150) | The `/workout/exercise/:id` route and its two entry points. `LastSessionCard` keeps working (it needs only `bestOneRepMax`). `fl_chart` becomes an unused dependency. | High |
| 3 | 30-day steps backfill: `StepsRepository._backfillIfNeeded` + `backfillDays`, `SettingsRepository.stepsBackfillCompleted`/`markStepsBackfillCompleted`, `StepsDao.inRange`/`upsert`, and the 5 backfill tests | ~80 lib + ~90 test | Nothing. `syncToday` loses two lines. The `steps.backfill_completed` key becomes an orphan row (harmless). | High |
| 4 | 24-hour auto-close: `WorkoutRepository.reconcileStaleWorkouts`, `WorkoutDao.unfinishedWorkoutsBefore`/`setCountIn`/`lastSetTimeIn`, `main.dart:14-18`, and the 5 reconcile tests | ~66 lib + ~85 test | Old unfinished sessions show "in progress" in history forever. Nothing else — resume is already day-scoped. | High |
| 5 | Step-goal settings UI: `settings_screen.dart:56-135`, `SettingsRepository.stepsTarget`/`watchStepsTarget`/`setStepsTarget`/`_parseTarget`/`_clampTarget`, `stepsTargetProvider`; replace with `const stepsTarget = 8000` | ~120 | `SettingsScreen` loses its only non-debug content. `steps_card_test` needs its `stepsTargetProvider` override removed (2 lines). `migration_test.dart:392-396` asserts on `SettingsRepository`; it would need to assert on the `Preferences` table directly instead — **that is a test change and needs your approval.** | High |
| 6 | All dead symbols in §3 (excluding tables) | ~120 | Nothing. | High |
| 7 | Duplicated leaf widgets: fold `_Message`/`_CenteredMessage` into one shared widget; inline `_RestDayCard` into `_MessageCard`; inline `PlaceholderScreen` into `ProgressScreen` | ~90 | Nothing. | High |
| 8 | `RepeatButton` hold-to-repeat and `_editExact` dialog in `stepper_controls.dart` | ~110 | Weight entry becomes tap-only in 1.25/2.5 kg steps, and a jump from 20 kg to 60 kg takes 16 taps. **I think this is a real loss in the gym.** Listed for completeness, not recommended. | High that it is unrequested; **low** that it should go. |
| 9 | Rest-over notifications (`rest_alerts.dart`, the manifest receivers and alarm permissions, `flutter_local_notifications` + `timezone` + desugaring) | ~170 lib + ~35 manifest + 2 dependencies | The rest timer only alerts when the app is in the foreground. Removing the dependencies also removes the `USE_EXACT_ALARM` question entirely. Touches `pubspec.yaml` and the Gradle desugaring config. | High that it is unrequested; **low** that it should go — a rest timer you cannot hear is not a rest timer. Your call, not mine. |
| 10 | Debug date override (`effective_clock.dart`, `settings_screen.dart:137-213`), replaced by test-only provider overrides | ~175 | The weekday→session resolver becomes untestable by hand on a device. `effective_clock_test.dart` goes. CLAUDE.md §10 documents this as a convention, so removing it means amending CLAUDE.md. | Medium. I built it and I like it; treat my defence sceptically. |
| 11 | Convert 11 private leaf widget classes to functions | ~90 | Nothing functionally; loses const-construction and rebuild scoping. | High that it saves lines; **low** that it is worth doing. |

Items 2–7 together: **~1,000 lib lines and ~175 test lines, with nothing lost
that traces to a requirement.** That is 13% of hand-written `lib/`.

*Measured: 1,103 lines of hand-written `lib/`, or 15%.*

---

## 7. What is genuinely good — do not touch

Short, as asked. These are load-bearing.

1. **The migration chain and `migration_test.dart`.** `app_database.dart:60-108`
   plus its 418-line test are the only thing standing between you and losing a
   training log. The v3→v4 index repair encodes a bug that actually shipped and
   that version numbers alone cannot detect. Never edit a step in place; never
   trim this test.
2. **`WorkoutDao.openWorkoutFor` keyed on (date, planDayId)** —
   `workout_dao.dart:47-64`. This is the P0 fix. Every "did my log fork?"
   property depends on it, and it is what makes item 4 above deletable.
3. **`WorkoutDao.nextSetIndex` deriving from `MAX(set_index)`, not `COUNT`** —
   `workout_dao.dart:103-114`. One line of thinking that prevents silent
   corruption after a mid-exercise delete, with a test that would catch a
   regression.
4. **`RestTimerState` defined by a wall-clock deadline** —
   `rest_timer_provider.dart:16-63`. The whole timer is correct because
   `remaining` is a rendering of `deadline` rather than an accumulator. This
   survives backgrounding, throttling and resume. The four `remainingAt` tests
   are the ones to keep.
5. **`HealthRepository` / `FakeHealthRepository`.** The seam is what makes 19
   tests possible for a feature with no testable platform. Your call to keep it
   was right.
6. **`StepsDao.dayKey` and `DailySteps` keyed on midnight** —
   `steps_dao.dart:17-23`. One day, one row, re-syncable. Prevents a whole class
   of duplicate-row bugs.
7. **`seedTrainingDataIfEmpty` idempotence** — `seed_runner.dart:11-19`, run in
   `beforeOpen`. It cannot duplicate the plan or clobber history, and
   `migration_test.dart:169-173` proves it does not re-seed over an existing plan.
8. **The theme token layer** (`app_colors`/`app_spacing`/`app_typography`). Three
   dead tokens is a rounding error against the fact that no widget in the tree
   hardcodes a hex, a size or a pad. This discipline held.
9. **`phase1_seed.dart`.** It is long because the training plan is long. It
   diffs cleanly against `training-plan.md`, which is the property that matters.
10. **NOTES.md.** Flagging that the Recording API is not what the `health`
    package provides, rather than guessing, was the correct call and is the
    single best-documented decision in the repo.

---

## 8. Line accounting

Hand-written `lib/` only. Attribution is per-feature and approximate — files mix
categories, so lines were apportioned by block. Rounded to the nearest 50.

| Bucket | Before | Share | After | Share |
|---|---:|---:|---:|---:|
| Serving a requirement stated in the repo | ~3,600 | 48% | ~3,550 | 56% |
| Serving a requirement stated in conversation | ~545 | 7% | ~545 | 9% |
| Serving a requirement you implied | ~1,300 | 18% | ~1,300 | 20% |
| **No traceable requirement** | **~1,050** | **14%** | **~30** | **<1%** |
| Defensive / infrastructural overhead | ~950 | 13% | ~900 | 14% |
| **Total** | **7,445** | 100% | **6,342** | 100% |

The "stated in conversation" row is the audit's correction. It originally
counted those ~545 lines under "no traceable requirement", which is why that
bucket read 21% rather than 14% (§4).

### The single number

**Before: ~73%** of hand-written `lib/` served a requirement — ~5,445 of 7,445,
counting repo-stated, chat-stated and implied. The audit reported 66% because it
could not see the chat-stated ones.

**After: ~85%** — ~5,395 of 6,342. Essentially nothing is left that traces to
nothing: the residual ~30 lines are the `foods_fts` index and the FOOD enums,
which M3 consumes next.

The remaining ~14% is layering, model-mirroring, degraded-state branches and
provider wiring — overhead no requirement names but that the architecture in
ARCHITECTURE.md §7 and CLAUDE.md §10 makes unavoidable.

Including tests and Android, hand-written total is 8,231 lines *(was 9,313)*.
With generated output the tree is 29,845 *(was 33,239)*, still **72%
machine-written**.

### Caveats on this number

- "Implied" is the soft bucket and the one where I have the most incentive to be
  generous to myself. If you read the rest timer, warm-up rendering and
  session-resume as un-asked-for rather than implied, the post-deletion figure
  drops to about **64%** — stated requirements only.
- Apportioning mixed files (`settings_screen.dart`, `workout_repository.dart`,
  `workout_models.dart`) is a judgement call; ±150 lines across the buckets.
- The generated-line saving from dropping tables was estimated at ~5,600 from
  class-boundary line numbers. **Measured: ~2,300 net**, because the historical
  schema dumps keep the dropped tables forever and v6 added a sixth. The
  correction under §2 explains why, and it is the most consequential thing this
  audit got wrong.
