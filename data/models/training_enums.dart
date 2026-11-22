/// The four lifting sessions in the Phase 1 week.
enum PlanDayKey {
  lowerA,
  upperA,
  lowerB,
  upperB
  ;

  /// Short label, e.g. "Lower A".
  String get shortLabel => switch (this) {
    PlanDayKey.lowerA => 'Lower A',
    PlanDayKey.upperA => 'Upper A',
    PlanDayKey.lowerB => 'Lower B',
    PlanDayKey.upperB => 'Upper B',
  };
}

/// The section of a session a plan item belongs to.
///
/// Rendered in this declaration order: warm-up, then plyometrics, then the
/// lift itself.
enum TrainingBlock {
  warmup,
  plyo,
  main
  ;

  String get label => switch (this) {
    TrainingBlock.warmup => 'Warm-up',
    TrainingBlock.plyo => 'Plyometrics',
    TrainingBlock.main => 'Lift',
  };
}

/// Movement pattern taxonomy from the architecture spec.
enum MovementPattern {
  squat,
  hinge,
  press,
  pull,
  plyo,
  isolation,
}
