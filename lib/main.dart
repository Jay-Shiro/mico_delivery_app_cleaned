import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:micollins_delivery_app/pages/LoginPage.dart';
import 'package:micollins_delivery_app/pages/MapPage.dart';
import 'package:micollins_delivery_app/pages/RecoverPassword.dart';
import 'package:micollins_delivery_app/pages/SignUpPage.dart';
import 'package:micollins_delivery_app/pages/firstPage.dart'; // Import FirstPage to access IndexProvider
import 'package:micollins_delivery_app/pages/ordersPage.dart';
import 'package:micollins_delivery_app/pages/profilePage.dart';
import 'package:micollins_delivery_app/pages/splash_screen.dart';
import 'package:micollins_delivery_app/pages/supportPage.dart';
import 'package:micollins_delivery_app/pages/user_chat_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:micollins_delivery_app/services/notification_service.dart';

// Add a navigator key to access navigation from outside the widget tree
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Add this near the beginning of your main() function
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize notification service
  await NotificationService().init();
  
  // Check login status
  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  
  // Listen for notification taps
  NotificationService().onNotificationTapped.listen((payloadString) {
    _handleNotificationTap(payloadString);
  });
  
  runApp(MyApp(isLoggedIn: isLoggedIn));
}

// Make sure the _handleNotificationTap function is properly implemented
void _handleNotificationTap(String payloadString) {
  try {
    final payload = json.decode(payloadString);
    
    if (payload['type'] == 'message') {
      // Get the necessary data from the payload
      final deliveryId = payload['deliveryId'];
      final senderId = payload['senderId'];
      final receiverId = payload['receiverId'];
      final orderId = payload['orderId'];
      final userName = payload['userName'] ?? 'Rider';
      final userImage = payload['userImage'];
      
      // Navigate to the chat screen
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => UserChatScreen(
            userName: userName,
            userImage: userImage,
            orderId: orderId,
            deliveryId: deliveryId,
            senderId: receiverId,  // Note: these are swapped because we're opening from notification
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
      navigatorKey: navigatorKey, // Add this line
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
