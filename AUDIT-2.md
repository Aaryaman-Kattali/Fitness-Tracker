# Codebase audit — the midterm

**Status: report only. Nothing deleted, nothing changed.** Audited 2026-09-18
against commit `9abfd29`, working tree clean. `AUDIT.md` (18 Aug 2026) is the
precedent and every number below is measured against its post-cleanup figures.

Method, stated so it can be discounted: line counts are `wc -l`; comment ratios
are computed per file; symbol reachability is a whole-corpus word index over
`lib/`, `test/` and `tool/` with every candidate re-checked by hand; provider,
DAO and theme-token reachability were each swept exhaustively rather than
sampled. `flutter analyze` and `flutter test` were run and their output is
quoted. `flutter build apk --debug` was **not** run — this commit changes no
code, and the last commit that did was verified against it.

**Bias disclosure up front, as the August audit did:** `git log` shows every
commit in this repository is mine. This is an audit of my own work and the
failure mode is justifying it. §7 says where I am defending rather than
reporting.

---

## 1. Inventory

### Totals, against the August baseline

| Group | Aug 2026 | Now | Change |
|---|---:|---:|---:|
| `lib/` hand-written | 6,342 | **14,578** | **+8,236 (+130%)** |
| `lib/` generated | 12,594 | 16,316 | +3,722 |
| `test/` hand-written | 1,692 | **14,325** | **+12,633 (+747%)** |
| `test/` generated | 8,971 | 10,564 | +1,593 |
| `tool/` hand-written | 0 | **1,736** | new |
| `android/app/src/` hand | 197 | 223 | +26 |
| `assets/` (text) | 0 | **3,348** | new — the vendored map style |
| **Hand-written total** | **8,231** | **34,210** | **+25,979** |
| **Tree total** | 29,845 | **61,090** | +31,245 |

Generated has fallen from **72%** of the tree to **44%**. That is the headline
structural change and it is a good one: the growth since August is
overwhelmingly hand-written pipeline, tests and fixtures rather than more
`app_database.g.dart`.

`lib/data/db/app_database.g.dart` is 13,502 lines *(was 10,576)* — 22% of the
repository *(was 35%)*. `test/generated/migrations/` is 10,564 *(was 8,971)*:
schema v7 added 1,590 lines that no later deletion recovers, exactly as §2 of
the August audit predicted.

### Where the `lib/` growth went

| Area | Hand-written | Generated | Aug | Delta |
|---|---:|---:|---:|---:|
| **A — GPS pipeline, run recording, map, diagnostics** | **7,086** | 677 | 0 | **+7,086** |
| M2 — workout logging, history, seed | 3,519 | 1,036 | 3,757 | −238 |
| M1 — shell, theme, router, Today | 1,795 | 486 | 1,171 | +624 |
| M4 — Health Connect, steps | 1,382 | 238 | 1,134 | +248 |
| shared / db wiring | 737 | 13,879 | 280 | +457 |
| M3 — food tables only | 74 | 0 | 74 | 0 |
| **Total** | **14,593** | **16,316** | 6,342 | |

*(The 14,593 here and the 14,578 above differ by 15 lines: `foods_fts.drift` is
counted once in the area table and not in the `.dart`-only total. Stated rather
than reconciled away.)*

**86% of the growth is the activity block.** That is where the work went and it
is what the milestone said. The other four areas moved by a few hundred lines
each and M2 actually shrank.

M1's +624 is not shell work: it is `app_colors.dart` 113→224 and
`app_spacing.dart` 40→154, both almost entirely doc comments (75% and 62%
comment respectively), plus `app_router.dart` +32 for the run routes and
`another_session_row.dart` (84, C-5).

### `lib/` — the activity block (7,086 hand-written)

| File | Lines | Code | Com% |
|---|---:|---:|---:|
| `pipeline/track_processor.dart` | 1,212 | 516 | 47% |
| `pipeline/track_diagnostics.dart` | 886 | 621 | 20% |
| `widgets/run_map.dart` | 823 | 464 | 37% |
| `run_recording_screen.dart` | 520 | 364 | 22% |
| `diagnostics/run_diagnostics_store.dart` | 418 | 225 | 34% |
| `pipeline/stream_detector.dart` | 416 | 174 | 46% |
| `providers/run_recording_provider.dart` | 390 | 229 | 30% |
| `run_detail_screen.dart` | 375 | 308 | 10% |
| `pipeline/noise_process.dart` | 345 | 171 | 41% |
| `../repositories/tracelet_run_recorder.dart` | 258 | 168 | 24% |
| `pipeline/rts_smoother.dart` | 222 | 136 | 26% |
| `widgets/map_tile_source.dart` | 185 | 55 | 62% |
| `../db/dao/run_dao.dart` | 108 | — | |
| `../db/tables/activity_tables.dart` | 97 | — | |
| `diagnostics/fix_capture.dart` | 100 | — | |
| `run_list_screen.dart` | 98 | — | |
| `providers/run_history_provider.dart` | 114 | — | |
| `providers/run_diagnostics_provider.dart` | 93 | — | |
| `diagnostics/reconstruct_diagnostics.dart` | 69 | — | |
| `pipeline/raw_fix.dart` | 65 | — | |
| `providers/run_exports_provider.dart` | 52 | — | |
| `../repositories/run_recorder.dart` | 121 | — | |
| `../repositories/file_sharer.dart` | 45 | — | |
| `run_format.dart` | 41 | — | |
| `pipeline/geo.dart` | 33 | — | |
| plus settings sections (`run_exports` 210, `run_diagnostics` 120) | 330 | | |

**The comment ratio is the thing to read here, not the line count.** The four
pipeline files that carry the project's hard-won findings run 41–47% comment.
`track_processor.dart` is 1,212 lines of which **516 are code**. That is not
bloat in the §4 sense; it is the decision record living next to the decision.
Whether it should live there rather than in `PROGRESS.md` is a real question and
I take it up in §4.

### `test/` (14,325 hand-written, 10,564 generated)

| File | Lines | Tests |
|---|---:|---:|
| `support/synthetic_track.dart` | 1,698 | — (fixtures) |
| `migration_test.dart` | 906 | 8 |
| `run_map_test.dart` | 768 | 30 |
| `synthetic_track_test.dart` | 746 | 34 |
| `map_style_test.dart` | 566 | 20 |
| `capture_threshold_report_test.dart` | 496 | 3 |
| `track_diagnostics_test.dart` | 423 | 16 |
| `run_recording_screen_test.dart` | 355 | 15 |
| `walking_fixtures_test.dart` | 330 | 21 |
| `corner_cutting_test.dart` | 324 | 8 |
| `network_stream_report_test.dart` | 323 | 3 |
| 38 further test files | 5,079 | ~300 |
| `support/` (4 files) | 297 | — |

`test/generated/migrations/` is seven schema dumps, v1–v7, 10,525 lines.

### `tool/` (1,736 hand-written + 2,375 CSV data)

| File | Lines |
|---|---:|
| `build_food_db.py` | 1,066 (13% comment) |
| `test_build_food_db.py` | 670 |
| `data/raw/INDB.csv` | 1,015 |
| `data/raw/recipes_servingsize.csv` | 1,015 |
| `data/raw/Units.csv` | 346 |
| `data/README.md` | 69 |
| `fixtures/*.csv` | 32 |

`tool/__pycache__/` (490 lines of `.pyc`) is present in the working tree.
Check it is ignored; it is not source and should not be committed.

### `android/app/src/` (223 hand, 59 generated)

`AndroidManifest.xml` 137 *(was 111)* — the +26 is the foreground service, the
location permissions and `share_plus`'s `FileProvider`. `MainActivity.kt` 12,
unchanged. The remaining 74 lines are untouched Flutter scaffold.

### `assets/`

| File | Lines / bytes | Declared in `pubspec.yaml`? |
|---|---:|---|
| `map_style/positron.json` | 3,348 | **yes** |
| `fonts/Inter/*.ttf` (4) | 12.7k binary | **yes** |
| `fonts/Inter/LICENSE.txt` | 92 | no — correct, it is a licence file |
| `db/food.sqlite` | 266 KB | **no** |

`assets/db/food.sqlite` is generated, git-untracked and deliberately not
committed (`tool/data/README.md:13`). It is also not declared as an asset, so
it does not ship. That is correct for today — M3 has no UI — but it is a
wiring step that must land with M3-1 and there is nothing in `PROGRESS.md`
holding it.

---

## 2. Requirements reconciliation

Every row in `REQUIREMENTS.md`, checked against the tree.

### In and built (M1–M4) — 13 rows

All thirteen verified built. Spot checks: M1-4's shifted week is
`weekday_session.dart` with `weekday_session_test` pinning "all four sessions
exactly once"; M2-2's resume key is `workout_dao.dart:44 openWorkoutFor` on
`(date, planDayId)`; M2-7's nullable load is `SetLogs.weightKg`; M4-3 is
`steps_card_test`'s "does not wait on the steps check".

### Agreed in conversation (C-1 … C-9-1) — 10 rows

All ten built and all ten traceable. C-5 → `another_session_row.dart` (84) with
`another_session_row_test` (3 cases). C-6 → `health_diagnostics_section.dart`
(204) + `health_diagnostics_test` (4). C-7 → `track_diagnostics.dart` (886) +
`reconstruct_diagnostics.dart`. C-9 → `run_exports_section.dart` (210) +
`file_sharer.dart`. C-9-1's sidecar is `ExportKind.countCache` in
`run_diagnostics_store.dart:261`, exercised by `dated_captures_test` (8).

**One defect against C-2.** *(Fixed 18 Sep in `71817de`; C-2 now carries the
amendment. Left here as the audit found it.)* `RestAlerts` detects that the OS
has withheld exact alarms (`rest_alerts.dart:71`), uses the answer internally
to pick a schedule mode (`:94`), and exposes it as `isExact` (`:40`) — **which
nothing reads.**
The degradation is handled and never shown. CLAUDE.md §4's platform-boundary
exception is explicitly "degrade visibly… shown to the user, never swallowed",
and `CLAUDE.md` §10 names the inexact fallback as the required behaviour. The
timer silently becomes approximate and the user is told nothing. See §3.

### Cut — 7 rows

All seven verified absent. No `fl_chart` in `pubspec.yaml`, no
`exercise_detail_screen.dart`, no `one_rep_max_chart.dart`, no `Photos` table,
no step-goal picker, no backfill, no `reconcileStaleWorkouts`. `bestOneRepMax`
and `epleyOneRepMax` survive in `core/one_rep_max.dart` (27 lines) exactly as
the row says.

### In, not yet built — the rows that have moved

| ID | Status in file | Measured | Verdict |
|---|---|---|---|
| M3-1 / M3-2 | next / agreed | no `features/nutrition/`, no food DAO | **correct** |
| M3-3 … M3-5 | built 27 Aug | `build_food_db.py` 1,066 lines, `--write` gate present | **correct** |
| M3-6 … M3-12 | agreed 31 Aug | in the script + `test_build_food_db.py` | **built, row says agreed** |
| M6-1 | "table exists, no DAO yet" | `Measurements` declared, no DAO, no repository | **correct** |
| A1-2 | agreed, deferred to A6 | raw altitude stored (`run_dao.dart:57`), nothing derived | **correct** |
| A1-3 | agreed, columns in v7 | `activity_tables.dart:40-41`, `run_dao.dart:39` leaves them null | **correct** |
| A1-7 | agreed 26 Aug | `rts_smoother.dart` + `smoothedTrack()` built, **unwired** | **correct** — see §4 |
| **A2** | **agreed, current** | run list, detail, map, overlay, offline banner all shipped | **BUILT — row and `PROGRESS.md` checkbox are stale** |
| A2-1 … A2-10 | mixed | all built | correct, except A2-10 below |
| **U-7** | **agreed 9 Sep** | `positron.json`: both layers carry `text-halo-color: #14151B` | **BUILT** |
| **U-8** | **agreed 9 Sep** | `positron.json:727` `line-color: #7DA89F` | **BUILT** |
| **U-9** | **agreed 9 Sep** | `app_spacing.dart:114` `runMarkerCoincidentM = 35` | **BUILT** |
| A1c-18 | open, oracle failing | two budgets red at 23 s and 21 s | **correct, confirmed §5** |
| N4 | agreed, not built | nothing | **correct** |
| A6 | (PROGRESS) not started | nothing | **correct** |

**Three rows marked "agreed" are shipped** (U-7, U-8, U-9) and **A2 is
substantially complete while both its requirement row and its `PROGRESS.md`
checkbox say otherwise**. All four were landed in commits `b429ea3` and
`f5c1222`, which updated `REQUIREMENTS.md` to *record* the decision and never
came back to move the status. That is a bookkeeping failure, not an untraceable
feature — but a file whose whole purpose is to say what was agreed and what
exists is wrong about four rows.

### Rows now falsified by the code

**U-1 is superseded and the file does not say so.** It reads: *"`AppColors.accent`
moves to #105666 light / #1FA7C7 dark… Explicitly NOT a palette: no new colour
tokens… pinned by `test/app_colors_contrast_test.dart`."*

Measured: there is no `AppColors.accent`. There is no light theme. There are
**three new accent tokens** (`accentPrimary #FF3D9A`, `accentSuccess #C6FF33`,
`accentSecondary #22D3EE`), the surfaces were renamed and re-valued, and
`CupertinoDynamicColor` is gone from every token. `app_colors_contrast_test.dart`
now measures that palette, so the row's own pin points at a test that no longer
tests what the row claims.

**A2-10 is superseded.** It says `trackPosition` and `trackRawFix` read from
`AppColors.accent` and `trackLine` stays `#FF9500`. Measured: `trackLine` is
`accentPrimary` (`app_colors.dart:133`), `trackRawFix` is a hardcoded `#105666`
at 0.6 alpha and the doc comment says the link to the accent was **deliberately
broken**.

**U-3 is superseded.** It specifies land `#F7F4D5`, water `#0A3323`, buildings
`#D3968C` — a light basemap. The shipped style is a dark ground (`#14151B`) with
light roads.

**U-4's measured numbers are stale.** "Worst ground 1.00:1 → 2.19:1… on water
13.90:1" describes the light basemap. `20c6786`'s commit message records the
shipped figures (cloud 2.20 worst, on path) and `map_style_test.dart` pins them.

### The reverse: code with no requirement row

**One finding, and it is large.**

> **The whole-app palette overhaul — commits `4978151` "Theme tokens: one role
> per colour, single theme, dark" and `20c6786` "Basemap: dark ground, light
> roads, magenta route" — has no row in `REQUIREMENTS.md`.**

What it changed: every colour token renamed by role, `CupertinoDynamicColor`
removed from all of them, `.resolveFrom(context)` deleted from ~125 call sites,
the light theme dropped, three accents introduced, four role colours re-valued,
and the basemap inverted from a light ground to a dark one with the route moved
from orange to magenta. It touches `app_colors.dart`, `app_theme.dart`,
`positron.json`, and — by the commit's own count — 170 call sites.

**`REQUIREMENTS.md` has been edited four times since** (`8b41089`, `c9949a4`,
`f3310ff`, `dc88575`) and never got a row for it. The rule in CLAUDE.md §1 is
"every agreed requirement lands in `REQUIREMENTS.md` **before** it is
implemented". It did not, and the three superseded rows above are the direct
consequence: U-1, U-3 and A2-10 now describe an app that does not exist.

**The discipline held everywhere else.** I checked every other feature in
`lib/` against the file and found no second case. C-5, C-7, C-8, C-9, C-9-1,
A2-9, A2-10, U-5, U-6 all have rows, several written retroactively and saying so.
The A1c series is exhaustively recorded. `another_session_row.dart`,
`file_sharer.dart`, `reconstruct_diagnostics.dart`, `run_format.dart`,
`map_tile_source.dart` — every one traces. So the answer to "did the discipline
hold" is: **yes, for 13 features and one milestone's worth of measurement work,
and no for the single largest visual change in the project.**

Two smaller ones, both traceable but not to `REQUIREMENTS.md`:

- **The Inter font.** `ARCHITECTURE.md:23` names it ("SF Pro substitute — SF Pro
  licence forbids non-Apple platforms") and that is a legitimate source of truth
  for stack. No requirement row; none needed under the file's own rules.
- **`tool/test_build_food_db.py`** (670 lines). Implied by M3-3's "the report is
  the product", never named.

### `ARCHITECTURE.md` is wrong in three places

Named authoritative for stack and schema by `REQUIREMENTS.md`, so these matter:

1. **§1 and §8 both claim the e1RM chart ships.** §1: *"the e1RM chart that
   shipped in M2 draws with `CustomPainter`"*; §8: *"**Done** — e1RM ships,
   drawn without `fl_chart`"*. It was deleted on 18 Aug 2026 and
   `REQUIREMENTS.md` lists it under **Cut**. Two sources of truth disagreeing —
   a CLAUDE.md §1 stop-and-ask trigger.
2. **§1 still lists "OpenFreeMap Positron / dark"**. `dark.json` was deleted
   under U-3 and `NOTES.md` records the deletion.
3. **§4 repeats the Open Food Facts paragraph verbatim** at lines 272–275 and
   277. Harmless, but it is a duplicated paragraph in a spec.

---

## 3. Dead and unreachable

The sweep: every public top-level declaration and every public class member in
non-generated `lib/` (1,213 declarations) checked against a word index over all
of `lib/`, `test/` and `tool/`; 73 candidates re-checked by hand.

**The result is remarkably clean — three items.**

> **CORRECTION, 18 Sep 2026.** This section originally listed a fourth,
> `AppTypography.title2`, as defined and never used. **It is not dead.**
> `app_theme.dart:42,45` sets it as the Cupertino picker and date-picker text
> style. The token sweep excluded `lib/app/theme/` so that each token's own
> declaration would not count as a use, and that exclusion also hid its only
> consumer, which happens to live in the same directory. Caught by
> `flutter analyze` at the moment of deletion, not by the sweep. Its doc
> comment claimed it was "used for the numeric readouts on the set logger",
> which is what made the false positive plausible; it now names where it is
> actually wired. **Re-run without the exclusion: all 68 theme tokens are
> used and the correct finding is zero dead tokens.** The method error is the
> one worth carrying — an exclusion added to suppress self-references also
> suppresses same-directory references, so a sweep that excludes a directory
> cannot report on anything consumed inside it.

| Symbol | Location | Note |
|---|---|---|
| `RestAlerts.isExact` | `rest_alerts.dart:40` | The getter is dead; the private `_isExact` is load-bearing at `:94`. **This is the C-2 defect in §2** — a platform degradation computed and never shown. **Resolved 18 Sep**: replaced by `RestAlertDelivery` and surfaced on the timer bar. |
| `MapTileSource.esriLightGray` | `map_tile_source.dart:111` | **Not dead by intent.** 20 lines of documented alternative, kept under A2-7's swappability rule, with its own reason for not being the default. Keep. |
| `TrackProcessor.smoothedTrack()` | `track_processor.dart:718` | Zero production callers; 20 call sites in tests. A1-7, deliberate. §4 judges it. |

**Providers never watched: none.** All 42 provider symbols have at least one
`ref.watch` / `ref.read` / `overrideWith` consumer. Checked individually,
including the three that read as single-reference (`exerciseSetsProvider`,
`setDraftControllerProvider`, `lastExerciseSessionProvider` — all consumed in
`exercise_log_screen.dart`).

**DAO methods never called: none.** All 34 methods across five DAOs have a
repository, provider or test caller. The August audit found four dead; that has
not recurred.

**Theme tokens never used: none.** All 68 are referenced — see the correction
above; the first pass reported one and was wrong. The August audit found four
dead out of ~50. The discipline held through a palette rewrite that renamed
everything.

**Assets never loaded: one** — `assets/db/food.sqlite`, and correctly so (§1).

**Tests asserting what no code path can produce: one, and it is the sixth.**

> **`test/rest_timer_state_test.dart:61` — "holds the stored remainder while
> paused".** It constructs `RestTimerState(total: 3 min, remaining: 95 s,
> isRunning: false)` — a state with a live remainder and no deadline — and
> asserts the clock does not consume it.
>
> **No code path produces that state.** `RestTimerState` has exactly three
> producers: `RestTimerState.idle()` (all zero), `start()` (`:113`) and
> `_restartFrom()` (`:79`), and both of the latter always set a deadline.
> `RestTimer.pause` and `RestTimer.resume` were **deleted in the August audit**
> as dead code. The paused concept now survives only in this test and in a
> stale doc comment at `rest_timer_provider.dart:40` ("Null while paused,
> finished or idle").
>
> It fails differently from the five already catalogued. Those five had a
> fixture, a harness or an assertion that could not discriminate. This one is
> correct, discriminating, and pointed at a state the app cannot reach — the
> test outlived its feature by a month, and the deletion that removed the
> feature did not notice the test still describing it.

That is the sixth. For completeness, three near-misses I checked and cleared:

- `capture_distance_report_test.dart` asserts only `distanceM > 0` — but it
  **declares itself** a reporting harness in its own doc comment, which is the
  honest form. One real defect: it replays **four** captures while
  `stopped_time_test` replays **six**. The two 8 Sep captures were added to one
  and not the other.
- `map_tile_source_test`'s live-attribution test could have skipped silently
  forever; it nulls `HttpOverrides.global` specifically to stop that, and it
  ran and passed here.
- `effective_clock_test` is thin but every case can fail.

**One uncovered guard, worth more than any of them.** `DateOverride.setDate`'s
`if (!kDebugMode) return;` (`effective_clock.dart:56`) is the single line
keeping C-3's date override out of a release binary, and **it has no test and
cannot have one in this harness** — `kDebugMode` is always true under
`flutter test`. `effective_clock_test.dart` never touches `DateOverride` at all;
it tests the pure `EffectiveClock` value class. Nothing in the repo records
this as unverifiable. Same shape as A1c-17's rule: *when a value is not
consumed by any check, it has no oracle — validate it or say in writing that it
is untested.*

**No debug prints, no TODOs, no dead code, no commented-out blocks** anywhere in
`lib/`. The only two `debugPrint` calls are the sanctioned platform-boundary
ones at `health_connect_repository.dart:289` and `rest_alerts.dart:138`.

---

## 4. Bloat

70 non-generated files exceed 150 lines. Read them with the comment column,
because it changes the verdict on most of them.

### The files where comment is the bulk

| File | Total | Code | Com% | Verdict |
|---|---:|---:|---:|---|
| `app_colors.dart` | 224 | **29** | 75% | 29 lines of colour, 169 of why. Every hex has a measured reason and a rejected alternative. **Keep.** |
| `map_tile_source.dart` | 185 | **55** | 62% | Same shape. The comments are A2-7's swappability record. **Keep.** |
| `app_spacing.dart` | 154 | **37** | 62% | Same. **Keep.** |
| `track_processor.dart` | 1,212 | 516 | 47% | See below. |
| `stream_detector.dart` | 416 | **174** | 46% | 174 lines of code for the single largest correction in the pipeline. **Keep.** |
| `noise_process.dart` | 345 | **171** | 41% | A1c-G/H. **Keep.** |
| `run_map.dart` | 823 | 464 | 37% | See below. |

I do not think these are bloat and I will say why once: this project's method
is that a measurement is worthless without the reasoning that produced it, and
three separate times (A1c-12, A1c-13, the U-2 reversal) a *deleted* or *stale*
justification cost a round of work. Comments that record a falsified hypothesis
next to the constant it produced are the cheapest form of that record. The
question is only whether they belong in the file or in `PROGRESS.md`, and the
answer the repo has settled on — the finding in `PROGRESS.md`, the invariant in
the file — is right.

### The four files I would look at hardest

**`track_processor.dart` — 1,212 lines, 516 code.** It is the buffer, the
accuracy gate, the stream-detector call, cold start, the kinematic bound, the
Kalman filter, distance accumulation, the stop rule, splits, pace, the RTS
state tape and the report hand-off. That is nine responsibilities in one class.
The minimum is not fewer lines — every one of those is required — it is that
the two-axis Kalman filter (`_Axis`, the `_filtered` tape and `smoothedTrack()`,
roughly 300 lines) is a separable unit with a clean boundary, and pulling it out
would leave the chain readable end to end. **I am not recommending it.** The
file has no duplication, no abstraction with one implementation, and 20 test
files pointed at it; splitting it is a refactor with no defect behind it and
CLAUDE.md §5 says list, do not fix.

**`run_map.dart` — 823 lines, 464 code, one widget file.** It owns the style
load, the tile layer, the polyline, the casing, both markers, the split-marker
geometry, the puck, the raw-fix overlay, the camera, follow-me, the manual-pan
break, the fit-bounds button and the failure banner. This is the one file where
I think the line count is real rather than documentary. The split that suggests
itself is the marker geometry (U-6's coincident-donut logic) into its own
file — it is pure geometry, it has its own tests in `run_map_test`, and it is
the part a reader has to scroll past to reach the camera. Again: listed, not
recommended.

**`capture_threshold_report_test.dart` (496) + `network_stream_report_test.dart`
(323) — 819 test lines, 6 tests, 0 assertions between them.** These are the
harnesses for A1c-L and A1c-M. Both questions are **rejected and closed**. The
harnesses now run on every `flutter test`, take a measurable share of the
44-second suite, print ~200 lines of table nobody reads, and assert nothing.

They are the strongest deletion candidate in the repo, and I still think they
should stay — but for exactly one reason, which should be checked rather than
assumed: A1c-M names the evidence that would reopen it (*"a capture with a long
outdoor GPS outage"*), and when that capture arrives the harness is what scores
it. A rejected ruling with a named falsification test is not a closed question.
**The cheap fix is not deletion: skip them by tag and keep the harness.**

> **Corrected in the doing, 19 Sep 2026.** This paragraph originally said they
> "already carry `@Tags(['report'])`, so excluding that tag costs one line".
> **`report` is the wrong axis.** Five files carry it and only three lack an
> oracle: `stopped_time_test` prints a table *and* pins A1c-O's invariant on
> all six captures, and `reported_speed_test` pins A1c-N. Excluding that tag
> would have silently dropped live coverage — the exact defect shape this audit
> was looking for, proposed by the audit. A second tag, `no-oracle`, carries
> the three.
>
> And `exclude_tags` was the wrong mechanism. Measured: it drops the seven
> tests correctly, and then `flutter test --tags no-oracle` fails with
> `include: "<all>" / exclude: "no-oracle"` — the config exclusion beats the
> command line, and naming the file by path does not escape it. The opt-in
> route would not have existed. `tags: { no-oracle: { skip: … } }` is what
> shipped: the skip is visible in the runner's output with its reason, and
> `flutter test --run-skipped --tags no-oracle` runs exactly the seven.

**`synthetic_track.dart` — 1,698 lines of fixtures.** Twenty-odd fixtures, each
with its ground truth verified independently by `synthetic_track_test` (34
cases). This is the largest single hand-written file in the project and it is
the reason the pipeline can be reasoned about indoors. **Do not touch.**

### Abstractions with one implementation

| Abstraction | Impls | Earns it? |
|---|---|---|
| `HealthRepository` | 2 (+ fake) | **Yes**, as August found. |
| `RunRecorder` / `TraceletRunRecorder` | 1 (+ `FakeRunRecorder`) | **Yes.** `run_recording_provider_test` (12) and `run_recording_screen_test` (15) are unreachable without the fake, and A1-5 depends on the seam. |
| `RunDiagnosticsStore` / `FakeDiagnosticsStore` | 1 (+ fake) | **Yes**, same argument. |
| `FileSharer` | 1 | Marginal — 45 lines wrapping `share_plus`. Justified by CLAUDE.md §10's plugin-seam invariant. |
| `PlanRepository` over `PlanDao` | 1 | Unchanged from August: mandated by the layering rule. |
| `MapTileSource` | 1 active, 4 documented | **Yes** — A2-7 is literally about this. |

**No new one-implementation abstraction has appeared since August.** That is the
rule-of-three holding under 8,000 lines of growth.

### Defensive code for impossible states

I found **none** newly introduced in the activity block. What looks defensive
there is not: the `null`-vs-`0` distinction in `displacementSpeedForCandidate`
(`track_processor.dart:1096`) is the fix for a real shipped bug (NOTES, the
Zurich walk), and the `maxBufferedFixes` cap (`:343`) guards a receiver whose
clock stops, which is a real failure mode for a device app.

Two carried forward from August and still true:
`health_connect_repository.dart`'s `lastDay.isBefore(firstDay)` guard cannot
fire, and `one_rep_max.dart:12`'s `weightKg <= 0` cannot fire. Both ~1 line.

### Parallel paths that could be one

1. `today_screen.dart:` and `session_screen.dart:` still render warm-up / plyo /
   main blocks near-identically in two screens (~35 lines). August called this a
   genuine rule-of-two and left it. Unchanged, still correct to leave.
2. `run_detail_screen.dart` and `run_recording_screen.dart` both lay out a
   full-bleed map with a stats panel over it (A2-4 specifies exactly that). The
   stats formatting is shared through `run_format.dart`; the layouts are not.
   **This is where the U-5 overflow defect is un-mirrored:** the recording
   screen got `run_stats_overflow_test` (4 cases × real formatter output at
   worst case, on 320 and 430 surfaces); the detail screen's sheet has no
   equivalent. Its test drives one fixture (`5.50 km`) at one default surface.
   Same shape as NOTES case 4, on the sibling screen, not yet found on device.

### The RTS smoother — the judgement asked for

**The code needs to exist. The runtime cost it imposes does not.**

Two halves, and they should be judged separately:

`rts_smoother.dart` (222) + `smoothedTrack()` (~90 in `track_processor.dart`) +
`rts_smoother_test.dart` (286, 13 cases) are **the instrument that produced
A1c-14 and A1c-15**, and those findings are comparisons — filter against
smoother, seven `an` values, five datasets, plus a coastline-decimation ratio.
`PROGRESS.md` carries the *result tables*. It cannot carry the *ability to
re-run them*, and the whole method of this repo is that a number is only worth
what the instrument that produced it is worth. Delete the code and A1c-14's
tables become unfalsifiable folklore — which is precisely the failure A1c-13
recorded when a constant was defended by a measurement that never happened.
It is also the only implementation available the day a coordinated-turn or IMM
motion model is tried, which is A1c-14's own named next step. **Keep.**

The part I would question is the other half. `TrackProcessor._filtered`
(`:349`) accumulates one 13-double record per accepted fix, **unconditionally,
on every real recording**, to serve a method nothing in production calls.
`PROGRESS.md` prices it at ~0.9 MB for a two-hour run. That is a real cost paid
by every walk for an offline analysis, and it is the one thing here that a
constructor flag would fix — default off in `TraceletRunRecorder`, on in the
replay harness and the tests. One parameter, no redesign, no loss of evidence.

**So: the commit message and the `PROGRESS.md` entry do NOT carry the finding
adequately, because the finding is a sweep and not a sentence. But the live
state tape is machinery running on a phone for a test, and it should be
switchable.**

---

## 5. Test audit

**493 tests, 491 passing, 2 failing.** Measured:

```
00:44 +491 -2: Some tests failed.
```

*(The brief says 511; the suite reports 493. The gap is probably the three
`@Tags(['report'])` files being counted differently, or a stale figure. 493 is
what `flutter test` returns today.)*

`flutter analyze`: **`No issues found! (ran in 78.0s)`**

### The two deliberate reds — confirmed, and for the stated reason

```
walking_fixtures_test.dart
  moving time an irregular cadence does not invent stops either [E]
    Expected: a value less than <20>
      Actual: <23>
  moving time a brisk walk is never mistaken for standing still [E]
    Expected: a value less than <20>
      Actual: <21>
```

23 s and 21 s against a `<20` budget, on `variableCadenceWalk` and
`measuredVariableCadenceWalk`. That is exactly what `PROGRESS.md` A1c-18
records, digit for digit. The regular-cadence sibling still reads green. **They
still fail for the stated reason and nothing has been retuned to hide them.**

### Which tests would catch a real regression

The proportion is much better than in August. Of 493:

**High value — would catch a real regression (~400).**

- `migration_test` (8, 906 lines). Still the highest-value file in the repo,
  now covering v1→v7. The `loggedAt` two-workout fixture and the v3→v4 index
  repair both encode bugs that shipped.
- The pipeline suite — `track_distance_test`, `track_metrics_test`,
  `track_filters_test`, `track_splits_test`, `kinematic_bound_test`,
  `reorder_buffer_test`, `stream_detector_test`, `stream_wiring_test`,
  `smoother_init_test`, `smoothing_order_test`, `stopped_distance_test`,
  `stopped_time_test`, `reported_speed_test`, `sub_second_steps_test`,
  `corner_cutting_test`, `rts_smoother_test` (~170 tests). Almost every one of
  these was written to reproduce a specific measured defect, several are
  verified by mutation in their own comments, and `track_diagnostics_test` is a
  20-fixture change detector that makes any pipeline edit visible.
- `device_capture_test` + `second_walk_capture_test` (22) — the only budgets
  scored against ground truth walked on the ground.
- `synthetic_track_test` (34) — verifies each fixture's ground truth
  independently of the pipeline, including the determinism guard that stops an
  unseeded fixture failing one run in twenty.
- `map_style_test` (20) + `app_colors_contrast_test` (13) — computed WCAG over
  the *composite*, pinned against the JSON rather than restated in Dart. These
  caught the `#6E7280` label failure before it shipped.
- `run_map_test` (30) — including the two-brightness test that would pass
  against a build that still switched, deliberately written that way.
- `run_stats_overflow_test` (4 → 9 cases) — real formatter output at worst
  case, two surface widths, verified able to fail.
- `steps_card_test` (8), `warmup_checks_test` (7), `workout_repository_test`
  (11), `run_dao_test` (4), `dated_captures_test` (8), `run_exports_test` (9).

**Low value, framework-level or trivially true (~25).**

- `rest_timer_state_test`: `progress` (3) and the two lifecycle-flag cases are
  one-line getters. August flagged them and kept them; unchanged.
- `effective_clock_test`: the no-override case restates the implementation.
- `capture_distance_report_test` (1): `> 0`.

**Zero-assertion by design (6).** `capture_threshold_report_test` (3),
`network_stream_report_test` (2), `capture_distance_report_test`'s print block.
All labelled. See §4 for the tag proposal.

**Unreachable (1).** The paused-timer case in §3.

### The sixth green-but-empty test

Reported in §3: **`rest_timer_state_test.dart:61`, asserting over a
`RestTimerState` that no producer can construct since `pause`/`resume` were
deleted in August.** It is the first of the six whose emptiness was *created by
a deletion* rather than present at birth, which is a new failure mode for the
list: the August audit removed the feature and left the test, and a passing
test is the one artefact a deletion sweep never re-reads.

---

## 6. What is genuinely good

Load-bearing. Know these before anything is deleted.

1. **`synthetic_track.dart` + `synthetic_track_test`.** 1,698 lines of fixtures
   whose ground truth is verified independently of the pipeline, seeded so
   randomness cannot make a test flaky, with the noise model derived from a
   measurement (A1c-G/H) rather than guessed. This is the single most valuable
   artefact built since August and it is what makes everything else provable
   indoors.

2. **The `captures/` directory.** Six real walks, three with ground truth
   measured on the ground, committed with their reports and raw tracks, named so
   they cannot overwrite each other (C-7-1). Irreplaceable — a capture is one
   walk's worth of evidence that cannot be regenerated. **Never prune these.**

3. **`StreamDetector` + `maxAccuracyM`.** The largest correction in the
   pipeline: 6,171 m of network-stream fiction removed from a 1,610 m walk, and
   1,632,725 m from a 4.3 km Zurich walk. Note that A1c-17 found it *inert on
   five of six captures* — that is not a reason to delete it, it is a reason to
   know that `maxAccuracyM: 9` is currently carrying the separation by luck and
   the detector becomes load-bearing again the moment 9 moves.

4. **The migration chain and `migration_test.dart`.** v1→v7, 906 lines, and the
   only thing standing between you and losing a training log. The v3→v4 index
   repair still encodes a bug version numbers cannot detect. Never edit a step;
   never trim this test.

5. **`TrackProcessor`'s ordering: buffer → accuracy → stream → cold start →
   kinematic → smooth → accumulate.** Every step is there because a measurement
   put it there, and `PROGRESS.md` A1c-13 records why cold start had to move
   behind both gates. Transposing smoothing and accumulation is the one
   transposition that silently over-reports on foot.

6. **The anchor-freezing stop rule (A1c-J).** Distance and stopped time now have
   one definition each and the stops list decomposes the header exactly
   (A1c-O), asserted on every fixture and all six captures. The `null`-vs-`0`
   distinction in `displacementSpeedForCandidate` is the fix for a bug that
   reported zero metres on a 960 m walk, and it is pinned by mutation.

7. **The contrast oracles — `map_style_test` and `app_colors_contrast_test`.**
   They measure the composite that actually renders, not the nominal hex, and
   they are pinned against the style JSON. They caught a specified label colour
   that failed AA on all three surfaces *before* it shipped, and the commit that
   inverted the basemap found five assertions that had to invert with it rather
   than three. This is an oracle doing exactly what CLAUDE.md §6 asks of one.

8. **`WorkoutDao.openWorkoutFor` on `(date, planDayId)`** and **`nextSetIndex`
   from `MAX(set_index)`.** Unchanged from August, still the two lines that keep
   the training log from forking or silently corrupting.

9. **`RestTimerState` defined by a wall-clock deadline.** Survives
   backgrounding, throttling and resume because `remaining` is a rendering of
   `deadline` rather than an accumulator.

10. **`PROGRESS.md` and `NOTES.md` as they now stand.** The retraction trail is
    the best thing in this repository: A1c-12's amended attribution, A1c-13's
    "the false reason is written down here on purpose", the U-2 reversal
    explaining why the parking note's boundary was drawn wrong, the four
    green-test post-mortems. Three separate rounds of work were saved by a
    previously-falsified hypothesis being findable. Do not compress these.

---

## 7. Bias disclosure

`git log` shows every commit in this repository is mine — 40 since the August
audit, all of them. This is an audit of my own work and the failure mode is
justifying it. Where I am defending rather than reporting:

- **§4 on the comment ratios.** I wrote those comments and I argued they earn
  their place. Read that argument sceptically. The counter-case is real: 169
  lines of prose in a 224-line colour file is a lot of file to read to find a
  hex, and a reader who wants the palette has to skim an essay.
- **§4 on the RTS smoother.** I recommended keeping code with zero production
  callers. That is exactly the recommendation an author makes about their own
  work. The honest summary is that the *tests* are the asset and the
  implementation is their fixture; if you disagree that A1c-14 needs to stay
  re-runnable, the whole thing goes and PROGRESS.md keeps the tables as claims.
- **§4 on the two report harnesses.** Same shape. I proposed tagging them out
  rather than deleting them, which is the answer that preserves my own work.
- **§6.** Listing ten things as load-bearing is an author's list.

**And one thing this audit got outright wrong**, recorded in place rather than
quietly amended: `AppTypography.title2` was reported dead and is not. A
directory exclusion added to stop each token counting its own declaration also
hid the only consumer, which lives in that directory. The build caught it; the
sweep did not. Same class as the August audit's ~545-line misattribution — a
method that cannot see a category of evidence, reported as an absence of
evidence.

Where I am reporting against myself, for balance: the palette overhaul with no
requirement row (§2) is the exact failure `REQUIREMENTS.md` was created to
prevent, and I committed it twice; the four stale status rows are mine; the
`ARCHITECTURE.md` e1RM claim has been wrong since 18 Aug and I rewrote that file
on 1 Sep without catching it; the sixth empty test exists because my own
deletion sweep did not re-read the tests around what it deleted; and `isExact`
is a platform degradation I detected and never showed the user, which is the one
rule CLAUDE.md §4 makes an explicit exception for.

**The audit's own blind spot, unchanged from August:** requirements agreed in
conversation leave no trace in the repo. Where I report a feature as having no
row, I mean no row *in the repo*, and §2's palette finding is stated as a
bookkeeping failure rather than as unrequested code for that reason.

---

## STOP — and what was decided

Nothing here was a recommendation to delete. The four things put to you,
smallest first, with the ruling:

1. ~~`AppTypography.title2` — one dead token.~~ **Withdrawn.** Not dead; the
   audit was wrong. See the correction in §3. The comment that misled me is
   fixed.
2. `rest_timer_state_test.dart:61` and the stale doc comment at
   `rest_timer_provider.dart:40`. **Deleted and corrected**, `4870d4e`. The
   mechanism is new and is recorded in `NOTES.md` as the sixth entry, with a
   one-line rule in CLAUDE.md §5: *a deletion sweep re-reads failing tests and
   never passing ones — grep the suite for the feature's TYPES, not its
   function names, and read the green hits.*
3. `RestAlerts.isExact`. **Surfaced, not deleted**, `71817de`. C-2's own
   reasoning decides it: the phone is in a pocket between sets. Both degraded
   states are now on the timer bar — the `unavailable` case as well as the
   `inexact` one, since "never" is strictly worse than "late" and was hidden by
   the same mechanism. Verified by mutation both ways.
4. The doc corrections. **All done**, this commit.

The `_filtered` tape flag and the `@Tags(['report'])` exclusion were both
approved and follow.
