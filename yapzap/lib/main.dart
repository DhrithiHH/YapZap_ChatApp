import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart'; // Import the Lottie package

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Lottie Animation Example'), // Title of your app
        ),
        body: Center(
          child: Lottie.asset(
            'assets/animations/animation.json', // Path to your animation JSON file
            width: 200, // Set width of the animation
            height: 200, // Set height of the animation
            fit: BoxFit.contain, // Control the animation's fit
          ),
        ),
      ),
    );
  }
}
