// TODO Implement this library.
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreenDemo extends StatefulWidget {
  @override
  _RegisterScreenDemoState createState() => _RegisterScreenDemoState();
}

class _RegisterScreenDemoState extends State<RegisterScreenDemo> {
  final _userIdController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  void _register() async {
    try {
      final userId = _userIdController.text.trim();
      final username = _usernameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (userId.isEmpty || username.isEmpty || email.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please fill in all fields')),
        );
        return;
      }

      // Check if userId exists
      if (await _checkIfUserIdExists(userId)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User ID already exists. Please choose another.')),
        );
        return;
      }

      // Check if email exists
      if (await _checkIfEmailExists(email)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Email already exists. Please log in.')),
        );
        return;
      }

      // Create user in Firebase Authentication
      // ignore: unused_local_variable
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore
      await _firestore.collection('users').doc(userId).set({
        'userId': userId,
        'username': username,
        'email': email,
        'lastSeen': FieldValue.serverTimestamp(),
        'profilePic': '', // Placeholder, can be updated later
        'status': 'offline', // Default status
        'contacts': [], // Empty contact list
        'archiveMessages': [], // No archived messages initially
        'additionalInfo': {
          'bio': '', // Placeholder bio
          'location': '', // Placeholder location
          'birthdate': null, // Placeholder birthdate
          'phoneNumber': '', // Placeholder phone number
        },
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration successful!')),
      );

      // Navigate to login screen or another page
      // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreenDemo()));
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred, please try again.';
      if (e.code == 'email-already-in-use') {
        message = 'This email is already registered.';
      } else if (e.code == 'weak-password') {
        message = 'Password must be at least 6 characters.';
      }

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register Screen Demo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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
            SizedBox(height: 16.0),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _register,
              child: Text('Register'),
            ),
            TextButton(
              onPressed: () {
                // Navigate to login screen
                // Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreenDemo()));
              },
              child: Text('Already have an account? Login here'),
            ),
          ],
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
