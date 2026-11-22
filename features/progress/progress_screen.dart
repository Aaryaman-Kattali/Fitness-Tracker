import 'package:fitness_tracker/app/router/app_router.dart';
import 'package:fitness_tracker/app/theme/app_colors.dart';
import 'package:fitness_tracker/app/theme/app_spacing.dart';
import 'package:fitness_tracker/app/theme/app_typography.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

/// Placeholder until M6 (photos, measurements, trend charts).
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.surfacePage,
      child: CustomScrollView(
        slivers: [
          const CupertinoSliverNavigationBar(largeTitle: Text('Progress')),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    CupertinoIcons.chart_bar_alt_fill,
                    size: 44,
                    color: AppColors.textLabel,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Photos, measurements and body-composition trends arrive '
                    'in a later milestone.',
                    textAlign: TextAlign.center,
                    style: AppTypography.subhead.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  // The way into runs. Recording now lives behind the list
                  // rather than beside it: a run is something you look at
                  // afterwards far more often than you start, and A2 gave the
                  // recorded ones somewhere to be.
                  CupertinoButton.filled(
                    onPressed: () => context.push(Routes.runs),
                    child: const Text('Runs'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
