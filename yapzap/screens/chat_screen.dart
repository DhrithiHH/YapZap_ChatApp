import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// ignore: library_prefixes//
import 'package:socket_io_client/socket_io_client.dart' as IO;

class WebRTCChatApp extends StatefulWidget {
  final String userId;
  final String peerId;

  const WebRTCChatApp({required this.userId, required this.peerId, super.key});

  @override
  // ignore: library_private_types_in_public_api
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
  // Sort the user IDs to ensure a consistent document ID
  List<String> users = [widget.userId, widget.peerId];
  users.sort(); // Sorts the user IDs

  String chatId = '${users[0]}_${users[1]}'; // Generate the chat document ID

  final snapshot = await FirebaseFirestore.instance
      .collection('messages')
      .doc(chatId)  // Use sorted chatId
      .collection('chatMessages')
      .orderBy('timestamp')
      .get();

  setState(() {
    messages = snapshot.docs
        .map((doc) => {'from': doc['from'], 'message': doc['message']})
        .toList();
  });
}

void _sendMessage() {
  final message = messageController.text.trim();
  if (message.isNotEmpty) {
    // Sort the user IDs to ensure a consistent document ID
    List<String> users = [widget.userId, widget.peerId];
    users.sort(); // Sorts the user IDs

    String chatId = '${users[0]}_${users[1]}'; // Generate the chat document ID

    dataChannel?.send(RTCDataChannelMessage(message));

    // Save to Firebase with the sorted chatId
    FirebaseFirestore.instance
        .collection('messages')
        .doc(chatId)  // Use sorted chatId
        .collection('chatMessages')
        .add({
      'from': widget.userId,
      'message': message,
      'timestamp': Timestamp.now(),
    });

    setState(() {
      messages.add({'from': widget.userId, 'message': message});
      messageController.clear();
    });
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
        ],
      ),
    );
  }
}
