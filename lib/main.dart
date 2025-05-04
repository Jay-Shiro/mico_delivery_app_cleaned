import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upgrader/upgrader.dart';

import 'pages/LoginPage.dart';
import 'pages/MapPage.dart';
import 'pages/RecoverPassword.dart';
import 'pages/SignUpPage.dart';
import 'pages/firstPage.dart';
import 'pages/ordersPage.dart';
import 'pages/profilePage.dart';
import 'pages/splash_screen.dart';
import 'pages/supportPage.dart';
import 'pages/user_chat_screen.dart';

import 'services/global_message_service.dart';
import 'services/onesignal_service.dart';

// Global key for navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize OneSignal
    await OneSignalService().init();

    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final String? userString = prefs.getString('user');

    // Register external user ID if logged in
    if (isLoggedIn && userString != null) {
      final userData = json.decode(userString);
      final userId = userData['_id'];
      if (userId != null) {
        await OneSignalService().setExternalUserId(userId);
      }
    }

    // Start polling chat if saved data exists
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

    // Listen for OneSignal notification taps
    OneSignalService().onNotificationTapped.listen((payloadString) {
      _handleNotificationTap(payloadString);
    });

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => IndexProvider()),
          // Add more providers as needed
        ],
        child: MyApp(isLoggedIn: isLoggedIn),
      ),
    );
  }, (error, stackTrace) {
    print('Uncaught error: $error');
    // Optional: Log to Crashlytics or another service
  });
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

      WidgetsBinding.instance.addPostFrameCallback((_) {
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
              recipientName: '',
            ),
          ),
        );
      });
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
    return UpgradeAlert(
      child: MaterialApp(
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
          '/chatpage': (context) => UserChatScreen(
                deliveryId: '',
                senderId: '',
                receiverId: '',
                recipientName: '',
              ),
        },
      ),
    );
  }
}
