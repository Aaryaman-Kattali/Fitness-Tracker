import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

part 'rest_alerts.g.dart';

/// Tells the user their rest is over when they are not looking at the screen.
///
/// A rest timer that only exists on screen is useless in a gym: the phone is
/// in a pocket between sets. So the end of a rest is announced twice — a
/// notification the OS delivers whether or not this app is in front, and a
/// haptic distinct from the one that confirms a saved set.
///
/// The notification is *scheduled* at the deadline rather than shown when a
/// Dart timer fires, because Android throttles timers in backgrounded apps and
/// a rest alert that arrives late is worse than none.
/// Whether the off-screen rest alert will arrive, and on time.
enum RestAlertDelivery {
  /// Scheduled as an alarm clock. It fires at the deadline.
  exact,

  /// The OS withheld exact alarms, so the notification may lag by minutes.
  /// The on-screen countdown is unaffected.
  inexact,

  /// [RestAlerts.initialize] did not complete — a refused notification
  /// permission, a channel that could not be created, or no Android plugin at
  /// all. Nothing is scheduled and no notification arrives.
  unavailable,
}

class RestAlerts {
  RestAlerts(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  static const _channelId = 'rest_timer';
  static const _channelName = 'Rest timer';

  /// One id, reused: there is only ever one rest running, and rescheduling
  /// under the same id replaces the pending alert instead of stacking.
  static const _restOverId = 1;

  /// False until [initialize] succeeds. Every platform call is gated on it so
  /// that tests and any environment without the plugin simply do nothing.
  bool _ready = false;

  bool _isExact = false;

  /// How — and whether — the off-screen alert will actually arrive.
  ///
  /// **Read by `RestTimerBar` and shown to the user.** Both degraded values
  /// used to be invisible: an inexact alarm was chosen silently at [
  /// scheduleRestOver], and a failed [initialize] made every call here a
  /// no-op with nothing on screen to say so. C-2 exists because the phone is
  /// in a pocket between sets, so an alert that will not arrive — or will
  /// arrive minutes late — is the whole feature failing, and CLAUDE.md §4's
  /// platform-boundary exception requires that to be *shown* rather than
  /// swallowed.
  RestAlertDelivery get delivery {
    if (!_ready) return RestAlertDelivery.unavailable;
    return _isExact ? RestAlertDelivery.exact : RestAlertDelivery.inexact;
  }

  Future<void> initialize() async {
    tz_data.initializeTimeZones();

    await _plugin.initialize(
      settings: const InitializationSettings(
        // The launcher icon doubles as the notification icon: this app ships
        // no separate monochrome asset, and a personal build does not need
        // one badly enough to justify the artwork.
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (android != null) {
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: 'Fires when a between-sets rest is over.',
          importance: Importance.max,
        ),
      );
      // Android 13+ only; a no-op below that.
      await android.requestNotificationsPermission();
      _isExact = await android.canScheduleExactNotifications() ?? false;
    }

    _ready = true;
  }

  Future<void> scheduleRestOver({
    required DateTime deadline,
    String? exerciseName,
  }) async {
    if (!_ready) return;
    await cancelRestOver();

    await _plugin.zonedSchedule(
      id: _restOverId,
      // Converted by instant, not by wall-clock name. The zone database is
      // loaded but the device zone is not resolved, and it does not need to
      // be: a countdown cares about the moment, not what it is called.
      scheduledDate: tz.TZDateTime.from(deadline, tz.UTC),
      title: 'Rest over',
      body: exerciseName == null ? 'Next set.' : 'Next set — $exerciseName.',
      // A rest ending is exactly an alarm going off, so it earns an alarm's
      // scheduling. Falls back to inexact when the OS withholds that.
      androidScheduleMode: _isExact
          ? AndroidScheduleMode.alarmClock
          : AndroidScheduleMode.inexactAllowWhileIdle,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.max,
          priority: Priority.high,
          category: AndroidNotificationCategory.alarm,
        ),
      ),
    );
  }

  Future<void> cancelRestOver() async {
    if (!_ready) return;
    await _plugin.cancel(id: _restOverId);
  }

  /// The buzz at zero, for when the phone *is* in hand.
  ///
  /// Two heavy taps rather than the single medium tap that confirms a saved
  /// set — through a pocket the pattern is the only thing distinguishing them.
  Future<void> ringRestOver() async {
    if (!_ready) return;
    await HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 160));
    await HapticFeedback.heavyImpact();
  }
}

@Riverpod(keepAlive: true)
RestAlerts restAlerts(Ref ref) => RestAlerts(FlutterLocalNotificationsPlugin());

/// Wires up notifications at launch.
///
/// Failures are swallowed on purpose: an app that will not start because the
/// notification channel could not be created is a worse outcome than a rest
/// timer that only buzzes.
Future<void> initializeRestAlerts(ProviderContainer container) async {
  try {
    await container.read(restAlertsProvider).initialize();
  } on Object catch (error, stackTrace) {
    debugPrint('Rest alerts unavailable: $error\n$stackTrace');
  }
}
