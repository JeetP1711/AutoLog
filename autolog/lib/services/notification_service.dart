import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../data/reminder_repository.dart';
import '../models/models.dart';
import '../utils/date_formatter.dart';

/// Wraps [FlutterLocalNotificationsPlugin] to schedule and cancel reminders.
///
/// All scheduling is done through this service — no screen calls the plugin
/// directly. The service works entirely offline.
class NotificationService {
  NotificationService({
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  /// Whether notification permission has been granted on Android 13+.
  bool _permissionGranted = false;
  bool get permissionGranted => _permissionGranted;

  // ── Initialisation ─────────────────────────────────────────────────────────

  /// Initialises the notification plugin and requests permission on Android 13+.
  ///
  /// Must be called once during app startup before any scheduling.
  Future<void> init() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Request POST_NOTIFICATIONS permission on Android 13+
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      _permissionGranted = granted ?? false;
    } else {
      _permissionGranted = true; // Non-Android platforms
    }
  }

  // ── Scheduling ─────────────────────────────────────────────────────────────

  /// Schedules a local notification for [reminder].
  ///
  /// If [reminder.dueDate] is in the past or null (odometer-based reminder),
  /// the notification is not scheduled but the reminder is still stored.
  Future<void> scheduleReminder(Reminder reminder, String vehicleNickname) async {
    if (!_permissionGranted) {
      debugPrint('NotificationService: permission not granted, skipping schedule');
      return;
    }

    final dueDate = reminder.dueDate;
    if (dueDate == null) {
      // Odometer-based reminders cannot be scheduled as time-based notifications.
      return;
    }

    if (dueDate.isBefore(DateTime.now())) {
      debugPrint('NotificationService: due date is in the past, skipping schedule');
      return;
    }

    final notificationId = _notificationId(reminder.id);
    final body = _buildBody(reminder, vehicleNickname);

    final androidDetails = AndroidNotificationDetails(
      'autolog_reminders',
      'AutoLog Reminders',
      channelDescription: 'Vehicle service and document reminders',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    final details = NotificationDetails(android: androidDetails);

    await _plugin.zonedSchedule(
      notificationId,
      reminder.title,
      body,
      tz.TZDateTime.from(dueDate, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Cancels the scheduled notification for [reminderId].
  Future<void> cancelReminder(String reminderId) async {
    await _plugin.cancel(_notificationId(reminderId));
  }

  /// Cancels all scheduled notifications for [vehicleId] by looking up
  /// reminders from [repository].
  Future<void> cancelAllForVehicle(
    String vehicleId,
    ReminderRepository repository,
  ) async {
    final reminders = await repository.getByVehicle(vehicleId);
    for (final reminder in reminders) {
      await cancelReminder(reminder.id);
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  /// Converts a reminder UUID string to a stable integer notification ID.
  int _notificationId(String reminderId) =>
      reminderId.hashCode.abs() % 2147483647;

  /// Builds the notification body text from [reminder] and [vehicleNickname].
  String _buildBody(Reminder reminder, String vehicleNickname) {
    final buffer = StringBuffer();
    buffer.write(vehicleNickname);
    buffer.write(' — ');
    buffer.write(_reminderTypeLabel(reminder.reminderType));

    if (reminder.dueDate != null) {
      buffer.write(': ');
      buffer.write(DateFormatter.format(reminder.dueDate!));
    } else if (reminder.dueOdometerKm != null) {
      buffer.write(' at ');
      buffer.write(reminder.dueOdometerKm!.toStringAsFixed(0));
      buffer.write(' km');
    }

    return buffer.toString();
  }

  String _reminderTypeLabel(ReminderType type) {
    switch (type) {
      case ReminderType.insuranceExpiry:
        return 'Insurance Expiry';
      case ReminderType.pucExpiry:
        return 'PUC Expiry';
      case ReminderType.serviceDue:
        return 'Service Due';
      case ReminderType.odometerMilestone:
        return 'Odometer Milestone';
      case ReminderType.custom:
        return 'Reminder';
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    // Navigation from notification tap is handled by the router via
    // the notification payload. No action needed here.
    debugPrint('NotificationService: tapped notification id=${response.id}');
  }
}
