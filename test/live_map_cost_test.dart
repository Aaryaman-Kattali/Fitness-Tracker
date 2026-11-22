import 'package:drift/native.dart';
import 'package:fitness_tracker/data/db/app_database.dart';
import 'package:fitness_tracker/data/providers/database_providers.dart';
import 'package:fitness_tracker/features/activity/providers/run_diagnostics_provider.dart';
import 'package:fitness_tracker/features/activity/providers/run_recording_provider.dart';
import 'package:fitness_tracker/features/activity/widgets/run_map.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'support/fake_barometer.dart';
import 'support/fake_diagnostics_store.dart';
import 'support/fake_run_recorder.dart';
import 'support/synthetic_track.dart';

/// What a two-hour run costs the live map, measured rather than assumed.
///
/// The question this file exists to answer is whether the displayed track
/// needs decimating. It is asked here rather than settled by writing a
/// decimator, because flutter_map already simplifies what it draws — the
/// PolylineLayer runs Douglas-Peucker at a 0.3 px tolerance on every camera
/// change (`layer_projection_simplification/widget.dart:26`) and caches the
/// result. A second decimator on top of that is machinery for a cost nobody
/// has measured.
///
/// The bounds asserted below are deliberately loose. They are regression
/// tripwires for an order-of-magnitude change, not performance budgets; the
/// measured numbers printed alongside them are the actual finding, and a
/// number that drifts by 30% means the machine was busy, not that the code
/// changed. Timing in a test suite is evidence, not a gate.
void main() {
  /// A two-hour walk at 1 Hz, which is what the pipeline delivers on the
  /// device: 1.000 s between GPS fixes, ~1.6 m/s.
  ///
  /// Straight rather than shaped, because the cost being measured is per
  /// point — projection and list traversal — and geometry does not change it.
  /// Curvature would change how much Douglas-Peucker can throw away, which
  /// would flatter the result rather than stress it.
  List<LatLng> twoHourWalk() {
    const seconds = 7200;
    const metresPerSecond = 1.6;
    const metresPerDegreeLat = 111320.0;
    return [
      for (var i = 0; i < seconds; i++)
        LatLng(19.2183 + i * metresPerSecond / metresPerDegreeLat, 72.9781),
    ];
  }

  testWidgets('a two-hour track redraws in well under a frame', (tester) async {
    final route = twoHourWalk();
    expect(route, hasLength(7200));

    Future<void> pumpWith(List<LatLng> points) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: SizedBox(
            height: 800,
            width: 400,
            child: RunMap(route: points, currentPosition: points.last),
          ),
        ),
      );
    }

    // The first build is not the case of interest — it includes creating the
    // map, the tile layer and the camera. What happens once a second during a
    // run is the SECOND build: one more point on an existing map.
    await pumpWith(route.sublist(0, route.length - 1));
    await tester.pump(const Duration(milliseconds: 100));

    final watch = Stopwatch()..start();
    await pumpWith(route);
    watch.stop();

    // The measured number is the deliverable here, not the bound below it —
    // printing it is the point of the test.
    // ignore: avoid_print
    print(
      'live redraw at 7200 points: ${watch.elapsedMicroseconds / 1000} ms',
    );

    expect(
      watch.elapsedMilliseconds,
      lessThan(100),
      reason:
          'the redraw happens once per fix, so 1 Hz gives it a full second. '
          'A hundred milliseconds is a 10x tripwire, not a budget.',
    );
  });

  test('the live polyline is extended, never rebuilt', () async {
    // The O(n^2) this replaced. Publishing the live route by rebuilding the
    // LatLng list on every accepted fix costs sum(1..n) allocations over a
    // run — ~26 million on a two-hour walk, to add 7200 points.
    //
    // Asserted structurally rather than by a stopwatch. Two timings a few
    // milliseconds apart cannot tell O(n) from O(n^2) on a machine that is
    // also doing something else.
    //
    // The discriminator is that an EARLY published route keeps growing. It is
    // a window onto the controller's own list, so it ends the run the same
    // length as the last one; a rebuilt copy would be frozen at the length it
    // had when it was made. This is the deliberate non-immutability in
    // RunRecordingState.route, stated as a test so it cannot be "fixed" by
    // someone tidying a copy back in.
    //
    // An earlier version of this test compared the LatLng at index 0 by
    // identity. That passed against a rebuilt list too — List.of copies the
    // list and keeps the elements — so it was verifying nothing. Found by
    // mutation, which is the only reason it is not still here.
    final db = AppDatabase(NativeDatabase.memory());
    final recorder = FakeRunRecorder(fiveAndAHalfKm());
    addTearDown(db.close);
    addTearDown(recorder.dispose);

    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        runRecorderProvider.overrideWithValue(recorder),
        barometerProvider.overrideWithValue(FakeBarometer.absent()),
        runDiagnosticsStoreProvider.overrideWithValue(
          FakeRunDiagnosticsStore(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final published = <List<LatLng>>[];
    container.listen(
      runRecordingProvider,
      (_, next) => published.add(next.route),
    );

    await container.read(runRecordingProvider.notifier).start();

    final withPoints = published.where((route) => route.isNotEmpty).toList();
    expect(
      withPoints.length,
      greaterThan(1000),
      reason: 'this has to be a run long enough for rebuilding to show',
    );

    expect(
      withPoints.first.length,
      withPoints.last.length,
      reason:
          'the route published on the first fix is a window onto the live '
          'list, so by the end of the run it holds the whole track. A rebuilt '
          'copy would still be one point long.',
    );
    expect(
      withPoints.first.last,
      withPoints.last.last,
      reason: 'the same window, so the same last point',
    );
  });
}
