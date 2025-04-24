import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:micollins_delivery_app/pages/LoginPage.dart';
import 'package:micollins_delivery_app/pages/MapPage.dart';
import 'package:micollins_delivery_app/pages/RecoverPassword.dart';
import 'package:micollins_delivery_app/pages/SignUpPage.dart';
import 'package:micollins_delivery_app/pages/firstPage.dart';
import 'package:micollins_delivery_app/pages/ordersPage.dart';
import 'package:micollins_delivery_app/pages/profilePage.dart';
import 'package:micollins_delivery_app/pages/splash_screen.dart';
import 'package:micollins_delivery_app/pages/supportPage.dart';
import 'package:micollins_delivery_app/pages/user_chat_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:micollins_delivery_app/services/global_message_service.dart';
import 'package:micollins_delivery_app/services/onesignal_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize OneSignal
  await OneSignalService().init();

  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  // Declare userString variable here
  final String? userString = prefs.getString('user');

  // Listen for notification taps
  OneSignalService().onNotificationTapped.listen((payloadString) {
    _handleNotificationTap(payloadString);
  });

  // --- Add this block before runApp ---
  if (isLoggedIn) {
    if (userString != null) {
      final userData = json.decode(userString);
      final userId = userData['_id'];
      // Set external user ID for OneSignal
      if (userId != null) {
        await OneSignalService().setExternalUserId(userId);
      }
    }
  }

  final deliveryId = prefs.getString('deliveryId');
  final orderId = prefs.getString('orderId');
  if (userString != null && deliveryId != null && orderId != null) {
    final userData = json.decode(userString);
    final userId = userData['_id'];
    final userName = userData['name'];
    final userImage = userData['image'];
    final riderId = prefs.getString('riderId') ?? '';

    GlobalMessageService().startPolling(
      deliveryId: deliveryId,
      senderId: userId,
      receiverId: riderId,
      userName: userName,
      userImage: userImage,
      orderId: orderId,
    );
  }

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

void _handleNotificationTap(String payloadString) {
  try {
    final payload = json.decode(payloadString);

    if (payload['type'] == 'message') {
      final deliveryId = payload['deliveryId'];
      final senderId = payload['senderId'];
      final receiverId = payload['receiverId'];
      final orderId = payload['orderId'];
      final userName = payload['userName'] ?? 'Rider';
      final userImage = payload['userImage'];

      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => UserChatScreen(
            userName: userName,
            userImage: userImage,
            orderId: orderId,
            deliveryId: deliveryId,
            senderId: receiverId,
            receiverId: senderId,
            isDeliveryCompleted: false,
          ),
        ),
      );
    }
  } catch (e) {
    print('Error handling notification tap: $e');
  }
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({Key? key, required this.isLoggedIn}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      home: isLoggedIn ? SplashScreen() : LoginPage(),
      routes: {
        '/loginpage': (context) => LoginPage(),
        '/signuppage': (context) => SignUpPage(),
        '/resetpasspage': (context) => RecoverPassword(),
        '/mappage': (context) => MapPage(),
        '/firstpage': (context) => FirstPage(),
        '/orderspage': (context) => OrdersPage(),
        '/profilepage': (context) => ProfilePage(),
        '/supportpage': (context) => SupportPage(),
        '/chatpage': (context) => UserChatScreen(),
      },
    );
  }
}
