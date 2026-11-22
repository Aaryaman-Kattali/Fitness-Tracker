# PROGRESS.md

The activity block, item by item. One commit per item; the sha goes in the
line when it is done. An item is done only when its acceptance criterion is
objectively checkable and checked — "looks right" is not an acceptance
criterion.

Scope reference: `REQUIREMENTS.md`. GPS run recording was cut in schema v6 and
is back in scope as of August 2026; A1a-0 records that reversal before any code
lands.

---

## A1a — GPS processing pipeline (built; incomplete, see A1c)

Pure Dart. No plugin, no UI, no map, no BLE. Everything provable indoors
against synthetic tracks.

- [x] A1a-0 Scope reversal recorded
      Accept: `REQUIREMENTS.md` moves GPS run recording out of "Cut" into a
      dated in-scope row; no code in this commit
      Commit: fa9aa5a

- [x] A1a-1 Synthetic track fixtures, with ground-truth self-tests
      Accept: `test/support/` builds all seven fixtures as plain Dart data, no
      `dart:io`/plugin/network import; each fixture's stated ground truth is
      verified against the geometry independently of the pipeline
      Commit: a67625a
      Note: the acceptance criterion originally said "replays them through a
      pipeline interface". The pipeline does not exist at this commit, so
      replay is asserted from A1a-3 onward instead. Narrowed deliberately, not
      quietly: what a fixture commit can actually prove is that the fixtures
      are correct, and that is now proven rather than assumed.

      **LESSON, added 22 Aug 2026 after the first device test.** All twelve
      original fixtures are straight lines due north. Not one contains a turn.
      A Kalman smoother cuts corners by construction, and a city walk is
      mostly corners — so the one mechanism that could SHORTEN a real track
      was untested by the entire suite, while every bias the suite *could*
      measure runs long. **When every fixture shares a geometric property,
      that property is untested.**

      The property was not chosen carelessly; running due north is what makes
      `groundTruthDistanceM` exact along a meridian, independent of the
      longitude convergence factor. That is a good reason, and it is exactly
      how a blind spot gets built: the constraint that makes the oracle
      trustworthy also made every fixture the same shape. Both things were
      true at once and only one of them was noticed.

- [x] A1a-2 Schema v7 — Runs, RunPoints, Splits re-added
      Accept: `schemaVersion == 7`; the v6 block in `onUpgrade` is byte-identical
      to before; v7 block creates the three tables AND issues an explicit
      `CREATE INDEX IF NOT EXISTS` for `idx_runs_started_at` and
      `idx_run_points_run`; `drift_schema_v7.json` dumped
      Commit: 91a1bba

- [x] A1a-2b v6→v7 migration test
      Accept: a populated v6 database (plan, workouts, set_logs, daily_steps,
      measurements, preferences) migrates to v7 with every value read back
      unchanged; the three new tables exist; both new indexes appear in
      `sqlite_master`; `migrateAndValidate(db, 7)` passes from every version
      Commit: 91a1bba (with A1a-2: an unproven migration should not exist in
      history as its own commit)

- [x] A1a-3 Cold-start and accuracy filters
      Accept: first 3 fixes rejected regardless of quality; a fix with
      `accuracy > 50` rejected; the 3×80 m fixture yields 3 rejections with
      reason `accuracy`
      Commit: 3eeb670

- [x] A1a-4 Implied-speed filter (kinematic bound)
      Accept: 500 m/1 s teleport rejected; 400 m after a 60 s gap accepted.
      Both in one test file so the pair cannot drift apart
      Commit: d6b1afc

- [x] A1a-5 Smoothing
      Accept: zero-noise 1 km track still lands within 1% (proves the smoother
      does not eat real displacement); ±15 m fixture lands within 3%
      Accept (position): on the ±15 m fixture, mean distance from smoothed
      points to the true line must be LOWER than the same measure on the raw
      fixes. A smoother that degrades position while hitting a distance budget
      has not worked.
      Commit: a9af22a

      Design history: a scalar-gain (position-only) Kalman was approved and
      implemented first. It cannot meet both distance budgets at any Q — the
      two constraints are monotonic in Q and move in opposite directions,
      because a random-walk position model has no velocity state and therefore
      lags a constant-velocity target by a fixed distance. Measured: best case
      Q=1.0 gave clean -1.26% (budget 1%) and noisy +3.45% (budget 3%). It also
      put smoothed points ~17x further from the true line than the raw fixes.
      Do not revert to a position-only filter.

      Correction to that last figure: the 17x was an artefact of a bug in the
      measuring test, which paired smoothed points to truth by list index while
      the pipeline rejects fixes, so it compared against seconds the runner had
      not reached. Pairing now goes through the timestamp. The lag and the
      distance evidence are unaffected and the conclusion stands; only the
      positional multiplier was wrong. Retained rather than deleted because a
      number that was quoted in a decision should be visibly retracted.

      Fixture history: the noisy fixture originally used independent per-fix
      white noise at ±15 m, 1 Hz. That is physically wrong — real GPS error is
      dominated by ionosphere, multipath and geometry, which drift over
      minutes — and it contradicted the spec's own "naive over-report 10-30%"
      expectation, which at 1 Hz and 2.78 m steps requires sigma under ~1.2 m.
      Replaced with a first-order Gauss-Markov process. Do not revert to white
      noise for the realistic fixture; correlated drift is what actually bends
      a real track.

      Consequence of the fixture change, worth knowing before someone
      "restores" the strict positional assertion: on correlated noise a
      smoother cannot beat the drift, because a slowly wandering bias is
      indistinguishable from a runner easing left. Measured smoothed/raw
      positional error is ~1.007 — a draw. The strict "less than half of raw"
      claim therefore lives on the pathological fixture, where the error is
      separable and smoothing wins 3.5x. Both assertions exist; neither is
      the whole criterion on its own.

- [x] A1a-6 Distance accumulates from the SMOOTHED track
      Accept: a test that accumulates from the *unsmoothed* accepted track over
      the ±15 m fixture and asserts it over-reports by >10%, next to the real
      pipeline passing at <3%. Order is encoded as a failing alternative, not a
      comment
      Commit: a2a97b3
      Note: measured over the accepted fixes, the wrong order over-reports by
      ~8-12% rather than the ">10%" first written here — the fixture's 10-30%
      calibration covers every fix, including the three cold-start ones both
      orders discard. Threshold set from five noise draws, not from one.

- [x] A1a-7 Metrics — elapsed, moving time, average and current pace
      Accept: the 4-minute-standing-still fixture gives moving time excluding
      those 240 s ±12 s while elapsed time includes them; average pace equals
      moving time ÷ distance
      Commit: ca5e44b
      Note: the tolerance was written as ±5 s and is ±12 s. A detector that
      looks back over a 10 s window cannot know a stop has started until it
      has watched 10 s pass, so a few seconds are misattributed at each end;
      the bound is the window length, not a fudge. Measured 606 s of 600.

- [x] A1a-8 Per-kilometre splits
      Accept: the 5.5 km fixture yields exactly 6 splits — 5 marked full, the
      last marked partial with distance ≈500 m; split boundaries interpolated
      within the crossing segment, not snapped to a fix
      Commit: e10d0dd
      Note: the interpolation test runs at a 17 s fix cadence, not a round 20.
      At 20 s the 1000 m mark lands exactly on the eighteenth fix, so snapping
      and interpolating agree and the test would pass either way. Verified by
      mutation rather than assumed: snapping fails it.

### Lessons from A1a — apply to every fixture-backed task, not just this one

**A fixture can make the naive implementation look correct.** The splits test
first ran at a 20 s fix cadence, where the 1000 m mark falls exactly on the
eighteenth fix — so snapping the boundary to a sample and interpolating within
the segment give the same answer, and the test passed against an implementation
that did neither thing well. A cadence that puts the event *between* samples is
what makes the test mean anything. **Verify by mutation: break the
implementation deliberately and watch the test fail.** If it still passes, the
test was decoration.

**When a noise model changes, audit every fixture.** The Gauss-Markov change was
applied to the fixture it was requested for and left the standing-still fixture
on the old independent-noise model. That was not cosmetic: it added ~120 m of
phantom distance across a four-minute stop, and it surfaced two tasks later as
an average-pace failure whose apparent cause was somewhere else entirely. A
shared model living in more than one fixture is a single decision spread across
several files; changing it in one is changing it nowhere.

**Fixture randomness is seeded, and a test enforces that.** With a per-draw
spread of a few percent, an unseeded fixture fails perhaps one run in twenty,
which trains everyone to re-run rather than investigate. `fixtures are
deterministic` in `synthetic_track_test.dart` builds each track twice and
compares, so a seed becoming free fails immediately rather than at random.

Explicitly NOT in A1a: elevation gain. Raw altitude is stored in `RunPoints`
and nothing is computed from it. The A32 has no barometer and GPS altitude is
±10–15 m, which invents climb on flat ground.

---

## A1c — Calibration for real-world walking (open)

**A1a is not finished, whatever its ticks say.** Every item above passed
against a runner at 2.78 m/s arriving at exactly 1 Hz. The first device test
was a walk at 1.62 m/s delivering 0.78 fixes per second, and seven of A1a's
own budgets fail at that speed. The ticks record what was built and verified
at the time; this section records what that verification did not cover.

**No constant has been retuned to make any of these pass, and none may be
until the device diagnostics are in.** The seven failures are the oracle for
this work. A green suite bought by moving a threshold is worth less than a red
one that says where the problem is.

- [ ] A1c-0 Read the device diagnostics
      Accept: a fresh walk is recorded with the C-7 capture in place, and the
      accuracy distribution, inter-fix-interval distribution and out-of-order
      arrival count for that walk are recorded here as measured values
      Commit: <sha once done>
      This gates everything else in A1c. The accuracy distribution alone
      decides whether the recorded 3.46 km was roughly right or already
      inflated, and no threshold moves before it is known.

- [ ] A1c-1 Turning fixtures, and corner-cutting quantified
      Accept: a rectangular circuit and a switchback fixture, ground truth
      verified independently of the pipeline; loss measured AT the corners
      separately from loss along the straights; verified by mutation that the
      fixture distinguishes a corner-cutting smoother from one that does not
      Commit: <sha once done>

- [ ] A1c-2 Walking fixtures at the corrected speed
      Accept: the primary walking fixture runs at 1.6 m/s, matching the device
      measurement; the 1.0 m/s fixture is kept as the pessimistic case; the
      existing budgets are reported against both
      Commit: <sha once done>

- [x] A1c-3 Fixtures at the accuracy the device actually reports
      Accept: a walking fixture at 2.5 m median / 3.1 m p90 reported accuracy,
      correlated error, 1.6 m/s; the reported-accuracy distribution is checked
      against those two order statistics independently of the pipeline; the
      15 m fixtures are KEPT with their budgets as degraded-conditions cases
      Commit: 9f32cee

### Measure before calibrating

All fixtures were built at 15 m noise before any device measurement existed.
The device delivers 2.5 m median. The suite was calibrated to a guess that was
6x pessimistic, and the real error mechanism — out-of-order arrival producing
many sub-second-dt steps — was modelled by no fixture at all. Measure before
calibrating, and capture raw input before trusting a device test.

The correction, measured 22 Aug 2026:

| fixture | error | measured | true | error |
|---|---|---|---|---|
| brisk walk, straight | 15 m | 1038.60 | 1000 | +3.86% |
| brisk walk, straight | 2.5 m | 1001.36 | 1000 | **+0.14%** |
| brisk walk, irregular cadence | 15 m | 1015.18 | 1000 | +1.52% |
| brisk walk, irregular cadence | 2.5 m | 1000.46 | 1000 | **+0.05%** |

Five noise draws at 2.5 m: 998.3, 1000.5, 1002.6, 1003.7, 1008.8; mean 1002.80.
One draw reads short, so the estimator is not leaning — unlike the 15 m set,
where every draw of every fixture runs long.

**The measurement that closes the noise hypothesis.** A naive sum of the
delivered fixes, with the smoother, the filters and the accumulator all
removed, reads 1008.2 m at 2.5 m error — +0.8%. At 15 m the same sum reads
1316.4 m. So at the real operating point there is no arrangement of this
pipeline, including doing nothing at all, that turns 1.74 km into 1.94 km.
Whatever added the 200 m is not in the noise, and the smoother is not the
leading suspect. The remaining candidate the device named is arrival order.

**What the suite still cannot reproduce.** Max smoothed speed on the realistic
irregular-cadence fixture is 2.00 m/s against a 1.6 m/s walk. The device
reported 13.63 m/s on a walk whose median was 1.46. No fixture here produces
that tail, because no fixture delivers a fix out of order or at a sub-second
interval. That gap is the next two commits.

- [x] A1c-4 The sub-second-interval fixture, and what it costs
      Accept: a fixture whose true path is fixed and whose fixes arrive at
      mixed intervals including sub-100 ms bursts; the distance carried by
      steps under 0.5 s is measured against the distance genuinely walked in
      those intervals; no gate implemented
      Commit: 6a7c680

### The speed tail is reproducible. The excess is not.

`burstCadenceWalk` samples the realistic walk with roughly one interval in ten
opening a burst of three fixes 30-100 ms apart. Measured 22 Aug 2026:

| quantity | measured |
|---|---|
| total distance | 1002.45 m over a true 1000 (+0.25%) |
| accepted steps under 0.5 s | 142, min dt 0.030 s |
| metres those steps carried | 15.83 |
| metres genuinely walked in them | 14.37 |
| **phantom metres** | **1.46** |
| max smoothed speed | 5.78 m/s on a 1.6 m/s walk |
| largest smoothed step | 3.09 m |

**So a sub-second interval reproduces the device's speed tail and almost none
of its distance.** 5.78 m/s appears on a walk with no step over 3.09 m, which
is the same shape as the device's 13.63 m/s under a 33.8 m ceiling: a small
step divided by a near-zero dt. The tail was never evidence of added distance.

Why the interval is nearly free: GPS error is correlated, so two fixes 40 ms
apart carry almost the same error and differencing them returns almost exactly
the true displacement. For a short step to cost real metres the two fixes must
disagree by noise-scale distance, which 40 ms of drift cannot produce.

**The consequence, and it narrows the search.** The device's short steps must
carry error that is NOT correlated across them. That is what a fix arriving out
of sequence looks like, and also what a fix from a second source looks like —
tracelet is configured with `distanceFilter: 0` and `allowIdenticalLocations`,
over a fused provider. Both remain open. Neither is a property of the interval,
so a minimum-elapsed-time gate would suppress the symptom and leave the cause,
and it stays unimplemented on that basis.

- [x] A1c-5 Raw fix capture, and an offline replay path
      Accept: every DELIVERED fix is written as NDJSON in arrival order with an
      explicit sequence number; a capture replays through the pipeline to the
      same distance as the live run, to the last bit; the sequence survives
      sorting the file by timestamp
      Commit: 6cd4e49

### The capture, and the thing it should have prevented

`lib/features/activity/diagnostics/fix_capture.dart` and
`RunDiagnosticsStore.saveFixCapture`. One file per run, named for the run's
start time in UTC and **never overwritten**:
`run_fixes_<YYYYMMDD-HHMMSS>.ndjson` in the app documents directory, beside the
`run_index_<stamp>.txt` count sidecar. Settings → Export run data (C-9) is the
normal way off the device; by hand it is two steps, because there is no fixed
name to cat:

```
adb shell run-as com.personal.fitness_tracker ls app_flutter
adb exec-out run-as com.personal.fitness_tracker \
  cat app_flutter/run_fixes_20260823-141530.ndjson > walk.ndjson
```

**Amended 23 Aug 2026 — this paragraph used to say the opposite.** It described
a fixed name, `run_fixes_latest.ndjson`, overwritten once per run. C-7-1
reversed that after recording the second walk silently destroyed the first
walk's capture: overwriting a file whose entire purpose is to be the record of
something is the wrong default, and a capture is one walk's worth of evidence
that cannot be regenerated. Captures are now dated, nothing prunes them
automatically, and deletion is an explicit confirmed action. `_latest` is
retired and `groupExportsByStamp` deliberately ignores it — it would otherwise
group under a stamp of "latest".

**Why it exists.** The 48-minute walk produced 119 out-of-order arrivals and
106 discarded fixes, and not one of them can be re-examined. Only accepted
points are stored, and only their smoothed positions. Every question asked of
that run has to be asked again on a new walk. The reorder buffer cannot be
scored against the run that motivated it, and neither could any threshold
change, because the input was never kept.

**Arrival order is the payload.** The file is written in arrival order AND
carries a sequence number, because sorting a capture by timestamp is the
obvious first thing anyone does with one and would destroy the only evidence
the file was written for.

**What it makes possible.** One recorded walk through two pipeline
configurations, byte-identical input, difference attributable. That is a
controlled experiment on real data, and it was not available anywhere in this
project before. `replayCapture(contents, into: TrackProcessor(...))`.

**What it still cannot know.** `deliveredByPlugin` and `undatableDropped` read
unknown. A fix the plugin emitted with an unparseable timestamp never reaches
the stream the capture is written from, so the file has no evidence of it, and
reporting the line count under that heading would claim a clean delivery record
it cannot support.

**Held in memory, written at stop.** ~2,000 lines is a few hundred kilobytes
against a track the pipeline is already holding, and the alternative is two
thousand file writes during a run. The cost is that a process killed mid-run
loses the capture, which is the same exposure the diagnostics report has always
had. If a run is ever lost that way, this is the trade to revisit.

A1c-0 is still open and still needs a walk. What has changed is that the walk
after this one is the last one that has to be repeated.

- [x] A1c-6 Reorder buffer
      Accept: a fixture delivering the realistic walk out of order with ground
      truth unchanged; a bounded buffer holding ~3 s, sorting by timestamp and
      emitting in order; only fixes older than the horizon rejected; verified
      by mutation that a zero horizon fails it
      Commit: d65d1b3

### The buffer works. It is not the fix.

`shuffledArrivalWalk` delivers the realistic walk with one fix in five held
2.5 s and four held 12 s. Same fixes, same timestamps, same 1000 m — only the
order changes. Measured 22 Aug 2026, 417 fixes, 65 arrivals out of sequence:

| | buffer off | buffer on |
|---|---|---|
| accepted | 347 | **410** |
| rejected, non-monotonic clock | 67 | 0 |
| rejected, past the buffer | — | 4 |
| largest smoothed step | 11.63 m | 7.87 m |
| **distance** | **1000.36 m** | **1000.47 m** |

In-order reference: 1000.46 m. The buffer reconstructs the sequence to within
a centimetre of the walk that was never scrambled.

**And the distance moved by 0.11 m.** Sixty-three fixes recovered, a sixth of
the run, and the total is unchanged. Commit 2 was planned on the premise that
out-of-order handling was the primary cause of the 11.5 % over-report. That
premise is false, and the fixture falsifies it directly: discarding a late fix
does not add a step, it makes the next accepted step longer over a
proportionally longer dt, and the smoother rebuilds almost the same path from
what is left.

The buffer is still worth having. A sixth of the evidence recovered is a
better map, better splits, a better stop detector, and a largest step cut from
11.63 m to 7.87 m. It is a data-recovery improvement. Calling it a distance fix
would send the next person looking in the wrong place, so
`reorder_buffer_test` asserts the negative result explicitly and says why.

**Latency.** Live stats lag by the horizon, three seconds. The saved track does
not: `stopAndSave` flushes before anything reads the processor, and publishes
again afterwards so the screen and the database cannot disagree. Proven by the
pinned baselines in `track_diagnostics_test`, every one of which still holds to
0.01 m — holding an in-order fix for three seconds and then processing it gives
the same track as processing it at once.

### Three mechanisms tested, three negatives

| candidate | fixture | verdict |
|---|---|---|
| noise at the real accuracy | `realisticWalkingKm` | +0.14 %, and raw is +0.8 % |
| sub-second fix intervals | `burstCadenceWalk` | 1.46 m phantom over 142 steps |
| out-of-order arrival | `shuffledArrivalWalk` | 0.11 m |

None of them produces 200 m over 1.74 km. What has NOT been modelled at the
real operating point, in the order I would try them:

1. **Near-simultaneous fixes carrying UNCORRELATED error** — two sources, or
   one source reporting twice. A1c-4 showed a short step is free only because
   the error either side is correlated; two fixes from different sources 40 ms
   apart would not be. tracelet runs over the fused provider with
   `distanceFilter: 0` and `allowIdenticalLocations: true`, so this is
   configuration we chose and can test.
2. **Stationary periods at 2.5 m accuracy.** Every stop fixture is at 15 m or
   clean-while-walking. `walkWithStop` at 1.6 m/s reads 976.40 over a true 960,
   +1.7 %, from 1.5 m of drift across one three-minute stop. The device walk
   had roughly twelve minutes of stops.
3. **Turns at the real accuracy.** `rectangleCircuit` reads +1.0 % on a
   noise-free path with four corners. A city route has many more.

None of these is decidable from a fixture alone. All three are decidable from
one replayed capture, which is why A1c-5 came first.

### The seven failing budgets, with measured values

Fixtures at 1.0 m/s under 15 m correlated error, measured 21 Aug 2026 and
pinned in `test/track_diagnostics_test.dart`. All live in
`test/walking_fixtures_test.dart`.

| Budget | Measured | True |
|---|---|---|
| walked km within 3% | 1084 m | 1000 |
| unbiased across 5 seeds | 1084–1115, mean 1102, every draw long | 1000 |
| irregular cadence within 3% | 1106 m | 1000 |
| walk + 3 min stop within 1% | 614 m | 600 |
| no phantom stops, 1 Hz | 47 s called stopped | 0 |
| no phantom stops, irregular | 59 s called stopped | 0 |
| 1.0 m/s reads 16:40/km | 879 s/km | 1000 |

Passing at walking pace, for contrast: the clean walk with a spur (600.0 m),
the spur's rejection by the kinematic bound (exactly 1), the three-minute stop
excluded within ±12 s (599 s), and the irregular cadence at low noise
(1000 m).

### What governs the error — it is not speed

Mean over five seeds, 1 km walked at 1.0 m/s under correlated error:

| error σ | 3 m | 5 m | 8 m | 15 m | 15 m *at 2.78 m/s* |
|---|---|---|---|---|---|
| measured | +0.5% | +1.2% | +3.0% | **+10.2%** | +1.4% |

The pipeline has no speed-dependent constant, so speed cannot be what changed.
What changed is the ratio of error magnitude to per-fix displacement: walking
cuts the denominator by four and leaves the numerator alone, and the
degradation in that ratio is superlinear. **Hypotheses (a) walking pace and
(c) the 50 m accuracy threshold are therefore one hypothesis, not two** — the
question is not which fixes are discarded but how much error the accepted ones
carry, and if the device's median accuracy is near 15 m then a *tighter*
threshold helps where a looser one hurts. Nothing decides that but the
measurement.

### Irregular cadence — FALSIFIED, and closed

At 3 m error, an irregular cadence costs 0.14%. dt is handled correctly.

Verified by mutation rather than by inspection: forcing `_Axis.predict` to use
`dt = 1` regardless of the real interval — a total dt bug — moved the pinned
baselines, the irregular walk from 1106 to 1068 m and the pathological
white-noise fixture from 1465 to 1383 m. (That second one is nominally 1 Hz;
its rejections leave two- and three-second gaps behind them, which is why it
notices.) So a dt bug does fail the suite, and the suite currently says there
is not one.

Note for the next person: the same mutation does **not** fail the low-noise
cadence test, which is the test that looks like it should catch it. On a
constant-velocity walk with clean fixes the update step pulls the estimate back
onto each measurement whatever the prediction did, and the error never reaches
the distance. The test is documented in place as the weaker claim it actually
makes.

### Two defences against the Strava spur, not one

Removing the kinematic bound entirely (`maxSpeedMps = 1e9`) still leaves the
250 m spur out of the track: 601.8 m with a largest step of 2.5 m. The smoother
catches it independently — a 30 m-accuracy outlier against a filter confident
in a steady walk has a small Kalman gain, so a 250 m excursion lands as a 2.5 m
nudge. Reassuring, and a trap: the largest-step assertion alone would not
notice if one defence were removed, so the rejection count is asserted
separately.

### A1c-7 — Two streams, not one. The finding that reframed the milestone

The 23 Aug walk was recorded against a distance measured on the ground:
1610 m, against Strava's 1630 m (+1.2%) and the pipeline's 1736 m (+8.1%). The
capture is committed at `captures/2026-08-23_1610m.ndjson` and is the first
oracle in this project that nobody invented.

**Android's fused provider does not deliver one stream.** Splitting the 1205
delivered fixes on whether the timestamp lands on a whole second:

| | n | cadence | acc median | acc range | quantised to 0.1 m |
|---|---|---|---|---|---|
| GPS, `.000` timestamps | 1051 | 1.000 s | 2.50 m | 2.0 – **8.10** | 98% |
| network, fractional | 154 | 6.82 s | 26.82 m | **9.60** – 200.00 | 9% |

The second stream is wifi/cell trilateration. Its 154 fixes trace 6171 m across
a 1610 m walk — 3.8x the whole route — because each lands tens of metres off
the GPS position and the track jumps out and back. The pipeline was accepting
88 of them at `maxAccuracyM: 50`.

The two do not overlap in reported accuracy on this capture, so a threshold of
9 separates them exactly: 1051 GPS kept, 0 network, no GPS fix lost. That is
what `maxAccuracyM` now means. It is not a quality band.

Everything the earlier rounds were chasing dissolves into this:

- **The sub-second delivery intervals are not a fast receiver.** The p10
  delivered interval of 0.14 s is a network fix landing milliseconds after a
  GPS tick. 81 fixes in 21 s of wall clock carried 30% of all raw distance.
- **The positional-duplicate hypothesis is dead.** One exact duplicate in the
  whole file, costing 0.8 m. Of the 40 fixes delivered within 0.5 s of their
  predecessor, *zero* are positionally identical — they are two sensors
  disagreeing, not one sensor repeating.
- **The implied-speed filter was not failing.** It was being handed 25 m of
  slack by a 25 m network accuracy. Rejections fell from 35 to 1 once the
  stream was gone.

Raw accepted distance fell from 4917 m to 1766 m — +205% to +9.7% — before any
smoothing changed at all.

**Dependency to watch: the split rests on the millisecond field.** GPS arrives
on the exact second and network does not. If `tracelet` ever rounds or
normalises timestamps, that discriminator disappears and the accuracy
separation is all that is left — and the accuracy gap is measured on one walk.
A network fix claiming better than 9 m would pass unnoticed today.

### A1c-8 — The error model, measured. Both fixture assumptions were wrong

Estimated by leave-one-out prediction: a quadratic fitted to each fix's
neighbours within ±5 s, excluding the fix itself. Nothing from the pipeline,
the ground truth or the accuracy field enters it.

**Reported accuracy does not discriminate within the GPS stream.** Pearson
r(|residual|, reported accuracy) is +0.818, but that is carried entirely by the
86 network fixes at 10–50 m. Spearman is +0.338. Inside the GPS stream the
field is nearly inert: the 2.0–2.5 m bin has a median residual of 0.93 m and a
p90 of 5.13 m, twice its own claim. As a *stream label* the field is excellent.
As a *per-fix error estimate* it is not usable.

**The error IS time-correlated, and the first answer here was wrong.**

This section originally said the error was white, on two pieces of evidence,
and both were artefacts of how they were measured:

- Residual autocorrelation read −0.040 at 1 s, +0.035 at 5 s, −0.007 at 30 s.
  But the leave-one-out estimator fits a quadratic over ±5 s and subtracts it,
  so it removes slowly-varying error **by construction** and can only ever
  report the high-frequency remainder as white. It cannot answer this question
  and should never have been asked it.
- Decimation appeared to confirm it: raw accepted fell from 4917 m at 0.9 s
  sampling to 1602 m at 18.5 s. But that was run over the *accepted* set, which
  at the time was 88 network fixes, and it was measuring them.

Measured properly, on the GPS stream alone, with a structure function —
`E[|p(t+τ) − p(t)|²] = (v·τ)² + D(τ)` — which needs no ground truth and no
fitted baseline, so neither blind spot applies:

| lag | 1 s | 2 s | 3 s | 5 s | 8 s |
|---|---|---|---|---|---|
| D(τ), m² | 1.18 | 2.96 | 4.96 | 8.69 | 12.27 |

White error is flat at 4σ² from the first lag. D rising from near zero is
exactly what it does not do. σ = 2.5 m with τ₀ ≈ 20 s predicts an rms inter-fix
step of 1.89 m against a measured 1.88 m, and a raw path length of 1766 m
against a measured 1766 m. A white σ = 2.5 model predicts 5491 m — **+241% on a
walk where the GPS stream produced +9.7%.**

So consecutive GPS fixes are correlated at ρ ≈ 0.95, and the +205% raw
over-report that started all of this was the network stream, not the GPS one.
The old 300 s guess was wrong in the same direction but fifteen times too far.

> **The suite was calibrated twice to invented noise models, and the first
> attempt to measure the receiver got the correlation time wrong too — by
> measuring it with an estimator that could not see it. The device delivers
> ~2.5 m per-axis GPS error correlated over ~20 s, at exactly 1.000 s, plus a
> separate ~27 m network stream on fractional timestamps. Reported accuracy
> separates the two streams perfectly and predicts almost nothing within
> either. Measure the receiver before modelling it — and check that the
> instrument can see what you are pointing it at.**

*Limitation:* beyond ~12 s the walk's own loop geometry makes (v·τ)² an
overestimate of real displacement and D goes negative, so only the short lags
are usable. That is enough for path length, which is driven by the 1 s value,
and not enough to say anything about drift over minutes.

**The receiver's speed field is unusable and nothing should be built on it.**
111 fixes report exactly 0.0 m/s, scattered across 110 separate clusters — an
isolated no-Doppler sentinel, never a stop. 63 fixes report over 12 m/s, the
largest 3746 m/s. The stop detector uses displacement over a window and must
keep doing so.

### A1c-9 — Displacement gates: right ruling, wrong reason

The 21 Aug ruling against displacement gates was made on the grounds that they
would under-report genuine slow movement under 15 m correlated noise. **That
reasoning was void** — the noise model it rested on is not what the device
produces — so the ruling was reopened and measured. It stands, on new grounds.

Scored against 1610 m, gating the smoothed track, anchor held when a step is
blocked so slow movement accumulates rather than being discarded:

| gate | distance | vs 1610 | | min dt | distance | vs 1610 |
|---|---|---|---|---|---|---|
| 0.5x accuracy | 1722.1 | +7.0% | | 0.5 s | 1731.2 | +7.5% |
| 1.0x | 1708.2 | +6.1% | | 1.0 s | 1727.5 | +7.3% |
| 2.0x | 1684.4 | +4.6% | | 5.0 s | 1694.2 | +5.2% |
| 3.0x | 1660.2 | +3.1% | | 12.0 s | 1624.0 | +0.9% |

A gate at 3x reported accuracy — 7.8 m, more than four seconds of walking —
buys 4.7 points. The smoother's own constant buys 5.2 for nothing. The gates
are weak because the excess is not concentrated in small steps they could veto;
it is spread evenly across every ordinary 1 Hz step. Scaling by reported
accuracy also buys nothing over a fixed gate, because accuracy barely varies
within the GPS stream (median 2.5, p90 3.4).

**No displacement gate. No minimum-time gate.** Neither ships.

**Still open: the gap to Strava.** The shipped pipeline reads +3.6% on this
walk against Strava's +1.2%. Lowering `accelerationNoiseMps2` to 0.01 closes it
to +1.6% and collapses a hairpin by a quarter, so it is not available as a
constant. Whatever closes the remaining gap is probably adaptive — process
noise that responds to turning — and that is a design, not a retune. Do not
spend it on another sweep of the same knob.

### A1c-11 — The second ground-truth walk, and what two walks show that one cannot

Same 1.61 km loop, same phone, same code, 24 Aug 2026. Committed at
`captures/2026-08-24_1610m.ndjson` with its report and raw track, renamed from
the device's `run_fixes_20260824-152512.*` to match the first capture's naming.
Replayed and pinned in `second_walk_capture_test`.

| | 23 Aug | 24 Aug |
|---|---|---|
| ground truth (Google-Maps-traced) | 1610 m | 1610 m |
| raw, all delivered — arrival order | 14858 m | **7913 m** |
| raw, all delivered — timestamp order | 14996 m | 7994 m |
| raw, GPS stream only | 1766 m (+9.7%) | **1642 m (+2.0%)** |
| raw, network stream only | 6171 m | 4602 m |
| **smoothed, shipped pipeline** | **1668 m (+3.6%)** | **1605 m (−0.3%)** |
| Strava | 1630 m (+1.2%) | 1590 m (−1.2%) |
| delivered / GPS / network | 1205 / 1051 / 154 | 913 / 819 / 94 |
| out-of-order arrivals | 109 | 73 |
| walking speed (smoothed ÷ moving) | 1.59 m/s | 1.97 m/s |
| accepted accuracy p90 / max | 3.40 / 8.10 m | 3.00 / 4.90 m |

Raw totals are given in both orders because they differ by the out-of-order
arrivals and the diagnostics report accumulates in arrival order — that is what
the pipeline actually saw. 7913 and 7994 are the same walk, not a discrepancy.

**The result, stated honestly.** −0.3% against a ground truth that is itself
±1–2%, next to Strava's −1.2%. Those two numbers are not distinguishable by
this instrument. The claim is parity, not victory, and nothing in the pipeline
should be tuned on the difference between them.

> **LESSON. The governing quantity is measurement error relative to per-fix
> displacement, not speed or accuracy alone. A 29% faster walk with cleaner GPS
> moved the same route from a predicted +3.6% to a measured −0.3% with no code
> change. Condition variance exceeds the difference between this pipeline and
> Strava, so a single walk cannot demonstrate accuracy.**

#### The stream split failed on this walk, and nothing caught it but luck

`device_capture_test` was written with this exact sentence in it: *"if a second
capture is ever added and the two streams overlap in reported accuracy, this
fails loudly rather than the threshold quietly starting to admit wifi fixes
again."* It has happened.

| | worst GPS accuracy | best network accuracy | gap |
|---|---|---|---|
| 23 Aug | 8.10 m | 9.60 m | clean, 1.50 m |
| 24 Aug | 5.00 m | **4.20 m** | **crossed** |

One network fix on 24 Aug reported 4.20 m and passed `maxAccuracyM: 9`. It was
discarded — by the **cold-start filter**, because it arrived at seq 1 and the
first three fixes go regardless of quality. Arriving at seq 400 it would have
been accepted, and a 4.2 m-accuracy network fix sits tens of metres off the GPS
position, which is what the other 93 do. **That is a spur that did not happen,
not a spur the pipeline prevented.**

So A1c-A's basis — "the two do not overlap in reported accuracy on this
capture" — was a property of one capture and is now falsified by the second.
The accuracy threshold is still doing almost all the work (91 of 94 network
fixes rejected on it), but it is no longer sufficient on its own, and the
timestamp-granularity discriminator PROGRESS.md flagged as a dependency to
watch is now the only one that separated the streams cleanly on both walks.
This is measured support for making it primary, which was previously a
hypothetical.

Not acted on here. Recorded, asserted in `second_walk_capture_test` so it
cannot quietly regress further, and left for the calibration work.

### A1c-10 — The fixtures, rebuilt from the measurement

The suite is green: 260 passed, 0 failed. It had ten deliberately-red budgets
before this milestone and twenty-nine after the pipeline changed.

**Retired.** Every 15 m correlated fixture and every "realistic" 2.5 m
uncorrelated one. `noisyKm`, `briskWalkingKm` and the 15 m defaults of
`walkingKm` / `variableCadenceWalk` are gone; `realisticWalkingKm` and
`realisticVariableCadenceWalk` are now `measuredWalkKm` and
`measuredVariableCadenceWalk`, rebuilt on the structure function above. The old
"at 1.6 m/s" group in `walking_fixtures_test.dart` went with them — after the
rebuild it ran the primary fixture under a second name and asserted the same
numbers twice.

**Kept, and why.** Two stress fixtures, testing different mechanisms rather
than different numbers:

- `urbanCanyonKm` — 15 m of correlated multipath **reported as 2.5 m**. The
  only fixture that tests a receiver whose accuracy field lies, which the
  measurement identified as possible and could not rule out. Every filter that
  reads `accuracyM` is deceived here. Not used for any budget: there is no
  ground truth from a real canyon and inventing one is the mistake this whole
  section exists to stop repeating.
- `severeWhiteNoiseKm` — the measured process at six times the magnitude,
  reported as 8 m so the accuracy filter does not simply reject it and leave
  the fixture testing nothing while still passing. Robustness only.

**New.** `walkWithNetworkStream`: the measured walk with 74 network fixes
interleaved on fractional timestamps at 27 m. The mechanism that put +8.1% on
the first ground-truth walk, which no fixture modelled. Its GPS fixes are
byte-identical to `measuredWalkKm`'s, so the two totals landing within 0.1 m of
each other is the claim that the threshold keeps the second stream out.

**Re-derived budgets, with the measured values:**

| fixture | measured | budget |
|---|---|---|
| `measuredWalkKm` | +1.14% (+0.50 to +1.79 over 7 seeds) | 2.5% |
| `measuredVariableCadenceWalk` | +1.25% | 2.5% |
| `walkWithNetworkStream` | +1.15% | 2.5%, and within 5 m of GPS-only |
| `walkingKm` (1.0 m/s) | +3.43% | 5% |
| `burstCadenceWalk` | +3.02% | 3.5% |
| `walkWithStop` (1.0 m/s) | +7.90% | 10% |

Three findings fell out of the rebuild and are worth keeping in view:

1. **The lean is long on every draw now.** At the old uncorrelated model the
   sign varied across seeds and that was recorded as evidence of an unbiased
   estimator. Correlated error bends a track outward and a smoother cannot tell
   the bend from the route, so every draw runs ~1.25% long. That is also why
   the real walk reads +3.6% rather than 0%.
2. **A stationary receiver is no longer nearly still.** The stop fixtures
   carried 1.5 m correlated over 300 s, which barely moves inside a
   four-minute stand. The measured 2.5 m over 20 s genuinely wanders: moving
   time on `standingStill` went from 606 s to 627 s against a true 600, and the
   four-minute stand now splits into two stop segments. The arithmetic agrees —
   a still phone covers ~3.5 m in 10 s, or 0.35 m/s against a 0.5 m/s
   threshold. **The stop detector has under 0.15 m/s of headroom.**
3. **Sub-second bursts are not free after all.** `sub_second_steps_test` used
   to find them nearly costless, on the correct reasoning that correlated error
   cancels between fixes 40 ms apart — but at the guessed 300 s it cancelled
   completely, and at the measured 20 s it does not. A burst costs ~0.15 m per
   extra fix. This matters less than it sounds: the GPS stream arrives at
   exactly 1.000 s and has no bursts. The sub-second intervals in the original
   diagnostics were the network stream interleaving, so that fixture now models
   a hypothesis rather than an observation.

`track_diagnostics_test`'s pipeline-change detector was re-baselined wholesale.
Every number in it described a pipeline with `maxAccuracyM` 50 and
`accelerationNoiseMps2` 0.2 measuring fixtures built on a falsified noise model.
Re-baseline it only alongside a deliberate pipeline change, never to make it
pass.

### A1c-12 — Hunt latent order-dependent bugs BEFORE the change that reorders inputs

**A change that alters WHICH inputs a system accepts first will surface latent
input-order defects as if it caused them.** A latent defect in the smoother's
opening pair was shipped code that had never fired; the stream detector would
have been the first thing to change the opening sequence, and the defect would
have been attributed to it. When a change reorders inputs, hunt for latent
order-dependent bugs BEFORE wiring, not after.

The lesson stands. **The example it was originally hung on does not, and the
attribution is amended here rather than quietly dropped.**

The defect is real and the fix in fa9955c is a real fix for it. Reproduced on
shipped code with no detector present: a standing start whose true displacement
is zero reads 1.8 m/s at a 500 ms opening gap, 9.0 at 100 ms, 30.0 at 30 ms.
`smoother_init_test` fails on both of those without the guard.

But it was **not** what made `burstCadenceWalk` fail in the reverted wiring
attempt. That failure was `largestStepM` — 32.1 **metres**, not 32.1 m/s —
read out of the diagnostic as a speed, and the whole velocity-corruption
hypothesis was built on that misread. 32.1 m over 21.1 s is 1.52 m/s, which is
that fixture's own walking pace, and the 21.1 s is the hole the stream
detector's undecided probe opens at the head of a fractional-timestamp
receiver. See A1c-13.

**A unit misread in a diagnostic produced a hypothesis, a hunt, a reverted fix,
and — separately — a constant defended by a measurement that never happened
(A1c-13, the quality ceiling). Check the unit before building on the number.**
Two quantities near 32 in the same test are one transcription away from a wrong
root cause, and the cost of that transcription was most of two rounds.

**The first diagnosis was wrong, and the fix written for it was reverted rather
than kept.** The mechanism was read as velocity-state corruption through
`_Axis.fromPair`, whose opening speed is displacement/dt and equally unbounded.
A fallback for it was written, and it changed nothing measurable across all 328
tests. It was a guess that happened to describe a real property of the code, not
the property producing the number — which is simply that at initialisation the
position estimate *is* the raw measurement, so the track's first step is raw
noise divided by a sub-second interval.

**A plausible fix that demonstrably does nothing is worse than no fix — it looks
load-bearing to the next reader.** A no-op guard sitting in the smoother's
opening path would have been read as the thing keeping opening speeds sane, and
the actual defect would have been hunted somewhere else. Delete a fix that
cannot be shown failing without it. Mutation is the test: disable the guard and
watch something go red, or the guard is decoration.

### A1c-13 — The stream detector, wired in

`StreamDetector` is now inside `TrackProcessor`. The chain is

    buffer → accuracy → stream → cold start → implied speed → smooth → sum

and the two moves are that stream detection exists at all, and that **cold
start runs behind both gates**. Cold start exists to discard a settling
receiver, so its three-fix budget has to be spent on fixes from the stream
being kept. Both walks open with network fixes — the first five delivered on
23 Aug are all network — so with cold start first the budget went on fixes
that were never the receiver settling, and the settling fixes were then
accepted.

`maxAccuracyM` and the detector's `ceilingM` are the same field now: the
processor constructs the detector with its own threshold rather than letting
two copies of 9 drift apart.

**Measured, both captures, `stream_wiring_test`:**

| | 23 Aug | 24 Aug |
|---|---|---|
| discriminator | granularity | granularity |
| split, primary / other | 1051 / 154 | 819 / 93 |
| accuracy cut used | none | none |
| distance, before | 1666.97 m | 1605.2 m |
| distance, detector off | 1666.97 m | 1606.23 m |
| distance, shipped | **1666.97 m** | **1608.51 m** |
| rejected `otherStream` | 0 | 1 |
| accepted accuracy max | 6.50 m | 4.80 m (was 4.90) |

The 24 Aug split reads 819 / 93 against the capture's 819 / 94, and the
missing fix is the one the reorder buffer refused as `arrivedTooLate` before
any filter ran. The detector sits behind the buffer, so 912 of 913 is the
correct count and a reading of 94 here would mean it had been moved in front.

**23 Aug did not move at all, and that is the useful half.** Its network fixes
are all worse than 9 m, so the quality gate already took them and cold start
already landed on GPS. The change reaching nothing on one of the two captures
is a measurement, not an absence of one.

**24 Aug decomposes.** 1605.2 → 1606.23 is cold start moving behind the
quality gate; 1606.23 → 1608.51 is the 4.20 m network fix no longer reaching
the track. −0.30% becomes −0.09% against 1610 m. Both arms are asserted, so
neither can be claimed by the other.

**The mutation, and it needed a mid-track case.** With the detector off the
4.20 m fix is *still* stopped on 24 Aug — by cold start, at seq 1, exactly the
luck the original test called out. That capture therefore cannot prove the
detector does anything positional. `walkWithNetworkStream` can: its second
stream is interleaved throughout, 8 of its fixes claim better than 9 m, and
with the detector off 3 of them land on the track in the middle of the walk.
With it on, none do.

**Sixteen of twenty fixtures are byte-identical.** The four that moved are the
three with fractional timestamps plus `walkWithNetworkStream`:

| fixture | distance | moving |
|---|---|---|
| irregular cadence, 1.0 m/s | 1037.76 → 1037.35 | 997 → 976 s |
| irregular cadence, 1.6 m/s | 1012.54 → 1011.41 | 625 → 603 s |
| `burstCadenceWalk` | 1030.18 → 1028.85 | 625 → 603 s |
| `walkWithNetworkStream` | 1011.50 → 1011.40 | 625 s |

`walkWithNetworkStream` now lands on `measuredWalkKm`'s total to the
centimetre rather than within 0.1 m — the accuracy threshold had kept 66 of
its 74 network fixes out and the granularity rule takes the other 8. No
walking budget failed; every one of these is inside the budget it already had.

**The other three pay for strict-undecided, and the price is a hole at the
head.** Their fixes almost never land on a whole second, so granularity never
resolves and the detector refuses fractional fixes through its 20-fix probe.
On `burstCadenceWalk` that is 15 fixes and 21.1 s: the second accepted point
sits 32.1 m from the first, which is real travel at the fixture's own 1.52 m/s
and not an artefact. Distance survives it — the step across the hole still
measures the walk — but **moving time drops 22 s, because a 10 s window cannot
see across a 21 s gap and scores that one step as stopped.**

On the real captures the probe closes on the 8th fix (23 Aug) and the 6th
(24 Aug), refusing 5 and 3 fixes on the way. Every one of those is fractional,
so no GPS fix was ever refused by it.

#### Two decisions taken rather than deferred again

**Quality ceiling: `maxAccuracyM` stays 9, marked PROVISIONAL in the code.**
The decision is unchanged; the evidence for it was falsified on the way and is
worth recording.

The reason on file was that raising it to 50 degrades `burstCadenceWalk`, from
5.78 m/s to 32.1 m/s of max smoothed speed. **It does not reproduce.** Swept
across all twenty fixtures and both captures with the detector wired in, 9
against 50 changes *nothing at all* — same distance everywhere to the
centimetre. `burstCadenceWalk`'s accuracies are all between 1.6 and 4.7 m, so
a ceiling at 9 never touched them and one at 50 cannot either; its max
smoothed speed is 21.89 m/s at both. The granularity rule already rejects
everything the ceiling used to, and the fixes merely change which reason they
are filed under: on 23 Aug, 121 move from `accuracy` to `otherStream`.

The false reason is written down here on purpose. **Nobody should defend this
constant on reasoning that never held**, and a justification that is silently
replaced leaves the old one alive in whoever read it first. It came from the
same unit misread as A1c-12: 32.1 was `largestStepM` in metres, and "50
degrades `burstCadenceWalk`" was inferred from it.

So there is no measured cost to 50 and no measured benefit to 9 on any
evidence this project holds. What keeps it at 9 is the case the evidence
cannot see: where granularity is unavailable — a single-stream receiver, or
one whose timestamps do not carry the split — the detector reports
`singleStream` and this threshold is the only filter left between a 27 m fix
and the track. **Defence in depth for the receiver nobody has captured**, and
that is the whole of the justification. Revisit when one is captured; the S26
Ultra may be one.

**Strict undecided: kept.** It costs 3.7% on `shuffledArrivalWalk`, 15 fixes
on `burstCadenceWalk`, and no GPS fix on either real walk, and it prevents the
exact failure being fixed: on 23 Aug the first five delivered fixes are all
network. A pipeline poisonable by its opening fixes is not fixed. Revisit when
the S26's timestamp format is measured.

#### Correction: the 32.1 that blocked the first attempt was never a speed

NOTES.md recorded the unexplained failure as "`burstCadenceWalk`'s max
smoothed speed at 32.1 m/s". It is **32.1 metres**, and it is `largestStepM`,
not `acceptedSpeedMps.max` — the assertion at `sub_second_steps_test:144`
bounds the largest step. 32.1 m over 21.1 s is 1.52 m/s, which is the
fixture's walking pace.

So the thing that stopped the first wiring attempt was the opening hole
described above, fully explained and entirely expected once the strict-
undecided rule is understood. It was **not** the latent smoother-init defect
fixed in fa9955c. That defect was real, was demonstrated on its own terms, and
is verified by mutation — but it does not fire on this fixture, and attributing
this failure to it would have been a second wrong diagnosis of the same
number. The lesson in A1c-12 stands unchanged; the specific claim that the
32 m/s *was* that defect does not, and A1c-12 now carries the amendment.

Both errors in this milestone trace to the same line of output read with the
wrong unit. **Check the unit before building on the number.**

Check the units before adopting a number from a failure message. Two
quantities near 32 in the same test are one transcription away from a wrong
root cause.

### A1c-14 — The RTS backward pass: a MEASURED NEGATIVE RESULT

**This is not dead code and must not be deleted as such.** The code and its
tests are kept because they are the evidence for a closed question. Decided
26 Aug 2026:

> An RTS backward pass was implemented on the hypothesis that corner-cutting
> came from the filter being causal. It does not. Across both captures and both
> geometry fixtures the smoother is worse at every value of `an`, and the fork
> inverts rather than dissolving: with the filter there is a crossing point at
> 0.035; with the smoother, lower is monotonically worse. 24 Aug goes from
> 1.5 m of error to 114 m. Coastline decimation shows the smoother does remove
> real jitter (1.77%/1.00% vs the filter's 4.12%/3.93%) — it deletes corners at
> the same time, and on real loops the corner loss dominates.
>
> The corner problem is therefore in the MOTION MODEL, not the direction of the
> pass. A constant-velocity model has no representation of turning, so seeing
> the future does not help; it smooths through the turn rather than
> anticipating it. **Do not re-attempt a backward pass over a CV model.**

A coordinated-turn or IMM model is the agreed next candidate and is **not
started**: it is not worth beginning on this evidence alone.

**Seen, 7 Sep 2026.** Everything above was inferred from numbers — distance
residuals against two ground-truth walks and a coastline-decimation ratio. On
the device, at the recoloured raw-fix overlay, the artefact is now directly
visible: the raw accepted fixes cut the inside of a bend while the smoothed
line stays wide of it. That is the corner-cutting mechanism itself, on screen,
at one corner. It changes no measurement and reverses no conclusion — the
motion model is still the cause and a backward pass over a CV model is still
ruled out — but the effect is no longer something only a spreadsheet has seen,
which is what A2-3 bought the overlay for in the first place.

Built as specified: the forward causal Kalman filter is untouched and still
feeds the live map and the live numbers; a Rauch-Tung-Striebel backward pass
runs once over the stored state and covariance and produces a second reading
of the same run. `TrackProcessor.smoothedTrack()`.

**It is NOT wired to the saved track.** On both ground-truth walks the smoothed
distance is further from the truth than the filtered one, so wiring it in would
have shipped a −7% change to what gets stored.

**Memory.** One record per accepted fix — both axes' position, speed and 2×2
covariance, plus the interval — thirteen doubles, about 128 bytes on the heap.
A two-hour run at 1 Hz is 7200 fixes, or roughly 0.9 MB held for the length of
the recording and released with the processor. A Kalman filter's business is
forgetting, so the covariance cannot be reconstructed after the fact: the tape
is written while the run happens or the backward pass is impossible.

**Amended 19 Sep 2026 — that price is no longer paid by the phone.** This
paragraph used to call it "the unavoidable price", and the unavoidable part is
only the *timing*, not the *always*. `TrackProcessor.recordFilterStates`
defaults to **false**; `replay()` in the test harness and the replay paths in
`rts_smoother_test` turn it on, and the live recorder does not. So every real
recording had been carrying 0.9 MB for an analysis that only ever runs on a
laptop, against a method A1c-14 explicitly declined to wire in.

Opt-in rather than opt-out, so a future production call site has to ask for
the cost instead of inheriting it, and `smoothedTrack()` **throws** without the
tape rather than running the backward pass over an empty one — which would
sail through and return a plausible-looking wrong distance, the failure shape
A1c-17 generalised into a rule. Pinned by three tests in `rts_smoother_test`
and verified by mutation: flipping the default to true reddens two of them.
The forward pass is asserted identical with the tape on and off, so this is an
observer and not a second pipeline.

#### The sweep, all four datasets, filter against smoother

| | | 0.2 | 0.1 | 0.05 | **0.035** | 0.02 | 0.01 |
|---|---|---|---|---|---|---|---|
| 23 Aug, 1610 m | filter | +6.70% | +5.74% | +4.36% | **+3.54%** | +2.36% | +1.58% |
| | smoother | −0.57% | −2.28% | −3.67% | **−4.21%** | −5.10% | −6.30% |
| 24 Aug, 1610 m | filter | +0.03% | −0.26% | −0.23% | **−0.09%** | +0.26% | +0.79% |
| | smoother | −4.71% | −5.85% | −6.71% | **−7.09%** | −7.71% | −8.09% |
| switchback, 272 m | filter | +5.08% | +7.33% | +5.00% | **−0.16%** | −12.38% | −26.55% |
| | smoother | −13.76% | −21.46% | −37.00% | **−48.48%** | −65.11% | −74.20% |
| rectangle, 728 m | filter | +0.99% | +1.22% | +1.59% | **+1.92%** | +2.79% | +4.35% |
| | smoother | −3.10% | −4.57% | −6.18% | **−6.95%** | −8.16% | −10.62% |

**The headline question is answered, and the answer is no.** The hypothesis
was that the backward pass removes the corner penalty, so the fork that pinned
`accelerationNoiseMps2` at 0.035 dissolves and a lower value becomes safe on
every geometry. Under the smoother every dataset gets monotonically *shorter*
as the tuning drops. The fork does not dissolve — **it inverts.** With the
filter, lowering the knob improves the straight walk and destroys the hairpin,
so there is a crossing point and 0.035 is it. With the smoother there is no
crossing point: lower is worse everywhere.

**Two captures, and here they agree.** Both lose about seven percentage
points. 23 Aug goes from +3.54% to −4.21%, which crosses the truth and lands
*further out on the other side* — 57 m of error becomes 68 m, so the
near-symmetry of the percentages is misleading. 24 Aug goes from −0.09% to
−7.09%: 1.5 m of error becomes 114 m. Nothing is averaged; they point the same
way and the shipped value is worse under the smoother on both.

#### Why, and it is not a bug

The implementation is checked four ways, all in `rts_smoother_test`: a
noise-free track is exact at every tuning; the final smoothed point equals the
final filtered point to the bit, which is the recursion's boundary condition;
at `accelerationNoiseMps2: 100` the gain goes to zero and the smoother
converges on the filter, which a transposed or mis-signed gain does not do;
and the forward pass is provably undisturbed.

The mechanism is that **the backward pass applies the motion model harder, in
both time directions.** Where the model is right, that is a large win — the
straight measured walk goes from +1.14% to **+0.004%**, essentially exact.
Where the model is wrong it is a large loss, and a 90° corner is exactly where
it is wrong: the constant-velocity model says that acceleration does not
happen, and the smoother now has the whole future as evidence for insisting on
it. The noise-free rectangle is the clean attribution — no measurement error
exists in that fixture, so its −6.95% is entirely the smoother deleting four
corners that genuinely happened.

That is also why `measuredWalkKm`'s near-perfect result does not transfer to
the captures. **That fixture is a straight line.** Both real walks are loops.

**The coastline check says the length it removes is genuinely noise.** Keeping
every 20th point and re-measuring:

| | filtered | smoothed |
|---|---|---|
| 23 Aug | 4.12% lost | 1.77% lost |
| 24 Aug | 3.93% lost | 1.00% lost |

The filtered track is four times as dependent on its own sub-20-fix wiggle.
So the backward pass is doing what a smoother should — removing jitter —
and the reason the total still gets worse is that it removes real corners at
the same time. Those are two effects, not one, and only the second is a defect.

#### What this leaves

The corner problem is now located precisely: it is the **motion model**, not
the direction of the pass. A constant-velocity model cannot represent a turn,
and neither running it forwards nor running it backwards changes that.

`accelerationNoiseMps2` is unchanged at 0.035.

**And with that the activity accuracy work is closed.** The shipped pipeline
reads −0.09% on 24 Aug and +3.54% on 23 Aug against a ground truth that is a
Google Maps trace carrying ±1–2% itself. That is parity with Strava and below
what this instrument can measure. Further tuning against these two walks is
tuning against the noise in the ruler; the next real move is a new
measurement, not a new estimator.

**Reopened 1 Sep 2026 by that new measurement.** The prediction held — a new
walk on new hardware, not a new estimator, is what moved this. See A1c-15.

---

### A1c-15 — The filter's benefit is DEVICE-DEPENDENT IN SIGN

First S26 Ultra capture, 1 Sep 2026, 1930 m ground truth, committed at
`captures/2026-09-01_1930m.ndjson`. Strava read 1930 m on the same walk.
`accelerationNoiseMps2` is **unchanged at 0.035** and nothing below is acted
on: two more walks are being recorded, and what they settle is the SHAPE of
the change, not whether to make one.

#### The sweep, all five datasets, error against ground truth

| an | S26 1930 m | A32 23 Aug 1610 m | A32 24 Aug 1610 m | switchback 272 m | rectangle 728 m |
|---|---|---|---|---|---|
| **raw accepted** | **+0.35%** | **+9.69%** | **+1.98%** | — | — |
| 0.2 | +0.84% | +6.70% | +0.03% | +5.08% | +0.99% |
| 0.1 | +0.99% | +5.74% | −0.26% | +7.33% | +1.22% |
| 0.05 | +1.12% | +4.36% | −0.23% | +5.00% | +1.59% |
| **0.035** | **+1.01%** | **+3.54%** | **−0.09%** | **−0.16%** | **+1.92%** |
| 0.02 | +0.44% | +2.36% | +0.26% | −12.38% | +2.79% |
| 0.01 | −0.68% | +1.58% | +0.79% | −26.55% | +4.35% |
| 0.005 | −1.81% | +1.68% | +1.49% | −34.56% | +5.85% |
| 0 | −25.74% | −21.14% | −18.09% | −39.01% | −15.88% |

Smoothed-track coastline, k=20, percentage of length lost to decimation:

| an | S26 | A32 23 Aug | A32 24 Aug |
|---|---|---|---|
| raw accepted | 5.35% | 11.05% | 7.90% |
| 0.2 | 5.06% | 7.63% | 5.87% |
| 0.05 | 3.88% | 4.69% | 4.19% |
| **0.035** | **3.64%** | **4.12%** | **3.93%** |
| 0.02 | 3.11% | 3.39% | 3.49% |
| 0.01 | 2.39% | 2.63% | 2.83% |
| 0.005 | 1.83% | 2.09% | 2.35% |

The 0.035 column reproduces A1c-14 exactly, including its 4.12% / 3.93%
coastline, so this is the same instrument that produced the committed record.

#### The finding

**The Kalman filter's benefit is DEVICE-DEPENDENT IN SIGN, not degree.** A32
23 Aug: raw +9.69% → smoothed +3.54%, load-bearing. S26: raw +0.35%, and no
value of `an` beats it — best is 0.02 at +0.44%. The filtered coastline loses
LESS than raw at every value, so the filter removes wiggle as designed and the
track is still 13 m longer; what remains is the positive-signed corner artifact
the noise-free rectangle isolates at +1.92%. On a receiver quiet enough that
there is no noise left to remove, the artifact is all that is left.

`an` = 0 is MAXIMUM smoothing, not none: zero process noise asserts
acceleration cannot happen, fitting a straight line (−25.7% S26, −15.9% on the
noise-free rectangle). Raw-accepted is the baseline. Drop `an` = 0 from sweeps.

The noise-scaling relation under-predicts by ~2x: S26 sigma_step 0.146–0.179 m
against the A32's 0.405 m scales `an` to 0.0126–0.0155, while the sweep optimum
is 0.02 and raw beats both. The sweep is the stronger instrument.

#### Three claims this capture killed

Recorded because each was stated confidently before the measurement and each
was wrong in a way the measurement made obvious.

- **"`an` = 0 is the no-smoothing baseline."** It is the opposite: maximum
  smoothing. It reads −15.9% on a noise-free fixture, which is the tell — a
  track with no noise in it cannot lose 16% of its length to noise removal.
- **"Near-zero smoothing wins on the S26."** Inferred from two endpoints of a
  curve that is not monotone. The S26 sweep rises to +1.12% at 0.05, turns, and
  crosses zero between 0.02 and 0.01; 0.005 is worse than the shipped value.
  Ranked by |error| the order is 0.02, 0.01, 0.2, 0.1, 0.035, 0.05, 0.005.
- **"Reported accuracy is two sentinels, 3.79 and 9.94, so the stream
  detector's bimodality fallback would find a false gap between them."** The
  two modes are real — 1187 and 48 of 1327 whole-second fixes — but they are
  not the whole distribution: 91 fixes span 3.792 to 7.812 m and one sits above
  9.935. `findAccuracyGap` returns **null** on this capture, on the delivered
  set and on the whole-second set alike; the largest log-space gap is
  5.129 → 5.509 m, 0.38 m wide, and the existing 1 m floor refuses it. The
  fallback is never reached anyway — granularity fires on a median of 3.79 m
  against 100.0 m. **No guard was added.** Machinery against a failure no
  capture produces is the thing this file exists to stop.

What survives of that third claim, and is a real criticism: 93% of accepted
fixes report one accuracy value, so the accuracy-weighted measurement noise is
a fixed gain, and `maxAccuracyM` 9 sits between the two modes by luck rather
than by measurement.

#### What is open

`accelerationNoiseMps2` stays 0.035. Two more walks are being recorded. The
question they settle is the shape of the change — retune to 0.02, or bypass the
filter entirely when the measured noise is below a threshold — not whether to
make it. A per-device constant is no longer avoidable on this evidence; what is
not yet known is whether the switch should be on the device or on the
measurement.

---

### A1c-16 — The sixth capture is indoors, and it reopened two rulings

9 Sep 2026. `captures/run_fixes_20260908-162309.ndjson`, 100:44 elapsed,
2416 m smoothed, 3034 of 4428 fixes accepted. Walked partly inside a shop,
which is the first environment in the set where the receiver loses lock for
long enough to matter. **No constant moved on it.** Both investigations are
report-only and both conclusions are in NOTES.md; what follows is the summary
and the two things worth carrying forward.

**Acceptance 68.5%, the lowest recorded, with an accepted median of 3.79 m.**
Those two numbers together are what an environment looks like rather than what
a broken filter looks like, and the report now says so in place (A1c-K).

**The network stream inverts indoors.** Its median is 17.49 m here against
200 m in the forest and 500 m outdoors in Zurich — the stream the pipeline
exists to reject is, indoors, an order of magnitude better than the one it
accepts elsewhere. An accuracy ceiling alone cannot separate the cases: at
20 m the shop admits 64% of its network stream and the two ground-truth A32
walks admit 17–21% of theirs. A **gap gate** does separate them cleanly on
this evidence — no outdoor capture has a single two-minute gap in the accepted
stream. **INVESTIGATED AND REJECTED, 9 Sep 2026, not left open**; the numbers
and the one piece of evidence that would reopen it are under A1c-M below.

#### A1c-L — pace-relative stop detection: proposed, then falsified

**A hypothesis of mine, killed by the measurement it asked for, and recorded
here because the shape of the error is more useful than the answer.**

The proposal was that Strava scales stop detection to the activity's own pace,
and it came off a real trend across the three Strava-anchored captures: fast
we are stricter, slow we are looser. Zurich at 1.37 m/s median reads 1:36
stricter than Strava; the forest at 0.88 reads 11:45 looser; the shop at 0.79
reads 5:45 looser. Two captures disagreeing in opposite directions is noise
and three is a trend, so the earlier "leave it at 0.5, the evidence is
decisive" ruling was explicitly disregarded and the question reopened.

**It fails by SIGN, which is what makes the falsification decisive rather than
inconclusive.** The two slow walks already count too much as moving, so
correcting them needs a HIGHER threshold. Scaling to pace gives a slow walk a
LOWER one — 0.88 x 0.30 = 0.27 against the shipped 0.5 — so the rule moves the
two captures the trend was drawn from further from Strava, not closer:

| capture | 0.25x | 0.35x | fixed 0.5 |
|---|---|---|---|
| Zurich | +1:55 | −1:18 | −1:36 |
| forest | +20:03 | +16:35 | **+11:45** |
| shop | +7:24 | +7:07 | **+5:45** |

And the threshold that actually matches Strava, found by bisection, is **0.31x
of Zurich's median, 1.02x of the forest's and 0.98x of the shop's**. If a
scaling law were there that column would be a constant. The two values that
agree, agree at ~1.00x — setting a threshold to a walk's own median calls
about half of it stopped by construction, which is a coincidence of the median
rather than a rule. No fixed value fits all three either: the forest wants
~0.90, the shop ~0.77, Zurich ~0.42.

**`minMovingSpeedMps` stays 0.5, and the reason has changed.** It was held
before on an absence of evidence — two captures pointing opposite ways. It is
held now on a measurement: the pace-relative family was tested across five
multipliers and four floors against every anchor available, and every member
of it is worse than the fixed value on at least two of the three. The trend is
real and the explanation for it was wrong; what the three anchors actually
show is that Strava is not applying a plain speed threshold at all.

The general lesson, which is the part worth keeping: **a trend across three
points constrains the sign of a correction before it constrains its size, and
the sign is the cheaper thing to check.** Reading the direction off the
existing sweep would have killed this before the harness was written.

#### A1c-M — the network-stream fallback: investigated and REJECTED

Not an open idea, not deferred, not "worth trying if there is time". Measured
and turned down, with the numbers, so that the next reader meeting the same
inversion does not rediscover it as a fresh possibility.

**What it would have been.** When GPS has been absent from the accepted stream
for over two minutes, admit network fixes under an accuracy ceiling and
reconstruct the gap from them instead of drawing a chord.

**Two independent reasons, either sufficient.**

**One — the false positive has never been walked.** The gate separates
perfectly on the six captures in hand, and that separation is carried entirely
by the gap: no outdoor capture has a single two-minute gap in the accepted
stream, so the rule cannot fire outdoors and the fiction it admits there is
exactly zero, ground-truth error unchanged at every ceiling (+3.5%, −0.1%,
+0.8% from 9 m to 50 m). But that is a property of four routes, not of outdoor
routes. Zurich's network median is **500 m** and **4.4% of its network stream
is already under 20 m**, so a canopy, tunnel or underpass that killed GPS for
two minutes would fire the same gate on that input and the ceiling would not
stop it. **Unfalsified is not safe**, and this is the failure mode this
project has never caught cheaply: like map matching, it fabricates in a way
that makes the track look *more* plausible, not less.

**Two — the reconstruction is poor even where it is supposed to work.** The
three indoor gaps chain **1402 m at a 20 m ceiling where 500–750 m was
walked**, roughly double, taking the run from 2416 m to 3749 m. At 16 m they
chain 840 m, the top of the estimate, and Strava on the same walk read 2.92 km
against our 2.42 km — a ~500 m addition, more conservative than either. So the
best case is a ceiling picked to land on an estimate, tuned against a number
recalled from memory. That is the instrument problem A-map-match was turned
down for, in a smaller frame.

**What would reopen it: a capture containing a long outdoor GPS outage** — a
tunnel, an underpass, a station, a genuine street canyon — with the receiver
gone from the accepted stream for over two minutes and network fixes delivered
throughout. That capture is the falsification test the rule has never faced,
and it is cheap to record deliberately. Nothing short of it changes this
ruling; another indoor walk only re-confirms the half that already passes.

**`accelerationNoiseMps2` is still 0.035 and this capture does not bear on
it.** A32-vs-S26 sweep evidence is unchanged; nothing here was measured
against ground truth, because there is none for this route.

---

### A1c-17 — Four defects the sixth capture's own report was carrying

9 Sep 2026. Found by reading the shop capture's diagnostics against the raw
NDJSON rather than trusting the summary. **All four are report or plumbing
defects. No distance, pace or moving time moves, and nothing recorded under
A1c-15 or A1c-16 changes** — every published stopped-time figure was already
`elapsed - movingTime`.

#### One — `run_points.speedMps` held impossible values, and they were stored

`RawFix.speedMps` is the receiver's Doppler estimate. The recorder refuses the
plugin's negative "not available" sentinel and passes everything else through;
`run_dao.dart:59` writes it into `run_points`. Nothing bounded it, because the
implied-speed filter bounds a pair of POSITIONS and had never looked at this
field. Measured across the six captures, on fixes whose positions are fine:

| capture | delivered | dropped | rows that WERE stored bad | max kept |
|---|---|---|---|---|
| 23 Aug A32 | 1205 | 63 | 23 | 11.61 |
| 24 Aug A32 | 913 | 18 | 2 | 3.11 |
| 01 Sep S26 | 1395 | 7 | 3 | 1.97 |
| 07 Sep Zurich | 3423 | 198 | **158** | 4.34 |
| 08 Sep forest | 7974 | 460 | **340** | 4.02 |
| 08 Sep shop | 4428 | 46 | 11 | 11.77 |

**537 rows across six walks**, with maxima of 39708 m/s on Zurich and
18013 m/s on the forest walk — 143,000 km/h. Harmless to every number the
pipeline computes and not harmless at all to A7, a pace chart or an export,
none of which can tell a stored 39708 from a measured 3.

Bounded now at `TrackProcessor.add`, the pipeline's own boundary, against
`maxSpeedMps` — the constant the kinematic filter already uses, because one
physical claim gets one number. **Nulled, not clamped**: a clamp writes a
wrong value in the shape of a right one, and the precedent is
`SetLogs.weightKg`. **The fix is kept**; only the annotation is dropped, since
losing a good position to a bad speed would be the more expensive error. The
count prints in the report, because silently nulling bad values makes a
contaminated receiver look healthy.

**Existing stored runs are NOT rewritten.** Recorded data is evidence. Runs
saved before this commit carry unbounded speeds and no consumer may trust that
column for them; NOTES.md carries the same warning and so does the report.

##### The shape of this one generalises, so it is written as a rule

**A persisted column can be wholly corrupt while every check that matters
stays green.** 537 stored fixes across all six captures, values up to
39,708 m/s, through six walks and every budget, fixture and ground-truth
comparison in this repo — and nothing caught it. Not because the checks are
weak, but because they were checking something else: the implied-speed bound
works on POSITIONS, the positions were fine, and the track was never affected.
There was no test that could have gone red, because nothing read the column.

It surfaced as an odd max in a report line, which is luck rather than method.

**When a value is stored but not consumed, it has no oracle. Validate it at
the boundary, or accept in writing that it is untested.** The two are the only
honest options; the third — storing it, not reading it, and assuming it is
fine — is what produced this, and it stays invisible for exactly as long as
nobody uses the data. The cost lands on the first consumer, which here would
have been A7 reading heart rate beside a pace column full of impossible
numbers, long after the walks that produced them.

Worth pairing with the A1a lesson about fixtures that can actually fail: that
one is about a test too weak to catch a defect, this one about a defect with
no test pointed at it at all. The second is harder to notice, because a
missing check leaves nothing behind — no red, no warning, no artefact. The
only signal a column like this can produce is a number that looks wrong to
someone reading a report, and that is not a mechanism.

#### Two — stopped time had two definitions that differed by 31:40

The shop report printed `elapsed 100:44  moving 32:01` and, further down,
`18 segment(s), 37:03 stopped in total`. 100:44 - 32:01 is **68:43**. Both
numbers were in the same report and neither was labelled as a different
quantity.

`movingTime` sums each accepted fix's `dt` when it is moving, so stopped time
includes the interval *before* each stopped fix. `stopSegments()` ran from the
first stopped fix to the next moving one — excluding that interval, including
the one after. At 1 Hz they agree within a second. Across the 1298 s hole in
that walk's accepted stream they did not: the fix closing the hole is
classified stopped and contributed **21:38** to the header, while its own
segment printed as **`0:01`**. So the run's largest stop was invisible in the
list of stops.

The divergence is exactly the captures with outages: shop 1900 s, forest 34 s,
01 Sep 42 s, Zurich 1 s, the A32 pair 0.

One rule now, and it is the `dt` rule, because that is the one `movingTime`
already used and pace divides by moving time. A stopped fix owns
`[previous fix, this fix]`; consecutive stopped fixes merge; the segments
partition stopped time exactly. `stopped_time_test` asserts
`totalStopped == elapsed - movingTime` on both fixtures and all six captures,
and pins the shop walk's longest stop above 20 minutes.

The report's hedge — "the 10 s window means each edge is late by up to that
much" — read as covering this and did not. It now says what it covers: the
edges, not the total.

#### Three — the stream detector is inert on five of six captures

Replayed with `detectStreams` on and off, accepted count and distance are
**identical** on 23 Aug, 01 Sep, Zurich, forest and shop. Only 24 Aug differs,
by one fix and 3 m — the 4.20 m network fix A1c-13 was built for. On the shop
capture all 1318 fractional fixes are taken by the accuracy gate first, so
`otherStream` is 0 and the report was printing a whole STREAM DETECTION block
that changed nothing.

Not a defect and not a reason to delete it: `maxAccuracyM` 9 is doing the
separation, and A1c-15 already recorded that 9 "sits between the two modes by
luck rather than by measurement". The risk is that the detector becomes
load-bearing again the moment 9 moves, having been silently redundant for
five captures. So the report now states its effect on the run in hand,
derived from the `otherStream` count — which is exact, because that rejection
fires only on fixes that already passed the accuracy gate.

#### Four — `kept + other` did not reconcile with `reached pipeline`

3037 + 1318 = 4355 against 4428 delivered. The missing 73 are the
`arrivedTooLate` fixes: the detector sits *after* the reorder buffer, so the
claim "the detector sees every delivered fix before the quality gate" was
wrong for exactly the fixes the buffer drops. Corrected to say it sees every
fix that SURVIVES the buffer, and that the shortfall is that count.

#### What this uncovered, and is deliberately left RED

Fixing Two turned two budgets in `walking_fixtures_test` red, and **they stay
red as the oracle for the next piece of work** rather than being retuned —
the A1c precedent, and for the same reason.

| budget | reads | budget | fixture |
|---|---|---|---|
| an irregular cadence does not invent stops either | **23 s** | <20 | `variableCadenceWalk` |
| a brisk walk is never mistaken for standing still | **21 s** | <20 | `measuredVariableCadenceWalk` |
| walking is not mistaken for standing still | 2 s | <20 | `walkingKm`, regular cadence — green |

**These fixtures always produced 23 s and 21 s.** Both budgets read
`report.totalStopped`, which was the segment sum, and `elapsed - movingTime`
read 23 and 21 before this change as well — `movingTime` is untouched, which
the 20-fixture moving-seconds table in `track_diagnostics_test` proves by
staying green. The budgets were passing on the understating number.

So the finding is real and pre-existing: **the moving/stopped decision loses a
1.0–1.6 m/s walker in the noise for about 2% of an irregular-cadence walk, and
only at irregular cadence.** The regular-cadence sibling reads 2 s. That is a
pipeline question, not a report one, and it needs its own measurement against
the captures before any constant moves. **Do not re-baseline these two to make
the suite green.**

---

### A1c-19 — Two measured walks, one phone, two cities

18 Sep 2026, Zurich, 1890 m measured. Committed at
`captures/2026-09-18_zurich_1890m.ndjson` with its report and raw track,
renamed from the device's `run_*_20260918-163156.*`. **Both measured walks
are the S26 Ultra.** This is two references on one receiver, not two
devices; the A32 captures have no measured ground truth.

Both rows replayed on the same code, `3b688d5`, so nothing in this table
mixes versions. That is why Thane reads +0.77% here and +1.01% in A1c-15:
that sweep is 1 Sep code, and the pipeline has changed since. Which change
moved it was not bisected.

| | 01 Sep Thane | 18 Sep Zurich |
|---|---|---|
| device | S26 Ultra | S26 Ultra |
| ground truth (measured) | 1930 m | 1890 m |
| **smoothed, shipped pipeline** | **1945 m (+0.77%)** | **1887 m (−0.16%)** |
| raw accepted, fix to fix | 1935 m (+0.27%) | 1889 m (−0.04%) |
| Strava | 1930 m (0.00%) | 1900 m (+0.53%) |
| moving, ours / Strava | 20:42 / — | 22:00 / 22:45 |
| inter-fix error, high bracket | 0.179 m | 0.151 m |
| code replayed on | `3b688d5` | `3b688d5` |
| **saved after A1c-Q, `c16fdfc`** | **1930 m (−0.01%)** | **1887 m (−0.16%)** |

**What it shows.** On this receiver raw accepted is at or closer to truth
than smoothed on both walks, and the gap is largest where the route turns
most — Thane, +0.77% against +0.27%. Zurich is a steady route with few
corners and the two are two metres apart. That is A1c-15's sign finding
reproduced on a second route, and it is the evidence for the bypass below
rather than a result in itself. One walk beating Strava by 0.4 points is
parity, not a ranking; A1c-11's lesson on condition variance applies.

#### A1c-Q — the hybrid bypass, replayed on all seven captures

Below 0.30 m of inter-fix error (high end of the bracket) the saved distance
and splits come from the raw accepted positions; stops and moving time stay on
the smoothed track. Pinned in `saved_track_test`.

| capture | noise, high | side | smoothed | saved | moving time |
|---|---|---|---|---|---|
| 23 Aug A32 | 0.496 | smooth | 1667 | 1667 | unchanged |
| 24 Aug A32 | 0.582 | smooth | 1609 | 1609 | unchanged |
| 01 Sep Thane S26 | 0.179 | bypass | 1945 (+0.77%) | **1930 (−0.01%)** | unchanged |
| 07 Sep Zurich S26 | 0.225 | bypass | 4121 | 4160 (+39) | unchanged |
| 08 Sep forest S26 | 0.178 | bypass | 4532 | 4586 (+54) | unchanged |
| 08 Sep shop S26 | 0.197 | bypass | 2416 | 2448 (+32) | unchanged |
| 18 Sep Zurich S26 | 0.151 | bypass | 1887 (−0.16%) | 1887 (−0.16%) | unchanged |

It does not fire on the A32, which is the requirement: the pair sits at 0.50
and 0.58 against a 0.30 threshold. On Thane it removes the corner artifact
outright. On today's walk it changes nothing measurable, as expected on a
steady route. The three S26 walks without ground truth move by +0.9% to +1.3%,
and nothing here says whether that is toward the truth.

**Caveat:** it adds 0.9-1.3% to the three S26 walks with no ground truth, and
nothing measured says whether that is toward truth. The bypass is justified by
two measured walks; three others move on faith.

**The plain bypass was
measured and rejected:** deciding stops on raw positions put +311 m and +3:43
of moving time on 7 Sep Zurich, which is A1c-J's phantom distance returning.

---

## Remaining activity block — not started

- [ ] A1c-18 Stop detection at an irregular cadence — OPEN, and its oracle is
      already written and already failing
      Accept: `variableCadenceWalk` and `measuredVariableCadenceWalk` report
      under 20 s of stopped time, without loosening either budget and without
      moving `minMovingSpeedMps`
      Commit: <sha once done>

      **The two red budgets in `walking_fixtures_test` ARE the acceptance
      criterion.** They read 23 s and 21 s against <20; the regular-cadence
      sibling reads 2 s. Nothing in either fixture stands still, so every one
      of those seconds is the 10 s displacement window losing a 1.0–1.6 m/s
      walker in the noise when fixes arrive unevenly. They were green until
      9 Sep 2026 only because they read the segment sum rather than
      `elapsed - movingTime` — see A1c-17.

      **Do not open by retuning the threshold.** The captures say a fixed 0.5
      is right and say so on measurement (A1c-L); the fixtures say the failure
      is cadence-shaped. Those are different claims and the second one is the
      one nothing has looked at.

- [x] A1b Plugin integration
      Accept: the plugin lives behind a repository interface and the A1a
      fixtures still satisfy it; the pipeline consumes the stream unchanged;
      runs are written to the v7 tables
      Pinned `tracelet: 3.2.17` exactly, no caret.
      Commits: 138bbb1 (recorder + DAO), dc8fed3 (controller + screen)

      **Version ceiling, and it is a real one.** 3.8.7 was the intended pin.
      Every tracelet from 3.2.18 onward requires `meta ^1.18.0`, and the
      Flutter SDK here (3.41.7) pins `meta` to 1.17.0 through `flutter_test`,
      so nothing above 3.2.17 resolves at all. Raising it means upgrading the
      Flutter toolchain, which is a decision about the whole app rather than
      about this feature. 3.2.17 has the OEM APIs this milestone needed.

      **The plugin has its own filter chain.** `LocationFilter` ships an
      accuracy threshold (100 m), an implied-speed cap (80 m/s) and a Kalman
      smoother — A1a's filters (b), (c) and (d) — and its `policy` defaults to
      `adjust`, which *smooths rejected locations and records them* rather
      than dropping them. Left alone it would hand the pipeline positions it
      had already moved, presented as measurements. All of it is opened wide
      or switched off in `TraceletRunRecorder._config`. Do not "tidy" that
      config: two filter chains with different constants is two sources of
      truth, and only one of them is under test.

      **Monotonic arrival is NOT guaranteed.** Not documented either way, and
      there is no sorting anywhere in the delivery path — `onLocation` maps
      the native event channel straight through. The package also exposes a
      `timestampDriftMs` field, which is the author acknowledging the problem
      exists. No workaround was written: A1a already rejects any fix that does
      not move the clock forward, which was added as a guard in A1a-3 and is
      the correct handling either way. Device check still outstanding.

- [x] A1b-device Confirm on real hardware — FIRST PASS DONE, 21 Aug 2026
      Accept: a real run on the A32 (Android 13) and on the S26 Ultra
      (Android 15+) produces a track the pipeline accepts, with the
      foreground notification visible and the recording surviving the screen
      going off; report whether any fix arrives out of order

      A 48-minute walk. Recorded 3.46 km / moving 35:41 / elapsed 47:52,
      against Strava's 4.36 km / 45:18 / 49:11 over the same period on the
      same receiver. The recording survived: the elapsed times agree to
      79 seconds, so the foreground service was not killed.

      **Strava is not ground truth here.** Its map shows a long straight
      out-and-back spur that was never walked, which is what one bad fix
      produces, and the length is counted twice. Some fraction of its 4.36 km
      is fiction. Do not tune toward it.

      **The stop detector is probably right.** ~12 minutes of genuine stops,
      confirmed against memory. Strava excluded 3:53 over the same walk. The
      two disagree on threshold, not on principle, and ours matches what
      happened.

      Out-of-order arrivals: NOT ANSWERED. The pipeline counted nothing at the
      time, and only accepted points are stored, so the question A1b left open
      survived the device test. That gap is what A1c-0 exists to close, and it
      is answered on the next walk rather than this one.

- [x] A2b Live track while recording
      Accept: the recording screen draws the causal filter's smoothed track as
      it grows, with a position puck; the camera follows and stops following
      the moment the map is panned, offering a recentre button that never
      fires itself; widget tests drive all of it from fixture data with no
      plugin and no network
      Commit: <sha once done>

      **Redraw cadence: once per accepted fix, ~1 Hz. No timer.** The GPS
      stream arrives at exactly 1.000 s (A1c-7), so a timer faster than that
      redraws identical content and one slower makes the line lag the puck.
      What needed bounding was the cost of a redraw, not the rate of them.

      **Measured, `live_map_cost_test`.** A 7200-point track — two hours at
      1 Hz — redraws in **37 ms** on this machine, or ~76 ms with the whole
      suite running in parallel. Once a second, against a full second of
      budget. No display decimator was written, and that is the finding
      rather than an omission: flutter_map's `PolylineLayer` already runs
      Douglas-Peucker at a 0.3 px tolerance on every camera change and caches
      it (`layer_projection_simplification/widget.dart:26`), so the drawn
      geometry is already bounded by what is visible. A second decimator on
      top would be machinery for a cost nobody had measured. **The stored
      track and every metric are untouched either way** — nothing in the
      display path writes back.

      The remaining per-fix cost was the controller rebuilding the whole
      `LatLng` list on every publish: O(n²) over a run, ~26 million
      allocations on a two-hour walk. It now appends, publishing an
      `UnmodifiableListView` window rather than a copy. That makes
      `RunRecordingState` not deeply immutable, which is deliberate, bounded
      by the track being append-only, and asserted in the test so it cannot
      be tidied away.

- [x] A2 Map — done 7 Sep 2026; tick added 18 Sep by the midterm audit, which
      found every acceptance clause below satisfied and the box still empty.
      Commits: 23129a5, 97d531a, 52bee89, d95539d and the recolour chain.
      `run_list_screen.dart`, `run_detail_screen.dart` and `run_map.dart`
      ship the polyline, the fitted bounds, the start/finish markers, the
      debug raw-fix overlay and the offline banner; `run_map_test` (30) and
      `run_detail_screen_test` (5) drive all of it from fixtures with no
      database and no network. A2-3 closed on device the same day.
      Accept: a recorded run renders its polyline with start and end markers
      and bounds fitted to the track, alongside distance / moving time /
      elapsed / average pace; a debug-only overlay draws the raw accepted
      fixes as faint points under the smoothed line; the screen opens with no
      network available and says so visibly while still rendering the
      polyline and every statistic, which are local data; a widget test
      drives it from fixture data with no database and no network
      Commit: <sha once done>

      **Ordered ahead of the calibration work on purpose.** Three rounds went
      into debugging a geometry problem using only scalar totals, while the
      track sat unrendered in the database. Corner-cutting, phantom spurs and
      drift through buildings are visually obvious and numerically subtle; the
      raw-under-smoothed overlay shows the gap at every turn, which no
      distance total can. The map is a diagnostic before it is a feature.

- [ ] A-map-match Snap the track to the road network — UNDER REVIEW, not
      cancelled, and not to be started without a decision
      Accept: unchanged from the original plan, which is kept below

      **The reassessment, 26 Aug 2026.** It is the hardest remaining work in
      the project — a routable road graph, a Hidden Markov emission/transition
      model, an offline tile or extract pipeline, and a way to test it that is
      not "it looks right on one walk" — for perhaps two weeks. What it buys
      numerically is close to nothing: the captures already read −0.09%
      (24 Aug) and +3.54% (23 Aug) against a ground truth that is a Google Maps
      trace and carries ±1–2% itself. **The instrument cannot measure the
      improvement it would make.** Tuning against it would be tuning against
      the noise in the ruler.

      Against that, a real downside with no natural detector: map matching
      fails by snapping confidently to the *wrong* parallel road — a service
      lane, the other carriageway, a footpath twenty metres off. That error is
      invisible in every number the app produces, and it makes the track look
      *more* plausible, not less. Every failure mode this project has caught
      so far announced itself as a bad number.

      **What it is actually worth is aesthetic, and that is a real thing to
      want.** The line following the road exactly is the difference between a
      track that looks recorded and one that looks drawn. That is a legitimate
      reason to build it.

      **Amended 1 Sep 2026, and the argument for it is better than the one
      above.** Strava's own documentation names map matching as part of how
      they compute distance — "straight-line or map-matched" — so it is not a
      cosmetic pass applied to a finished number, it is one of the two ways the
      number itself is produced. That is a substantially stronger case than
      "the line would look nicer", which is how this row previously framed it,
      and it retires the flat claim that this is not an accuracy feature. See
      NOTES.md, "What Strava's documentation says their pipeline does".

      **What has not changed, and still governs the decision.** The instrument
      cannot measure the improvement — a ±1–2% Google-Maps-traced truth against
      captures already reading −0.09% and +3.54%. The silent-failure mode is
      unchanged: snapping confidently to the wrong parallel road is invisible
      in every number the app produces. And their matching leans on heat and
      popularity data from other people's activities, which a single-user
      offline app does not have, so what could be built here is the weaker half
      of what their docs describe. The two weeks of work is unchanged.

      Still UNDER REVIEW. The amendment changes the *reason* on the table, not
      the ruling: revisit when there is either an instrument that can measure
      the difference, or a decision that the geometry is worth it on its own.

- [ ] A3 Splits UI
      Accept: the 5.5 km fixture's splits render as 5 full rows plus a labelled
      partial; a widget test drives it from fixture data with no database
      Commit: <sha once done>

- [ ] A5 Pace/distance chart
      Accept: renders from a run's splits; empty and single-split runs render
      an explicit state rather than an axis with no data
      Commit: <sha once done>

- [ ] A6 Elevation gain — BUILT 19 Sep 2026, device check outstanding
      Accept: computed only where a barometer is present (runtime probe, never
      `Build.VERSION`); absent-but-honest on the A32 rather than a fabricated
      number from GPS altitude
      Commits: 8ac2122 (gain), 9dc5848 (barometer, capture, row, screen)

      Not ticked until a walk on each phone: the S26 recording a gain, the A32
      saying "NO BAROMETER" in its report and "Not measured" on the detail
      screen. **The 2 m deadband is PROVISIONAL (A6-2).** Every noise
      parameter in `elevation_gain_test` is assumed, and dropping the 5 s means
      moves the flat-route fixture only from 0.0 to 2.06 m against a 2 m
      budget, so the first walk with pressure in its capture is what decides
      whether either is right. Real climbs over-read by about the noise range:
      6 m reads 7.7 and 30 m reads 31.4 on the fixture.

- [ ] A7 BLE heart rate
      Accept: a heart-rate strap's samples are recorded against a run; no strap
      present degrades visibly and the run still records
      Commit: <sha once done>

A4 was noise and implied-speed filtering. It folded into A1a-3 and A1a-4, so
the number is retired rather than reused.
