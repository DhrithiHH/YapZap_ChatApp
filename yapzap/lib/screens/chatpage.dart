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
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isSending = false;

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

  Future<void> _fetchPreviousMessages() async {
    List<String> users = [widget.userId, widget.peerId];
    users.sort(); // Ensure consistent chatId generation
    String chatId = '${users[0]}_${users[1]}';

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('messages')
          .doc(chatId)
          .collection('chatMessages')
          .orderBy('timestamp', descending: true)
          .get();

      setState(() {
        _messages.addAll(snapshot.docs.map((doc) {
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

  void _onMessageReceived(dynamic data) {
    debugPrint('Message received: $data');
    if (data['from'] != widget.userId) {
      setState(() {
        _messages.insert(0, {
          'from': data['from'],
          'message': data['message'],
        });
      });
    }
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    setState(() => _isSending = true);

    List<String> users = [widget.userId, widget.peerId];
    users.sort(); // Ensure consistent chatId generation
    String chatId = '${users[0]}_${users[1]}';

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

      debugPrint('Message stored in Firestore: $messageObject');

      // Send the message via socket
      widget.socket.emit('message', {
        'message': message,
        'to': widget.peerId,
        'from': widget.userId,
      });

      debugPrint('Message emitted: $messageObject');

      // Update UI
      setState(() {
        _messages.insert(0, {
          'from': widget.userId,
          'message': message,
        });
        _messageController.clear();
      });
    } catch (e) {
      debugPrint('Error sending message: $e');
      _showError('Failed to send message. Please try again.');
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    ));
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
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return Align(
                  alignment: message['from'] == widget.userId
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: message['from'] == widget.userId
                          ? Colors.blue[200]
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      message['message'],
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
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
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    _isSending ? Icons.hourglass_empty : Icons.send,
                    color: _isSending ? Colors.grey : Colors.blue,
                  ),
                  onPressed: _isSending
                      ? null
                      : () {
                          String message = _messageController.text;
                          if (message.isNotEmpty) {
                            _sendMessage(message);
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
