import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:yapzap/screens/webRtc.dart';
// import 'webrtc_logic.dart';

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
  late WebRTCLogic _webRTCLogic;

  @override
  void initState() {
    super.initState();

    // Initialize WebRTC logic with userId, peerId, and socket
    _webRTCLogic = WebRTCLogic(widget.userId, widget.peerId, widget.socket);
  }

  @override
  void dispose() {
    // Dispose WebRTC resources when leaving the screen
    _webRTCLogic.endCall();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                _webRTCLogic.startCall();
              },
              child: const Text('Start Call'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _webRTCLogic.sendMessage('Hello from Chat Screen!');
              },
              child: const Text('Send Message'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _webRTCLogic.endCall();
              },
              child: const Text('End Call'),
            ),
          ],
        ),
      ),
    );
  }
}
