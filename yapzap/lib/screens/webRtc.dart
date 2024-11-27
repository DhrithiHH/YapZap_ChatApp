import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class WebRTCLogic {
  late IO.Socket socket;
  late RTCPeerConnection peerConnection;
  late RTCDataChannel dataChannel;
  MediaStream? localStream; // Made nullable to handle uninitialized state
  MediaStream? remoteStream; // Made nullable to handle uninitialized state
  final String userId;  // Current user's ID
  final String peerId;  // Target peer's ID

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
    try {
      final stream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': {'facingMode': 'user'},
      });
      localStream = stream;
    } catch (e) {
      print('Error initializing media stream: $e');
    }
  }

  // Create the peer connection
  Future<void> initializePeerConnection() async {
    if (localStream == null) {
      await initializeMedia();
    }

    final Map<String, dynamic> configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    };

    // Use the factory method to create the peer connection
    peerConnection = await createPeerConnection(configuration);

    // Add local stream to the peer connection
    localStream?.getTracks().forEach((track) {
      peerConnection.addTrack(track, localStream!);
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
    try {
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
    } catch (e) {
      print('Error handling offer: $e');
    }
  }

  // Handle incoming answer
  void _handleAnswer(data) async {
    try {
      final answer = data['answer'];
      await peerConnection.setRemoteDescription(RTCSessionDescription(answer['sdp'], answer['type']));
    } catch (e) {
      print('Error handling answer: $e');
    }
  }

  // Handle incoming ICE candidates
  void _handleIceCandidate(data) async {
    try {
      final candidate = RTCIceCandidate(
        data['candidate'],
        data['sdpMid'],
        data['sdpMLineIndex'],
      );
      await peerConnection.addCandidate(candidate);
    } catch (e) {
      print('Error handling ICE candidate: $e');
    }
  }

  // Send message through data channel
  void sendMessage(String message) {
    if (dataChannel.state == RTCDataChannelState.RTCDataChannelOpen) {
      dataChannel.send(RTCDataChannelMessage(message));
      print('Message sent: $message');
    } else {
      print('Data channel is not open yet. Cannot send message.');
    }
  }

  // Start a call by sending an offer to another peer
  Future<void> startCall() async {
    try {
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
    } catch (e) {
      print('Error starting call: $e');
    }
  }

  // End the call by closing the peer connection
  void endCall() {
    try {
      peerConnection.close();
      socket.emit('disconnect');
    } catch (e) {
      print('Error ending call: $e');
    }
  }

  // Clean up resources when done
  void dispose() {
    try {
      localStream?.dispose(); // Dispose of local stream
      remoteStream?.dispose(); // Dispose of remote stream if initialized
      peerConnection.close();
      socket.dispose();
    } catch (e) {
      print('Error disposing resources: $e');
    }
  }
}
