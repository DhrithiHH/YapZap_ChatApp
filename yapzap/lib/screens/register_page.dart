import 'package:flutter/material.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Remove the backgroundColor property to let the gradient take over
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFF4081), // Pink
              Color(0xFF9C27B0), // Purple
              Color(0xFFFFA527), // Orange
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo with Fade Transition
              FadeTransition(
                opacity: AlwaysStoppedAnimation(1.0),
                child: Center(
                  child: Image.asset(
                    'assets/images/yapzap_logo.png', // Ensure the logo path is correct
                    width: 100,
                    height: 100,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title with white color
              const Text(
                'Join YapZap!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // White title
                  fontFamily: 'ComicSans', // Playful font
                ),
              ),
              const SizedBox(height: 30),

              // Full Name Input
              _buildTextField(
                  'Full Name', Icons.person, Color(0xFF9C27B0), false),
              const SizedBox(height: 20),

              // Email Input
              _buildTextField('Email', Icons.email, Color(0xFF4A90E2), false),
              const SizedBox(height: 20),

              // Password Input
              _buildTextField('Password', Icons.lock, Color(0xFFFF4081), true),
              const SizedBox(height: 30),

              // Register Button with Gradient
              _buildGradientButton(context, 'Sign Up', () {
                Navigator.pushNamed(context, '/home');
              }),
              const SizedBox(height: 10),

              // Login Link
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

              // Animated Gradient Line
              AnimatedContainer(
                duration: const Duration(seconds: 2),
                width: 100,
                height: 5,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFF4081),
                      Color(0xFF9C27B0),
                    ], // Pink to Purple gradient
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Reusable TextField Widget without Blur Effect or Border
  Widget _buildTextField(
      String label, IconData icon, Color iconColor, bool obscureText) {
    return TextField(
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: iconColor,
        ), // Use the respective color for text field labels
        prefixIcon: Icon(icon, color: iconColor),
        filled: true,
        fillColor: Colors.white.withOpacity(0.7), // Translucent fill color
        border: InputBorder.none, // Remove the border
      ),
    );
  }

  // Reusable Gradient Button
  Widget _buildGradientButton(
      BuildContext context, String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF7ED321), // Green button color
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      child: const Text(
        'Sign Up',
        style: TextStyle(fontSize: 18, color: Colors.white),
      ),
    );
  }
}
