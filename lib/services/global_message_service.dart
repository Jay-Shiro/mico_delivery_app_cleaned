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
          final lastMsgId = lastMsg['_id'];
          final isUser = lastMsg['sender_id'] == senderId;

          print(
              'Last message ID: $lastMsgId, isUser: $isUser, _lastMessageId: $_lastMessageId');

          if (!isUser) {
            print('Triggering notification for message from rider!');
            
            // Use OneSignal for local notification
            await OneSignalService().sendLocalNotification(
              title: 'New message from ${userName ?? "Rider"}',
              body: lastMsg['message'] ?? 'You have a new message',
              additionalData: {
                'payload': json.encode({
                  'type': 'chat',
                  'deliveryId': deliveryId,
                  'senderId': receiverId,
                  'receiverId': senderId,
                  'userName': userName,
                  'userImage': userImage,
                  'orderId': orderId,
                }),
              },
            );
          }
        }
      }
    } catch (e) {
      print('Error checking for new messages: $e');
    }
  }
}
