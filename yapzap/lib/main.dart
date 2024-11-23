// import 'package:flutter/material.dart';
// import 'package:lottie/lottie.dart'; // Import the Lottie package

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         appBar: AppBar(
//           title: const Text('Lottie Animation Example'), // Title of your app
//         ),
//         body: Center(
//           child: Lottie.asset(
//             'assets/animations/alien_angry.json', // Path to your animation JSON file
//             width: 200, // Set width of the animation
//             height: 200, // Set height of the animation
//             fit: BoxFit.contain, // Control the animation's fit
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import '../screens/navigation_screen.dart';
import 'screens/login_screen_demo.dart';
import 'screens/register_screen_demo.dart';
import 'screens/home_page_demo.dart';
import 'screens/chat_screen.dart';
import 'screens/forgot_password_screen_demo.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Navigation Test',
      initialRoute: '/',
      routes: {
        '/': (context) => NavigationTestScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/homepage': (context) => HomePage(),
        '/chatscreen': (context) => ChatScreen(),
        '/forgotpassword': (context) => ForgotPasswordScreen(),
      },
    );
  }
}

