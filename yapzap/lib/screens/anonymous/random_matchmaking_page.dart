import 'package:flutter/material.dart';

class RandomMatchmakingPage extends StatefulWidget {
  @override
  _RandomMatchmakingPageState createState() => _RandomMatchmakingPageState();
}

class _RandomMatchmakingPageState extends State<RandomMatchmakingPage> {
  bool isSearching = true;
  String userId = "#1234"; // Temporary random identifier

  void skipMatch() {
    setState(() {
      isSearching = true;
      userId =
          "#${(1000 + (9999 - 1000) * (new DateTime.now().millisecondsSinceEpoch % 1000) / 1000).toInt()}"; // Generate new random ID
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Searching for a new match...")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Connecting..."),
        backgroundColor: Color(0xFFFFB0FE), // Pink color from theme
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isSearching
                ? Column(
                    children: [
                      CircularProgressIndicator(
                        color: Color(0xFF7DD2B3), // Green color from theme
                      ),
                      SizedBox(height: 20),
                      Text(
                        "Searching for a random user...",
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
                      SizedBox(height: 20),
                      Text(
                        "Your ID: $userId",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  )
                : Text(
                    "Match found! Redirecting to chat...",
                    style: TextStyle(fontSize: 16, color: Colors.green),
                  ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: skipMatch,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFD7AEF3), // Purple color from theme
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                "Skip / Disconnect",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
