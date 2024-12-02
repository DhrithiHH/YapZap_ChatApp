import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:cloud_firestore/cloud_firestore.dart';

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
  TextEditingController _messageController = TextEditingController();
  List<Map<String, dynamic>> messages = [];

  @override
  void initState() {
    super.initState();

    // Listen for incoming messages via socket
    widget.socket.on('message', _onMessageReceived);

    // Fetch previous messages from Firestore
    _fetchPreviousMessages();
  }

  @override
  void dispose() {
    // Remove the listener for chat messages
    widget.socket.off('message', _onMessageReceived);
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

  // Handle incoming messages via socket
  void _onMessageReceived(dynamic data) {
    debugPrint('Message received: $data');

    setState(() {
      messages.add({
        'from': data['from'],
        'message': data['message'],
      });
    });
  }

  // Send a message via socket and store it in Firestore
  Future<void> _sendMessage(String message) async {
    List<String> users = [widget.userId, widget.peerId];
    users.sort(); // Ensure consistent chatId generation.
    String chatId = '${users[0]}_${users[1]}';

    // Message object
    final messageObject = {
      'from': widget.userId,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      // Store the message in Firestore
      await FirebaseFirestore.instance
          .collection('messages')
          .doc(chatId)
          .collection('chatMessages')
          .add(messageObject);

      // Send the message via socket
      widget.socket.emit('message', {messageObject, widget.peerId});

      debugPrint('Message sent: $messageObject');

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
                      _sendMessage(message); // Send the message
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
