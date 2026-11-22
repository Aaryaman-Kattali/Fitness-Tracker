import 'package:fitness_tracker/app/router/app_router.dart';
import 'package:fitness_tracker/app/theme/app_colors.dart';
import 'package:fitness_tracker/app/theme/app_spacing.dart';
import 'package:fitness_tracker/app/theme/app_typography.dart';
import 'package:fitness_tracker/data/models/session_plan.dart';
import 'package:fitness_tracker/data/models/training_enums.dart';
import 'package:fitness_tracker/data/providers/database_providers.dart';
import 'package:fitness_tracker/features/today/providers/steps_providers.dart';
import 'package:fitness_tracker/features/today/providers/today_providers.dart';
import 'package:fitness_tracker/features/today/widgets/another_session_row.dart';
import 'package:fitness_tracker/features/today/widgets/plan_item_row.dart';
import 'package:fitness_tracker/features/today/widgets/steps_card.dart';
import 'package:fitness_tracker/features/today/widgets/warmup_checklist.dart';
import 'package:fitness_tracker/shared/widgets/inset_card.dart';
import 'package:fitness_tracker/shared/widgets/section_header.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// The landing screen. Today's session is the first thing rendered.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(todayDateProvider);
    final session = ref.watch(todaySessionProvider);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.surfacePage,
      child: CustomScrollView(
        slivers: [
          const CupertinoSliverNavigationBar(largeTitle: Text('Today')),
          // Pulling down re-reads Health Connect. It deliberately does not
          // reload the plan: the plan comes from the seed, so there would be
          // nothing new to find, and a refresh that rebuilt the session card
          // would flicker the Start/Resume label for no reason.
          CupertinoSliverRefreshControl(
            onRefresh: () => ref.read(stepsPanelProvider.notifier).refresh(),
          ),
          SliverSafeArea(
            top: false,
            sliver: SliverList.list(
              children: [
                _DateLine(date: date),
                const StepsCard(),
                const SizedBox(height: AppSpacing.md),
                switch (session) {
                  AsyncData(value: final plan) when plan != null =>
                    _SessionContent(session: plan),
                  AsyncData() => _MessageCard(
                    title: 'No lifting today',
                    detail: ref.watch(todayRestLabelProvider),
                  ),
                  AsyncError(:final error) => _MessageCard(
                    title: 'Could not load the plan',
                    detail: '$error',
                  ),
                  _ => const Padding(
                    padding: EdgeInsets.only(top: AppSpacing.xxl),
                    child: CupertinoActivityIndicator(),
                  ),
                },
                // Below every branch, rest day included: a shut gym or a
                // shifted week must not leave the app with nothing to log.
                if (session is! AsyncLoading) ...[
                  const SizedBox(height: AppSpacing.md),
                  const AnotherSessionRow(),
                ],
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DateLine extends StatelessWidget {
  const _DateLine({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter + AppSpacing.xs,
        0,
        AppSpacing.gutter,
        AppSpacing.md,
      ),
      child: Text(
        DateFormat('EEEE, d MMMM').format(date),
        style: AppTypography.subhead.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

/// Today's session: the title card, then warm-up, plyometrics and lift.
class _SessionContent extends ConsumerWidget {
  const _SessionContent({required this.session});

  final SessionPlan session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final warmups = session.itemsIn(TrainingBlock.warmup);
    final plyos = session.itemsIn(TrainingBlock.plyo);
    final mains = session.itemsIn(TrainingBlock.main);

    // Unresolved reads as "Start": the label settles within a frame, and
    // promising a resume that does not exist is the worse way to be wrong.
    final openWorkoutId = ref.watch(openSessionIdProvider(session.id)).value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InsetCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                session.dayKey.shortLabel.toUpperCase(),
                style: AppTypography.footnoteEmphasis.copyWith(
                  color: AppColors.accentPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                session.name,
                style: AppTypography.title1.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${mains.length} exercises',
                style: AppTypography.footnote.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  onPressed: () => context.go(Routes.session(session.id)),
                  child: Text(
                    openWorkoutId == null ? 'Start session' : 'Resume session',
                  ),
                ),
              ),
            ],
          ),
        ),
        if (warmups.isNotEmpty) ...[
          SectionHeader(TrainingBlock.warmup.label, accent: AppColors.warmup),
          InsetCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final item in warmups)
                  WarmupChecklist(
                    checklist: item.notes ?? '',
                    planItemId: item.id,
                    workoutId: openWorkoutId,
                    startWorkout: () => _startWorkout(ref),
                  ),
              ],
            ),
          ),
        ],
        if (plyos.isNotEmpty) ...[
          SectionHeader(TrainingBlock.plyo.label, accent: AppColors.plyo),
          InsetCard(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: _ItemColumn(items: plyos),
          ),
        ],
        if (mains.isNotEmpty) ...[
          SectionHeader(TrainingBlock.main.label),
          InsetCard(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: _ItemColumn(items: mains),
          ),
        ],
      ],
    );
  }

  /// Opens today's workout so a warm-up tick has somewhere to live.
  ///
  /// Ticking the first warm-up line from Today is the user saying they have
  /// started training, so it starts the session — the same one the button
  /// would resume, which is why the label is invalidated straight after.
  Future<int> _startWorkout(WidgetRef ref) async {
    final workoutId = await ref
        .read(workoutRepositoryProvider)
        .openOrStartWorkout(
          planDayId: session.id,
          now: ref.read(todayDateProvider),
        );
    ref.invalidate(openSessionIdProvider(session.id));
    return workoutId;
  }
}

/// A column of [PlanItemRow]s separated by hairlines.
class _ItemColumn extends StatelessWidget {
  const _ItemColumn({required this.items});

  final List<PlannedItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < items.length; index++) ...[
          if (index > 0) const InsetDivider(indent: 0),
          PlanItemRow(item: items[index]),
        ],
      ],
    );
  }
}

/// A card that explains rather than shows: a rest day, or a failed load.
class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return InsetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.title1.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            detail,
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
