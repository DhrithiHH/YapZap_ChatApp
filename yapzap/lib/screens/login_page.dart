import 'package:flutter/material.dart';
import 'dart:math';

// Import your custom button widget
import '../widgets/custom_button.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Bubble Animation Background
          const AnimatedBackground(),

          // Login Form
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Image.asset(
                    'assets/images/yapzap_logo.png',
                    width: 150,
                    height: 150,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Welcome to YapZap!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // White text for contrast
                    fontFamily: 'ComicSans', // Playful font
                  ),
                ),
                const SizedBox(height: 40),
                FadeTransitionWidget(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: const TextStyle(color: Colors.white),
                      prefixIcon: const Icon(Icons.email, color: Colors.white),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FadeTransitionWidget(
                  child: TextField(
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: const TextStyle(color: Colors.white),
                      prefixIcon: const Icon(Icons.lock, color: Colors.white),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                CustomButton(
                  text: 'Login',
                  onPressed: () {
                    Navigator.pushNamed(context, '/home');
                  },
                ),
                const SizedBox(height: 10),
                CustomButton(
                  text: 'Login with Google',
                  color: const Color(0xFF4285F4),
                  onPressed: () {
                    // Add Google login logic
                  },
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/forgot-password');
                  },
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/register');
                  },
                  child: const Text(
                    'Don’t have an account? Register',
                    style: TextStyle(
                      color: Colors.yellowAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Animated Background with Floating Bubbles and Gradient
class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({Key? key}) : super(key: key);

  @override
  _AnimatedBackgroundState createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Bubble> bubbles = List.generate(30, (index) => Bubble());

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF7ED321),
            Color(0xFF4A90E2)
          ], // Green to Blue Gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: BubblePainter(bubbles, _controller.value),
          );
        },
      ),
    );
  }
}

class Bubble {
  late double x;
  late double y;
  late double radius;
  late Color color;

  Bubble() {
    final random = Random();
    x = random.nextDouble(); // Fractional x-coordinate
    y = random.nextDouble(); // Fractional y-coordinate
    radius = random.nextDouble() * 40 + 10; // Radius between 10 and 50
    color = Color.fromRGBO(
      random.nextInt(256),
      random.nextInt(256),
      random.nextInt(256),
      0.4 + random.nextDouble() * 0.3, // Transparency between 0.4 and 0.7
    );
  }
}

class BubblePainter extends CustomPainter {
  final List<Bubble> bubbles;
  final double progress;

  BubblePainter(this.bubbles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (var bubble in bubbles) {
      final dx = bubble.x * size.width;
      final dy = (bubble.y + progress) % 1.0 * size.height;
      final effectiveY = dy < 0 ? dy + size.height : dy;

      paint.color = bubble.color;
      canvas.drawCircle(Offset(dx, effectiveY), bubble.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Fade Transition Widget
class FadeTransitionWidget extends StatefulWidget {
  final Widget child;

  const FadeTransitionWidget({Key? key, required this.child}) : super(key: key);

  @override
  _FadeTransitionWidgetState createState() => _FadeTransitionWidgetState();
}

class _FadeTransitionWidgetState extends State<FadeTransitionWidget>
    with SingleTickerProviderStateMixin {
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
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _animation, child: widget.child);
  }
}
