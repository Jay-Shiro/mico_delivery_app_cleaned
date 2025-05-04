import 'dart:async';
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class OneSignalService {
  static final OneSignalService _instance = OneSignalService._internal();
  factory OneSignalService() => _instance;
  OneSignalService._internal();

  static const String oneSignalAppId = "d676b5cd-14d1-4ded-9f1c-8b20a59b7054";

  final StreamController<String> _notificationStreamController =
      StreamController<String>.broadcast();
  Stream<String> get onNotificationTapped =>
      _notificationStreamController.stream;

  Future<void> init() async {
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

    OneSignal.initialize(oneSignalAppId);

    await OneSignal.Notifications.requestPermission(true);

    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      print("Notification received in foreground: ${event.notification.body}");

      event.notification.display();
    });

    OneSignal.Notifications.addClickListener((event) {
      debugPrint("Notification opened: ${event.notification.body}");

      if (event.notification.additionalData != null) {
        final data = event.notification.additionalData!;
        if (data.containsKey('payload')) {
          _notificationStreamController.add(data['payload']);
        }
      }
    });
  }

  Future<void> setExternalUserId(String userId) async {
    await OneSignal.login(userId);
  }

  Future<void> sendLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final notificationId = DateTime.now().millisecondsSinceEpoch.toString();

      print("Attempting to send notification: $title - $body");

      await OneSignal.User.addTags({
        'last_notification_title': title,
        'last_notification_body': body,
        'notification_timestamp': notificationId,
      });

      print("Notification data set with ID: $notificationId");
      print(
          "Note: For direct push notifications, you'll need to use the OneSignal REST API");
    } catch (e) {
      print("Error with notification: $e");
    }
  }

  // Tag user for segmentation - fixed method name
  Future<void> tagUser({required String key, required String value}) async {
    // The correct method is sendTags with a Map
    await OneSignal.User.addTags({key: value});
  }

  // Clear all notifications - fixed method name
  Future<void> clearAllNotifications() async {
    // The correct method is clearAll()
    await OneSignal.Notifications.clearAll();
  }
}
