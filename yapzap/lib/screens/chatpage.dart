import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yapzap/screens/webRtc.dart';

class ChatScreen extends StatefulWidget {
  final String userId;
  final String peerId;
  final IO.Socket socket;

  const ChatScreen({
    Key? key,
    required this.userId,
    required this.peerId,
    required this.socket,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late WebRTCLogic _webRTCLogic;
  TextEditingController _messageController = TextEditingController();
  List<Map<String, dynamic>> messages = [];

  @override
  void initState() {
    super.initState();

    // Initialize WebRTC logic with userId, peerId, and socket
    _webRTCLogic = WebRTCLogic(widget.userId, widget.peerId, widget.socket);

    // Fetch previous messages
    _fetchPreviousMessages();
  }

  @override
  void dispose() {
    // Dispose WebRTC resources when leaving the screen
    _webRTCLogic.endCall();
    super.dispose();
  }

  // Fetch previous messages from Firestore
  Future<void> _fetchPreviousMessages() async {
    List<String> users = [widget.userId, widget.peerId];
    users.sort(); // Ensure consistent chatId generation.
    String chatId = '${users[0]}_${users[1]}';

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('messages')
          .doc(chatId)
          .collection('chatMessages')
          .orderBy('timestamp')
          .get();

      setState(() {
        messages.addAll(snapshot.docs.map((doc) {
          return {
            'from': doc['from'],
            'message': doc['message'],
          };
        }).toList());
      });
    } catch (e) {
      debugPrint('Error fetching previous messages: $e');
    }
  }

  // Send message to Firestore
  Future<void> _sendMessage(String message) async {
    List<String> users = [widget.userId, widget.peerId];
    users.sort(); // Ensure consistent chatId generation.
    String chatId = '${users[0]}_${users[1]}';

    try {
      await FirebaseFirestore.instance.collection('messages').doc(chatId).collection('chatMessages').add({
        'from': widget.userId,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
      });

      setState(() {
        messages.add({
          'from': widget.userId,
          'message': message,
        });
      });
      _messageController.clear();
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Page'),
        actions: [
          IconButton(
            icon: Icon(Icons.call), // Audio Call Icon
            onPressed: () {
              _webRTCLogic.startCall(); // Start the audio call
            },
          ),
          IconButton(
            icon: Icon(Icons.videocam), // Video Call Icon
            onPressed: () {
              _webRTCLogic.startCall(); // Start the video call
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Message Display Area
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return ListTile(
                  title: Text(message['message']),
                  subtitle: Text(message['from']),
                );
              },
            ),
          ),

          // Text Input and Send Button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    String message = _messageController.text;
                    if (message.isNotEmpty) {
                      _sendMessage(message); // Send the message to Firestore
                      _webRTCLogic.sendMessage(message); // Send message over WebRTC
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
