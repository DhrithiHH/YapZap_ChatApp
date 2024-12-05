import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenDemoState createState() => _RegisterScreenDemoState();
}

class _RegisterScreenDemoState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _userIdController = TextEditingController();
  final _usernameController = TextEditingController();
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
    _userIdController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _controller.dispose();
    super.dispose();
  }

  bool isEmail(String input) {
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(input);
  }

  Future<bool> _checkIfUserIdExists(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    return userDoc.exists;
  }

  Future<bool> _checkIfEmailExists(String email) async {
    final querySnapshot = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .get();
    return querySnapshot.docs.isNotEmpty;
  }

  Future<void> _register() async {
    try {
      final userId = _userIdController.text.trim();
      final username = _usernameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (userId.isEmpty || username.isEmpty || email.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all fields')),
        );
        return;
      }

      if (!isEmail(email)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid email')),
        );
        return;
      }

      if (await _checkIfUserIdExists(userId)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User ID already exists. Please choose another.')),
        );
        return;
      }

      if (await _checkIfEmailExists(email)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email already exists. Please log in.')),
        );
        return;
      }

      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection('users').doc(userId).set({
        'userId': userId,
        'username': username,
        'email': email,
        'lastSeen': FieldValue.serverTimestamp(),
        'profilePic': '',
        'status': 'offline',
        'contacts': [],
        'requestR': [],
        'requestS': [],
        'archiveMessages': [],
        'additionalInfo': {
          'bio': '',
          'location': '',
          'birthdate': null,
          'phoneNumber': '',
        },
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration successful!')),
      );

      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred, please try again.';
      if (e.code == 'email-already-in-use') {
        message = 'This email is already registered.';
      } else if (e.code == 'weak-password') {
        message = 'Password must be at least 6 characters.';
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
                    const Text(
                      'Create a New Account',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 30),
                    BubbleTextField(
                      controller: _userIdController,
                      hint: 'Enter User ID',
                      // label: 'User ID',
                      icon: Icons.person,
                    ),
                    const SizedBox(height: 20),
                    BubbleTextField(
                      controller: _usernameController,
                      hint: 'Enter Username',
                      // label: 'Username',
                      icon: Icons.account_circle,
                    ),
                    const SizedBox(height: 20),
                    BubbleTextField(
                      controller: _emailController,
                      hint: 'Enter Email',
                      // label: 'Email',
                      icon: Icons.email,
                    ),
                    const SizedBox(height: 20),
                    BubbleTextField(
                      controller: _passwordController,
                      hint: 'Enter Password',
                      // label: 'Password',
                      icon: Icons.lock,
                      isPassword: true,
                    ),
                    const SizedBox(height: 20),
                    PurpleButton(
                      text: 'Register',
                      onPressed: _register,
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/login');
                      },
                      child: const Text(
                        'Already have an account? Login here',
                        style: TextStyle(color: Colors.purple),
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
        color: Color(0xFFF7F7F9),
      ),
    );
  }
}

class BubbleTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  // final String label;
  final IconData icon;
  final bool isPassword;

  const BubbleTextField({
    Key? key,
    required this.controller,
    required this.hint,
    // required this.label,
    required this.icon,
    this.isPassword = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Padding(
        //   padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
        //   child: Text(
        //     label,
        //     style: const TextStyle(
        //       color: Colors.black,
        //       fontSize: 14.0,
        //       fontWeight: FontWeight.w500,
        //     ),
        //   ),
        // ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15.0,
                spreadRadius: 5.0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFFCACBCF)),
              prefixIcon: Icon(icon, color: Colors.black),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
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
        backgroundColor: const Color(0xFFFFB0FE),
        minimumSize: const Size.fromHeight(50),
      ),
      onPressed: onPressed,
      child: Text(text),
    );
  }
}
