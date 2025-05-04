import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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

  String? _lastMessageId;

  Future<void> _checkForNewMessages({
    required String deliveryId,
    required String senderId,
    required String receiverId,
    required String? userName,
    required String? userImage,
    required String? orderId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('https://deliveryapi-ten.vercel.app/chat/$deliveryId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String? latestMessageId;
        bool hasNewMessage = false;

        if (data is List && data.isNotEmpty) {
          final latestMessage = data.last;
          latestMessageId = latestMessage['_id'];

          if (_lastMessageId != latestMessageId &&
              latestMessage['sender_id'] != senderId) {
            hasNewMessage = true;
          }
        } else if (data['messages'] != null && data['messages'].isNotEmpty) {
          final latestMessage = data['messages'].last;
          latestMessageId = latestMessage['_id'];

          if (_lastMessageId != latestMessageId &&
              latestMessage['sender_id'] != senderId) {
            hasNewMessage = true;
          }
        }

        if (latestMessageId != null) {
          _lastMessageId = latestMessageId;
        }

        if (hasNewMessage) {
          await http.put(
            Uri.parse(
                'https://deliveryapi-ten.vercel.app/chat/$deliveryId/$senderId/mark-read'),
          );

          // Send OneSignal push to the receiver
          await sendPushToUser(
            externalUserId: receiverId,
            title: 'New message from ${userName ?? "User"}',
            body: 'You have a new message',
            additionalData: {
              'type': 'message',
              'deliveryId': deliveryId,
              'senderId': senderId,
              'receiverId': receiverId,
              'userName': userName,
              'userImage': userImage,
              'orderId': orderId,
            },
          );
        }
      }
    } catch (e) {
      print('Error checking for new messages: $e');
    }
  }

  Future<void> sendPushToUser({
    required String externalUserId,
    required String title,
    required String body,
    Map<String, dynamic>? additionalData,
  }) async {
    const String oneSignalRestApiKey =
        'os_v2_app_2z3lltiu2fg63hy4rmqklg3qktyc2wekyx6emlfka37xl7iuwku5cablnutxoe2s3klvqig5gojocr67fk2fg55w4vp7isvbz5tnvqi';
    const String oneSignalAppId = 'd676b5cd-14d1-4ded-9f1c-8b20a59b7054';

    final url = Uri.parse('https://onesignal.com/api/v1/notifications');
    final headers = {
      'Content-Type': 'application/json; charset=utf-8',
      'Authorization': 'Basic $oneSignalRestApiKey',
    };

    final payload = {
      'app_id': oneSignalAppId,
      'include_external_user_ids': [externalUserId],
      'headings': {'en': title},
      'contents': {'en': body},
      'data': additionalData ?? {},
    };

    final response =
        await http.post(url, headers: headers, body: json.encode(payload));

    if (response.statusCode != 200) {
      print('Failed to send push notification: ${response.body}');
    }
  }

  void startBackgroundMessageCheck({
    required String deliveryId,
    required String senderId,
    required String receiverId,
    required String? userName,
    required String? userImage,
    required String? orderId,
    Duration interval = const Duration(seconds: 30),
  }) {
    Timer.periodic(interval, (timer) async {
      try {
        await _checkForNewMessages(
          deliveryId: deliveryId,
          senderId: senderId,
          receiverId: receiverId,
          userName: userName,
          userImage: userImage,
          orderId: orderId,
        );
      } catch (e) {
        print('Error during background message check: $e');
      }
    });
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
