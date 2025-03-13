import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:micollins_delivery_app/pages/firstPage.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    // ignore: unused_local_variable
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedSplashScreen(
        duration: 10000, // 10 seconds
        splash: SizedBox(
          width: double.infinity, // Full width
          height: screenHeight, // Full height
          child: Lottie.asset(
            'assets/animations/customerAppIntro.json',
            fit: BoxFit.cover, // Ensures it fills the screen
          ),
        ),
        nextScreen: const FirstPage(),
        splashTransition: SplashTransition.fadeTransition, // Smooth fade effect
        backgroundColor: Colors.white,
        animationDuration: const Duration(milliseconds: 2500), // 2.5s animation
      ),
    );
  }
}
