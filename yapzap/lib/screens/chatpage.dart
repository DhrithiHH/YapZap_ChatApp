import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

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
  bool _isVanishMode = false;

  @override
  void initState() {
    super.initState();

    // Listen for vanish mode status updates from the server
    widget.socket.on('vanish_mode_update', (data) {
      if (data['userIds'].contains(widget.userId) && data['userIds'].contains(widget.peerId)) {
        setState(() {
          _isVanishMode = data['isVanishMode'];
        });

        if (_isVanishMode) {
          setState(() {
            _messages.clear(); // Clear messages if vanish mode is on
          });
        }
      }
    });

    // Fetch vanish mode status and previous messages
    _fetchVanishModeStatus();
    _fetchPreviousMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    widget.socket.off('vanish_mode_update');
    super.dispose();
  }

  // Fetch Vanish Mode status
  Future<void> _fetchVanishModeStatus() async {
    List<String> users = [widget.userId, widget.peerId];
    users.sort();
    String chatId = '${users[0]}_${users[1]}';

    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('messages')
          .doc(chatId)
          .get();

      if (docSnapshot.exists) {
        // Check if the 'isVanishMode' field exists
        bool isVanishMode = docSnapshot['isVanishMode'] ?? false;  // Default to false if field is missing
        setState(() {
          _isVanishMode = isVanishMode;
        });

        if (_isVanishMode) {
          setState(() {
            _messages.clear(); // Clear messages if vanish mode is on
          });
        }
      } else {
        // If document does not exist, initialize the chat with vanish mode set to false
        await FirebaseFirestore.instance
            .collection('messages')
            .doc(chatId)
            .set({
          'isVanishMode': false, // Default vanish mode to false
        }, SetOptions(merge: true));

        setState(() {
          _isVanishMode = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching vanish mode status: $e');
      _showErrorMessage('Failed to fetch vanish mode status. Please try again.');
    }
  }

  Future<void> _fetchPreviousMessages() async {
    if (_isVanishMode) return; // Skip fetching messages if vanish mode is active

    List<String> users = [widget.userId, widget.peerId];
    users.sort();
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
            'isStarred': doc['isStarred'] ?? false,
            'messageId': doc.id,
            'timestamp': doc['timestamp'],
          };
        }).toList());
      });
    } catch (e) {
      debugPrint('Error fetching previous messages: $e');
      _showErrorMessage('Failed to load previous messages. Please try again.');
    }
  }

  // Toggle vanish mode
  Future<void> _toggleVanishMode() async {
    List<String> users = [widget.userId, widget.peerId];
    users.sort();
    String chatId = '${users[0]}_${users[1]}';

    try {
      // Toggle vanish mode in Firestore
      await FirebaseFirestore.instance
          .collection('messages')
          .doc(chatId)
          .set({
            'isVanishMode': !_isVanishMode, // Toggle vanish mode
          }, SetOptions(merge: true));

      // Emit vanish mode toggle via socket to the other user
      widget.socket.emit('vanish_mode_update', {
        'userIds': [widget.userId, widget.peerId],
        'isVanishMode': !_isVanishMode,
      });

      setState(() {
        _isVanishMode = !_isVanishMode;
      });

      if (_isVanishMode) {
        setState(() {
          _messages.clear(); // Clear messages if vanish mode is on
        });
      }
    } catch (e) {
      debugPrint('Error toggling vanish mode: $e');
      _showErrorMessage('Failed to toggle vanish mode. Please try again.');
    }
  }

  // Send a message
  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    setState(() => _isSending = true);

    List<String> users = [widget.userId, widget.peerId];
    users.sort();
    String chatId = '${users[0]}_${users[1]}';

    final messageObject = {
      'from': widget.userId,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(), // Use timestamp as messageId
      'isStarred': false,
    };

    try {
      // If vanish mode is not active, store the message in Firestore
      if (!_isVanishMode) {
        await FirebaseFirestore.instance
            .collection('messages')
            .doc(chatId)
            .collection('chatMessages')
            .add(messageObject);
      }

      // Emit the message via socket (always send, even in vanish mode)
      widget.socket.emit('message', {
        'message': message,
        'to': widget.peerId,
        'from': widget.userId,
        'isVanishMode': _isVanishMode, // Send vanish mode status
      });

      // Add message to the local state only if vanish mode is off
      setState(() {
        _messages.insert(0, {
          'from': widget.userId,
          'message': message,
          'isStarred': false,
          'messageId': DateTime.now().millisecondsSinceEpoch.toString(), // Timestamp as messageId
        });
        _messageController.clear();
      });
    } catch (e) {
      debugPrint('Error sending message: $e');
      _showErrorMessage('Failed to send message. Please try again.');
    } finally {
      setState(() => _isSending = false);
    }
  }

  // Delete message from Firestore
  Future<void> _deleteMessage(String messageId) async {
    List<String> users = [widget.userId, widget.peerId];
    users.sort();
    String chatId = '${users[0]}_${users[1]}';

    try {
      await FirebaseFirestore.instance
          .collection('messages')
          .doc(chatId)
          .collection('chatMessages')
          .doc(messageId)
          .delete();
      
      setState(() {
        _messages.removeWhere((message) => message['messageId'] == messageId);
      });
    } catch (e) {
      debugPrint('Error deleting message: $e');
      _showErrorMessage('Failed to delete message. Please try again.');
    }
  }

  // Show error message to user
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Show message options popup
  void _showMessageOptions(BuildContext context, String messageId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Message Options'),
          actions: [
            TextButton(
              onPressed: () {
                _deleteMessage(messageId);
                Navigator.pop(context);
              },
              child: const Text('Delete'),
            ),
            TextButton(
              onPressed: () {
                // Implement Star functionality here
                Navigator.pop(context);
              },
              child: const Text('Star'),
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
        title: const Text('Chat Page'),
        actions: [
          IconButton(
            icon: Icon(
              _isVanishMode ? Icons.visibility_off : Icons.visibility,
            ),
            onPressed: _toggleVanishMode,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
  child: ListView.builder(
    reverse: true,
    itemCount: _messages.length,
    itemBuilder: (context, index) {
      final message = _messages[index];
      return GestureDetector(
        onLongPress: () {
          _showMessageOptions(context, message['messageId']);
        },
        child: Align(
          alignment: message['from'] == widget.userId
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Material(
              color: message['from'] == widget.userId
                  ? Colors.blueAccent  // Color for sent messages
                  : Colors.grey,      // Color for received messages
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  message['message'],
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      );
    },
  ),
),
Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Enter message...',
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                IconButton(
                  icon: _isSending
                      ? const CircularProgressIndicator()
                      : const Icon(Icons.send),
                  onPressed: () {
                    if (!_isSending) {
                      _sendMessage(_messageController.text.trim());
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
