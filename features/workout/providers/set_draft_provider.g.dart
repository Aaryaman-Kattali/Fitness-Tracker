// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'set_draft_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The draft set for one exercise, pre-filled from last session.
///
/// Starting from last session's numbers is the point: double progression means
/// the user almost always repeats the weight and tries to add a rep, so the
/// screen should open on the answer and let them nudge it.

@ProviderFor(SetDraftController)
final setDraftControllerProvider = SetDraftControllerFamily._();

/// The draft set for one exercise, pre-filled from last session.
///
/// Starting from last session's numbers is the point: double progression means
/// the user almost always repeats the weight and tries to add a rep, so the
/// screen should open on the answer and let them nudge it.
final class SetDraftControllerProvider
    extends $AsyncNotifierProvider<SetDraftController, SetDraft> {
  /// The draft set for one exercise, pre-filled from last session.
  ///
  /// Starting from last session's numbers is the point: double progression means
  /// the user almost always repeats the weight and tries to add a rep, so the
  /// screen should open on the answer and let them nudge it.
  SetDraftControllerProvider._({
    required SetDraftControllerFamily super.from,
    required ({int exerciseId, int workoutId, int? repLow}) super.argument,
  }) : super(
         retry: null,
         name: r'setDraftControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$setDraftControllerHash();

  @override
  String toString() {
    return r'setDraftControllerProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  SetDraftController create() => SetDraftController();

  @override
  bool operator ==(Object other) {
    return other is SetDraftControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$setDraftControllerHash() =>
    r'4910c5d5e8179941cf2d0e01b500695de3ff8d60';

/// The draft set for one exercise, pre-filled from last session.
///
/// Starting from last session's numbers is the point: double progression means
/// the user almost always repeats the weight and tries to add a rep, so the
/// screen should open on the answer and let them nudge it.

final class SetDraftControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          SetDraftController,
          AsyncValue<SetDraft>,
          SetDraft,
          FutureOr<SetDraft>,
          ({int exerciseId, int workoutId, int? repLow})
        > {
  SetDraftControllerFamily._()
    : super(
        retry: null,
        name: r'setDraftControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The draft set for one exercise, pre-filled from last session.
  ///
  /// Starting from last session's numbers is the point: double progression means
  /// the user almost always repeats the weight and tries to add a rep, so the
  /// screen should open on the answer and let them nudge it.

  SetDraftControllerProvider call({
    required int exerciseId,
    required int workoutId,
    int? repLow,
  }) => SetDraftControllerProvider._(
    argument: (exerciseId: exerciseId, workoutId: workoutId, repLow: repLow),
    from: this,
  );

  @override
  String toString() => r'setDraftControllerProvider';
}

/// The draft set for one exercise, pre-filled from last session.
///
/// Starting from last session's numbers is the point: double progression means
/// the user almost always repeats the weight and tries to add a rep, so the
/// screen should open on the answer and let them nudge it.

abstract class _$SetDraftController extends $AsyncNotifier<SetDraft> {
  late final _$args =
      ref.$arg as ({int exerciseId, int workoutId, int? repLow});
  int get exerciseId => _$args.exerciseId;
  int get workoutId => _$args.workoutId;
  int? get repLow => _$args.repLow;

  FutureOr<SetDraft> build({
    required int exerciseId,
    required int workoutId,
    int? repLow,
  });
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<SetDraft>, SetDraft>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<SetDraft>, SetDraft>,
              AsyncValue<SetDraft>,
              Object?,
              Object?
            >;
    element.handleCreate(
      ref,
      () => build(
        exerciseId: _$args.exerciseId,
        workoutId: _$args.workoutId,
        repLow: _$args.repLow,
      ),
    );
  }
}
