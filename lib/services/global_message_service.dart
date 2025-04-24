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
      final response = await http.get(
        Uri.parse('https://deliveryapi-ten.vercel.app/chat/$deliveryId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String? latestMessageId;
        bool hasNewMessage = false;
        
        // Process messages to find the latest one
        if (data is List && data.isNotEmpty) {
          final latestMessage = data.last;
          latestMessageId = latestMessage['_id'];
          
          // Check if this is a new message
          if (_lastMessageId != latestMessageId && 
              latestMessage['sender_id'] != senderId) {
            hasNewMessage = true;
          }
        } else if (data['messages'] != null && data['messages'].isNotEmpty) {
          final latestMessage = data['messages'].last;
          latestMessageId = latestMessage['_id'];
          
          // Check if this is a new message
          if (_lastMessageId != latestMessageId && 
              latestMessage['sender_id'] != senderId) {
            hasNewMessage = true;
          }
        }
        
        // Update the last message ID
        if (latestMessageId != null) {
          _lastMessageId = latestMessageId;
        }
        
        // If there's a new message and it's not from the current user, show a notification
        if (hasNewMessage) {
          // Mark messages as read if the chat is currently open
          await http.put(
            Uri.parse('https://deliveryapi-ten.vercel.app/chat/$deliveryId/$senderId/mark-read'),
          );
          
          // Send a local notification
          NotificationService().showMessageNotification(
            title: 'New message from ${userName ?? "User"}',
            body: 'You have a new message',
            payload: {
              'type': 'chat',
              'deliveryId': deliveryId,
              'senderId': receiverId, // Swap sender and receiver for the notification
              'receiverId': senderId,
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
}
