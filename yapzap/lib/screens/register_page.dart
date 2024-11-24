import 'package:flutter/material.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB), // Light blue background
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Image.asset(
                'assets/images/yapzap_logo.png',
                width: 100,
                height: 100,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Join YapZap!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF7ED321), // Green
                fontFamily: 'ComicSans', // Playful font
              ),
            ),
            const SizedBox(height: 30),
            TextField(
              decoration: InputDecoration(
                labelText: 'Full Name',
                labelStyle: const TextStyle(color: Color(0xFF9C27B0)), // Purple
                prefixIcon: const Icon(Icons.person, color: Color(0xFF9C27B0)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide:
                      const BorderSide(color: Color(0xFF9C27B0), width: 2),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: const TextStyle(color: Color(0xFF4A90E2)), // Blue
                prefixIcon: const Icon(Icons.email, color: Color(0xFF4A90E2)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide:
                      const BorderSide(color: Color(0xFF4A90E2), width: 2),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: const TextStyle(color: Color(0xFFFF4081)), // Pink
                prefixIcon: const Icon(Icons.lock, color: Color(0xFFFF4081)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide:
                      const BorderSide(color: Color(0xFFFF4081), width: 2),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/home');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7ED321), // Green
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Sign Up',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              child: const Text(
                'Already have an account? Log In',
                style: TextStyle(
                  color: Color(0xFF4A90E2), // Blue
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: AnimatedContainer(
                duration: const Duration(seconds: 2),
                width: 100,
                height: 5,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFF4081),
                      Color(0xFF9C27B0)
                    ], // Pink to Purple gradient
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
