import 'package:flutter/material.dart';

class ConnectUsersPage extends StatelessWidget {
  const ConnectUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect Users'),
      ),
      body: const Center(
        child: Text(
          'Connect Users Page',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}