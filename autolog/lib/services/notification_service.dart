import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../data/reminder_repository.dart';
import '../models/models.dart';
import '../utils/date_formatter.dart';

/// Wraps [FlutterLocalNotificationsPlugin] to schedule and cancel reminders.
/// All operations are wrapped in try-catch so notification failures never
/// crash the app.
class NotificationService {
  NotificationService({
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;
  bool _permissionGranted = false;
  bool get permissionGranted => _permissionGranted;

  // ── Initialisation ─────────────────────────────────────────────────────────

  Future<void> init() async {
    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);

      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      _initialized = true;

      // Request POST_NOTIFICATIONS permission on Android 13+
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final granted =
            await androidPlugin.requestNotificationsPermission();
        _permissionGranted = granted ?? false;
      } else {
        _permissionGranted = true;
      }
    } catch (e) {
      debugPrint('NotificationService.init failed (non-fatal): $e');
      _initialized = false;
    }
  }

  // ── Scheduling ─────────────────────────────────────────────────────────────

  Future<void> scheduleReminder(
      Reminder reminder, String vehicleNickname) async {
    if (!_initialized || !_permissionGranted) return;

    try {
      final dueDate = reminder.dueDate;
      if (dueDate == null || dueDate.isBefore(DateTime.now())) return;

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

      await _plugin.zonedSchedule(
        notificationId,
        reminder.title,
        body,
        tz.TZDateTime.from(dueDate, tz.local),
        NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('NotificationService.scheduleReminder failed (non-fatal): $e');
    }
  }

  Future<void> cancelReminder(String reminderId) async {
    if (!_initialized) return;
    try {
      await _plugin.cancel(_notificationId(reminderId));
    } catch (e) {
      debugPrint('NotificationService.cancelReminder failed (non-fatal): $e');
    }
  }

  Future<void> cancelAllForVehicle(
    String vehicleId,
    ReminderRepository repository,
  ) async {
    if (!_initialized) return;
    try {
      final reminders = await repository.getByVehicle(vehicleId);
      for (final reminder in reminders) {
        await cancelReminder(reminder.id);
      }
    } catch (e) {
      debugPrint('NotificationService.cancelAllForVehicle failed (non-fatal): $e');
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  int _notificationId(String reminderId) =>
      reminderId.hashCode.abs() % 2147483647;

  String _buildBody(Reminder reminder, String vehicleNickname) {
    final buffer = StringBuffer()
      ..write(vehicleNickname)
      ..write(' — ')
      ..write(_reminderTypeLabel(reminder.reminderType));

    if (reminder.dueDate != null) {
      buffer
        ..write(': ')
        ..write(DateFormatter.format(reminder.dueDate!));
    } else if (reminder.dueOdometerKm != null) {
      buffer
        ..write(' at ')
        ..write(reminder.dueOdometerKm!.toStringAsFixed(0))
        ..write(' km');
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
    debugPrint('NotificationService: tapped id=${response.id}');
  }
}
