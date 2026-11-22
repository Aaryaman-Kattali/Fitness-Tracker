// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'run_history_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Every recorded run, newest first, as a live query.
///
/// Watched rather than fetched so that finishing a run puts it in the list
/// without anyone having to know to refresh.

@ProviderFor(runHistory)
final runHistoryProvider = RunHistoryProvider._();

/// Every recorded run, newest first, as a live query.
///
/// Watched rather than fetched so that finishing a run puts it in the list
/// without anyone having to know to refresh.

final class RunHistoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<RunSummary>>,
          List<RunSummary>,
          Stream<List<RunSummary>>
        >
    with $FutureModifier<List<RunSummary>>, $StreamProvider<List<RunSummary>> {
  /// Every recorded run, newest first, as a live query.
  ///
  /// Watched rather than fetched so that finishing a run puts it in the list
  /// without anyone having to know to refresh.
  RunHistoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'runHistoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$runHistoryHash();

  @$internal
  @override
  $StreamProviderElement<List<RunSummary>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<RunSummary>> create(Ref ref) {
    return runHistory(ref);
  }
}

String _$runHistoryHash() => r'6df058a19ef64715011db136d4253d44e0047887';

@ProviderFor(runDetail)
final runDetailProvider = RunDetailFamily._();

final class RunDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<RunDetail>,
          RunDetail,
          FutureOr<RunDetail>
        >
    with $FutureModifier<RunDetail>, $FutureProvider<RunDetail> {
  RunDetailProvider._({
    required RunDetailFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'runDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$runDetailHash();

  @override
  String toString() {
    return r'runDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<RunDetail> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<RunDetail> create(Ref ref) {
    final argument = this.argument as int;
    return runDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is RunDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$runDetailHash() => r'2da547cd1fd0efe56e92e102142db2f166143041';

final class RunDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<RunDetail>, int> {
  RunDetailFamily._()
    : super(
        retry: null,
        name: r'runDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  RunDetailProvider call(int runId) =>
      RunDetailProvider._(argument: runId, from: this);

  @override
  String toString() => r'runDetailProvider';
}
