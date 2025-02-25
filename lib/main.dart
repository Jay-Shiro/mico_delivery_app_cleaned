import 'package:flutter/material.dart';
import 'package:micollins_delivery_app/pages/LoginPage.dart';
import 'package:micollins_delivery_app/pages/MapPage.dart';
import 'package:micollins_delivery_app/pages/RecoverPassword.dart';
import 'package:micollins_delivery_app/pages/SignUpPage.dart';
import 'package:micollins_delivery_app/pages/chat_screen.dart';
import 'package:micollins_delivery_app/pages/firstPage.dart';
import 'package:micollins_delivery_app/pages/homePage.dart';
import 'package:micollins_delivery_app/pages/profilePage.dart';
import 'package:micollins_delivery_app/pages/supportPage.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check if the user is logged in
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = prefs.getBool("isLoggedIn") ?? false;

  runApp(
    ChangeNotifierProvider(
      create: (context) => IndexProvider(),
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
      home: isLoggedIn ? FirstPage() : LoginPage(),
      routes: {
        '/loginpage': (context) => LoginPage(),
        '/signuppage': (context) => SignUpPage(),
        '/resetpasspage': (context) => RecoverPassword(),
        '/homepage': (context) => Homepage(),
        '/firstpage': (context) => FirstPage(),
        '/mappage': (context) => MapPage(),
        '/profilepage': (context) => ProfilePage(),
        '/supportpage': (context) => SupportPage(),
        '/chatpage': (context) => ChatScreen(),
      },
    );
  }
}
