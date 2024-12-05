import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yapzap/screens/home.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _controller.dispose();
    super.dispose();
  }

  bool isEmail(String input) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(input);
  }

  Future<String?> _getEmailByUserId(String userId) async {
    try {
      final docSnapshot = await _firestore.collection('users').doc(userId).get();
      if (docSnapshot.exists) {
        return docSnapshot.data()?['email'];
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching email: $e');
      return null;
    }
  }

  Future<String?> _getUserIdByEmail(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      return querySnapshot.docs.isNotEmpty ? querySnapshot.docs.first.id : null;
    } catch (e) {
      print('Error fetching userId: $e');
      return null;
    }
  }

  Future<void> _login() async {
    try {
      final input = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (input.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter email/userId and password')),
        );
        return;
      }

      String email;

      if (isEmail(input)) {
        email = input;
      } else {
        final fetchedEmail = await _getEmailByUserId(input);
        if (fetchedEmail == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No email found for the provided userId.')),
          );
          return;
        }
        email = fetchedEmail;
      }

      // Firebase Auth login
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      // Fetch the userId by querying Firestore
      final userId = await _getUserIdByEmail(email);

      if (userId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login Successful')),
        );

        // Navigate to the homepage, passing the userId
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => Home(userId: userId),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No userId found for the provided email.')),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred, please try again.';
      if (e.code == 'user-not-found') {
        message = 'No user found with this email/userId.';
      } else if (e.code == 'wrong-password') {
        message = 'Incorrect password.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unexpected error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(),
          Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: FadeTransition(
                opacity: _animation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Welcome to YapZap!',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    BubbleTextField(
                      controller: _emailController,
                      hint: 'Enter email or userId',
                      icon: Icons.person,
                    ),
                    const SizedBox(height: 20),
                    BubbleTextField(
                      controller: _passwordController,
                      hint: 'Enter password',
                      icon: Icons.lock,
                      isPassword: true,
                    ),
                    const SizedBox(height: 20),
                    PurpleButton(
                      text: 'Login',
                      onPressed: _login,
                    ),
                    const SizedBox(height: 20),
                    PurpleButton(
                      text: 'Login with Google',
                      onPressed: () {
                        // TODO: Implement Google login logic
                      },
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/registerf');
                      },
                      child: const Text(
                        'Don\'t have an account? Register here',
                        style: TextStyle(color: Color.fromARGB(255, 59, 10, 87)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedBackground extends StatelessWidget {
  const AnimatedBackground({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xF7F7F9), // Pink background
      ),
    );
  }
}

class BubbleTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool isPassword;

  const BubbleTextField({
    Key? key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.isPassword = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F9), // Whitish Grey
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1), // Lighter shadow color
            blurRadius: 15.0, // Increase blur radius for a smoother shadow
            spreadRadius: 5.0, // Spread the shadow a bit further
            offset: const Offset(0, 4), // Vertical shadow offset
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFCACBCF)), // Grey placeholder
          prefixIcon: Icon(icon, color: Colors.black),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class PurpleButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const PurpleButton({Key? key, required this.text, required this.onPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFFB0FE), // PINK button
        minimumSize: const Size.fromHeight(50), // Match text field size
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}
