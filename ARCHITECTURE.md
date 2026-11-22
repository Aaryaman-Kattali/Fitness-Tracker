# Personal Fitness App — Architecture Spec

Single-user, offline-first Android app. iOS visual language. No backend.

> **How to read this file.** `REQUIREMENTS.md` names it authoritative for stack
> and schema, so it has to describe what ships rather than what was planned.
> Rewritten against the tree on **1 Sep 2026**; it had drifted far enough that a
> fresh session following it would have built the wrong app. Where a line was
> **falsified** rather than merely superseded, it is kept as an amendment trail
> — the treatment A2-3 got in `REQUIREMENTS.md` — because the reason a plan was
> wrong is worth more than the plan being quietly correct.
>
> `pubspec.yaml` and the drift tables are the real source of truth. When they
> and this file disagree, they win and this file is stale again.

---

## 1. Stack

```yaml
framework:    Flutter 3.41.7, Dart SDK ^3.11.5
ui:           Cupertino widgets (CupertinoApp, NOT MaterialApp)
font:         Inter (SF Pro substitute — SF Pro licence forbids non-Apple platforms)
navigation:   go_router ^16.0.0
state:        flutter_riverpod ^3.0.0 + riverpod_annotation/generator ^4.0.0
database:     drift ^2.28.2 + drift_flutter, sqlite3_flutter_libs (FTS5 enabled)
health:       health ^13.3.2 (→ Android Health Connect)
location:     tracelet 3.2.17 — PINNED EXACTLY, no caret
barometer:    sensors_plus ^7.1.0 — pressure only, for A6 elevation gain
maps:         flutter_map ^8.3.1
              + flutter_map_vector_tiles 2.8.1 — PINNED EXACTLY
              + ONE vendored style, assets/map_style/positron.json (U-3),
                recoloured to this app's palette (U-11); tiles, sprites and
                glyphs still from OpenFreeMap, keyless. dark.json is DELETED
notifications: flutter_local_notifications ^22.3.0 + timezone
sharing:      share_plus ^13.3.0 — debug-only in USE, not in the binary
charts:       NONE — fl_chart is not a dependency
backend:      NONE
```

**Target:** applicationId `com.personal.fitness_tracker`, minSdk 26,
**compileSdk 36**, targetSdk 35, Android only. Core library desugaring is on and
must stay on: `flutter_local_notifications` requires it. `MainActivity` extends
`FlutterFragmentActivity`, because the Health Connect plugin uses
`registerForActivityResult`.

**Both pins are pins for a reason, not caution.** `tracelet` shipped 3.6.9
through 3.8.7 in 26 days, and everything from 3.2.18 up requires `meta ^1.18.0`
while this Flutter SDK pins `meta` to 1.17.0 through `flutter_test` — 3.8.7 does
not resolve at all. `flutter_map_vector_tiles` went 0.1.0 → 2.8.1 with two
breaking majors and was five days old when adopted. See the comments in
`pubspec.yaml`; they carry the current reasoning.

**Amendments — lines this section carried that turned out to be wrong:**

- ~~`location: geolocator + flutter_foreground_task`~~ → **tracelet 3.2.17**
  (A1-4). Apache 2.0, no paid tier, and it ships its own foreground service.
  It adds no transitive packages that were not already here.
- ~~`maps: CARTO Positron / Dark Matter`~~ → **OpenFreeMap vector tiles** via
  `flutter_map_vector_tiles` (A2-3, amended twice). CARTO's keyless tiles
  worked when they were chosen and within weeks served an "API KEY REQUIRED"
  watermark — **HTTP 200, a valid PNG, so it rendered as map content and
  looked like a defect in this app.** The requirement is the *property*
  (near-monochrome, keyless, swappable in one line via `MapTileSource`), never
  the vendor. Verify a source is keyless **today** before choosing it.
- ~~`charts: fl_chart`~~ → **removed.** M6's trends were cut with the scope
  cut. A dependency for a feature that is not built is a dependency that ages
  in the lock file.
  **Corrected 18 Sep 2026:** this line used to end "and the e1RM chart that
  shipped in M2 draws with `CustomPainter`". There is no e1RM chart. It was
  deleted on 18 Aug 2026 with `exercise_detail_screen.dart` and
  `one_rep_max_chart.dart` (AUDIT.md §6 item 2, ~543 lines), and
  `REQUIREMENTS.md` lists it under **Cut**. Only `bestOneRepMax` survives, to
  label last session's best set on `LastSessionCard`. The claim was wrong from
  the day this file was rewritten on 1 Sep and survived that rewrite — two
  sources of truth disagreeing, found by the midterm audit.
- ~~`compileSdk 35`~~ → **36**. targetSdk stays at 35, so runtime behaviour is
  unchanged; only what the tree compiles against moved.
- ~~`barcode: mobile_scanner`~~, ~~`images: image_picker`~~, ~~`http: dio`~~ →
  **none of these are dependencies.** Barcode scanning and progress photos are
  under review or cut (see §8), and nothing ships an HTTP client: Open Food
  Facts is not wired in, and `tool/build_food_db.py` is standard-library-only
  Python that runs on a PC, not in the app.

**Rejected deliberately:**
- React Native — Material Design leaks through native components
- Google Maps SDK — requires billing-enabled GCP account
- flutter_background_geolocation — paid licence for Android release builds
- Google Fit APIs — dead end of 2026, use Health Connect
- Firebase / Supabase — a single-user app needs no server
- MapLibre (`maplibre`, `flutter-maplibre-gl`) — renders as a **platform
  view**, so no Flutter widget can live inside the map and every A2 layer would
  need rewriting against a different coordinate system. Mapbox / HERE /
  MapTiler / Geoapify — a free tier requiring an account is the same revocation
  risk CARTO demonstrated. Full list and reasons in `NOTES.md`, "Map
  rendering: what was rejected, and why".

---

## 2. Project structure

```
lib/
  main.dart
  app/                 router, theme, cupertino tokens
  core/                extensions, formatters, units
  data/
    db/                drift schema, DAOs, migrations
    repositories/
    remote/            OpenFoodFacts, USDA FDC clients
  features/
    today/             DEFAULT LANDING SCREEN
    workout/           plan, session logging, history, e1RM
    nutrition/         NOT YET — M3 creates it
    activity/          steps, run recording, map, splits, diagnostics
    progress/          measurements (photos are CUT — see §8)
    settings/
  shared/widgets/      reusable Cupertino components
assets/
  db/food.sqlite       NOT YET — M3 produces it
  fonts/Inter/
tool/
  build_food_db.py     INDB → SQLite pipeline (run once, Python, stdlib only)
```

`lib/data/remote/` does not exist: no remote client is wired in. `lib/app/`
also holds `debug/` (the `kDebugMode` date override) and `theme/`, which owns
every colour, spacing and text token — a widget never hardcodes one.

Every feature flows **model → dao → repository → provider → widget**, and
nothing skips a layer. Only `HealthConnectRepository` may import `health`;
only the map layer touches tiles. No plugin call happens in a widget.

---

## 3. Database schema (drift)

**`schemaVersion` is 7.** A `?` means nullable.

```dart
// ---------- FOOD ---------- (declared ahead of M3; no DAO yet)
Foods:        id, name, nameLocal?, brand?, source (INDB|USDA|OFF|USER),
              barcode?, isRecipe, kcal100, protein100, carbs100, fat100,
              fibre100, sugar100?, satFat100?, sodium100?
Servings:     id, foodId→Foods, label ("1 katori","1 medium roti"), grams, isDefault
FoodsFts:     VIRTUAL TABLE fts5(name, nameLocal, brand)   -- foods_fts.drift

RecipeItems:  id, recipeFoodId→Foods, ingredientFoodId→Foods, grams
FoodLogs:     id, date, meal (breakfast|lunch|snack|dinner),
              foodId→Foods, grams, loggedAt

// ---------- TRAINING ----------
Exercises:    id, name, pattern (squat|hinge|press|pull|carry|plyo|isolation),
              equipment, isUnilateral
PlanDays:     id, dayKey (lowerA|upperA|lowerB|upperB), name, orderIndex
PlanItems:    id, planDayId, exerciseId?, targetSets?, repLow?, repHigh?, notes?
Workouts:     id, date, planDayId?, startedAt, endedAt?, notes?
SetLogs:      id, workoutId, exerciseId, setIndex, weightKg?, reps, rir?,
              isWarmup, loggedAt?
WarmupChecks: id, workoutId, planItemId, lineIndex
              UNIQUE(workoutId, planItemId, lineIndex)

// ---------- ACTIVITY ----------
Runs:         id, startedAt, endedAt?, distanceM, movingS, elapsedS,
              elevGainM?, avgPaceSPerKm, polyline?, avgHrBpm?, maxHrBpm?, notes?
RunPoints:    id, runId, lat, lon, elevM?, timestamp, accuracyM?, speedMps?
Splits:       id, runId, km, durationS, elevDeltaM?
DailySteps:   date (PK), steps, activeKcal, source

// ---------- PROGRESS ----------
Measurements: id, date, weightKg?, waistCm?, chestCm?, armCm?, thighCm?,
              hipCm?, neckCm?, broadJumpCm?

// ---------- SETTINGS ----------
Preferences:  key (PK), value            -- text/text; SettingsRepository types it
```

**Indexes:** `FoodLogs(date)`, `SetLogs(workoutId)`, `SetLogs(exerciseId)`,
`WarmupChecks(workoutId)`, `RunPoints(runId)`, `Runs(startedAt)`.

**Amendments — what this section got wrong:**

- ~~`Photos: id, takenAt, pose, filePath, weightKg?`~~ → **dropped in v6 and
  not coming back.** Progress photos and the pose-overlay camera are CUT.
  `Measurements` survived the same cut because M6-1 did; do not drop it.
- ~~Runs / RunPoints / Splits as originally listed~~ → **dropped in v6, then
  re-added in v7 in a different shape.** Not a revert: the v6 step stands
  exactly as it ran on real devices, and the tables came back with every
  column whose producing feature is unbuilt made *nullable* rather than
  zero-filled, plus the two heart-rate columns A7 will need (A1-3).
- ~~`SetLogs.weightKg` non-null~~ → **nullable, and this is the precedent the
  whole schema follows.** Bodyweight, band and plyometric work carries no
  load; storing 0 there drags an e1RM trend to the floor. Null-weight
  exercises are excluded from 1RM charts and get a volume trend instead. Null
  is the honest record that nothing measured it; zero is a value something
  downstream will average.
- **`Preferences` and `WarmupChecks` were missing from this file entirely.**
  Preferences arrived in v5 as a key/value table so a new setting does not
  cost a schema version. WarmupChecks arrived in v3: a row's existence *is*
  the tick, and unticking deletes it, so the table never stores "nothing
  happened".
- `Workouts` is keyed by `(date, planDayId)` in practice — that pair is what
  lets any plan day be started or resumed on any date (C-5).

**Migration rules, and they are not negotiable.** Bump `schemaVersion` and
**append** an `if (from < n)` step for every table change; never edit a step
that has run on a real device. And **`m.createTable()` does not create the
table's `@TableIndex` entries — `createAll()` does.** That shipped a real bug:
devices upgraded into v3 lacked `idx_warmup_checks_workout` while fresh v3
installs had it, indistinguishable by version number. Repaired in v4 with
`CREATE INDEX IF NOT EXISTS`, because drift's `createIndex` emits a bare
`CREATE INDEX` that throws on the half that already has it. When adding a table
with indexes, create the indexes explicitly.

**Prefer fewer, larger migrations.** Every schema version permanently adds
~1,500 generated lines to `test/generated/`, and dropping the tables later does
not recover them — the old dumps must keep describing the old schema. This is
why v1 declaring tables years ahead of their DAOs cost four migrations rather
than saving them.

An enum used by a drift table must be imported in `app_database.dart` even
though it looks unused there: the generated part file resolves it against that
library's imports.

**Search query pattern:**
```sql
SELECT f.* FROM foods_fts
JOIN foods f ON f.id = foods_fts.rowid
WHERE foods_fts MATCH ? ORDER BY rank LIMIT 50;
```
Recently-logged and favourite foods rank above FTS results in the repository layer.

---

## 4. Food database pipeline

Run `tool/build_food_db.py` once on Windows. Output: `assets/db/food.sqlite`.

**Sources:**

| Source | Get it from | Provides |
|---|---|---|
| INDB recipes (n=1,014) | github.com/lindsayjaacks/Indian-Nutrient-Databank-INDB / anuvaad.org.in | **Cooked Indian dishes only**, per-100g AND per-serving |
| IFCT raw items | **NOT in the INDB repo — request from ICMR-NIN** | Raw ingredients for the recipe builder |
| USDA FoodData Central | fdc.nal.usda.gov (free API key) | Pasta, oats, generic international |
| Open Food Facts | world.openfoodfacts.org — no key needed | Packaged Indian brands, barcode lookup |

**Amendment — the raw-ingredient source is not where this file said it was.**
~~"INDB / IFCT items (n=1,095), same [repo]"~~ is wrong twice over. The INDB
repository contains the **1,014 cooked recipes and nothing else**; the IFCT
ingredient tables are a separate ICMR-NIN publication and have to be requested
from them. The 1,095 figure describes nothing in either source and should not
be carried into a validation budget. The script reflects this: it documents the
IFCT sheet's column names exactly (`IFCT_COLUMNS`) because that publication
names them, and refuses to guess INDB's, aborting on an unrecognised header
with the headers it actually found. **Until the IFCT sheet is obtained there is
no ingredient table, so the recipe builder has no inputs.**

**Pipeline steps:**
1. Parse INDB recipe CSV → `Foods` with `isRecipe = true`, `source = INDB`
2. Parse IFCT raw items → `Foods`, `isRecipe = false` — *blocked on the source*
3. Fetch ~200 common USDA generics by FDC ID → `Foods`
4. Deduplicate on normalised name; INDB wins for any Indian item
5. Attach household servings (see §5) → `Servings`
6. Build FTS5 index
7. `VACUUM` and ship as asset

**The report is the product, not the .sqlite** (M3-3). The script prints a
validation report and stops; `--write` is a separate flag and refuses to run
while any error-level check fails. **CSV only, standard library only, no
invented identifiers** (M3-5): `.xlsx` is refused with "export to CSV" rather
than pulling in openpyxl, and without `--usda-ids` step 3 reports as skipped
rather than inventing 200 FDC IDs.

Rows failing macro reconciliation are **quarantined, not dropped and not
corrected** (M3-8): written, flagged, excluded from `foods_fts` so they cannot
be searched, and listed in the report. 38 of 1,014 fail and none of the four
candidate explanations fits — they are per-row source errors with no repairing
transformation. Deleting source data because it cannot be explained is how a
real signal is lost.

Open Food Facts is queried **live at scan time**, not bundled — its Indian
dataset is large and changes constantly. Cache every scanned result into the
local `Foods` table with `source = OFF` so it works offline afterwards. Note
that barcode scanning itself is under review (§8), so this path is unbuilt.

---

## 5. Household servings (critical for adherence)

Nobody weighs 150 g of dal. Gram-only entry is the #1 reason food logging is abandoned. Every high-frequency Indian food gets realistic serving rows:

```
1 katori dal (cooked)      ~150 g
1 medium chapati           ~35 g
1 large chapati            ~50 g
1 katori rice (cooked)     ~150 g
1 katori sabzi             ~100 g
1 idli                     ~40 g
1 medium dosa              ~85 g
1 glass milk (250 ml)      ~250 g
1 katori curd              ~120 g
1 large egg                ~50 g
1 roti-sized paratha       ~60 g
```

Add a **grams-per-katori calibration setting** (M3-2) — katori size varies
enormously by household. Weigh yours once, set it, and every katori entry
scales. The katori is the unit that varies most, which is why it is the one
with a calibration hook.

**Amendment — "katori" is this app's vocabulary, not the source's.** Measured
31 Aug 2026: the word **katori appears zero times in all three INDB files**.
INDB says `bowl` (269 rows), `small bowl` (15) and `curry bowl` (7). That
matters because §5 and the M3-2 calibration setting are both written against
"katori", so a source-faithful label alone leaves the calibration with nothing
to key off, while a katori-only label silently rewrites what the source said.

**So the bowl family emits two serving rows** (M3-7), and only that family:

| INDB says | default row | non-default row |
|---|---|---|
| `bowl` | `1 katori` | `1 bowl` |
| `curry bowl` | `1 katori` | `1 curry bowl` |
| `small bowl` | `1 small katori` | `1 small bowl` |

The katori row is the default and is what M3-2 calibrates; the bowl row is what
INDB actually published, kept so the provenance survives. Every other unit
emits a single row in the source's own words. The cost is two near-identical
picker entries; the gain is that neither the calibration hook nor the source
wording is lost.

Serving weights are derived from INDB's own `unit_serving_*` columns — `serving_g
= 100 × unit_serving_energy_kcal ÷ energy_kcal` — not from a unit lookup (M3-6).
The table above still overrides for these staples. A serving that comes back
implausible is **quarantined, never silently adjusted** (M3-12): instant coffee
carries a published "1 tea cup" of 449.6 g, which the arithmetic recovers
correctly from a wrong source row. Editing it down to a plausible 240 would
erase the only evidence the row is unreliable.

---

## 6. Key implementation notes

**Today screen (landing).** Resolves the current weekday → `PlanDays.dayKey` → renders today's session at the top. Below it: macro rings, steps ring, quick-log row. Everything else is one tap away via `CupertinoTabScaffold`.

**Health Connect.** Request `READ_STEPS` and `READ_ACTIVE_CALORIES_BURNED` via
the `health` package. Health Connect must be installed (bundled in Android 14+,
Play Store app below that) — handle the not-available case gracefully, with
`HealthConnectClient.getSdkStatus()` rather than a `Build.VERSION` check. **The
Today screen must never block on Health Connect**: it renders fully with the
steps ring in an unavailable state.

> **FALSIFIED: ~~"Use the Recording API for steps: no Google account, no
> scopes, better battery."~~** The Recording API
> (`FitnessLocal.getLocalRecordingClient()`, in Play services) and the `health`
> package (which wraps Health Connect) are **two different systems, and no
> single package does both** — so this line and the line above it could not
> both hold. `RecordingMethod` in the `health` package is unrelated provenance
> metadata, not the Recording API. The three properties the Recording API was
> wanted *for* are all true of Health Connect anyway. Full working in NOTES.md,
> "M4: the Recording API is not what the `health` package gives you"; the
> outcome recorded there is **option 1, leave it**, contingent on the S26.

**Run recording.** `tracelet` 3.2.17, with **its own filtering disabled**
(A1-5): it ships an accuracy threshold, an implied-speed cap and a Kalman
smoother, and defaults to *adjusting* rejected fixes rather than dropping them.
Two filter chains with different constants is two sources of truth, and only
this pipeline's is under test. A foreground service with a persistent
notification is required or One UI kills it on screen-off (A1-6).

> **SUPERSEDED: ~~"discard points with `accuracy > 20 m`, and discard
> implausible speeds (> 8 m/s while running)"~~.** The real chain runs in a
> fixed and load-bearing order — reorder buffer, quality ceiling
> (`maxAccuracyM: 9`), stream separation, cold start, kinematic bound,
> smoother, and only then distance accumulated **from the smoothed track**.
> The bound is not a flat speed cap: it scales with elapsed time and allows
> both fixes' uncertainty as slack, combined **in quadrature** (A1c-B),
> because a receiver that loses lock under a bridge has genuine travel to
> report while a 500 m jump in one second does not. `maxAccuracyM: 9` is
> PROVISIONAL and knowingly so — see the doc comment on it. Smoothing before
> accumulating is the step that gets transposed and must not be: on foot the
> jitter is larger than the real displacement between fixes.

Store the full track in `RunPoints`, and persist an encoded polyline on `Runs`
for fast list rendering.

Android's fused provider **interleaves two producers** — GPS on whole-second
timestamps and network trilateration on fractional ones — and separating them
is the single largest correction in this pipeline: the other stream traced
6,171 m across a 1,610 m walk. `StreamDetector` does it without needing a gap
in the accuracy distribution to exist, because that gap was a property of one
walk and the second walk crossed it.

**Share cards.** Under review (§8). `share_plus` is present for the debug-only
run-data export (C-9), not for this.

**Progress photos.** **CUT.** Table dropped in schema v6; the pose-overlay
camera goes with it. The ruling against AI body-fat estimation stands and is
worth keeping: vision models return confident numbers with ±3–5% error, which
exceeds a month of real change.

**Android version flexibility.** One binary runs on Android 13 and 15+. Never
gate behaviour on `Build.VERSION` — use runtime capability checks, and probe
hardware (barometer, dual-band GNSS) rather than assuming it. Anything needing
Android 15+ must be feature-detected and degrade **visibly**, never crash and
never silently no-op. minSdk stays 26.

---

## 7. Claude Code setup

**`CLAUDE.md` exists at the repo root. Read that file, not a copy of it.**

This section used to embed a copy of it, and the copy had been wrong for
months — it described a four-line conventions list where the real file carries
the prime directives, the stop-and-ask triggers, the simplicity budget, the
blast-radius rules and a landmines list that only exists because each entry
cost something. A stale duplicate of an operating manual is worse than no
duplicate: it is followed with confidence.

Nothing about the setup belongs here except the pointer. The one thing worth
repeating, because it is the reason the lint set is strict: `flutter analyze`
output is read directly and iterated to zero, so a warning is a working signal
rather than a nag. And the trap that makes analyze insufficient on its own —
**it cannot see `*.g.dart` / `*.drift.dart`, so a clean analyze over a broken
tree is possible. Only `flutter build apk --debug` proves the tree compiles.**

---

## 8. Build order

**This table is the original plan and is kept for the record. `PROGRESS.md` is
the live one — go there for what is actually next.** Scope was cut in
July–August 2026 and A1 was then reinstated, so the numbering below no longer
describes the work.

| Milestone | Original scope | Where it actually stands |
|---|---|---|
| **M1** | Cupertino shell, tab scaffold, theme tokens, Today screen | **Done** |
| **M2** | drift schema, workout logging, history, PR tracking | **Done.** The e1RM *trend chart* was cut on 18 Aug 2026; `bestOneRepMax` survives to label last session's best set |
| **M3** | Food DB pipeline, search, logging, macro rings, servings | **Next**, and the highest-value remaining work. `build_food_db.py` exists and stops at the validation report; no UI yet |
| **M4** | Health Connect steps, daily rings | **Done** — Health Connect, not the Recording API (§6) |
| **M5** | GPS run recording, map, splits, run detail | **Renumbered A1/A2 and in progress.** Cut in v6, reinstated in v7. Pipeline, map, diagnostics and two ground-truth walks done; splits UI and pace chart open |
| **M6** | Progress photos, measurements, fl_chart trends | **Photos CUT** (table dropped in v6). `measurements` survives because M6-1 does, and has no DAO yet |
| **M7** | Barcode scanning, OFF integration, recipe builder | **Barcode under review.** The recipe builder is blocked on the IFCT ingredient tables (§4) |
| **M8** | Share cards, JSON export/import, home widget | **Share cards under review.** The debug-only run-data export (C-9) shipped and is not this |

Under review means **do not start**: GPS map matching, share cards, barcode
scanning, progress photo overlays. Assume they are out until told otherwise.

The original advice survives the renumbering and was right: ship M1+M2 and use
it for two weeks before writing M3. Two weeks of real use tells you more about
the UX than any amount of upfront design.

---

## 9. Nutrition constraint (informs seed data)

Target: **145 g protein/day**, whole food only, no whey or creatine, mostly-veg with flexible non-veg.

The seed food list should prioritise high-protein Indian staples, because 145 g on mostly-veg is the genuinely hard part:

| Food | Protein per 100 g |
|---|---|
| Soya chunks (dry) | ~52 g |
| Paneer | ~18 g |
| Chicken breast | ~31 g |
| Eggs (whole) | ~13 g |
| Greek/hung curd | ~10 g |
| Rajma, chana (dry) | ~22–24 g |
| Toor/moong dal (dry) | ~22–24 g |
| Peanuts | ~26 g |

Soya chunks are the single highest-leverage item — ~52 g protein per 100 g dry, very cheap, and they absorb any masala. Two portions a day plus eggs and dal makes the target reachable without touching supplements.
