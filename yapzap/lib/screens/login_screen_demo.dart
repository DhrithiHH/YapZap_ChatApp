import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yapzap/screens/home_page_demo.dart';

class LoginScreenDemo extends StatefulWidget {
  @override
  _LoginScreenDemoState createState() => _LoginScreenDemoState();
}

class _LoginScreenDemoState extends State<LoginScreenDemo> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Function to validate if the input is an email
  bool isEmail(String input) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(input);
  }

  // Function to fetch email by userId
  Future<String?> _getEmailByUserId(String userId) async {
    try {
      final docSnapshot = await _firestore.collection('users').doc(userId).get();
      if (docSnapshot.exists) {
        return docSnapshot.data()?['email']; // Return the email from the document
      } else {
        return null; // No user found with this userId
      }
    } catch (e) {
      print('Error fetching email: $e');
      return null;
    }
  }

  // Function to fetch userId by email
  Future<String?> _getUserIdByEmail(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.id; // Return the document ID (userId)
      } else {
        return null; // Email not found
      }
    } catch (e) {
      print('Error fetching userId: $e');
      return null;
    }
  }

  // Login function
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
        // Input is an email
        email = input;
      } else {
        // Input is a userId, fetch the email from Firestore
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
      // ignore: unused_local_variable
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

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
            builder: (context) => HomePageDemo(userId: userId),
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
      appBar: AppBar(
        title: Text('Login Screen Demo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email or UserId',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.text,
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _login,
              child: const Text('Login'),
            ),
            TextButton(
              onPressed: () {
                // Navigate to the registration screen
                Navigator.pushNamed(context, '/register');
              },
              child: Text('Don\'t have an account? Register here'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}