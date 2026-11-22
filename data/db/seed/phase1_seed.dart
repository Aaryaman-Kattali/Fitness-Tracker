import 'package:fitness_tracker/data/db/seed/seed_models.dart';
import 'package:fitness_tracker/data/models/training_enums.dart';

/// Phase 1 (weeks 1–8) of the 12-week foundation programme.
///
/// Transcribed from `training-plan.md`. The plyometric blocks are the
/// **weeks 1–4** progressions; the weeks 5–8 swap is made by hand.
///
/// This file is deliberately free of any drift import so the seed can be
/// asserted on directly in unit tests.
const List<SeedPlanDay> phase1Plan = [
  _lowerA,
  _upperA,
  _lowerB,
  _upperB,
];

// ---------------------------------------------------------------------------
// Warm-up checklists
// ---------------------------------------------------------------------------

const _upperWarmup = SeedPlanItem.warmup(
  'Band pull-aparts — 2 × 20\n'
  'Thoracic extension over a rolled towel — 10 slow reps\n'
  'Doorway pec stretch — 30 sec/side\n'
  'Cable face pull, very light — 2 × 15',
);

// ---------------------------------------------------------------------------
// Lower A
// ---------------------------------------------------------------------------

const _lowerA = SeedPlanDay(
  dayKey: PlanDayKey.lowerA,
  name: 'Lower A — Quad/Glute + Plyo',
  orderIndex: 0,
  items: [
    SeedPlanItem.warmup(
      'Skipping rope, easy pace — 3 × 1 min\n'
      'Leg swings front/back and side/side — 10 each\n'
      'Bodyweight glute bridge — 2 × 15\n'
      'Bodyweight squat — 2 × 10, slow',
    ),
    SeedPlanItem(
      block: TrainingBlock.plyo,
      exercise: SeedExercise(
        name: 'Pogo hop',
        pattern: MovementPattern.plyo,
        equipment: 'bodyweight',
      ),
      targetSets: 4,
      repLow: 20,
      repHigh: 20,
      notes: 'Stiff ankles, minimal knee bend, bounce off the floor.',
    ),
    SeedPlanItem(
      block: TrainingBlock.plyo,
      exercise: SeedExercise(
        name: 'Drop-and-stick',
        pattern: MovementPattern.plyo,
        equipment: 'box',
      ),
      targetSets: 3,
      repLow: 5,
      repHigh: 5,
      notes: 'From a low bench/step (~30 cm). Land soft, hold 2 sec.',
    ),
    SeedPlanItem(
      block: TrainingBlock.plyo,
      exercise: SeedExercise(
        name: 'Line hops',
        pattern: MovementPattern.plyo,
        equipment: 'bodyweight',
      ),
      targetSets: 3,
      notes: '20 sec each: forward-back, then side-side.',
    ),
    SeedPlanItem(
      block: TrainingBlock.main,
      exercise: SeedExercise(
        name: 'Smith machine squat',
        pattern: MovementPattern.squat,
        equipment: 'smith machine',
      ),
      targetSets: 4,
      repLow: 6,
      repHigh: 8,
      notes: 'Feet slightly forward of the bar. Full depth.',
    ),
    SeedPlanItem(
      block: TrainingBlock.main,
      exercise: SeedExercise(
        name: 'DB Bulgarian split squat',
        pattern: MovementPattern.squat,
        equipment: 'dumbbell',
        isUnilateral: true,
      ),
      targetSets: 3,
      repLow: 8,
      repHigh: 10,
      notes: 'Torso slightly forward — this loads the glute.',
    ),
    SeedPlanItem(
      block: TrainingBlock.main,
      exercise: SeedExercise(
        name: 'Smith machine hip thrust',
        pattern: MovementPattern.hinge,
        equipment: 'smith machine',
      ),
      targetSets: 3,
      repLow: 10,
      repHigh: 12,
      notes: 'Pad the bar. Chin tucked, ribs down, squeeze 1 sec at top.',
    ),
    SeedPlanItem(
      block: TrainingBlock.main,
      exercise: SeedExercise(
        name: 'Leg extension',
        pattern: MovementPattern.isolation,
        equipment: 'machine',
      ),
      targetSets: 3,
      repLow: 12,
      repHigh: 15,
    ),
    SeedPlanItem(
      block: TrainingBlock.main,
      exercise: SeedExercise(
        name: 'Standing calf raise',
        pattern: MovementPattern.isolation,
        equipment: 'machine',
      ),
      targetSets: 4,
      repLow: 10,
      repHigh: 12,
      notes: '3-second lower on every rep.',
    ),
    SeedPlanItem(
      block: TrainingBlock.main,
      exercise: SeedExercise(
        name: 'Tibialis raise',
        pattern: MovementPattern.isolation,
        equipment: 'bodyweight',
      ),
      targetSets: 3,
      repLow: 15,
      repHigh: 20,
      notes:
          'Heels on floor, back to wall, lift toes. Shin armour for running.',
    ),
  ],
);

// ---------------------------------------------------------------------------
// Upper A (push emphasis)
// ---------------------------------------------------------------------------

const _upperA = SeedPlanDay(
  dayKey: PlanDayKey.upperA,
  name: 'Upper A — Push emphasis',
  orderIndex: 1,
  items: [
    _upperWarmup,
    SeedPlanItem(
      block: TrainingBlock.main,
      exercise: SeedExercise(
        name: 'Seated incline chest press',
        pattern: MovementPattern.press,
        equipment: 'machine',
      ),
      targetSets: 4,
      repLow: 8,
      repHigh: 10,
      notes: 'Squeeze the handles hard. Full-body tension.',
    ),
    SeedPlanItem(
      block: TrainingBlock.main,
      exercise: SeedExercise(
        name: 'Lat pulldown',
        pattern: MovementPattern.pull,
        equipment: 'cable',
      ),
      targetSets: 4,
      repLow: 8,
      repHigh: 12,
      notes: 'Pull to upper chest, elbows down not back.',
    ),
    SeedPlanItem(
      block: TrainingBlock.main,
      exercise: SeedExercise(
        name: 'Seated DB shoulder press',
        pattern: MovementPattern.press,
        equipment: 'dumbbell',
      ),
      targetSets: 3,
      repLow: 8,
      repHigh: 12,
      notes: "Start at 7.5 kg. Ribs down, don't arch.",
    ),
    SeedPlanItem(
      block: TrainingBlock.main,
      exercise: SeedExercise(
        name: 'Cable row (neutral handle)',
        pattern: MovementPattern.pull,
        equipment: 'cable',
      ),
      targetSets: 3,
      repLow: 10,
      repHigh: 12,
      notes: 'Pause 1 sec with shoulder blades pinched.',
    ),
    SeedPlanItem(
      block: TrainingBlock.main,
      exercise: SeedExercise(
        name: 'Cable lateral raise',
        pattern: MovementPattern.isolation,
        equipment: 'cable',
      ),
      targetSets: 3,
      repLow: 12,
      repHigh: 15,
      notes: 'Light. This is a small muscle.',
    ),
    SeedPlanItem(
      block: TrainingBlock.main,
      exercise: SeedExercise(
        name: 'Face pull',
        pattern: MovementPattern.pull,
        equipment: 'cable',
      ),
      targetSets: 3,
      repLow: 15,
      repHigh: 20,
      notes: 'High to eye level. External rotation at the end. Posture money.',
    ),
    SeedPlanItem(
      block: TrainingBlock.main,
      exercise: SeedExercise(
        name: 'Triceps rope pushdown',
        pattern: MovementPattern.isolation,
        equipment: 'cable',
      ),
      targetSets: 3,
      repLow: 12,
      repHigh: 15,
    ),
  ],
);

// ---------------------------------------------------------------------------
// Lower B
// ---------------------------------------------------------------------------

const _lowerB = SeedPlanDay(
  dayKey: PlanDayKey.lowerB,
  name: 'Lower B — Hinge/Posterior + Plyo',
  orderIndex: 2,
  items: [
    SeedPlanItem.warmup(
      'Skipping rope — 3 × 1 min\n'
      '90/90 hip switches — 10/side\n'
      'Band clamshells — 2 × 15/side\n'
      'Bodyweight RDL, slow — 2 × 10',
    ),
    SeedPlanItem(
      block: TrainingBlock.plyo,
      exercise: SeedExercise(
        name: 'Skipping, single-leg alternating',
        pattern: MovementPattern.plyo,
        equipment: 'rope',
      ),
      targetSets: 3,
      notes: '30 sec per set.',
    ),
    SeedPlanItem(
      block: TrainingBlock.plyo,
      exercise: SeedExercise(
        name: 'Ankle hops in place',
        pattern: MovementPattern.plyo,
        equipment: 'bodyweight',
      ),
      targetSets: 4,
      repLow: 15,
      repHigh: 15,
      notes: 'Fast and stiff.',
    ),
    SeedPlanItem(
      block: TrainingBlock.plyo,
      exercise: SeedExercise(
        name: 'Split-stance jump (scissor)',
        pattern: MovementPattern.plyo,
        equipment: 'bodyweight',
      ),
      targetSets: 3,
      repLow: 6,
      repHigh: 6,
      notes: 'Soft landings.',
    ),
    SeedPlanItem(
      block: TrainingBlock.main,
      exercise: SeedExercise(
        name: 'Smith machine RDL',
        pattern: MovementPattern.hinge,
        equipment: 'smith machine',
      ),
      targetSets: 4,
      repLow: 8,
      repHigh: 10,
      notes: 'Bar close to legs, push hips back, feel the hamstrings.',
    ),
    SeedPlanItem(
      block: TrainingBlock.main,
      exercise: SeedExercise(
        name: 'Seated leg press',
        pattern: MovementPattern.squat,
        equipment: 'machine',
      ),
      targetSets: 4,
      repLow: 10,
      repHigh: 12,
      notes: "Feet mid-platform, don't let the lower back round.",
    ),
    SeedPlanItem(
      block: TrainingBlock.main,
      exercise: SeedExercise(
        name: 'Prone leg curl',
        pattern: MovementPattern.isolation,
        equipment: 'machine',
      ),
      targetSets: 3,
      repLow: 12,
      repHigh: 15,
      notes: '3-second lower.',
    ),
    SeedPlanItem(
      block: TrainingBlock.main,
      exercise: SeedExercise(
        name: 'DB step-up onto bench',
        pattern: MovementPattern.squat,
        equipment: 'dumbbell',
        isUnilateral: true,
      ),
      targetSets: 3,
      repLow: 10,
      repHigh: 10,
      notes: 'Drive through the heel, no push off the back foot.',
    ),
    SeedPlanItem(
      block: TrainingBlock.main,
      exercise: SeedExercise(
        name: 'Seated calf raise',
        pattern: MovementPattern.isolation,
        equipment: 'machine',
      ),
      targetSets: 4,
      repLow: 12,
      repHigh: 15,
      notes: 'Standing is a fine substitute.',
    ),
    SeedPlanItem(
      block: TrainingBlock.main,
      exercise: SeedExercise(
        name: 'Band clamshell + side-lying abduction',
        pattern: MovementPattern.isolation,
        equipment: 'band',
        isUnilateral: true,
      ),
      targetSets: 3,
      repLow: 12,
      repHigh: 12,
      notes: 'Glute medius. Fixes hip stability for running.',
    ),
  ],
);

// ---------------------------------------------------------------------------
// Upper B (pull emphasis)
// ---------------------------------------------------------------------------

const _upperB = SeedPlanDay(
  dayKey: PlanDayKey.upperB,
  name: 'Upper B — Pull emphasis',
  orderIndex: 3,
  items: [
    _upperWarmup,
    SeedPlanItem(
      block: TrainingBlock.main,
      exercise: SeedExercise(
        name: 'Lat pulldown (wide grip)',
        pattern: MovementPattern.pull,
        equipment: 'cable',
      ),
      targetSets: 4,
      repLow: 8,
      repHigh: 10,
    ),
    SeedPlanItem(
      block: TrainingBlock.main,
      exercise: SeedExercise(
        name: 'Chest-supported DB row',
        pattern: MovementPattern.pull,
        equipment: 'dumbbell',
      ),
      targetSets: 4,
      repLow: 10,
      repHigh: 12,
      notes: 'Bench at 30°. Elbows at 45°, no torso swing.',
    ),
    SeedPlanItem(
      block: TrainingBlock.main,
      exercise: SeedExercise(
        name: 'Seated chest press',
        pattern: MovementPattern.press,
        equipment: 'machine',
      ),
      targetSets: 3,
      repLow: 8,
      repHigh: 12,
    ),
    SeedPlanItem(
      block: TrainingBlock.main,
      exercise: SeedExercise(
        name: 'Rear delt fly machine',
        pattern: MovementPattern.isolation,
        equipment: 'machine',
      ),
      targetSets: 3,
      repLow: 15,
      repHigh: 15,
      notes: 'Light, high reps, feel it between the shoulder blades.',
    ),
    SeedPlanItem(
      block: TrainingBlock.main,
      exercise: SeedExercise(
        name: 'Cable row, single arm',
        pattern: MovementPattern.pull,
        equipment: 'cable',
        isUnilateral: true,
      ),
      targetSets: 3,
      repLow: 12,
      repHigh: 12,
      notes: 'Let the shoulder blade travel fully forward and back.',
    ),
    SeedPlanItem(
      block: TrainingBlock.main,
      exercise: SeedExercise(
        name: 'Incline DB curl',
        pattern: MovementPattern.isolation,
        equipment: 'dumbbell',
      ),
      targetSets: 3,
      repLow: 10,
      repHigh: 12,
      notes: 'Start at 5 kg. Yes, really.',
    ),
    SeedPlanItem(
      block: TrainingBlock.main,
      exercise: SeedExercise(
        name: 'Seated triceps dip machine',
        pattern: MovementPattern.isolation,
        equipment: 'machine',
      ),
      targetSets: 3,
      repLow: 10,
      repHigh: 12,
    ),
  ],
);
