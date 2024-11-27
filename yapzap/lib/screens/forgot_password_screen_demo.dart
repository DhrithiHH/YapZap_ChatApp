// import 'package:flutter/material.dart';
// import 'package:yapzap/screens/login_page.dart';
// import 'dart:math';

// import 'package:yapzap/widgets/custom_button.dart';

// class ForgotPasswordPage extends StatelessWidget {
//   const ForgotPasswordPage({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           // Animated Background with Bubbles
//           const AnimatedBackground(),

//           // Forgot Password Form
//           Padding(
//             padding: const EdgeInsets.all(20.0),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 // Animated Avatar
//                 Center(
//                   child: Transform.rotate(
//                     angle:
//                         sin(DateTime.now().millisecondsSinceEpoch / 500) * 0.1,
//                     child: Image.asset(
//                       'assets/images/forgot_password_alien.png',
//                       width: 150,
//                       height: 150,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 const Text(
//                   'Forgot Your Password?',
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     fontSize: 26,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white,
//                     fontFamily: 'ComicSans',
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 const Text(
//                   'No worries! We’ll help you reset it.',
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     fontSize: 16,
//                     color: Colors.white70,
//                   ),
//                 ),
//                 const SizedBox(height: 30),

//                 // Email Input Field
//                 FadeTransitionWidget(
//                   child: TextField(
//                     decoration: InputDecoration(
//                       labelText: 'Enter Your Email',
//                       labelStyle: const TextStyle(color: Colors.white),
//                       prefixIcon: const Icon(Icons.email, color: Colors.white),
//                       filled: true,
//                       fillColor: Colors.white.withOpacity(0.2),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(20),
//                         borderSide: BorderSide.none,
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 30),

//                 // Reset Password Button
//                 CustomButton(
//                   text: 'Send Reset Link',
//                   onPressed: () {
//                     // Reset password logic
//                     showDialog(
//                       context: context,
//                       builder: (context) {
//                         return AlertDialog(
//                           backgroundColor: Colors.deepPurpleAccent,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(20),
//                           ),
//                           content: Column(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               Image.asset(
//                                 'assets/images/email_sent.png',
//                                 width: 80,
//                                 height: 80,
//                               ),
//                               const SizedBox(height: 20),
//                               const Text(
//                                 'Success!',
//                                 style: TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 20,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                               const SizedBox(height: 10),
//                               const Text(
//                                 'Check your email for reset instructions.',
//                                 textAlign: TextAlign.center,
//                                 style: TextStyle(color: Colors.white70),
//                               ),
//                               const SizedBox(height: 20),
//                               CustomButton(
//                                 text: 'Got It!',
//                                 onPressed: () => Navigator.pop(context),
//                               ),
//                             ],
//                           ),
//                         );
//                       },
//                     );
//                   },
//                 ),
//                 const SizedBox(height: 10),

//                 // Back to Login Button
//                 TextButton(
//                   onPressed: () {
//                     Navigator.pop(context);
//                   },
//                   child: const Text(
//                     'Back to Login',
//                     style: TextStyle(
//                       color: Colors.yellowAccent,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
