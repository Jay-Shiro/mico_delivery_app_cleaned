import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final StreamController<String> _notificationStreamController =
      StreamController<String>.broadcast();
  Stream<String> get onNotificationTapped =>
      _notificationStreamController.stream;

  Future<void> init() async {
    tz.initializeTimeZones();

    // Request permissions
    await _requestPermissions();

    // Initialize notification settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    final DarwinInitializationSettings iOSSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      requestCriticalPermission: true, // Add this for critical notifications
    );

    final InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iOSSettings,
    );

    // Initialize the plugin
    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('Received notification response: ${response.payload}');
        if (response.payload != null) {
          _notificationStreamController.add(response.payload!);
        }
      },
    );

    // Create notification channels for Android
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }

    print('Notification service initialized successfully');
  }

  // Add this method to create notification channels for Android
  Future<void> _createNotificationChannels() async {
    const AndroidNotificationChannel messagesChannel =
        AndroidNotificationChannel(
      'messages_channel',
      'Messages',
      description: 'Notifications for new messages',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    const AndroidNotificationChannel fallbackChannel =
        AndroidNotificationChannel(
      'fallback_channel',
      'Fallback Channel',
      description: 'Fallback channel for notifications',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(messagesChannel);

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(fallbackChannel);

    print('Android notification channels created');
  }

  Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
            critical: true,
          );
      print('iOS notification permissions requested');
    } else if (Platform.isAndroid) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      print('Android notification permissions requested');
    }
  }

  Future<bool> isAppInForeground() async {
    return true;
  }

  Future<void> showMessageNotification({
    required String title,
    required String body,
    required Map<String, dynamic> payload,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final bool notificationsEnabled =
        prefs.getBool('notificationsEnabled') ?? true;

    if (!notificationsEnabled) {
      print('DEBUG: Notifications are disabled by user');
      return;
    }

    print('DEBUG: Attempting to show notification: $title - $body');
    print('DEBUG: Payload: ${json.encode(payload)}');

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'messages_channel',
      'Messages',
      channelDescription: 'Notifications for new messages',
      importance: Importance.max,
      priority: Priority.max,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
      channelShowBadge: true,
      category: AndroidNotificationCategory.message,
      fullScreenIntent: true,
      visibility: NotificationVisibility.public,
    );

    const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
      interruptionLevel: InterruptionLevel.timeSensitive,
      presentBanner: true,
      presentList: true,
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    final int notificationId = DateTime.now().millisecondsSinceEpoch % 10000;

    final String payloadStr = json.encode(payload);

    print('DEBUG: Using notification ID: $notificationId');

    try {
      if (Platform.isIOS) {
        print('DEBUG: Showing iOS notification');

        await _flutterLocalNotificationsPlugin.show(
          notificationId,
          title,
          body,
          platformDetails,
          payload: payloadStr,
        );

        await _flutterLocalNotificationsPlugin.zonedSchedule(
          notificationId + 1,
          title,
          body,
          tz.TZDateTime.now(tz.local).add(const Duration(milliseconds: 500)),
          platformDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: payloadStr,
        );
      } else {
        print('DEBUG: Showing Android notification');
        await _flutterLocalNotificationsPlugin.show(
          notificationId,
          title,
          body,
          platformDetails,
          payload: payloadStr,
        );
      }

      print('DEBUG: Notification sent successfully');
    } catch (e) {
      print('DEBUG: Error showing notification: $e');

      try {
        print('DEBUG: Trying fallback notification method');

        await _flutterLocalNotificationsPlugin.zonedSchedule(
          notificationId + 5,
          title,
          body,
          tz.TZDateTime.now(tz.local).add(const Duration(seconds: 1)),
          platformDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: payloadStr,
        );

        print('DEBUG: Fallback notification scheduled');
      } catch (fallbackError) {
        print('DEBUG: Even fallback notification failed: $fallbackError');
      }
    }
  }

  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledTime,
    required Map<String, dynamic> payload,
    String channelId = 'scheduled_channel',
    String channelName = 'Scheduled Notifications',
    String channelDescription = 'Notifications scheduled for future delivery',
  }) async {
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/launcher_icon',
    );

    const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    final int notificationId = DateTime.now().millisecondsSinceEpoch % 100000;

    final String payloadStr = json.encode(payload);

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payloadStr,
    );
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> checkForNewMessagesAndNotify({
    required String deliveryId,
    required String currentUserId,
    required String otherUserName,
  }) async {
    print('DEBUG: Checking for new messages for delivery $deliveryId');

    try {
      final response = await http.get(
        Uri.parse('https://deliveryapi-ten.vercel.app/chat/$deliveryId'),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        List<dynamic> messages = [];
        if (data is List) {
          messages = data;
        } else if (data['messages'] != null) {
          messages = data['messages'];
        }

        final prefs = await SharedPreferences.getInstance();
        final String notifiedIdsKey = 'notified_message_ids_$deliveryId';
        final List<String> notifiedIds =
            prefs.getStringList(notifiedIdsKey) ?? [];

        List<Map<String, dynamic>> unreadMessages = [];

        for (var msg in messages) {
          if (msg['sender_id'] != currentUserId) {
            final String messageId = msg['_id'];
            final bool isRead = msg['read'] == true;
            final bool alreadyNotified = notifiedIds.contains(messageId);

            print(
                'DEBUG: Message ID: $messageId, Read: $isRead, Already Notified: $alreadyNotified');

            if (!isRead && !alreadyNotified) {
              unreadMessages.add(Map<String, dynamic>.from(msg));
            }
          }
        }

        unreadMessages.sort((a, b) {
          final DateTime timeA = DateTime.parse(a['timestamp']);
          final DateTime timeB = DateTime.parse(b['timestamp']);
          return timeB.compareTo(timeA);
        });

        print(
            'DEBUG: Found ${unreadMessages.length} unread messages that need notifications');

        for (var msg in unreadMessages) {
          final String messageId = msg['_id'];
          final String messageText = msg['message'];

          print('DEBUG: Showing notification for unread message: $messageText');

          notifiedIds.add(messageId);

          await showMessageNotification(
            title: 'New message from $otherUserName',
            body: messageText,
            payload: {
              'type': 'message',
              'deliveryId': deliveryId,
              'messageId': messageId,
            },
          );

          await prefs.setStringList(notifiedIdsKey, notifiedIds);

          break;
        }

        if (unreadMessages.isEmpty) {
          print('DEBUG: No unread messages found that require notifications');
        }
      }
    } catch (e) {
      print('DEBUG: Error checking for new messages: $e');
    }
  }
}
