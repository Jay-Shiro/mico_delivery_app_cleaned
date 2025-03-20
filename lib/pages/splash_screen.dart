import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:micollins_delivery_app/pages/firstPage.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
      duration: 2800, // 6 seconds
      splash: Center(
        child: Lottie.asset(
          'assets/animations/MicoIntro.json',
          fit: BoxFit.cover,
        ),
      ),

      nextScreen: const FirstPage(),
      splashTransition: SplashTransition.fadeTransition,
      backgroundColor: Colors.white,
      animationDuration: const Duration(milliseconds: 2500),
    );
  }
}
