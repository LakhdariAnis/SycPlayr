import 'package:flutter/material.dart';
import 'player.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Start the timer
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      // Navigate to your Home Page
      // Use pushReplacement so the user can't go "back" to the splash screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PlayerPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset('assets/logo.png', width: 200, height: 200),
      ),
    );
  }
}
