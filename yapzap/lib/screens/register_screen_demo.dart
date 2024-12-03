import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yapzap/screens/home_page_demo.dart';

class RegisterScreenDemo extends StatefulWidget {
  @override
  _RegisterScreenDemoState createState() => _RegisterScreenDemoState();
}

class _RegisterScreenDemoState extends State<RegisterScreenDemo> {
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Check if User ID already exists in Firestore
  Future<bool> _checkIfUserIdExists(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    return userDoc.exists;
  }

  // Check if Email already exists in Firestore
  Future<bool> _checkIfEmailExists(String email) async {
    final querySnapshot = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .get();
    return querySnapshot.docs.isNotEmpty;
  }

  // Registration function
  Future<void> _register() async {
    try {
      final userId = _userIdController.text.trim();
      final username = _usernameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      // Validate input fields
      if (userId.isEmpty ||
          username.isEmpty ||
          email.isEmpty ||
          password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all fields')),
        );
        return;
      }

      // Check if User ID already exists
      if (await _checkIfUserIdExists(userId)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('User ID already exists. Please choose another.')),
        );
        return;
      }

      // Check if Email already exists
      if (await _checkIfEmailExists(email)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email already exists. Please log in.')),
        );
        return;
      }

      // Register user with Firebase Auth
      // ignore: unused_local_variable
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Add user data to Firestore
      Map<String, dynamic> newUser = {
        'userId': userId,
        'username': username,
        'email': email,
        'lastSeen': FieldValue.serverTimestamp(),
        'profilePic': '', // Empty profile picture initially
        'status': 'offline', // Default status
        'contacts': [], // Empty contacts list
        'requestR': [], // Empty contacts list
        'requestS': [], // Empty contacts list
        'archiveMessages': [], // Empty archive
        'additionalInfo': {
          'bio': '',
          'location': '',
          'birthdate': null,
          'phoneNumber': '',
        },
      };

      await _firestore.collection('users').doc(userId).set(newUser);

      // Navigate to HomePageDemo and pass userId
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePageDemo(userId: userId),
        ),
      );

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration successful!')),
      );
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
        SnackBar(content: Text('An unexpected error occurred: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Screen Demo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _userIdController,
                decoration: const InputDecoration(
                  labelText: 'User ID',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _register,
                child: const Text('Register'),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to login screen
                  Navigator.pushNamed(context, '/login');
                },
                child: const Text('Already have an account? Login here'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
