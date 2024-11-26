import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// ignore: library_prefixes
import 'package:socket_io_client/socket_io_client.dart' as IO;

class WebRTCChatApp extends StatefulWidget {
  final String userId;
  final String peerId;

  const WebRTCChatApp({required this.userId, required this.peerId, super.key});

  @override
  _WebRTCChatAppState createState() => _WebRTCChatAppState();
}

class _WebRTCChatAppState extends State<WebRTCChatApp> {
  IO.Socket? socket;
  RTCPeerConnection? peerConnection;
  RTCDataChannel? dataChannel;
  List<Map<String, dynamic>> messages = [];
  TextEditingController messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initSocket();
    _fetchPreviousMessages();
  }

  Future<void> _initSocket() async {
    socket = IO.io('https://server-ouzf.onrender.com', <String, dynamic>{
      'transports': ['websocket'],
    });

    socket?.on('offer', (data) async {
      await _createPeerConnection();
      await peerConnection?.setRemoteDescription(
        RTCSessionDescription(data['sdp'], data['type']),
      );
      RTCSessionDescription answer = await peerConnection!.createAnswer();
      await peerConnection!.setLocalDescription(answer);
      socket?.emit('answer', {'sdp': answer.sdp, 'type': answer.type, 'to': data['from']});
    });

    socket?.on('answer', (data) async {
      await peerConnection?.setRemoteDescription(
        RTCSessionDescription(data['sdp'], data['type']),
      );
    });

    socket?.on('ice-candidate', (data) async {
      RTCIceCandidate candidate = RTCIceCandidate(
        data['candidate'], data['sdpMid'], data['sdpMLineIndex'],
      );
      await peerConnection?.addCandidate(candidate);
    });

    _createPeerConnection();
  }

  Future<void> _createPeerConnection() async {
    Map<String, dynamic> config = {
      'iceServers': [{'urls': 'stun:stun.l.google.com:19302'}],
    };

    peerConnection = await createPeerConnection(config);

    peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      socket?.emit('ice-candidate', {
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
        'to': widget.peerId,
      });
    };

    peerConnection?.onDataChannel = (RTCDataChannel dc) {
      dataChannel = dc;
      dataChannel?.onMessage = (RTCDataChannelMessage message) {
        setState(() {
          messages.add({'from': widget.peerId, 'message': message.text});
        });
      };
    };

    // Create DataChannel for messaging
    dataChannel = await peerConnection!.createDataChannel('messaging', RTCDataChannelInit());
  }

  Future<void> _fetchPreviousMessages() async {
    List<String> users = [widget.userId, widget.peerId];
    users.sort();

    String chatId = '${users[0]}_${users[1]}';

    final snapshot = await FirebaseFirestore.instance
        .collection('messages')
        .doc(chatId)
        .collection('chatMessages')
        .orderBy('timestamp')
        .get();

    setState(() {
      messages = snapshot.docs
          .map((doc) => {'from': doc['from'], 'message': doc['message']})
          .toList();
    });
  }

  Future<void> _acceptRequest() async {
    List<String> users = [widget.userId, widget.peerId];
    users.sort();

    String chatId = '${users[0]}_${users[1]}';

    // Remove the request message
    await FirebaseFirestore.instance.collection('messages').doc(chatId).delete();

    setState(() {
      messages.removeWhere((msg) => msg['from'] == widget.peerId);
    });

    // You can now start the chat or transition UI as needed
  }

  void _sendMessage() {
  final message = messageController.text.trim();
  if (message.isNotEmpty) {
    // Create a sorted list of user IDs to generate a unique chatId
    List<String> users = [widget.userId, widget.peerId];
    users.sort(); // Sort the user IDs to ensure consistent chatId

    String chatId = '${users[0]}_${users[1]}'; // Create chatId based on sorted user IDs

    // Send the message using WebRTC DataChannel (if applicable)

    // Add the message to Firestore in the chatMessages subcollection
    FirebaseFirestore.instance
        .collection('messages')
        .doc(chatId) // Reference to the chat document
        .collection('chatMessages') // Subcollection to store messages
        .add({
      'from': widget.userId, // Sender's userId
      'message': message, // The actual message content
      'timestamp': Timestamp.now(), // Firestore timestamp
    });

    // Update the UI with the new message
    setState(() {
      messages.add({'from': widget.userId, 'message': message});
      messageController.clear(); // Clear the input field after sending
    });
    dataChannel?.send(RTCDataChannelMessage(message));
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat with ${widget.peerId}')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final isMine = messages[index]['from'] == widget.userId;
                return Align(
                  alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    decoration: BoxDecoration(
                      color: isMine ? Colors.blue : Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(messages[index]['message']),
                  ),
                );
              },
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(controller: messageController),
              ),
              IconButton(icon: const Icon(Icons.send), onPressed: _sendMessage),
            ],
          ),
          if (messages.any((msg) => msg['from'] == widget.peerId))
            ElevatedButton(
              onPressed: _acceptRequest,
              child: const Text('Accept Request'),
            ),
        ],
      ),
    );
  }
}
