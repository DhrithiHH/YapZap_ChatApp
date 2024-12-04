import 'package:flutter/material.dart';

class AnonymousEntryPage extends StatefulWidget {
  @override
  _AnonymousEntryPageState createState() => _AnonymousEntryPageState();
}

class _AnonymousEntryPageState extends State<AnonymousEntryPage> {
  bool isAnonymousModeEnabled = false;

  // Toggles the Anonymous Mode and shows a snackbar for feedback
  void toggleAnonymousMode(bool value) {
    setState(() {
      isAnonymousModeEnabled = value;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isAnonymousModeEnabled
              ? "Anonymous Mode Enabled"
              : "Anonymous Mode Disabled",
        ),
      ),
    );
  }

  // Displays a confirmation dialog before exiting
  void _showExitConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Exit Anonymous Mode"),
          content: Text("Are you sure you want to exit?"),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            ElevatedButton(
              child: Text("Exit"),
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/homepage', // Replace with your main entry page route
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Anonymous Mode"),
        backgroundColor: Color(0xFFFFB0FE), // Pink color from theme
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () => _showExitConfirmation(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Enable Anonymous Mode to chat without revealing your identity.",
              style: TextStyle(fontSize: 16, color: Colors.black),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            SwitchListTile(
              title: Text(
                "Anonymous Mode",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              value: isAnonymousModeEnabled,
              onChanged: toggleAnonymousMode,
              activeColor: Color(0xFF7DD2B3), // Green color from theme
            ),
            SizedBox(height: 20),
            Text(
              "Chats are end-to-end encrypted for your privacy.",
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => _showExitConfirmation(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF7DD2B3), // Green color from theme
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: Text(
                "Exit Anonymous Mode",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
