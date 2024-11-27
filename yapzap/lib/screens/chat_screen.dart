import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// ignore: library_prefixes
import 'package:socket_io_client/socket_io_client.dart' as IO;

class WebRTCChatApp extends StatefulWidget {
  final String userId;
  final String peerId;

  const WebRTCChatApp({required this.userId, required this.peerId, Key? key})
      : super(key: key);

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

  @override
  void dispose() {
    messageController.dispose();
    peerConnection?.close();
    socket?.disconnect();
    super.dispose();
  }

  Future<void> _initSocket() async {
    socket = IO.io('https://server-ouzf.onrender.com', <String, dynamic>{
      'transports': ['websocket'],
    });

    socket?.on('connect', (_) => print('Connected to signaling server'));
    socket?.on('disconnect', (_) => print('Disconnected from server'));

    // Handle WebRTC signaling
    socket?.on('offer', (data) async {
      await _createPeerConnection();
      await peerConnection?.setRemoteDescription(
        RTCSessionDescription(data['sdp'], 'offer'),
      );
      RTCSessionDescription answer = await peerConnection!.createAnswer();
      await peerConnection!.setLocalDescription(answer);
      socket?.emit('answer', {'sdp': answer.sdp, 'type': 'answer', 'to': data['from']});
    });

    socket?.on('answer', (data) async {
      await peerConnection?.setRemoteDescription(
        RTCSessionDescription(data['sdp'], 'answer'),
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

  void _sendMessage() {
    final message = messageController.text.trim();
    if (message.isEmpty) return;

    List<String> users = [widget.userId, widget.peerId];
    users.sort();
    String chatId = '${users[0]}_${users[1]}';

    FirebaseFirestore.instance
        .collection('messages')
        .doc(chatId)
        .collection('chatMessages')
        .add({
      'from': widget.userId,
      'message': message,
      'timestamp': Timestamp.now(),
    });

    dataChannel?.send(RTCDataChannelMessage(message));
    setState(() {
      messages.add({'from': widget.userId, 'message': message});
      messageController.clear();
    });
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
            Text('Chat with ${widget.peerId}'),
          ],
        ),
      ),
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
