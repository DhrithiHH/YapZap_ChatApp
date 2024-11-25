import 'package:flutter/material.dart';

class NavigationTestScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Navigation Test Screen'),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/login');
            },
            child: Text('Go to Login Screen'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/loginf');
            },
            child: Text('Go to Login Page'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/register');
            },
            child: Text('Go to Register Screen'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/registerf');
            },
            child: Text('Go to Register page'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/homepage');
            },
            child: Text('Go to Home Page'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/chatscreen');
            },
            child: Text('Go to Chat Screen'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/forgotpassword');
            },
            child: Text('Go to Forgot Password Screen'),
          ),
        ],
      ),
    );
  }
}