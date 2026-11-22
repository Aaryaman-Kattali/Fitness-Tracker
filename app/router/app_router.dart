import 'package:fitness_tracker/app/router/tab_shell.dart';
import 'package:fitness_tracker/features/activity/run_detail_screen.dart';
import 'package:fitness_tracker/features/activity/run_list_screen.dart';
import 'package:fitness_tracker/features/activity/run_recording_screen.dart';
import 'package:fitness_tracker/features/progress/progress_screen.dart';
import 'package:fitness_tracker/features/settings/settings_screen.dart';
import 'package:fitness_tracker/features/today/today_screen.dart';
import 'package:fitness_tracker/features/workout/exercise_log_screen.dart';
import 'package:fitness_tracker/features/workout/session_screen.dart';
import 'package:fitness_tracker/features/workout/workout_detail_screen.dart';
import 'package:fitness_tracker/features/workout/workout_history_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

/// Route paths, so no screen has to spell a location as a string literal.
abstract final class Routes {
  static const today = '/today';
  static const workout = '/workout';
  static const progress = '/progress';
  static const settings = '/settings';

  /// Recording a run. Lives under progress because that is where activity
  /// lands; it is not a tab of its own for one screen.
  static const runRecording = '$progress/run';

  /// The list of recorded runs, and one run's map.
  static const runs = '$progress/runs';

  static const runParam = 'runId';

  static String runDetail(int runId) => '$runs/$runId';

  static const planDayParam = 'planDayId';
  static const exerciseParam = 'exerciseId';
  static const workoutParam = 'workoutId';

  /// The session in progress for a plan day.
  static String session(int planDayId) => '$workout/session/$planDayId';

  /// Set logging for one exercise within a session.
  static String exerciseLog({
    required int planDayId,
    required int exerciseId,
  }) => '$workout/session/$planDayId/exercise/$exerciseId';

  /// A past session.
  static String workoutDetail(int workoutId) => '$workout/log/$workoutId';
}

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

int _intParam(GoRouterState state, String name) =>
    int.parse(state.pathParameters[name]!);

/// The app router. The tab shell is the root route; every screen lives in one
/// of its four branches.
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: Routes.today,
    routes: [
      StatefulShellRoute(
        builder: (context, state, navigationShell) => navigationShell,
        navigatorContainerBuilder: (context, navigationShell, children) =>
            TabShell(
              navigationShell: navigationShell,
              branchNavigators: children,
            ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.today,
                builder: (context, state) => const TodayScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.workout,
                builder: (context, state) => const WorkoutHistoryScreen(),
                routes: [
                  GoRoute(
                    path: 'session/:${Routes.planDayParam}',
                    builder: (context, state) => SessionScreen(
                      planDayId: _intParam(state, Routes.planDayParam),
                    ),
                    routes: [
                      GoRoute(
                        path: 'exercise/:${Routes.exerciseParam}',
                        builder: (context, state) => ExerciseLogScreen(
                          planDayId: _intParam(state, Routes.planDayParam),
                          exerciseId: _intParam(state, Routes.exerciseParam),
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'log/:${Routes.workoutParam}',
                    builder: (context, state) => WorkoutDetailScreen(
                      workoutId: _intParam(state, Routes.workoutParam),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.progress,
                builder: (context, state) => const ProgressScreen(),
                routes: [
                  GoRoute(
                    path: 'run',
                    builder: (context, state) => const RunRecordingScreen(),
                  ),
                  GoRoute(
                    path: 'runs',
                    builder: (context, state) => const RunListScreen(),
                    routes: [
                      GoRoute(
                        path: ':${Routes.runParam}',
                        builder: (context, state) => RunDetailScreen(
                          runId: _intParam(state, Routes.runParam),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.settings,
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
