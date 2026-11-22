// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'run_recording_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(runDao)
final runDaoProvider = RunDaoProvider._();

final class RunDaoProvider extends $FunctionalProvider<RunDao, RunDao, RunDao>
    with $Provider<RunDao> {
  RunDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'runDaoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$runDaoHash();

  @$internal
  @override
  $ProviderElement<RunDao> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RunDao create(Ref ref) {
    return runDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RunDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RunDao>(value),
    );
  }
}

String _$runDaoHash() => r'c0335097f78e37f831574b619eb91dc5bbff60c1';

/// The GPS boundary.
///
/// A provider rather than a direct construction so tests can replace it with
/// the fake, exactly as `healthRepository` exists for Health Connect. Nothing
/// below this line is reachable off a device.

@ProviderFor(runRecorder)
final runRecorderProvider = RunRecorderProvider._();

/// The GPS boundary.
///
/// A provider rather than a direct construction so tests can replace it with
/// the fake, exactly as `healthRepository` exists for Health Connect. Nothing
/// below this line is reachable off a device.

final class RunRecorderProvider
    extends $FunctionalProvider<RunRecorder, RunRecorder, RunRecorder>
    with $Provider<RunRecorder> {
  /// The GPS boundary.
  ///
  /// A provider rather than a direct construction so tests can replace it with
  /// the fake, exactly as `healthRepository` exists for Health Connect. Nothing
  /// below this line is reachable off a device.
  RunRecorderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'runRecorderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$runRecorderHash();

  @$internal
  @override
  $ProviderElement<RunRecorder> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RunRecorder create(Ref ref) {
    return runRecorder(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RunRecorder value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RunRecorder>(value),
    );
  }
}

String _$runRecorderHash() => r'e106650cb2b183df889b7068b9a1f430167f7601';

/// The pressure boundary, for elevation gain (A6-1). A provider for the same
/// reason as [runRecorder]: tests replace it, and nothing below it runs off a
/// device.

@ProviderFor(barometer)
final barometerProvider = BarometerProvider._();

/// The pressure boundary, for elevation gain (A6-1). A provider for the same
/// reason as [runRecorder]: tests replace it, and nothing below it runs off a
/// device.

final class BarometerProvider
    extends $FunctionalProvider<Barometer, Barometer, Barometer>
    with $Provider<Barometer> {
  /// The pressure boundary, for elevation gain (A6-1). A provider for the same
  /// reason as [runRecorder]: tests replace it, and nothing below it runs off a
  /// device.
  BarometerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'barometerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$barometerHash();

  @$internal
  @override
  $ProviderElement<Barometer> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Barometer create(Ref ref) {
    return barometer(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Barometer value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Barometer>(value),
    );
  }
}

String _$barometerHash() => r'afa8bc90e5d60fcd0292608fbbdd4e2905691ae3';

/// Drives a recording: recorder in, pipeline in the middle, database at the end.
///
/// The controller owns the [TrackProcessor] for the length of one run and
/// throws it away afterwards. The processor accumulates state by design and
/// reusing one across runs would silently join two runs into one.

@ProviderFor(RunRecording)
final runRecordingProvider = RunRecordingProvider._();

/// Drives a recording: recorder in, pipeline in the middle, database at the end.
///
/// The controller owns the [TrackProcessor] for the length of one run and
/// throws it away afterwards. The processor accumulates state by design and
/// reusing one across runs would silently join two runs into one.
final class RunRecordingProvider
    extends $NotifierProvider<RunRecording, RunRecordingState> {
  /// Drives a recording: recorder in, pipeline in the middle, database at the end.
  ///
  /// The controller owns the [TrackProcessor] for the length of one run and
  /// throws it away afterwards. The processor accumulates state by design and
  /// reusing one across runs would silently join two runs into one.
  RunRecordingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'runRecordingProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$runRecordingHash();

  @$internal
  @override
  RunRecording create() => RunRecording();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RunRecordingState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RunRecordingState>(value),
    );
  }
}

String _$runRecordingHash() => r'4a042d37ecce4acba9f385a9d87158174e75268f';

/// Drives a recording: recorder in, pipeline in the middle, database at the end.
///
/// The controller owns the [TrackProcessor] for the length of one run and
/// throws it away afterwards. The processor accumulates state by design and
/// reusing one across runs would silently join two runs into one.

abstract class _$RunRecording extends $Notifier<RunRecordingState> {
  RunRecordingState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<RunRecordingState, RunRecordingState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RunRecordingState, RunRecordingState>,
              RunRecordingState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
