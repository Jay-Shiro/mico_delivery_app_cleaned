import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:micollins_delivery_app/pages/firstPage.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white, // Ensure smooth background
      body: AnimatedSplashScreen(
        duration: 10000, // 10 seconds (in milliseconds)
        splash: Lottie.asset(
          'assets/animations/customerAppIntro.json',
          fit: BoxFit.contain,
          height: screenHeight * 0.5, // 50% of screen height
        ),
        nextScreen: const FirstPage(),
        splashTransition: SplashTransition.fadeTransition, // Smooth fade effect
        backgroundColor: Colors.white, // Matches app theme
        animationDuration: const Duration(milliseconds: 2500), // 2.5s animation
      ),
    );
  }
}
