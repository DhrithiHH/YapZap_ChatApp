import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yapzap/screens/CallScreen.dart';

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

    // Listen for incoming messages
    widget.socket.on('message', _onMessageReceived);

    // Listen for incoming calls
    widget.socket.on('call', _handleIncomingCall);

    // Fetch vanish mode status and previous messages
    _fetchVanishModeStatus();
    _fetchPreviousMessages();
  }

  @override
  void dispose() {
    // Remove socket listeners
    widget.socket.off('message', _onMessageReceived);
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
        setState(() {
          _isVanishMode = docSnapshot['isVanishMode'] ?? false;
        });

        if (_isVanishMode) {
          // Clear previous messages if vanish mode is enabled
          setState(() {
            _messages.clear();
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching vanish mode status: $e');
    }
  }

  // Fetch previous messages if vanish mode is off
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
          };
        }).toList());
      });
    } catch (e) {
      debugPrint('Error fetching previous messages: $e');
    }
  }

  // Handle incoming message
  void _onMessageReceived(dynamic data) {
    if (_isVanishMode) return; // Do not show message if vanish mode is on

    if (data['from'] != widget.userId) {
      setState(() {
        _messages.insert(0, {
          'from': data['from'],
          'message': data['message'],
        });
      });
    }
  }

  // Toggle vanish mode
  Future<void> _toggleVanishMode() async {
    List<String> users = [widget.userId, widget.peerId];
    users.sort();
    String chatId = '${users[0]}_${users[1]}';

    try {
      await FirebaseFirestore.instance
          .collection('messages')
          .doc(chatId)
          .set({
            'isVanishMode': !_isVanishMode, // Toggle vanish mode
          }, SetOptions(merge: true));

      setState(() {
        _isVanishMode = !_isVanishMode;
      });

      if (_isVanishMode) {
        setState(() {
          _messages.clear(); // Clear messages on Vanish Mode activation
        });
      }
    } catch (e) {
      debugPrint('Error toggling vanish mode: $e');
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
      'timestamp': FieldValue.serverTimestamp(),
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
          });
          _messageController.clear();
        });
    } catch (e) {
      debugPrint('Error sending message: $e');
    } finally {
      setState(() => _isSending = false);
    }
  }

  // Initiate a call
  void _initiateCall(String peerId, String callType) {
    final callData = {
      'from': widget.userId,
      'to': peerId,
      'type': callType,
    };

    widget.socket.emit('call', callData);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CallPage(data: callData, socket: widget.socket),
      ),
    );
  }

  // Handle incoming call
  void _handleIncomingCall(dynamic data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CallPage(data: data, socket: widget.socket, incoming: true),
      ),
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
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {
              _initiateCall(widget.peerId, 'video');
            },
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
                return Align(
                  alignment: message['from'] == widget.userId
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
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
                  ),
                  onPressed: _isSending
                      ? null
                      : () {
                          _sendMessage(_messageController.text);
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
