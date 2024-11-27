import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class WebRTCLogic {
  late IO.Socket socket;
  late RTCPeerConnection peerConnection;
  late RTCDataChannel dataChannel;
  late MediaStream localStream;
  late MediaStream remoteStream;
  late String userId;  // Add userId for the current user
  late String peerId;  // Add peerId for the target peer

  // Constructor to initialize userId and peerId
  WebRTCLogic(this.userId, this.peerId);

  // Connect to the signaling server using Socket.IO
  Future<void> connectSocket(String serverUrl) async {
    socket = IO.io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'query': {'userId': userId}, // Pass userId to the server
    });

    socket.on('connect', (_) {
      print('Connected to signaling server: ${socket.id}');
    });

    // Handle incoming signaling messages
    socket.on('offer', _handleOffer);
    socket.on('answer', _handleAnswer);
    socket.on('ice-candidate', _handleIceCandidate);
  }

  // Initialize local media (audio/video stream)
  Future<void> initializeMedia() async {
    final stream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': {'facingMode': 'user'},
    });
    localStream = stream;
  }

  // Create the peer connection
  Future<void> initializePeerConnection() async {
    final Map<String, dynamic> configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    };

    // Use the factory method to create the peer connection
    peerConnection = await createPeerConnection(configuration);

    // Add local stream to the peer connection
    localStream.getTracks().forEach((track) {
      peerConnection.addTrack(track, localStream);
    });

    // Set up data channel for messaging
    dataChannel = await peerConnection.createDataChannel('chat', RTCDataChannelInit());
    dataChannel.onMessage = (RTCDataChannelMessage message) {
      print('Received message: ${message.text}');
    };

    // Handle remote stream
    peerConnection.onAddStream = (MediaStream stream) {
      remoteStream = stream;
      print('Remote stream added');
    };

    // Handle ICE Candidate generation
    peerConnection.onIceCandidate = (RTCIceCandidate candidate) {
      if (candidate != null) {
        // Emit the ICE candidate over socket.io to the recipient
        socket.emit('ice-candidate', {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
          'to': peerId,  // The recipient's userId (peerId)
          'from': userId,  // The sender's userId
        });
      }
    };
  }

  // Handle incoming offer
  void _handleOffer(data) async {
    final offer = data['offer'];
    await initializePeerConnection();
    await peerConnection.setRemoteDescription(RTCSessionDescription(offer['sdp'], offer['type']));

    final answer = await peerConnection.createAnswer();
    await peerConnection.setLocalDescription(answer);

    socket.emit('answer', {
      'answer': {
        'sdp': answer.sdp,
        'type': answer.type,
      },
      'to': data['from'],
    });
  }

  // Handle incoming answer
  void _handleAnswer(data) async {
    final answer = data['answer'];
    await peerConnection.setRemoteDescription(RTCSessionDescription(answer['sdp'], answer['type']));
  }

  // Handle incoming ICE candidates
  void _handleIceCandidate(data) async {
    final candidate = RTCIceCandidate(
      data['candidate'],
      data['sdpMid'],
      data['sdpMLineIndex'],
    );
    await peerConnection.addCandidate(candidate);
  }

  // Send message through data channel
  void sendMessage(String message) {
    // Wait for the data channel to open before sending the message
    if (dataChannel.state == RTCDataChannelState.RTCDataChannelOpen) {
      // Send the message only if the data channel is open
      dataChannel.send(RTCDataChannelMessage(message));
      print('Message sent: $message');
    } else {
      print('Data channel is not open yet. Cannot send message.');
    }
  }

  // Start a call by sending an offer to another peer
  Future<void> startCall() async {
    await initializePeerConnection();

    final offer = await peerConnection.createOffer();
    await peerConnection.setLocalDescription(offer);

    socket.emit('offer', {
      'offer': {
        'sdp': offer.sdp,
        'type': offer.type,
      },
      'to': peerId,  // Send offer to the peer with peerId
    });
  }

  // End the call by closing the peer connection
  void endCall() {
    peerConnection.close();
    socket.emit('disconnect');
  }

  // Clean up resources when done
  void dispose() {
    peerConnection.close();
    socket.dispose();
  }
}
