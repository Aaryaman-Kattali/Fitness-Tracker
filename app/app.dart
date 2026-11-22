import 'dart:async';

import 'package:fitness_tracker/app/router/app_router.dart';
import 'package:fitness_tracker/app/theme/app_theme.dart';
import 'package:fitness_tracker/features/today/providers/steps_providers.dart';
import 'package:fitness_tracker/features/workout/providers/rest_timer_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Root widget.
///
/// [CupertinoApp] rather than `MaterialApp`: this app uses the iOS visual
/// language throughout, and a Material root would leak Material defaults into
/// every dialog, text selection handle and page transition.
class FitnessTrackerApp extends ConsumerStatefulWidget {
  const FitnessTrackerApp({super.key});

  @override
  ConsumerState<FitnessTrackerApp> createState() => _FitnessTrackerAppState();
}

class _FitnessTrackerAppState extends ConsumerState<FitnessTrackerApp> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Coming back to the foreground is the moment the rest timer has to be
    // re-derived from the clock: its ticker is throttled or suspended while
    // the app is backgrounded, which is most of any real rest.
    _lifecycle = AppLifecycleListener(onResume: _onResume);
  }

  void _onResume() {
    ref.read(restTimerProvider.notifier).sync();

    // Steps accrue entirely while the app is backgrounded, so resume is the
    // only moment the ring can be brought up to date without polling. Fire
    // and forget: the refresh resolves its own failures to a state the card
    // renders, and nothing here should be able to hold up a resume.
    unawaited(ref.read(stepsPanelProvider.notifier).refresh());
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final brightness = MediaQuery.platformBrightnessOf(context);

    return CupertinoApp.router(
      title: 'Fitness Tracker',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: brightness == Brightness.dark ? AppTheme.dark() : AppTheme.light(),
    );
  }
}
