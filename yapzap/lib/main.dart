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
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:yapzap/screens/anonymous/anonymous_chat_lobby_page.dart';
import 'package:yapzap/screens/anonymous/anonymous_entry_page.dart';
import 'package:yapzap/screens/anonymous/chat_interface_page.dart';
import 'package:yapzap/screens/anonymous/random_matchmaking_page.dart';
import 'package:yapzap/screens/forgot_password_page.dart';
import 'package:yapzap/screens/user_profile_page.dart';
// import 'package:yapzap/screens/connect.dart';
import '../screens/navigation_screen.dart';
import 'screens/login_screen_demo.dart';
import 'screens/register_screen_demo.dart';
// import 'screens/home_page_demo.dart';
//import 'screens/chat_screen.dart';
// import 'screens/forgot_password_screen_demo.dart';
import 'screens/splash_page.dart';
import 'screens/login_page.dart';
import 'screens/register_page.dart';
// import 'screens/chat_list.dart';
import 'screens/home.dart';
// import 'screens/friend_details_page.dart';
// import 'models/friend_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
        '/': (context) => const SplashPage(),
        // '/onboarding': (context) => NavigationTestScreen(),
        // '/onboarding': (context) => LoginScreenDemo(),
        '/onboarding': (context) => LoginPage(),
        // '/register': (context) => RegisterScreenDemo(),
        '/registerf': (context) => RegisterScreen(),
        // '/homepage': (context) => HomePageDemo(),
        // '/chatscreen': (context) => WebRTCChatApp(),
        '/forgotpassword': (context) => const ForgotPasswordPage(),
        '/homepage': (context) => const Home(userId: "charan"),
        '/userprofilepage': (context) => const UserProfilePage(userId: "charan"),
        '/AnonymousEntryPage': (context) => AnonymousEntryPage(),
        '/AnonymousChatLobbyPage': (context) => AnonymousChatLobbyPage(),
        '/RandomMatchmakingPage': (context) => RandomMatchmakingPage(),
        // '/ChatInterfacePage': (context) => ChatInterfacePage(),
      },
    );
  }
}
