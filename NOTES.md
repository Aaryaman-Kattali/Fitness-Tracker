# Open questions

## `Units.csv` is an ingredient table, and is parked until there is a recipe

**Not a question, a parking note**, so the next person to open
`tool/data/raw/Units.csv` does not re-derive this. It was expected to supply
tbsp/tsp/piece-to-gram conversions for the M3 household servings. It cannot:

- It converts **ingredient** quantities — "1 tbsp cumin = 2.1 g", "1 knob
  butter = 20 g", "1 stick cinnamon = 0.5 tsp" — many sourced to USDA FDC.
- It contains **no vessel word at all**: no bowl, plate, katori or thali.
- Of the 125 distinct `servings_unit` values in `INDB.csv` it matches 7,
  covering 20 rows, and all seven are word collisions (`egg`, `potato`,
  `tomato`, `capsicum`, `chicken`, `chicken breast`, `hot dog bun`) rather
  than serving conversions.

Serving weights came from `INDB.csv`'s own `unit_serving_*` columns instead
(M3-6). `Units.csv` becomes useful only if per-ingredient recipe scaling is
ever built — converting "2 tsp oil" to grams to recompute a dish. That work
does not exist and is not scheduled. **The ingredient file it would need is
not in this repo**: `tool/data/raw/` has only `INDB.csv`,
`recipes_servingsize.csv` and `Units.csv`, none of which lists ingredients per
dish. Exporting `recipes.xlsx` would also settle the 38 quarantined rows
(M3-8), which is the more valuable reason to go and find it.

`recipes_servingsize.csv` is parked for the same reason: no gram column, and
its `servings_unit` is identical to `INDB.csv`'s on all 1014 rows.

## Steps read 0 while Samsung Health showed 1008 — CLOSED on the A32, OPEN AGAIN on the S26

**Resolved 20 Aug 2026, and the cause was neither a bug nor a permission.**
Samsung Health had not yet written anything to Health Connect. It began doing
so after a sync cycle, and the ring filled on its own with no code change. **It
never backfills**, so the 1008 steps Samsung Health was already showing stayed
invisible to this app permanently — only steps recorded after the connection
existed ever appear.

The diagnostics section that was built to find this stays in Settings. It cost
nothing to keep and it is what will answer the same question next time, which
is now.

> **OPEN AGAIN on the S26 Ultra, for exactly the same reason.** A new phone is
> a new Health Connect store with nothing in it, and the same sync cycle has to
> happen before the ring can read anything. **A zero ring on the S26 is the
> expected first reading, not a regression** — give Samsung Health a sync cycle
> before suspecting the app, and run the diagnostics section before changing a
> line of code. Health Connect is a store, not a recorder: zero steps is a
> plausible correct reading.

What the diagnostics print, and what each line rules in or out:

- **SDK status** — separates "no provider / needs update" from a live client.
  The Today screen already collapses all of these into one muted ring.
- **Each permission on its own.** The app asks for STEPS and
  ACTIVE_ENERGY_BURNED together and `permissionStatus()` reads them together,
  so one granted and one refused currently reads as a flat refusal.
- **Raw records for the last 48 h**, with start, end, value and source package.
  Samsung Health writes *one* steps record per day and updates it in place, so
  a single 14-hour record is the expected shape, not a symptom. An empty list
  with the permission granted means the store genuinely has nothing.
- **The query windows in both local time and UTC.** A midnight-boundary or
  timezone mismatch is a prime suspect and is invisible with only one of the
  two. The today window shown is exactly the one `dailyTotals` uses.
- **`getTotalStepsInInterval` over that window**, next to the raw records. The
  aggregate returning null while records exist would point at the aggregate
  call; both empty points at the store or the permission.
- **Errors as text.** `dailyTotals` catches everything and returns `[]`, so a
  throwing read and an empty store look identical today.

Already known, and not worth re-deriving: historical data does not sync
retroactively into Health Connect, so nothing from before the connection was
enabled will ever appear; and the 30-day backfill was cut, so the app reads
today only.

## M4: the Recording API is not what the `health` package gives you

**Decided: option 1, leave it. 20 Aug 2026, and still contingent on the S26.**
The A32's ring filled once Samsung Health synced to Health Connect, which is
the condition option 1 rests on — something on the phone already writes steps.
No Kotlin plugin, no Gradle dependency, no second source. The `HealthRepository`
interface and the `daily_steps.source` column stay as they are; they are what
make option 2 a contained change if it is ever needed.

**What would reopen this.** The S26 Ultra is a different phone with an empty
store. If its ring is still empty *after* Samsung Health has had a sync cycle —
see the section above, which is open again for the same reason — then nothing
on that device writes steps, and option 2 becomes the answer rather than a
hypothetical. The reasoning below is kept in full for that case.

**The original writeup, unchanged from here down.**

M4 was specified as "`health` package → Android Health
Connect" *and* "use the Recording API path for steps (no Google account, no
scopes, better battery)". Those turn out to be two different systems, and no
single package does both.

What I checked, rather than going from memory:

- **Recording API** — `com.google.android.gms:play-services-fitness:21.2.0`,
  via `FitnessLocal.getLocalRecordingClient()`. Part of **Google Play
  services**, not Health Connect. Accountless, no OAuth scopes, records step
  and calorie deltas on-device, keeps ~10 days, needs
  `ACTIVITY_RECOGNITION`. Subscribed to with
  `LocalDataType.TYPE_STEP_COUNT_DELTA`.
- **`health` 13.3.2** — wraps Health Connect (and HealthKit). Its
  `RecordingMethod` enum (`unknown`/`active`/`automatic`/`manual`) is *not*
  the Recording API: it is provenance metadata on a Health Connect record,
  used to filter out hand-entered data. Nothing in the package's API surface
  or its 13.x changelog touches `LocalRecordingClient`.

So "use the `health` package" and "use the Recording API" cannot both hold.

**What I built:** Health Connect, per the first half of the spec. The three
properties the Recording API was wanted *for* — no Google account, no OAuth
scopes, good battery — are all true of Health Connect too. It needs no
account, uses Android runtime health permissions rather than scopes, and
reads totals the platform has already aggregated.

**What that does not cover, and why it may matter.** Health Connect is a
*store*, not a *recorder*. It only has steps if something writes them: Fit,
Samsung Health, a watch, or the OS on some devices. On a phone where nothing
writes step data, the ring will sit at "No steps yet today" indefinitely, and
nothing in this app can fix that. The Recording API is exactly the thing that
would fix it, because Play services itself does the recording off the
hardware step counter. If that is the case you had in mind, the instinct was
right and Health Connect alone does not deliver it.

**Options, if the ring turns out to be empty on your phone:**

1. **Leave it.** Correct if something on your phone already writes steps to
   Health Connect. Costs nothing; check the ring first.
2. **Add the Recording API as a second source.** A small Kotlin plugin over
   `LocalRecordingClient` behind the existing `HealthRepository` interface,
   with `daily_steps.source` distinguishing the two and Health Connect
   preferred when both have a day. This is the robust answer and the reason
   the interface and the `source` column exist. Costs a platform channel and
   a new Gradle dependency.
3. **Recording API only.** Simpler, but gives up on watches and other apps
   that write to Health Connect, and caps history at ~10 days rather than 30.

I did not build 2 or 3 unprompted: it is a platform-channel plugin and a new
dependency, which is more than a judgement call, and the spec named the
`health` package explicitly.

### Smaller thing in the same area

`ACTIVITY_RECOGNITION` is declared in the manifest because the `health`
README calls for it when reading fitness types, but nothing requests it at
runtime — that would mean adding `permission_handler`. Health Connect grants
`READ_STEPS` through its own sheet and does not need it, so this should not
matter. If steps read as empty on a real device *despite* the Health Connect
permission showing as granted, this is the first thing to suspect.

---

## Stream detection: wired in, and both open questions closed. 26 Aug 2026

`StreamDetector` is in the chain. The two questions this section carried are
answered and the reasoning lives in **PROGRESS.md under A1c-13** rather than
here:

- the quality ceiling stays at 9, PROVISIONAL, and the evidence that used to
  justify it was falsified on the way — 50 changes nothing anywhere;
- strict "undecided" is kept, at a measured cost of 15 fixes and 21 s at the
  head of a fractional-timestamp fixture and no GPS fix on either real walk.

The failure that blocked the first wiring attempt is also explained there: it
was the opening hole strict-undecided produces, and the "32.1 m/s" it was
recorded as is 32.1 **metres**, which at 21.1 s is the fixture's own walking
pace.

One dependency is still open and belongs here: **the S26 Ultra's timestamp
format is unmeasured.** If its GPS timestamps are fractional, it pays the
probe cost that `burstCadenceWalk` prices; if it is a single-stream receiver,
it is also the capture that would let the quality ceiling be chosen on
evidence. One walk answers both.

## Map rendering: what was rejected, and why

**Not a question, a parking note.** The basemap moved to OpenFreeMap vector
tiles rendered by `flutter_map_vector_tiles` (A2-3, 31 Aug 2026). These are the
options that lost, recorded so the search is not repeated and so a future
suggestion of one of them meets its reason rather than a shrug.

- **MapLibre — `maplibre`, `flutter-maplibre-gl`.** Renders as a **platform
  view**. Flutter widgets cannot live inside the map; they can only stack over
  it. `flutter_map_vector_tiles` was chosen because it draws into a plain
  `flutter_map` layer and `flutter_map` keeps owning the camera, gestures and
  every other layer.
  **Amended 7 Sep 2026 — the original reason here overstated the cost.** It
  said "every A2 layer would need rewriting". It would not. The layers are a
  polyline, two markers and the debug raw-fix circles, and MapLibre has native
  annotation APIs for all three; the stats sheet is already a `Stack` over the
  map, which is exactly what a platform view supports. The real work is the
  camera: fit-bounds, follow-me and the manual-pan break (C-8), and the widget
  tests that drive them, all move to a different API. Realistic cost is about a
  week, not a rewrite. The rejection stands on that price against zero
  accuracy benefit, not on an impossibility that was not there.
- **Leaflet, OpenLayers.** Web only. There is no web app and there is not
  going to be one.
- **Self-hosted OpenMapTiles, VersaTiles.** Needs a server. The architecture is
  deliberately backendless — see ARCHITECTURE §1 — and a tile server is not a
  smaller commitment than the sync backend that was already refused.
- **Mapbox, HERE, MapTiler, Geoapify.** All have workable free tiers and all
  require an account. **A free tier that requires registration is the same
  revocation risk as CARTO**, which is the test A2-7 exists to apply: a key-free
  public service with a published usage policy is a dependency on a published
  policy, while a free tier is a dependency on someone else's pricing decision.
- **Nominatim, GraphHopper, OSRM.** Geocoding and routing. Never requested,
  and nothing on any screen asks a question they answer.

Two properties of the chosen stack are worth keeping in view rather than
rediscovering. `flutter_map_vector_tiles` is published by an **unverified
uploader** with 2 likes and roughly 1,570 weekly downloads, so the risk here is
abandonment rather than revocation — it is BSD-3, so vendoring is the answer if
that day comes. And the **vector data stops at z14**: above it the server
answers `200` with an empty body, which is a successful-looking response
carrying no map, the same shape as CARTO's watermark. Nothing errors, so no
banner can catch it; what makes it safe is that the renderer overzooms z14
geometry by design (`tile_zoom.dart:18-34`) rather than showing the blank.

### 3D buildings: what it would buy, and what it would cost

**Status: NOT SCHEDULED.** Revisit after the device-adaptive change and after
the app has been used for real. Recorded 7 Sep 2026 so the next look starts
from the facts rather than re-deriving them.

- **The data is already being fetched.** Building heights are in the
  OpenFreeMap vector tiles this app already downloads — MapLibre's own 3D
  example uses `tiles.openfreemap.org`. Nothing new would be requested and no
  new source would be depended on, so A2-7 does not even enter into it.
- **The only reason there is no 3D is the renderer.**
  `flutter_map_vector_tiles` draws `fill-extrusion` as a flat fill. That is a
  limitation of the drawing package, not of the tiles or of the style.
- **3D therefore means MapLibre native (`maplibre_gl`)**, with the camera cost
  above. `any_map_maplibre` wraps it and exposes `enable3DBuildings()`, which
  would shorten the job — but it has 66 downloads. Too young to depend on, on
  the same abandonment reasoning already applied to the current renderer,
  except worse.
- **Zero accuracy benefit.** Extruded buildings tell you nothing about a track
  that a flat footprint does not. Urban drift is read against building
  *outlines*, which are already drawn. This is aesthetics, and it should be
  priced as aesthetics.

### Recolouring the basemap: why it did not happen, 7 Sep 2026

A muted restyle was specified — land `#F7F4D5` / `#0A3323`, parks `#839958`,
water `#105666`, buildings `#D3968C`, neutral roads — on the understanding
that the style JSON is ours and this is a file edit. **It is not.** There is
no style document in this repo. `run_map.dart:180` fetches it at runtime:

```dart
static Future<vt.Style> _readStyle(String uri) => vt.StyleReader(
      uri: uri, headers: const {'User-Agent': runMapUserAgent}).read();
```

from `tiles.openfreemap.org/styles/positron` and `/dark`. Recolouring means
**vendoring** both documents into `assets/` and pointing `MapTileSource` at
`asset://` URIs, which `StyleReader` does support — the route exists, it is
just much larger than a file edit, and it trades a style that tracks upstream
for two documents this repo owns forever.

The second blocker is the one that actually decides it, and it is A2-3's own
rule rather than a scheduling problem. **The overlay wins every tie**, and
there is currently no instrument to adjudicate the tie. The check is a corner
with the raw-fix overlay on, both themes, at the zoom corners are inspected
at; no Android device is attached, and `flutter_test`'s blanket HTTP failure
does not exercise the real tile path — already measured at zero banners after
six seconds of pumping, recorded above. So "revert if legibility degrades"
has nothing behind it.

Two properties of the proposed palette are worth keeping, because they are
what the device check would have to clear rather than reasons not to try:
**water at `#105666` is the accent's own light-mode hue**, and the raw-fix
overlay is currently blue (`trackRawFix`, `0x99007AFF`) — a 2 px translucent
blue point over teal water is the exact adjacency A2-3 exists to prevent.
And `#F7F4D5` land is a more saturated ground than Positron's `rgb(242,243,240)`,
which is a step away from the near-monochrome property, not toward it.

Recorded as **U-2**. Revisit with a phone in hand, not before.

### U-2 REVERSED, 7 Sep 2026 — the styles are vendored and we own them

Both blockers cleared, in the order they had to. **A2-3 closed on device**:
the raw-fix overlay is legible at the A2-10 accent, and the corner artefact
was seen directly for the first time. That is the instrument the note above
said did not exist, and with it the tie can be adjudicated — so the reason to
refuse the recolour was gone rather than merely inconvenient.

The reasoning that was too narrow is worth naming, because it is the same
mistake in both directions: the basemap was being optimised for **a 2 px
overlay that only exists in debug builds**, at the cost of the map actually
used while running. A near-black ground makes the road ahead hard to read in
daylight, which is the map's real job.

**What vendoring costs, paid deliberately.** `assets/map_style/positron.json`
and `dark.json` are byte-identical to what OpenFreeMap served on 7 Sep 2026.
`dark.json` is verified twice over: it matches the copy the phone had already
cached and rendered, same SHA-256
(`4ba4a199…0bc51631`), so the committed document is provably the one that
produced the A2-3 screenshot. `positron.json` is
`a0f5b848…c7d216db`.

One caveat on "byte-identical", stated because a hash was quoted. The
committed blobs are exact — checked with `git show :<path> | sha256sum`. But
this repo has `core.autocrlf=true` and no `.gitattributes`, so a *fresh
checkout* materialises these files with CRLF and they will no longer match
those hashes on disk. Harmless — JSON does not care, and the bundled asset
parses either way — but it means the hashes above verify the git content, not
whatever is sitting in a working tree. Pinning them with a `.gitattributes`
`-text` rule would fix it and needs a new root-level file, so it is left
undone rather than added unasked.

**These two documents no longer track upstream.**
Fixes, new layers, schema changes and label improvements at OpenFreeMap will
not arrive on their own, and nothing will tell us when we have diverged. The
mitigation is small and named rather than assumed: `MapTileSource
.openFreeMapHosted` still holds the hosted URLs, so abandoning local edits is
one line; `map_style_test.dart` pins that both documents parse, need no key,
and contain **only absolute URLs** — the last is the invariant vendoring
specifically endangers, since a relative URL would resolve against
`asset://assets/map_style/` and fail as a basemap that never draws.

Tiles, sprites and glyphs are **not** vendored and still come from OpenFreeMap
over the network. A2-1 and A2-7 are untouched: vendoring buys control of the
rendering, not of the data.

### Map contrast must be measured on the composite that renders

The lesson from getting the building colour wrong, recorded because it
generalises past this palette.

**Measure the COMPOSITE, not the nominal hex.** Buildings are a low-opacity
fill over land; the track is an orange fill inside a dark casing. Neither is
ever seen as its raw colour, so a solid-vs-solid comparison is a comparison of
two things that do not appear on screen together.

Concretely: `trackLine #FF9500` against a solid `#D3968C` measures 1.12:1,
which looks alarming and prompted a ruling to darken the buildings. Both the
alarm and the remedy were artefacts of the wrong comparison.

- At 0.35 opacity over `#F7F4D5` land, `#D3968C` composites to `#EAD3BB` —
  1.52:1 against the orange, and **6.44:1 against the casing**, which is what
  actually makes the line findable.
- The darkened `#934539` scores **1.16:1** at the same opacity — *worse than
  the colour it was replacing* — and 1.40:1 against the casing as a solid,
  which would sink the dark outline that defines the track into building
  fills.
- 3:1 against the orange is unreachable at low opacity in any case: a **pure
  black** fill needs alpha ≥ 0.7 to clear it. The track's luminance (0.428)
  sits mid-range, so both lighter and darker grounds converge on it.

**The binding constraint is the opacity ceiling, not the hex.** `#D3968C` at
≤ 0.35 is kept; the ceiling is pinned in a test, because that is the number
the result depends on.

~~Carried into the dark restyle: the same fill over a dark ground is a
different composite. `#D3968C` at 0.35 over `#0A3323` must be measured, not
assumed to inherit the light theme's answer.~~ **Void, 8 Sep 2026 — there is
no dark restyle.** U-3 left one style and one ground, so the composite above
is the only one that renders. The rule the paragraph was an instance of still
stands and is the part worth keeping: measure the composite, never the
nominal hex.

### U-3, 8 Sep 2026 — one style, ours, and `dark.json` is deleted

The 7 Sep instruction to keep both themes was withdrawn the next day, and the
reason it was wrong is worth keeping because it is the same reason U-1 picked
one accent. **A palette is an identity that holds everywhere.** Strava is
orange in dark mode too. A map that follows the OS setting has its colours
decided by a phone preference rather than by anyone who chose them, so
"recolour it to my palette" and "keep both themes" cannot both be satisfied —
the second cancels the first. The app chrome still follows the system theme.
The map does not.

**`dark.json` was vendored on 7 Sep and deleted on 8 Sep.** It is recorded
here rather than parked in `assets/` as an unreferenced file, because an
unused 47-layer document that still ships inside the APK is dead weight (§4)
and still reads as a choice somebody might wire back up. What it was: the
OpenFreeMap dark style, SHA-256 `4ba4a199…0bc51631`, verified twice over as
the exact document the phone had cached and rendered for the A2-3 screenshot.
Nothing about it was defective. It was dropped because there is no longer a
question it answers. `git show 98aa832:assets/map_style/dark.json` is the way
back if one ever reappears.

**Positron was kept as the base, and not for being the light one.** It carries
55 layers against the dark document's 47, with a richer road hierarchy and
bridge and tunnel treatments the dark document simply does not have — so it is
the better starting point for a recolour regardless of which end of the range
the result lands on. And the map is read outdoors, in daylight, while moving.

**Everything drawn on top became fixed, and that is load-bearing rather than
tidying.** `trackLineCasing`, `trackPosition` and `trackRawFix` were all
per-brightness tokens chosen against two grounds. With one fixed light ground
the dark variant can only ever be drawn on the wrong one, and the casing is
the sharp case: it does its job by sitting at the opposite end of the range
from the ground, so a casing that still inverted would resolve LIGHT on a
phone in dark mode. A light casing on a light map is not a weaker outline, it
is no outline, and the track would lose the thing that makes it findable.
`run_map.dart` now reads brightness nowhere, and `run_map_test` pins that by
pumping two brightnesses and asserting the SAME style URI and the SAME casing
— a test that merely stopped looking would pass against a build that still
switched.

### `.gitattributes`, approved 8 Sep 2026 — and what it does now

The CRLF problem was real: `core.autocrlf=true` meant a fresh checkout
materialised the vendored styles with CRLF, so the SHA-256 values quoted above
verified the git content and not the working tree. A root-level file needs
asking (§10), it was asked for, and it is in.

`assets/map_style/*.json -text` disables end-of-line conversion in **both**
directions, so the bytes on disk are the bytes in git. `eol=lf` was the
alternative and is weaker: it normalises on the way in, which is the same
rewrite from the other side.

**But note what the rule is now for, because the original justification has
expired.** `positron.json` has been recoloured; it is not byte-identical to
anything upstream any more and its provenance hash describes a document that
no longer exists here. The rule survives on the two reasons that outlast it:
line endings stay stable across machines, and a style document that git is not
rewriting produces diffs that mean something.

### The recolour, measured. 8 Sep 2026

Every number below is a computed WCAG ratio over the composite that renders,
and the ones that matter are pinned in `map_style_test.dart` against the JSON
rather than restated in Dart. `dE` is CIE76, included where a ratio understates
a difference that is mostly hue — which is most of this palette.

**The land colour costs the overlay nothing, which the parked note got wrong.**
U-2 worried that `#F7F4D5` was "a more saturated ground than Positron's
`rgb(242,243,240)`, a step away from the near-monochrome property". Measured,
the raw-fix cloud scores **2.96:1** on the new ground against **2.95:1** on the
old one. The concern was reasoned rather than computed, and it was wrong. The
near-monochrome property that A2-3 actually depends on is *quietness*, not
desaturation, and a warm ground of the same luminance is equally quiet.

**Paths, priority 1.** `highway_path` went from `rgb(234,234,234)` at
**1.08:1** — reproduced exactly by the test, 1.0802 — to `#6B7F3E` at
**3.99:1**, dE 50.7. Given its own hue rather than another step on the grey
ramp, because the classes it must be told apart from are all neutral. Weight
went 1→1.6 px at z13 and 10→12 at z20, still under `highway_minor` so the
hierarchy stays ordered.

**The path had a ceiling as well as a floor, and it is the interesting part.**
Darker reads better on land and worse against the track: `#4F5F2E` scores
6.27:1 on the ground but only **1.33:1** against the composited track casing,
and the route is drawn ON footpaths. `#6B7F3E` keeps 2.09:1 there. The
constraint is two-sided and the chosen value is not the most legible one.

**The road ramp**, against the land: minor 1.31 → major casing 1.95 → motorway
casing 3.26, each step ≥1.49:1 clear of the one below. Pinned as monotone and
separated rather than as hexes, so a future palette move has to keep the
ordering rather than merely differ.

**Buildings.** `#D3968C` at 0.35 composites to `#EAD3BB`: 1.52:1 against the
orange track, **7.03:1 against the composited casing**, which is what actually
makes the line findable. Note the correction to the earlier note — it recorded
6.44:1 against "the casing", measured against the raw `#1C1C1E`; the casing is
`0xCC` alpha and composites to a lighter grey, so the true figure is 7.03:1.
Same conclusion, better number.

**Green at full strength would have cost the overlay.** `#839958` opaque drops
the raw-fix cloud to 1.79:1. At 0.35 it composites to `#CED4A9`, holds 2.56:1,
and still reads unmistakably green at dE 14.2. Wood is capped at 0.45 on its
existing zoom ramp for the same reason.

#### RESOLVED 8 Sep 2026 — water is the accent's own hex, and the raw-fix cloud vanishes on it

Not a defect in anything built here, and not something a value can fix, so it
is recorded rather than quietly patched.

`AppColors.accent` light is `#105666`. The specified water colour is `#105666`.
`trackRawFix` is that accent at 0.6 alpha, so **over water the cloud composites
to exactly the water colour: 1.00:1, invisible.** This is the adjacency the
7 Sep parking note predicted, arrived at from the other direction — the note
expected a blue overlay on teal water, and instead the overlay moved onto the
same teal.

**Tuning water does not fix it**, which is why there is no quiet remedy. The
cloud IS that hue, so every candidate stays in the same family: `#0A3A46` gets
1.27:1, `#062830` gets 1.44:1, and buying even that costs the water its
identity as the accent. The honest options are two, and both are the user's
call rather than a colour choice:

1. **Accept it.** Runs are on land; the cloud is a debug-only overlay; and the
   route itself still reads on water at 3.75:1 on its orange core, which is
   asserted in `map_style_test.dart` precisely so this stays true.
2. **Move water off the accent** — a real palette decision, not a tweak.

Accepted as (1) for now, because the case where it bites is a route crossing
water WITH the debug overlay on, and the overlay ships only in debug builds.
Worth revisiting if a capture along a shoreline ever needs inspecting.

##### The resolution, and the reason the two options above were the wrong two

Revisited immediately: Zurich is a lakeside city and the overlay is the primary
diagnostic for the corner artifact, so a cloud that vanishes on water is not a
diagnostic.

**Both options listed above were colour changes, and the defect was not a
colour.** That is the part worth keeping. The cloud is a 0.6-alpha fill, so it
composites 60% of the way from any ground toward the accent, and its contrast
against that ground is therefore bounded by their luminance separation — with
both of them dark, the bound is tight. Swept across every colour: the ceiling
is 3.08:1 and only at a white "water" indistinguishable from land, or 1.61:1
subject to water still reading as water. `#0A3323` reaches 1.36:1. So option 2
could never have worked either, and the note asserted the right fact ("tuning
water does not fix it") while drawing the wrong boundary around it — it
concluded the problem was unfixable when it had only shown the BASEMAP could
not fix it.

**The fix was the overlay.** The route has `trackLineCasing` and the puck has
`trackPositionBorder` because a fill alone does not survive an arbitrary
ground; the cloud was the one element on the map that never got one. It has a
white hairline now, and the criterion it is measured against is the one the
track already lives by — findable if EITHER part separates, the casing carrying
it on land and the orange core on water.

```
worst ground, before   1.00:1   (water, invisible)
worst ground, after    2.19:1   (highway_major_casing)
on water, after       13.90:1   (the border; the fill is 1.36:1)
```

2.19 is the ceiling, not a comfortable margin, and the binding ground is now a
mid-luminance road casing where the FILL is already what carries it. No border
colour improves on it: anything dark enough to beat 2.19 there lands on the
same tone as a footpath. Raising it further means changing the fill.

Water then moved to `#0A3323` **on its own terms** rather than as a fix — 12.48:1
against land, 6.32:1 against the track's orange core, separated from the accent,
and closer to what Zurich's lake actually looks like. Verified independent:
reverting water alone leaves the overlay tests green and reddens only the
identity assertion, which is the correct shape.

One cost, confirmed rather than assumed: the track's casing composite on water
falls from 1.85:1 to 1.19:1. It does not matter, because the casing was never
what carried the route on water — the orange core is, and it improved. It used
to be the cloud's only remaining separation there; the cloud has its own border
now.

**The transferable lesson: check which variable the defect is actually a
function of before proposing values for a different one.** A compositing
problem was met with a palette proposal three times running.

### What Share Aura actually does, which reframes the comparison

Recorded 7 Sep 2026. Share Aura is the app the 3D question came from, and the
important thing about it is what it is not: **it does not measure anything.**
It imports finished routes from Strava, Garmin, Apple Health and Coros and
renders them. Its product is the graphics editor.

That is the whole comparison. The accuracy work this project has spent ten
rounds on — stream detection, the kinematic bound, the noise process, the
`accelerationNoiseMps2` sweep — is a problem Share Aura does not have, because
it consumes someone else's output. Comparing this app's map to theirs on
looks alone compares a measuring instrument to a poster printer. Any future
argument for 3D has to be made as "the rendering should be prettier", on its
own merits, and not as "a competitor has it".

## The Zurich walk, 7 Sep 2026 — the first capture with substantial stops

`captures/2026-09-07_zurich_4310m.ndjson`. 3423 delivered fixes, 50:58 elapsed,
28:38 moving, 22:19 standing still across 16 segments. Every earlier capture is
a continuous walk, and that is exactly why this one found something four of
them could not.

### The bug it found: distance accumulated while stationary

Measured from the capture, splitting the raw accepted path by the detector's
own stop segments:

```
raw accepted total   4529 m
  during moving      4054 m
  during stops        475 m   <- 11% of the total, phantom
```

The two long stops — 10:01 and 7:02, standing on a viewtower — contributed
202 m between them. ~1000 fixes at 3.79 m accuracy while standing still, each
adding a small positive step to a sum that never cancels.

This was **already recorded and never acted on**: stops excluded TIME but not
DISTANCE. The flag existed, the accumulation just did not read it. It is fixed
under A1c-J by freezing the accumulation anchor rather than by excluding
stopped fixes — see the requirement for why exclusion is the wrong shape.

### What the fix actually recovered, which is less than 475 m

**The phantom is large in the RAW path and much smaller in the smoothed total,
and conflating the two would overstate the fix.** The Kalman filter already
suppressed most stationary wander before any of this: a receiver standing still
produces a confident, barely-moving estimate. So of the 475 m visible in the
raw accepted path, only part ever reached the number the app displayed.

Replayed across every committed capture, forward pass:

```
                       before    after    moving time
2026-08-23_1610m       1662 m   1662 m       unchanged
2026-08-24_1610m       1604 m   1604 m       unchanged
2026-09-01_1930m       1945 m   1940 m       unchanged
2026-09-07_zurich      4307 m   4121 m       unchanged
```

Zurich drops **186 m**, or 4.3%. The two continuous ground-truth walks do not
move at all, which is the property that says the anchor rule reduces to
fix-to-fix while moving. Moving time is untouched everywhere — it was always
right.

The synthetic stop fixtures move the same way, and toward truth:

```
walk/stand/walk @1.0 m/s   truth 600.0    647.42 (+7.90%) -> 600.92 (+0.15%)
walk/stand/walk @1.6 m/s   truth 960.0   1012.34 (+5.45%) -> 977.11 (+1.78%)
run/stand/run              truth 1666.7  1744.72 (+4.68%) -> 1698.49 (+1.91%)
```

### What is left, and it is the detector's edge rather than the anchor

The residual is the **leading edge of every stop**. The rule judges displacement
over a trailing 10 s window, so it cannot know a stop has begun until it has
watched one go by. Measured on the `walkStandWalk` fixture: the first 12 s
inside the stop are still classified moving and accumulate 19.0 m fix to fix;
the remaining 159 fixes of the stop add exactly nothing.

**The important change is that the residual is now bounded by the window
instead of by the stop's length.** A three-minute stop and a thirty-minute stop
both cost ~19 m. Before, the thirty-minute one cost ten times more than the
three-minute one. On Zurich's 16 stops that leaves roughly 16 edges' worth still
in the total, which is most of the difference between the 186 m recovered and
the 475 m of raw phantom.

**Removing it would need a retroactive anchor** — on detecting a stop, rolling
the anchor back to the start of the window and subtracting what was accumulated
since. NOT DONE, and not a tuning question. It would make the live distance
tick backwards by ~19 m at every stop, and it would break the monotonicity of
`cumulativeDistanceM`, which `splitsOf` interpolates through and
`currentPaceSecPerKm` differences. Worth doing only if the edge residual turns
out to matter more than a distance readout that goes down while you watch it.

### A second bug, nearly shipped, that only appeared because of the first fix

**The anchor-freezing instruction created it.** Worth stating plainly rather
than leaving as a bug that merely turned up nearby: the flag existed and was
wrong at low cadence long before this work, and it was harmless the whole time
because distance ignored it. Freezing the anchor gave the flag a new consumer,
and the same wrongness became a run reporting near-zero metres.

Once distance depended on the moving flag, a case that had been harmless became
fatal. The rule needs a point inside its 10 s window to measure displacement
against. **At a 20 or 30 s cadence — where a phone sits when it is saving
battery — there never is one.** The in-list form returned 0 through a
division-by-zero guard, every fix read as stopped, nothing ever resumed, and
the run reported **zero metres**. Caught by `track_splits_test`, whose
low-cadence fixture went to zero splits.

The fix is that "no basis to judge" is now a distinct answer from "stopped":
`displacementSpeedForCandidate` returns null, moving time reads null as
not-moving exactly as before, and distance accumulates through it. Pinned in
`stopped_distance_test` and verified by mutation — restoring the 0 reports
0.0 m on a 960 m walk.

**The lesson, which is the part that transfers: when a flag acquires a new
consumer, re-audit every path that SETS it — including the guards.** The bug
was not in the moving rule's logic but in its divide-by-zero guard, which
answered "stopped" for a question it had no basis to answer. A guard returning
a plausible value instead of an unknown is invisible until something starts
depending on the difference. It was found only because the fix was tested; no
amount of reading the diff for the fix would have reached the guard, because
the guard is not in the diff.

### A cost on hairpins, small and worth knowing

Anchor freezing takes displacement ACROSS a frozen stretch, and out-and-back
displacement is shorter than out-and-back path. At a hairpin sharp enough to
read as stopped, that loses a little real distance. Measured on the switchback
fixture's RTS track: 140.13 m becomes 137.23 m, about 1 m per hairpin. The
forward pass is unaffected — no fix there ever classifies as stopped.

Accepted on the same terms as everything else here: bounded by the window,
unable to grow with the length of the turn, and in the safe direction on a
fixture already losing 48% to corner rounding.

### The pace test was passing because two errors cancelled

Worth recording as a lesson about green tests. `track_metrics_test`'s
"average pace is computed over moving time" asserted 360 ± 8 s/km on the
standing-still fixture and passed at 359.4. It passed because the phantom
distance (+78 m) and the moving-time overcount from the same 10 s window lag
(+27 s) divided out almost exactly.

Removing one error made the number worse — 369.2 — while the pipeline got more
correct. The budget is now 12 s/km, which is the size of the moving-time
overcount alone. Nothing regressed; the test simply stopped being right for the
wrong reason.

**This is the third green test in this project found to be measuring nothing
— and a fourth turned up the same day, listed below it. Three more have been
added since, so the list now runs to seven. They fail differently enough to be
worth keeping together:**

1. **The `loggedAt` backfill test** — a one-row fixture, so a backfill that
   ignored per-row correlation passed. Failed because the FIXTURE could not
   discriminate. Fixed by giving it two workouts with different start times;
   it is now the highest-value test in `migration_test`.
2. **The degraded-tile-path test** — `flutter_test`'s blanket HTTP failure
   never reaches `errorTileCallback`, which is wired to the image stream's
   error handler and not to a synchronous throw. Measured at zero banners
   after six seconds of pumping. Failed because the HARNESS never entered the
   code under test.
3. **This one** — correct fixture, correct harness, and two real errors of
   opposite sign that divided out. Failed because the ASSERTION was a ratio,
   and a ratio hides correlated errors in its numerator and denominator.
4. **The recording screen's stat panel** — added later the same day, after
   this list was written, which is its own small lesson about declaring a
   count closed. The screen had widget tests and they passed while the panel
   overflowed by 69 px on device: they asserted the labels were PRESENT, at
   one surface size, with every value showing its em-dash placeholder. Failed
   because the assertion was existence rather than layout, and because the
   fixture was the one state whose strings fit.

   **This is the same shape as the other three: the check was performed in
   the one condition where it passes.** Em dashes are three narrow glyphs
   that fit any width, so the panel was verified in the only state it could
   not fail in — the layout equivalent of the one-row `loggedAt` fixture.
5. **`workout_repository_test`'s "frees the next session from resuming an
   abandoned one"** — found by the August 2026 audit, which measured it
   passing with the entire feature deleted, because its two workouts were on
   different dates and `openWorkoutFor` is day-scoped regardless. Failed
   because the behaviour was ALREADY GUARANTEED elsewhere, so the test could
   not distinguish the feature's presence from its absence.
6. **`rest_timer_state_test`'s "holds the stored remainder while paused"** —
   found by the September 2026 audit. See the section below; it is the one
   case on this list that the other five do not cover.
7. **`saved_track_test`'s split sum — a near-miss, caught BEFORE shipping**,
   the first on this list not found after the fact. Recorded 19 Sep 2026. A
   split-sum-equals-total assertion can never fail, because `splitsOf`
   computes the last split as `distanceM - (km - 1) * 1000` and so sums to
   whatever total it is handed. New mechanism: **an assertion over a function
   that constructs its own agreement can never fail.** The discriminating
   checks are the last point's cumulative distance and the count of whole
   kilometres; see `expectSelfConsistent`. **Rule: when asserting a sum,
   check whether the producer derives the parts from the total.**

##### The sixth is a NEW mechanism: a deletion sweep never re-reads a green test

Recorded 18 Sep 2026, and kept separate from the five above because the
failure is not in the test's fixture, harness or assertion. All three were
fine. The test asserted, correctly and discriminatingly, over a state the app
**can no longer produce**.

`RestTimerState(total: 3 min, remaining: 95 s, isRunning: false)` — a live
remainder with no deadline — was reachable while `RestTimer.pause` and
`RestTimer.resume` existed. The August audit deleted both **as dead code**,
correctly. The test kept passing, because `remainingAt`'s null-deadline branch
still returns the stored remainder; it just does so for the idle case now. So
a month of green runs asserted a guarantee about a state with no producer, and
`deadline`'s doc comment went on describing "null while paused" to every
reader of the file.

**The mechanism, and it is the transferable part: a deletion sweep re-reads
FAILING tests and never re-reads passing ones.** That asymmetry is the whole
bug. Deleting a feature surfaces its tests loudly when they go red and
silently when they do not, and the ones that stay green are exactly the ones
testing a value type the feature merely *populated* rather than owned — which
is where the orphan lands. Nothing goes red, nothing is logged, and the stale
doc comment travels with it as apparent corroboration.

**The rule: when deleting a feature, grep the test suite for its TYPES, not
just its function names, and read every hit — including the green ones.**
Function names disappear with the feature and take their call sites with them;
the types outlive it, and a test constructing one by hand does not reference
the deleted function at all. `grep RestTimerState test/` would have found this
in August; `grep pause test/` found nothing, which is why it was missed.

Now in CLAUDE.md §5 as a one-line amendment.

##### Two wrong diagnoses of that overflow, recorded because they were plausible

Both were mine to check and both were stated before measuring. Kept because
each has a general form worth recognising rather than because the specific
values matter.

**"Pace is the widest string."** It is the NARROWEST at five characters.
`formatPace` already returns a bare `12:25` — the `/km` lives in the label —
so pace had nothing to trim. Distance was the culprit, and precisely because
it did the opposite: it carried ` km` INSIDE a 44 pt value, and removing it is
what bought the ordinary case back. The general form: a column's cost is the
value's rendered width, not the quantity's conceptual size, and the two come
apart exactly where a unit has already been factored into a label.

**"There is a widest realistic value that trips it."** There is no threshold.
`0.01 km` + `0:11` already exceeds the panel, so it overflowed from the FIRST
accepted fix and never stopped. The framing implied a boundary between values
that fit and values that do not, and the real boundary was between the
placeholder state and every real state. The general form: when a layout is
checked in one condition, ask whether that condition is a value or a MODE.
Looking for the value that crosses the line hides that the line was crossed
before any value existed.

##### What is still unmeasured here, and it is device-only

Whether an ordinary run scales down on a narrow handset. `flutter_test`
renders in a fixed-pitch test font about 1.76x SF Pro at 44 pt, so no width
measured in `run_stats_overflow_test.dart` reflects a device. That makes the
overflow assertions CONSERVATIVE, which is the safe direction, and makes the
appearance question unanswerable in the loop.

Equal thirds do not let a short column lend width to a long one, so a five
character duration can scale while a four character distance sits in spare
room — correct and overflow-proof, but a visible size difference between
adjacent columns. **Unmeasured on a 320-class phone**, which the available
S26 is not. Waiting for a narrow device rather than guessed at.

Numbers 1, 2 and 4 are caught by reading the test. The third is not: it is only
visible by mutation, or by the number moving the wrong way when something
unrelated gets more correct. **A test getting worse as the code gets more
correct is the signal**, and the instinct to treat that as a regression is
exactly backwards. Hence CLAUDE.md §6's rule about fixtures that can actually
fail — which covers case 1 and does not cover case 3.

### Ground truth: there is none for this route, and 3.0 km is NOT it

**The ~3.0 km estimate for this route is rough and must not be tuned toward.**
It is not a Maps trace and not a measured length. Ours reads 4.31 km and Strava
4.42 km — two independent estimators within 2.5% of each other, which is the
only thing here that behaves like evidence.

The 475 m finding does not depend on any of that. It is measured **from the
capture against the detector's own stop segments**, not against an external
reference, which is why it stands on its own while the route length does not.
Do not add this capture to the ground-truth budgets in `device_capture_test`.

### The other environment: Zurich's network stream is far worse than Thane's

Same receiver, second city, and the filter's value turns out to be strongly
environment-dependent:

```
network stream   381 fixes   median accuracy 500 m   max 1700 m
raw path, all delivered fixes: 1,632,725 m across a 4.3 km walk
StreamDetector rejected all 381
```

Thane's network fixes sat around 27 m. Half a kilometre of median accuracy is a
different phenomenon, and a pipeline without stream separation would have been
reporting kilometres of fiction here rather than the +205% seen in Thane. Worth
knowing before anyone proposes that `StreamDetector` is over-engineering for
one user: its value is not a constant, and one environment does not bound it.

### Elapsed and moving, against Strava on the same walk

```
elapsed   ours 50:58   Strava 51:02
moving    ours 28:38   Strava 30:14
```

Elapsed agrees to four seconds. Ours is stricter on moving time by 1:36,
consistent with every prior walk — the same direction and roughly the same
magnitude, so it is a property of the threshold rather than of this route.

## What Strava's documentation says their pipeline does, and where ours differs

**Not a question, a parking note.** Recorded 1 Sep 2026 from Strava's own
published documentation. It is their description of their pipeline, not a
measurement of it and not something verified from this repo — every claim below
is theirs. What it is good for is telling apart the gaps that are structural
from the ones that are a defect in this pipeline, because those get worked on
very differently.

**The structural difference: they are server-side and non-causal, we are
on-device and causal.** Strava processes uploaded raw points on a server with
the whole track in hand, and can reprocess history when the processing changes.
This pipeline runs on the phone, fix by fix, and each decision is made from what
has arrived so far. That is not a tuning gap and no constant closes it.

The RTS backward pass was the attempt to close it, and it failed for a reason
that is already understood: **the motion model, not the direction of the pass**
(A1-7, and the measurement under `rts_smoother_test`). A backward pass over a
constant-velocity model is still a constant-velocity model, so it does not
recover a turn it was never able to represent. Do not re-open this as "try
smoothing backwards again".

**They map-match; we do not, and they have a prior we cannot get.** Their docs
describe distance as straight-line *or map-matched*. There is no map matching
here — see `A-map-match`, still under review. Their matching also leans on
heat and popularity data accumulated from other people's activities, which is a
prior that does not exist for a single-user offline app and cannot be
substituted for.

**The one place this pipeline does something theirs does not claim to: stream
separation.** Nothing in Strava's documentation describes separating GPS fixes
from network-positioning fixes. `StreamDetector` removed **4.6 km of fiction
from a 1.61 km A32 walk** (24 Aug: 4602 m of network-stream path length across
a 1610 m route; 23 Aug was 6171 m). Worth knowing when weighing whether a gap
elsewhere is a deficiency — the comparison does not run one way only.

**Strava is explicitly not device-independent.** Their documentation says
accuracy "depends heavily on your specific phone model". So a per-device
calibration — the conversational "commit 5", which has no row in PROGRESS.md
yet — would be doing something they do not claim to do. **Whether that is an
edge or over-engineering for one user is untested**, and it stays untested until
there is a second receiver measured on the same loop. Do not treat the
observation as an argument for building it.

## Plan import, and the telemetry route that was rejected beside it. 2 Sep 2026

**Agreed: N4, plan import.** A user describes their situation to Claude or any
other LLM, gets a plan JSON back, and imports the file. No login, no backend, no
LLM inside the app — generation happens in their tool, the app only reads a
file.

**This is also how MY plan should change.** Right now a training-plan edit means
a code change and a rebuild, which is absurd for something adjusted every 8-12
weeks. That is the amendment: the same import path serves the single user it was
not originally written for, and it is the reason the requirement is worth
building at all rather than a feature for hypothetical strangers.

### REJECTED — telemetry / diagnostics upload

Considered as the way to gather captures from other devices and rejected.

For a capture to improve the model it has to reach me, and that means an
endpoint, storage, auth and a meaningful consent flow. That is a backend, which
ARCHITECTURE §1 refuses and which is the reason this app costs nothing to run.

**GPS traces are the most sensitive data class there is.** A walk reveals a
home, a gym and a routine. "Diagnostics collection" is not adequate consent for
location history, and no amount of wording makes a checkbox in a settings screen
into informed consent for that.

**The cheap equivalent.** A friend walks a MEASURED route and exports the three
files by hand — the C-9 share sheet already does this. Same data, no
infrastructure, unambiguous consent, and the person handing over the file knows
exactly what is in it because they can open it. Four devices once, not a
pipeline.

**And it is not needed for calibration anyway.** `sigma_step` is measured from
each walk locally (A1c-G), so every device calibrates itself from its own
evidence. Strava needs population data because they process server-side and
cannot measure the receiver at record time; that constraint is theirs and does
not transfer. The friends' captures would place exactly ONE threshold — where
measured noise stops justifying the filter, the open question in PROGRESS.md
A1c-15 — and one number does not need a distributed system.

**What would reopen this.** Nothing about scale or convenience. Only a finding
that the threshold cannot be placed from hand-carried captures at all.

## Overlapping street labels: it is the halo, not the renderer. 8 Sep 2026

Diagnosed before touching anything, against both suspects.

**(a) The recolour did not break placement.** Diffed all nineteen symbol layers
against the vendored upstream at `0dec594` (the pretty-print, which changed
nothing it said). `text-size`, `text-padding`, `symbol-spacing`,
`text-allow-overlap`, `icon-allow-overlap`, `text-max-angle`, every filter and
every zoom range are **byte-identical**. The only edits on any symbol layer are
`text-color`, `text-halo-color`, and one `text-halo-width` on
`highway-name-path` which went **up**, 0.5 to 1. Nothing that decides where a
label goes was touched.

**(b) The renderer implements collision, properly.** Read from
`flutter_map_vector_tiles-2.8.1` source, not assumed:
`render/label_painter.dart` builds a screen-space `_CollisionIndex` (128 px
grid buckets, `tryPlaceAll` all-or-nothing), places in priority order — style
layer, incumbency, `symbol-sort-key`, y, insertion — and reserves the
axis-aligned bounds of each rotated glyph box inflated by `text-padding`. Line
labels get **per-glyph** boxes when the line bends and one rotated box when it
does not. The AABB over-reserves, which errs toward dropping a label rather
than overlapping one. Collision is global across tiles, in one index for the
whole layer. `text-allow-overlap` and `icon-allow-overlap` are read and honoured.

The one approximation is deliberate and documented in that file: with label
fades on (the default, 150 ms) a full placement pass runs at most every 150 ms
and frames in between **replay** the frozen decision, so a camera drifting two
labels together between passes can show them overlapping for up to one interval.
Between passes only prior winners are laid out at all, so a newly published tile
cannot dump unfiltered labels on top. The file names this as the same trade
MapLibre makes, and it is: this is not a young-package gap.

**(c) What is actually wrong: `highway-name-minor` and `highway-name-major`
have no halo colour, and never did.** Both set `text-halo-width: 1` and
`text-halo-blur: 0.5` and specify **no `text-halo-color`**. The MapLibre spec
default is `rgba(0,0,0,0)` and `theme_reader.dart:165` implements exactly that,
so the halo is fully transparent and paints nothing. Upstream Positron got away
with it: `#666` on a near-white `#f8f4f0` ground with pale road fills is high
contrast on its own.

The recolour inverted the ground under them without inverting them. Street
labels are `#9DA1AC` and now lie along road ribbons that are **light**:

| label against | contrast |
|---|---|
| ground `#14151B` | 7.05:1 |
| minor road `#717A8A` | 1.67:1 |
| major road `#C8CEDA` | 1.64:1 |
| motorway `#F2F5FA` | 2.36:1 |

So a street name is legible where it crosses open ground and collapses where it
lies on the road it names, which is most of its length — and with no halo there
is nothing separating one label from the next either. That reads as merged text
even where placement is correct. `highway-name-path` is worse still and in a
different way: label and line are the **same colour**, `#8FBFB5`, 1.00:1.

**Fixed 9 Sep 2026, and the count was wrong: it is two layers, not three.**
`highway-name-path` already carries `text-halo-color: #14151B` — it was set
during the recolour, and the `text-halo-width` edit noted in (a) went with it.
Only `highway-name-minor` and `highway-name-major` had a width and no colour.
Both now take `#14151B`, the ground.

Measured after: label `#9DA1AC` to halo 7.05:1, and the halo clears every
surface a street name lies on — minor road 4.21:1, major 11.53:1, motorway
16.67:1. On open ground the ink carries it at 7.05:1 and the halo does not
need to, which is the same max(ink, halo) rule the route and the raw-fix cloud
already live by. `map_style_test` pins two things: that no symbol layer sets a
halo width without a colour, and that these two labels clear every ground by
ink or by halo.

**The path label's 1.00:1 stands as a raw number and is not the problem it
looks like.** It compares the label to its own line and ignores the halo that
was already painting between them. U-8 darkens the line to `#7DA89F`, which
lifts it to 1.29:1 as a side effect; the label stays `#8FBFB5`, because
lightening it to buy label-against-line would spend label-against-major-road,
and a path label lies on a path.

## The palette under colour-vision deficiency. 8 Sep 2026

Machado et al. (2009) severity-1.0 simulation, dE2000 in CIELab plus WCAG
luminance ratio. **Nothing that matters on the map separates by hue alone.**

**Route / start / finish all survive, everywhere.** Worst pair in any
simulation is start vs finish under tritanopia at dE 19.2; route vs finish under
deuteranopia is 23.2. Every marker also clears the ground by 9.3:1 or better, so
each is found by value before it is identified by hue — and after U-6 the two
markers are one split donut when they coincide, which is a shape.

**The road hierarchy separates by value and holds.** ground to minor 4.21:1,
minor to major 2.74:1, all four simulations within 0.1 of each other. Two pairs
sit close and both are close in normal vision too, so neither is a CVD finding:
major to motorway dE 9.3 (adjacent tones of one ramp, separated by stroke
width), and water `#2F4166` vs road casing `#39404E` dE 8.4 at 1.03:1 — that one
is worth knowing about generally, not under simulation. **Noted, not fixed,
9 Sep 2026:** stroke width separates them — the casing is a hairline under a
road and water is an area — and moving either would spend contrast the road
ramp and the raw-fix cloud are already using.

**One road pair does collapse under simulation only:** path `#8FBFB5` vs major
road `#C8CEDA`, dE 19.0 normal to **8.1 deuteranopia, 9.7 protanopia**. The
path's teal desaturates to a grey of nearly the same value. Paths are the thing
being looked at while running and they separate from major roads by hue more
than by width. **Changed 9 Sep 2026 — U-8, see below.**

**The app accents are a different story, and four pairs collapse.** These are UI
tints, not map elements, and each is worth checking against whether it is ever
the only cue:

- `plyo #C98BFF` vs `warmup #8B93FF` — **dE 0.89 protanopia, 4.97 deuteranopia,
  1.03:1 luminance.** Indistinguishable. They are the two `SectionHeader`
  accents on the Today and session screens and they appear on the same screen,
  one above the other. The headers carry their own text, so the colour is
  decoration rather than the cue — but these two are the same colour to a
  protanope and must not be used to mean anything on their own.
- `accentSuccess #C6FF33` vs `warning #FFB340` — dE 7.96 deuteranopia.
- `accentSecondary #22D3EE` vs `plyo #C98BFF` — dE 7.86 deuteranopia.
- `accentPrimary #FF3D9A` vs `danger #FF6B5E` — dE 5.72 **tritanopia**.

None of these four is on the map, and none is currently the sole carrier of a
distinction. **Recorded as U-10 on 9 Sep 2026, and the requirement is about
the next use rather than this one:** colour must NEVER encode meaning alone
anywhere in the app chrome. `plyo` and `warmup` are the same colour to a
protanope, so a future screen that told them apart by tint would be unreadable
and would look correct to everyone who checked it.

## Forest conditions: the stop threshold and the reorder buffer. 8 Sep 2026

Both questions came off one walk, so both were replayed across all five
captures. `test/capture_threshold_report_test.dart` regenerates every number
below.

### The stop threshold is not wrong; that walk is genuinely slow

| capture | median smoothed speed | x 0.5 m/s | elapsed | moving | stopped |
|---|---|---|---|---|---|
| 23 Aug A32 | 1.55 | 3.09 | 17:27 | 17:27 | 0:00 |
| 24 Aug A32 | 1.79 | 3.57 | 13:35 | 13:35 | 0:00 |
| 01 Sep S26 | 1.54 | 3.09 | 22:03 | 20:42 | 1:21 |
| 07 Sep Zurich | 1.37 | 2.74 | 50:58 | 28:38 | 22:20 |
| 08 Sep forest | **0.88** | **1.77** | 112:34 | 65:14 | 47:20 |

The forest walk is the outlier in **speed**, not in threshold behaviour. Its p90
is 1.32 m/s — the p10 of every other capture. Stopped time moves smoothly with
the threshold and there is no cliff at 0.5:

| threshold | 0.30 | 0.40 | 0.50 | 0.60 | 0.75 | 1.00 |
|---|---|---|---|---|---|---|
| 08 Sep forest, stopped | 42:08 | 44:44 | **47:20** | 49:32 | 52:50 | 64:50 |
| 07 Sep Zurich, stopped | 17:51 | 20:06 | **22:20** | 23:13 | 23:55 | 24:41 |

**And the disagreement with Strava does not point one way.** On Zurich ours is
STRICTER (moving 28:38 against Strava's 30:14); on the forest walk ours is
LAXER (65:14 against 53:29). One threshold cannot be moved to fix both — they
are errors in opposite directions — which is evidence that Strava is not
applying a plain speed threshold at all, rather than evidence that 0.5 is
mis-set. Matching Strava on the forest walk alone needs 0.75 to 1.00 m/s, which
would push Zurich from 2:28 too strict to nearly 4:00 too strict.

**Left at 0.5.** The threshold is doing what it says at every value tested; what
the forest walk shows is that a walk can sit at 1.77x it, not that the number is
wrong.

### The 172 "past the buffer" fixes are not data loss

They cost nothing. Replayed at eight horizons, `accepted` is **6594 on every
one** and the distance is 4532 m on every one. The rejection counts show where
they go:

```
  0s accepted 6594   coldStart 3, accuracy 1377
  3s accepted 6594   coldStart 3, accuracy 1205, arrivedTooLate 172
  5s accepted 6594   coldStart 3, accuracy 1376, arrivedTooLate 1
  8s accepted 6594   coldStart 3, accuracy 1377
```

1205 + 172 = 1377 exactly. Every fix filed under `arrivedTooLate` is a fix the
accuracy gate would have thrown out one step later. Their reported accuracy is
min 13.1 m, **median 400 m, p90 1100 m, max 1700 m** — the network stream, not
the receiver.

**That is the general finding, and it holds on every capture.** Late arrival is
a property of the other producer:

| capture | late fixes | median accuracy, late | median accuracy, on time |
|---|---|---|---|
| 23 Aug A32 | 109 | 26.4 m | 2.5 m |
| 24 Aug A32 | 73 | 29.4 m | 2.5 m |
| 01 Sep S26 | 63 | 100.0 m | 3.8 m |
| 07 Sep Zurich | 324 | 500.0 m | 3.8 m |
| 08 Sep forest | 897 | 200.0 m | 3.8 m |

Out-of-order delivery is a **signature of network positioning**, which is
computed asynchronously and handed over whenever it resolves. The reorder
buffer's job was always the GPS stream, and on the GPS stream nothing has ever
arrived late enough to lose: `lost` is 0, 1, 0, 2, 172 across the five, and the
172 are all the other producer.

**How late they were:** lag p50 3.24 s, p90 3.51 s, max 5.00 s. A 5 s horizon
catches all but one; 8 s catches everything. **The cost of raising it is 5
seconds of live-stats latency** and nothing else — the saved track does not care
when it was computed, and at ~1.2 fix/s the `maxBufferedFixes = 64` cap does not
bind until past 50 s.

**Not raised, because it buys nothing measurable.** It would relabel 172
rejections from `arrivedTooLate` to `accuracy` and add 5 s of lag to the live
screen. The one thing it WOULD buy is a diagnostics file that does not report a
frightening number for a benign condition, and that is better fixed by reading
this note than by delaying every live update by five seconds.

### Known behaviour under canopy: the pipeline bridges outages with straight lines

Recorded, not fixed. The 8 Sep capture has a **100 s gap in the ACCEPTED
stream** and a **39.4 m step over 35.0 s** at 12:13:53 UTC. Nothing is wrong
with either: under forest canopy the receiver loses lock, every fix delivered
during the outage is network-stream and correctly rejected, and the next
accepted fix is joined to the previous one by a straight line because that is
what a polyline between two points is.

The consequences are worth knowing. Distance across a gap is a **chord**, so a
curved path walked during an outage is under-measured. The moving/stopped
decision looks back 10 s, so a 100 s gap is decided by two fixes 100 s apart.
And the map draws a straight segment through whatever was actually walked. The
alternative — marking the track as broken across a gap — is a real design
question and is not open work until someone asks for it.

**A building does the same thing and does it harder, 9 Sep 2026.** The 8 Sep
shop capture's largest accepted step is **99.7 m over 117.0 s**, against the
forest's 39.4 m over 35.0 s under canopy. Both are the same mechanism and
neither is a defect; what differs is how long the receiver was gone. Two
consequences are worth stating as a pair, because they compound:

- The chord under-measures a curved route, and the longer the outage the more
  route there is to cut across. 117 s of walking reduced to a 99.7 m straight
  line is most of a shop's aisles rendered as one segment.
- The moving/stopped decision looks back 10 s, so across that step it is
  decided by **two fixes 117 s apart** — a window of 10 s reading an interval
  of two minutes. The decision is not wrong so much as unsupported: there is
  nothing in the 10 s it wants to look at.

The distance consequence and the stopped-time consequence pull in opposite
directions, which is why neither shows up as an obviously bad number.

## The start/finish markers: what the asymmetry was for. 8 Sep 2026

Superseded by U-6, recorded because the reasoning is not obvious from the
symmetric pair that replaced it and a later tidy-up would reach for exactly the
wrong repair.

**The pair was asymmetric on purpose.** A thin finish ring with a filled start
disc drawn inside it, finish first so the start lands on top. On a loop the two
coordinates coincide and two identical markers there means one hides the other;
a ring around a dot survives being concentric. That case is real and loops are
the common route here.

**Why it was reversed.** It solved the loop by making the finish permanently
worse — on every run that is not a loop, a hairline ring beside a solid disc
reads as an unfinished pair. Paying on every run for a case that happens
sometimes is the wrong trade.

**What replaced it.** The same asymmetry, but only when it is needed: within
15 m the pair becomes one donut split down the middle, start colour left,
finish colour right. A perpendicular offset was the alternative and lost on
three counts — this screen is read by comparing a smoothed line against the raw
fixes under it, so a marker drawn away from its own coordinate is the artefact
that reading looks for; an offset large enough to see has to be in pixels, so
the markers would slide apart as the map is pinched; and the coincidence is
itself information (the run was a loop) which the split states and separation
would hide.

**The threshold is marginal and that is measured, not assumed.** The same
1610 m loop closes to 11.1 m on 23 Aug and 31.8 m on 24 Aug. At 15 m it
combines on one of those walks and not the other. **Decided 9 Sep 2026: 35 m**
(U-9). One route, one receiver, two afternoons and two different pictures is
the worst of the available outcomes, because it makes the marker report the
closing error rather than the route. `run_map_test` pins both ends — 11.1 and
31.8 m combine, 60 m does not.

## 68.5% acceptance is the lowest recorded, and it is not a fault. 9 Sep 2026

The 8 Sep shop walk accepted 3034 of 4428 delivered fixes. Every capture
before it sits higher, and the reflex on seeing a third of the stream thrown
away is to look for a filter that has gone wrong.

**The accepted median accuracy on that same run is 3.79 m, with a p90 of
3.79 m.** A pipeline eating good fixes does not leave a distribution like
that; what it leaves is a low count of excellent fixes, which is exactly what
this is. The 1318 rejections are the other producer supplying positions while
the receiver had no sky — 900 of the 4428 delivered fixes carry fractional
timestamps, and their median is 17.49 m against the ceiling of 9.

So the rate is a measurement of the environment and not of the filter:
**a low acceptance rate beside a healthy accepted median is an environment
signal.** That sentence now prints in the diagnostics report itself (A1c-K),
because the alternative was that reading the number correctly depended on
having read this file.

## `run_points.speedMps` is NOT trustworthy for runs before 9 Sep 2026

The receiver's Doppler speed was unbounded on the way in until this date. The
recorder refused the plugin's negative "not available" sentinel and passed
everything else through, and the DAO wrote it per point — so `run_points` holds
values up to **39708 m/s** on fixes whose positions are perfectly good. The
implied-speed filter bounds a pair of POSITIONS and never looked at this field.

Measured across the six captures: 537 accepted fixes would have been stored
with an impossible speed — 340 on the forest walk, 158 on Zurich, 23 on
23 Aug. It is bounded at the pipeline boundary now, against `maxSpeedMps`, and
stored as **null rather than clamped**.

**Recorded runs are not rewritten, and that is deliberate.** Recorded data is
evidence; rewriting it to look correct is the one thing this project has been
most careful never to do. The consequence has to be carried instead of erased:

**A7, a pace chart, an export or anything else reading `run_points.speedMps`
must not trust that column for a run recorded before 9 Sep 2026.** There is no
flag on the row that says so — the run's own timestamp is the only
discriminator. If a consumer ever needs this column across old runs, the
honest options are to bound it at read time or to ignore it, never to repair
the stored value.

The pipeline itself never used the column, which is why this survived six
captures unnoticed: nothing that produced a visible number was reading it.

## MapLibre GL native: rejected, with the estimate. 9 Sep 2026

Recorded so the question is not reopened from memory in three months.

**7–11 days**, and the wide end is what makes it a no. It is the loss of 31
map tests in a repo whose whole method is an oracle before a fix, plus a
second location consumer on the one screen A2-5 exists to keep
single-sourced — the live map draws the causal filter's output and nothing
else, and a renderer with its own location plumbing cuts against that.

**The strongest argument for it was mine and it was wrong.** The overlapping
street labels are a halo bug, not a collision-engine gap. The halo bug lives
in the style document, so it would migrate to MapLibre along with the style
and arrive unchanged on the other side. Migrating would not have fixed the
thing it was being proposed to fix.

**And the premise under it — "young package, weak placement" — is false.**
Read from `flutter_map_vector_tiles-2.8.1` source rather than assumed:
`render/label_painter.dart` builds a screen-space `_CollisionIndex` in 128 px
buckets with an all-or-nothing `tryPlaceAll`, places in priority order (style
layer, incumbency, `symbol-sort-key`, y, insertion), reserves the
axis-aligned bounds of each rotated glyph box inflated by `text-padding`,
gives line labels per-glyph boxes when the line bends, keeps one index global
across tile borders, and reads and honours `text-allow-overlap` and
`icon-allow-overlap`. Its one approximation is documented in that file: with
label fades on, a full placement pass runs at most every 150 ms and the frames
between replay the frozen decision, so a camera drifting two labels together
can show them overlapping for up to one interval. **That is the same trade
MapLibre makes**, and between passes only prior winners are laid out at all,
so a newly published tile cannot dump unfiltered labels on top.

The estimate stands on its own without those two arguments, and without them
there is nothing on the other side of it.

## REPORT ONLY A — is the indoor case separable from the fiction case?

9 Sep 2026, from the 8 Sep shop walk. Nothing here is wired in and no constant
moved. `test/network_stream_report_test.dart` regenerates every number.

The capture is committed at `captures/run_fixes_20260908-162309.ndjson`, the
sixth in the set and the first recorded indoors.

### The network stream is a different instrument in every environment

Fractional-timestamp fixes only, which is how `StreamDetector` itself
classifies — so this is the shipped pipeline's own idea of "the other
producer", not a second rule invented for the report.

| capture | n | min | p25 | med | p75 | max |
|---|---|---|---|---|---|---|
| 23 Aug A32 | 154 | 9.60 | 20.82 | 26.82 | 41.72 | 200 |
| 24 Aug A32 | 94 | 4.20 | 23.26 | 29.79 | 47.63 | 109 |
| 01 Sep S26 | 68 | 11.56 | 19.35 | 100.00 | 100.00 | 200 |
| 07 Sep Zurich | 362 | 12.99 | 200.00 | **500.00** | 800.00 | 1700 |
| 08 Sep forest | 1000 | 12.44 | 100.00 | **200.00** | 400.00 | 1781 |
| 08 Sep shop | 900 | 10.01 | 14.32 | **17.49** | 23.37 | 300 |

Percentage of each capture's network stream at or under a ceiling:

| ceiling | 9 m | 16 m | 20 m | 25 m | 30 m | 50 m |
|---|---|---|---|---|---|---|
| 23 Aug A32 | 0.0% | 7.8% | 20.8% | 45.5% | 59.7% | 78.6% |
| 24 Aug A32 | 1.1% | 9.6% | 17.0% | 30.9% | 52.1% | 76.6% |
| 01 Sep S26 | 0.0% | 19.1% | 26.5% | 32.4% | 33.8% | 33.8% |
| 07 Sep Zurich | 0.0% | 1.7% | 4.4% | 6.9% | 9.9% | 10.5% |
| 08 Sep forest | 0.0% | 3.0% | 5.4% | 7.1% | 7.9% | 9.7% |
| **08 Sep shop** | 0.0% | **34.3%** | **64.3%** | **78.4%** | 86.2% | 94.4% |

**An accuracy ceiling ALONE does not separate them.** At 20 m the shop admits
64% of its network stream — and the A32 walks admit 17–21% of theirs, on the
two routes whose length is known. Those are the fixes that traced 6171 m over
a 1610 m walk. A ceiling is a quality band, and the thing that has to be
separated is an environment.

### The gap gate does separate them, and it is the whole result

Gaps in the ACCEPTED stream, by horizon:

| capture | >1 min | >2 min | >5 min | >10 min |
|---|---|---|---|---|
| 23 Aug A32 | 0 | 0 | 0 | 0 |
| 24 Aug A32 | 0 | 0 | 0 | 0 |
| 01 Sep S26 | 0 | 0 | 0 | 0 |
| 07 Zurich | 0 | 0 | 0 | 0 |
| 08 forest | 1 (13 m) | 0 | 0 | 0 |
| 08 shop | 4 (170 m) | 3 (71 m) | 3 (71 m) | 2 (53 m) |

**No outdoor capture in the set has a single two-minute gap in the accepted
stream.** The forest walk under canopy has one gap over a minute and none over
two. So a rule gated on "GPS absent for over 2 minutes" fires on the shop
capture and on nothing else, and the fiction it admits on the four outdoor
captures is exactly zero — the ground-truth errors are unchanged at every
ceiling: 23 Aug +3.5%, 24 Aug −0.1%, 01 Sep +0.8%, identical from 9 m to 50 m
because no gap qualifies for the rule to act on.

### What the reconstruction actually produces indoors

The three qualifying gaps: the chord the pipeline draws, against the network
fixes inside them chained in timestamp order — raw haversine, no smoothing,
which is an upper bound on what admitting them could produce.

| gap | chord | n(net) | 16 m | 20 m | 25 m | 50 m |
|---|---|---|---|---|---|---|
| 21:38 | 26.7 m | 215 | 327 | 586 | 599 | 659 |
| 17:59 | 26.5 m | 187 | 466 | 667 | 684 | 685 |
| 6:19 | 17.3 m | 66 | 47 | 149 | 220 | 220 |

Run total against the 2416 m shipped: 3186 m at 16 m, **3749 m at 20 m**,
3910 m at 50 m.

**Against the 500–750 m estimate, the 20 m ceiling roughly doubles it.** The
three gaps chain 1402 m where 500–750 m was walked. The 16 m ceiling chains
840 m, which lands at the top of the estimate — and Strava, on the same walk,
read 2.92 km against our 2.42 km, a difference of ~500 m, so Strava's own
reconstruction is more conservative than either. Chaining 1 Hz fixes with
~15 m of independent error inflates a slow walk; it is the same mechanism that
makes a raw accepted total longer than the smoothed one, and it is worse here
because the fixes are worse and the walking is slower.

### The answer, and the ruling: INVESTIGATED AND REJECTED

**Rejected 9 Sep 2026.** Not deferred and not an open idea — measured, and
turned down on the numbers above. The full record is PROGRESS.md A1c-M; this
section is the measurement that produced it.

**Separable, on this evidence, and the separation is carried entirely by the
gap gate rather than by the accuracy ceiling.** The mechanism is real and not
a coincidence of these six files: indoors means no sky, which means a long GPS
outage, and it means dense wifi, which is what makes network positioning good.
The two conditions arrive together because they have the same cause.

**What has not been tested is the false positive, and that is the one that
matters.** No outdoor capture here has a long outage, so nothing in this set
exercises the rule firing outdoors. Zurich's network median is 500 m; a
tunnel, a station or a dense street canyon that killed GPS for two minutes
would hand that rule 500 m fixes, and 4.4% of Zurich's network stream is
already under 20 m, so the ceiling would not save it. The rule is unfalsified
rather than demonstrated safe, and the capture that would falsify it has not
been walked.

And it is poor even where it is meant to work: 1402 m chained across the three
indoor gaps where 500–750 m was walked, roughly double, with the 16 m ceiling
landing on the estimate only because the estimate is what it was compared to.

**Not built, and not to be started without new evidence. The one thing that
would reopen it is a capture containing a long OUTDOOR GPS outage** — a
tunnel, an underpass, a station, a real street canyon — with the receiver
absent from the accepted stream for over two minutes and network fixes
arriving throughout. That is the falsification test this rule has never faced.
Another indoor walk only re-confirms the half that already passes.

## REPORT ONLY B — the pace-relative stop threshold, and why it fails

9 Sep 2026. The earlier "leave it at 0.5, the evidence is decisive" ruling was
made on two captures disagreeing in opposite directions and is disregarded, as
instructed. A third capture makes it a trend rather than noise. Every number
below comes from `test/capture_threshold_report_test.dart`.

`minMovingSpeedMps` does not move. What follows is why.

### 0.5 m/s as a fraction of each walk's own pace

The smoothed-speed median is measured per accepted fix, before any
moving/stopped decision, so a threshold set from it is not circular.

| capture | med speed | 0.5 is | ours | Strava | delta |
|---|---|---|---|---|---|
| 23 Aug A32 | 1.55 | 0.32x | 17:27 | — | — |
| 24 Aug A32 | 1.79 | 0.28x | 13:35 | — | — |
| 01 Sep S26 | 1.54 | 0.32x | 20:42 | — | — |
| 07 Sep Zurich | 1.37 | 0.37x | 28:38 | 30:14 | −1:36 |
| 08 Sep forest | 0.88 | 0.57x | 65:14 | 53:29 | +11:45 |
| 08 Sep shop | 0.79 | 0.63x | 32:01 | 26:16 | +5:45 |

**Three anchors, not six.** The A32 pair and the first S26 walk were recorded
without a Strava activity beside them, and a moving time cannot be recovered
from a distance. That is a limit of the evidence rather than an omission.

### The pace-relative rule moves in the WRONG DIRECTION

Moving time at k x each run's own median, signed error against Strava:

| capture | 0.20x | 0.25x | 0.30x | 0.35x | 0.40x | shipped 0.5 |
|---|---|---|---|---|---|---|
| Zurich | +3:21 | +1:55 | +0:18 | −1:18 | −2:09 | −1:36 |
| forest | +23:00 | +20:03 | +18:06 | +16:35 | +15:29 | **+11:45** |
| shop | +8:06 | +7:24 | +7:16 | +7:07 | +6:54 | **+5:45** |

The forest and shop walks already count too MUCH as moving. Correcting them
needs a HIGHER threshold. Scaling to pace gives a slow walk a LOWER one —
0.88 x 0.30 = 0.27 against the shipped 0.5 — so it makes the two captures the
trend was drawn from worse, not better. At both requested multipliers, 0.25x
and 0.35x, every one of the three anchors is worse than or level with the
fixed 0.5. **The hypothesis predicts the wrong sign.**

A floor changes nothing here. Below 0.35 m/s no floor binds on any capture,
and at 0.35 the floor IS the threshold on both slow walks — which is a fixed
threshold wearing a scaling's clothes.

### The threshold that actually matches Strava, by bisection

| capture | med speed | fits at | as a fraction |
|---|---|---|---|
| 07 Sep Zurich | 1.37 | 0.42 | 0.31x |
| 08 Sep forest | 0.88 | 0.90 | **1.02x** |
| 08 Sep shop | 0.79 | 0.77 | **0.98x** |

**If Strava scaled to pace, that last column would be a constant. It is not.**
And the two values that agree, agree at ~1.00x, which is a degenerate rule:
setting the threshold to a walk's own median speed calls about half of it
stopped by construction. Two walks landing there is what a coincidence looks
like, not what a scaling law looks like.

Nor does a fixed value fit all three: the forest wants ~0.90, the shop ~0.77,
Zurich ~0.42. At 0.75 the two slow walks come to +6:15 and +0:46 and Zurich
goes to −3:11.

**Said plainly, as asked: no pace-relative rule fits where a fixed one does
not. The shipped 0.5 stays, and the reason it stays has changed** — it was
held on an absence of evidence and is now held on a measurement. PROGRESS.md
A1c-L carries the ruling. What the three anchors show is that Strava is
not applying a plain speed threshold at all — which is the conclusion the
earlier ruling reached from weaker evidence, and it survives the third capture
that was meant to overturn it.

## An audit's "dead" finding is a hypothesis. 19 Sep 2026

The September audit reported `AppTypography.title2` as dead. It is not:
`app_theme.dart` sets it as the Cupertino picker and date-picker text style.
The token sweep excluded `lib/app/theme/` so that each token's own declaration
would not count as a use of itself, and that exclusion also removed the only
consumer, which lives in the same directory. The sweep then reported the
absence of a use it had been configured not to see. Deleting the token and
building is what caught it; the correction is recorded in place in AUDIT-2.md
§3.

**Same class as the August audit's ~545-line misattribution.** That audit
called code "no traceable requirement" because the requirements had been agreed
in conversation, which leaves no trace in the repo it was reading. Both times an instrument blind to a category of
evidence reported an absence of that evidence, and the report read exactly as
a real absence would have. Nothing in either output said which categories the
method could not see.

This is not the green-test list above. Those are checks that pass without
measuring anything; this is a search that returns nothing because of where it
was not allowed to look. The fix for one is a fixture that can fail; the fix
for the other is a test that can contradict the finding.

**The rule: an audit's "dead" finding is a hypothesis, and deleting and
building is the test.** A sweep can nominate candidates. Only removing the
thing and running the build (and the suite) establishes that nothing consumed
it — and a report that has not done that should say "unreferenced by this
search", naming what the search excluded, rather than "dead".
