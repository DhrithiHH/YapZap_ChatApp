import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'webRtc.dart'; // Assuming your WebRTCLogic is in this file.
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ChatScreen extends StatefulWidget {
  final String userId;
  final String peerId;
  final IO.Socket socket; // Accept socket as a parameter

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
  final TextEditingController messageController = TextEditingController();
  final List<Map<String, dynamic>> messages = [];
  late WebRTCLogic webRTCLogic;

  @override
  void initState() {
    super.initState();
    _initializeWebRTC();
    _fetchPreviousMessages();
  }

  @override
  void dispose() {
    webRTCLogic.dispose(); // Close WebRTC connections.
    messageController.dispose();
    super.dispose();
  }

  // Initialize WebRTC and connect to the signaling server
  Future<void> _initializeWebRTC() async {
    webRTCLogic = WebRTCLogic(widget.userId, widget.peerId, widget.socket);
    await webRTCLogic.initMedia();

    // Listen for incoming messages through WebRTC data channel
    webRTCLogic.dataChannel.onMessage = (RTCDataChannelMessage message) {
      setState(() {
        messages.add({
          'from': widget.peerId,
          'message': message.text,
        });
      });
    };
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

  // Send a message via Firestore and WebRTC
  void _sendMessage() {
    final message = messageController.text.trim();
    if (message.isEmpty) return;

    // Generate a consistent chatId
    List<String> users = [widget.userId, widget.peerId];
    users.sort();
    String chatId = '${users[0]}_${users[1]}';

    // Save the message in Firestore
    FirebaseFirestore.instance
        .collection('messages')
        .doc(chatId)
        .collection('chatMessages')
        .add({
      'from': widget.userId,
      'message': message,
      'timestamp': Timestamp.now(),
    });

    // Update the UI immediately
    setState(() {
      messages.add({'from': widget.userId, 'message': message});
      messageController.clear();
    });

    // Try to send the message through WebRTC data channel
    try {
      if (webRTCLogic.dataChannel.state ==
          RTCDataChannelState.RTCDataChannelOpen) {
        webRTCLogic.sendMessage(message);
      } else {
        debugPrint(
            'Data channel is not initialized or not open. Message saved to Firestore only.');
      }
    } catch (e) {
      debugPrint('Error sending message via WebRTC: $e');
    }
  }

  // Start Audio Call
  void _startAudioCall() {
    webRTCLogic.startCall();
  }

  // Start Video Call
  void _startVideoCall() {
    webRTCLogic.startCall();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              child: Text(widget.peerId.substring(0, 2).toUpperCase()),
            ),
            const SizedBox(width: 10),
            Expanded(
              // Fix for RenderFlex overflow
              child: Text(
                'Chat with ${widget.peerId}',
                overflow: TextOverflow.ellipsis, // Ensures text truncation
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.phone),
            onPressed: _startAudioCall, // Audio call button
          ),
          IconButton(
            icon: Icon(Icons.videocam),
            onPressed: _startVideoCall, // Video call button
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final isMine = messages[index]['from'] == widget.userId;
                return Align(
                  alignment:
                      isMine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    margin:
                        const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    decoration: BoxDecoration(
                      color: isMine ? Colors.blueAccent : Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      messages[index]['message'],
                      style: TextStyle(
                        color: isMine ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  // Fix for RenderFlex overflow
                  child: TextField(
                    controller: messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _sendMessage,
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
