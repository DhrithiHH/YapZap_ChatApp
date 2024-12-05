import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class RandomMatchmakingPage extends StatefulWidget {
  @override
  _RandomMatchmakingPageState createState() => _RandomMatchmakingPageState();
}

class _RandomMatchmakingPageState extends State<RandomMatchmakingPage> {
  late IO.Socket socket;
  bool isSearching = true;
  String userId = "#1234"; // Temporary random identifier
  String? matchUserId;
  String? sessionId;

  @override
  void initState() {
    super.initState();
    connectToSocket();
  }

  void connectToSocket() {
    socket = IO.io('http://your-backend-url', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();

    socket.onConnect((_) {
      print("Connected to the server");
      findMatch();
    });

    socket.on('waiting-for-match', (_) {
      setState(() {
        isSearching = true;
      });
    });

    socket.on('matched', (data) {
      setState(() {
        isSearching = false;
        matchUserId = data['matchUser'];
        sessionId = data['sessionId'];
      });
    });

    socket.on('user-left', (data) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("User ${data['userId']} left the match.")),
      );
      resetState();
    });
  }

  void findMatch() {
    socket.emit('find-match', {'userId': userId});
  }

  void leaveQueue() {
    socket.emit('leave-queue', {'userId': userId});
  }

  void leaveChat() {
    if (sessionId != null) {
      socket.emit('leave-chat', {'sessionId': sessionId, 'userId': userId});
    }
    resetState();
  }

  void resetState() {
    setState(() {
      isSearching = true;
      matchUserId = null;
      sessionId = null;
    });
  }

  @override
  void dispose() {
    leaveQueue();
    socket.disconnect();
    super.dispose();
  }

  void skipMatch() {
    leaveQueue();
    setState(() {
      isSearching = true;
      userId =
          "#${(1000 + (9999 - 1000) * (DateTime.now().millisecondsSinceEpoch % 1000) / 1000).toInt()}";
    });
    findMatch();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Searching for a new match...")),
    );
  }

  void disconnectMatch() {
    leaveChat();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Disconnected from the match.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isSearching ? "Connecting..." : "Matched!"),
        backgroundColor: Color(0xFFFFB0FE),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            leaveQueue();
            Navigator.pop(context);
          },
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
                        color: Color(0xFF7DD2B3),
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
                : Column(
                    children: [
                      Text(
                        "Match found! Redirecting to chat...",
                        style: TextStyle(fontSize: 16, color: Colors.green),
                      ),
                      SizedBox(height: 20),
                      Text(
                        "Matched User ID: $matchUserId",
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    ],
                  ),
            SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: skipMatch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFD7AEF3),
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    "Skip",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
                SizedBox(width: 20),
                ElevatedButton(
                  onPressed: disconnectMatch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    "Disconnect",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
