import 'package:fitness_tracker/app/debug/effective_clock.dart';
import 'package:fitness_tracker/data/models/health_models.dart';
import 'package:fitness_tracker/data/providers/database_providers.dart';
import 'package:fitness_tracker/features/settings/widgets/health_diagnostics_section.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'support/fake_health_repository.dart';

void main() {
  late FakeHealthRepository health;

  // Pinned through the effective clock, so the report's windows are fixed
  // rather than whatever date the test machine happens to be on.
  final today = DateTime(2026, 8, 19);
  final stamp = DateFormat('yyyy-MM-dd HH:mm:ss');

  setUp(() {
    health = FakeHealthRepository();
  });

  Widget wrap() => ProviderScope(
    overrides: [
      healthRepositoryProvider.overrideWithValue(health),
      effectiveClockProvider.overrideWithValue(EffectiveClock(today)),
    ],
    child: const CupertinoApp(
      home: CupertinoPageScaffold(
        child: SingleChildScrollView(child: HealthDiagnosticsSection()),
      ),
    ),
  );

  Future<void> pumpFrames(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  testWidgets('prints the query window in both local time and UTC', (
    tester,
  ) async {
    health.setDay(today, steps: 1008);

    await tester.pumpWidget(wrap());
    await pumpFrames(tester);

    final midnight = DateTime(2026, 8, 19);
    expect(
      find.textContaining('${stamp.format(midnight)} local'),
      findsOneWidget,
    );
    expect(
      find.textContaining('${stamp.format(midnight.toUtc())} UTC'),
      findsOneWidget,
      reason:
          'the UTC half is the whole point — a timezone mismatch is '
          'invisible with only one of the two',
    );
  });

  testWidgets('separates an empty store from a refused permission', (
    tester,
  ) async {
    // Granted, and the platform genuinely has nothing. The Today screen shows
    // exactly the same empty ring for this as for a refusal.
    await tester.pumpWidget(wrap());
    await pumpFrames(tester);

    expect(find.textContaining('STEPS  granted: true'), findsOneWidget);
    expect(find.textContaining('0 record(s)'), findsWidgets);
  });

  testWidgets('names the source package of every raw record', (tester) async {
    // Samsung Health writes one steps record per day and updates it in place,
    // so a single long record is the expected shape, not a symptom.
    health
      ..setDay(today, steps: 1008)
      ..stepRecords = [
        HealthRecordSample(
          start: today,
          end: today.add(const Duration(hours: 14)),
          value: '1008',
          unit: 'COUNT',
          sourcePackage: 'com.sec.android.app.shealth',
          recordingMethod: 'automatic',
        ),
      ];

    await tester.pumpWidget(wrap());
    await pumpFrames(tester);

    expect(find.textContaining('1 record(s)'), findsOneWidget);
    expect(
      find.textContaining('com.sec.android.app.shealth · automatic'),
      findsOneWidget,
    );
    expect(find.textContaining('1008 COUNT'), findsOneWidget);
  });

  testWidgets('shows a read failure rather than an empty list', (tester) async {
    health.availabilityResult = HealthAvailability.notInstalled;

    await tester.pumpWidget(wrap());
    await pumpFrames(tester);

    expect(find.textContaining('SDK status:'), findsOneWidget);
    expect(find.textContaining('Mapped to:    notInstalled'), findsOneWidget);
  });
}
