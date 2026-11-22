import 'package:fitness_tracker/app/debug/effective_clock.dart';
import 'package:fitness_tracker/data/models/health_models.dart';
import 'package:fitness_tracker/data/providers/database_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'health_diagnostics_provider.g.dart';

/// The debug Health Connect read-out.
///
/// Autodisposed and never kept alive: it is only ever on screen while someone
/// is looking at it, and every value in it can change outside the app.
@riverpod
class HealthDiagnosticsPanel extends _$HealthDiagnosticsPanel {
  @override
  Future<HealthDiagnostics> build() => ref
      .watch(healthRepositoryProvider)
      .diagnose(now: ref.watch(effectiveClockProvider).now());

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(build);
  }

  /// Re-opens the Health Connect permission sheet, then re-reads everything.
  Future<void> requestPermissions() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(healthRepositoryProvider).requestPermissions();
      return build();
    });
  }
}
