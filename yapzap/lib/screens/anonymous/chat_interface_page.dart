import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ChatInterfacePage extends StatefulWidget {
  final String userId; // Unique identifier for the anonymous user

  ChatInterfacePage({required this.userId});

  @override
  _ChatInterfacePageState createState() => _ChatInterfacePageState();
}

class _ChatInterfacePageState extends State<ChatInterfacePage> {
  late IO.Socket socket;
  final TextEditingController _messageController = TextEditingController();
  List<Map<String, String>> _messages = []; // List of messages with sender info

  @override
  void initState() {
    super.initState();
    _connectToServer();
  }

  // Connects to the WebSocket server
  void _connectToServer() {
    socket = IO.io(
      'http://your-server-url:3000', // Replace with your server URL
      IO.OptionBuilder()
          .setTransports(['websocket']) // Use WebSocket transport
          .disableAutoConnect()
          .build(),
    );

    socket.connect();

    // Listen for events
    socket.onConnect((_) {
      print("Connected to server");
      socket.emit("join", {"userId": widget.userId}); // Emit join event
    });

    socket.on("message", (data) {
      // Update UI when a new message is received
      setState(() {
        _messages.add({"sender": data["sender"], "message": data["message"]});
      });
    });

    socket.onDisconnect((_) => print("Disconnected from server"));
  }

  // Sends a message to the server
  void sendMessage() {
    String message = _messageController.text.trim();
    if (message.isNotEmpty) {
      setState(() {
        _messages.add({"sender": "You", "message": message});
      });
      socket.emit("message", {
        "sender": widget.userId,
        "message": message,
      });
      _messageController.clear();
    }
  }

  @override
  void dispose() {
    socket.disconnect(); // Disconnect from server
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Anonymous Chat"),
        backgroundColor: Color(0xFF7DD2B3), // Green color from theme
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            socket.emit("disconnect_user", {"userId": widget.userId});
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(10),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                bool isSentByUser = _messages[index]["sender"] == "You";
                return Align(
                  alignment: isSentByUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 5),
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSentByUser
                          ? Color(0xFFFFB0FE) // Pink for sent messages
                          : Color(0xFFD7AEF3), // Purple for received messages
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "${_messages[index]["sender"]}: ${_messages[index]["message"]}",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
            ),
          ),
          Divider(height: 1),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            color: Colors.grey[200],
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                IconButton(
                  icon: Icon(Icons.send, color: Color(0xFF7DD2B3)), // Green
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
