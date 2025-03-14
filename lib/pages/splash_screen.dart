import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:micollins_delivery_app/pages/firstPage.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(219, 230, 76, 1),
      body: AnimatedSplashScreen(
        duration: 8000, // 10 seconds
        splash: Center(
          child: Lottie.asset(
            'assets/animations/MicoIntro.json',
            width: MediaQuery.of(context).size.width * 0.8, // Responsive width
            height:
                MediaQuery.of(context).size.height * 0.8, // Responsive height
            fit: BoxFit.contain, // Prevents overflow
          ),
        ),
        nextScreen: const FirstPage(),
        splashTransition: SplashTransition.fadeTransition, // Smooth fade effect
        backgroundColor: const Color.fromRGBO(219, 230, 76, 1),
        animationDuration: const Duration(milliseconds: 2500), // 2.5s animation
      ),
    );
  }
}
