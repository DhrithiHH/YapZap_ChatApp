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
  bool _isSending = false; // Tracks sending state

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

  /// Fetch previous messages from Firestore
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
          .limit(50)
          .get();

      setState(() {
        _messages.insertAll(
          0,
          snapshot.docs.map((doc) {
            return {
              'from': doc['from'],
              'message': doc['message'],
              'timestamp': doc['timestamp']?.toDate() ?? DateTime.now(),
            };
          }).toList(),
        );
      });
    } catch (e) {
      debugPrint('Error fetching previous messages: $e');
      _showError('Failed to fetch messages. Please try again.');
    }
  }

  /// Handle incoming messages via socket
  void _onMessageReceived(dynamic data) {
    setState(() {
      _messages.insert(0, {
        'from': data['from'],
        'message': data['message'],
        'timestamp': DateTime.now(),
      });
    });
  }

  /// Send a message via socket and store it in Firestore
  Future<void> _sendMessage(String message) async {
    if (_isSending) return; // Prevent multiple clicks
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

      // Send the message via socket
      widget.socket.emit('message', {
        'from': widget.userId,
        'message': message,
        'to': widget.peerId,
      });

      setState(() {
        _messages.insert(0, {
          'from': widget.userId,
          'message': message,
          'timestamp': DateTime.now(),
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

  /// Show error message in a snackbar
  void _showError(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with ${widget.peerId}'),
      ),
      body: Column(
        children: [
          // Message Display Area
          Expanded(
            child: ListView.builder(
              reverse: true, // Show the newest messages at the bottom
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isOwnMessage = message['from'] == widget.userId;

                return Align(
                  alignment:
                      isOwnMessage ? Alignment.centerRight : Alignment.centerLeft,
                  child: Card(
                    color: isOwnMessage
                        ? Colors.blue[100]
                        : Colors.grey[300],
                    margin: const EdgeInsets.symmetric(
                      vertical: 5.0,
                      horizontal: 10.0,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: isOwnMessage
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          Text(
                            message['message'],
                            style: const TextStyle(fontSize: 16.0),
                          ),
                          const SizedBox(height: 5.0),
                          Text(
                            _formatTimestamp(message['timestamp']),
                            style: const TextStyle(fontSize: 12.0, color: Colors.grey),
                          ),
                        ],
                      ),
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
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: _isSending
                      ? const CircularProgressIndicator()
                      : const Icon(Icons.send),
                  onPressed: _messageController.text.trim().isEmpty
                      ? null
                      : () => _sendMessage(_messageController.text.trim()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Format a timestamp into a readable string
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    if (now.difference(timestamp).inDays < 1) {
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
    return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
  }
}
