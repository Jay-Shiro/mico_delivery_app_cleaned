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
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:micollins_delivery_app/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notification service
  await NotificationService().init();

  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  // Wrap the app with ChangeNotifierProvider for IndexProvider
  runApp(
    ChangeNotifierProvider(
      create: (_) => IndexProvider(),
      child: MyApp(isLoggedIn: isLoggedIn),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
