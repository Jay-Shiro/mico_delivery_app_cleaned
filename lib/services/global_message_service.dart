import 'dart:async';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:micollins_delivery_app/services/notification_service.dart';
import 'package:micollins_delivery_app/services/onesignal_service.dart';

class GlobalMessageService {
  static final GlobalMessageService _instance =
      GlobalMessageService._internal();
  factory GlobalMessageService() => _instance;
  GlobalMessageService._internal();

  Timer? _pollingTimer;
  String? _lastMessageId;

  void startPolling({
    required String deliveryId,
    required String senderId,
    required String receiverId,
    required String? userName,
    required String? userImage,
    required String? orderId,
  }) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkForNewMessages(
        deliveryId: deliveryId,
        senderId: senderId,
        receiverId: receiverId,
        userName: userName,
        userImage: userImage,
        orderId: orderId,
      );
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
  }

  Future<void> _checkForNewMessages({
    required String deliveryId,
    required String senderId,
    required String receiverId,
    required String? userName,
    required String? userImage,
    required String? orderId,
  }) async {
    try {
      print('Polling for new messages...');
      final response = await http.get(
        Uri.parse('https://deliveryapi-ten.vercel.app/chat/$deliveryId'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> messages = [];
        if (data is List) {
          messages = data;
        } else if (data['messages'] != null) {
          messages = data['messages'];
        }

        if (messages.isNotEmpty) {
          final lastMsg = messages.last;

          // Adjust the timestamp to account for the 1-hour discrepancy
          if (lastMsg['timestamp'] != null) {
            final originalTimestamp = DateTime.parse(lastMsg['timestamp']);
            final adjustedTimestamp = originalTimestamp.add(Duration(hours: 1));
            lastMsg['timestamp'] = adjustedTimestamp.toIso8601String();
          }

          final lastMsgId = lastMsg['_id'];
          final isUser = lastMsg['sender_id'] == senderId;

          print(
              'Last message ID: $lastMsgId, isUser: $isUser, _lastMessageId: $_lastMessageId');

          if (!isUser) {
            print('Triggering DIRECT notification for message from rider!');

            final FlutterLocalNotificationsPlugin
                flutterLocalNotificationsPlugin =
                FlutterLocalNotificationsPlugin();

            const AndroidNotificationDetails androidDetails =
                AndroidNotificationDetails(
              'direct_channel',
              'Direct Messages',
              channelDescription: 'Direct notifications for testing',
              importance: Importance.max,
              priority: Priority.max,
              showWhen: true,
              enableVibration: true,
              playSound: true,
              icon: '@mipmap/ic_launcher',
            );

            const DarwinNotificationDetails iOSDetails =
                DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            );

            const NotificationDetails platformDetails = NotificationDetails(
              android: androidDetails,
              iOS: iOSDetails,
            );

            await flutterLocalNotificationsPlugin.show(
              DateTime.now().millisecondsSinceEpoch % 100000,
              'New message from ${userName ?? "Rider"}',
              lastMsg['message'],
              platformDetails,
            );

            // Also try the service approach
            await NotificationService().showMessageNotification(
              title: 'New message from ${userName ?? "Rider"}',
              body: lastMsg['message'] ?? 'You have a new message',
              payload: {
                'type': 'chat',
                'deliveryId': deliveryId,
                'senderId': receiverId,
                'receiverId': senderId,
                'userName': userName,
                'userImage': userImage,
                'orderId': orderId,
              },
            );
            ;

            // Update the last message ID to prevent duplicate notifications
            _lastMessageId = lastMsgId;
          }
        }
      }
    } catch (e) {
      print('Error checking for new messages: $e');
    }
  }
}
