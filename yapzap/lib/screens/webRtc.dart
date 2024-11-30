import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class WebRTCLogic {
  late RTCPeerConnection _peerConnection;
  late RTCDataChannel _dataChannel;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  final String userId;
  final String peerId;
  final IO.Socket socket;

  WebRTCLogic(this.userId, this.peerId, this.socket) {
    _joinSignaling(); // Join signaling server first
  }

  final Map<String, dynamic> configuration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
    ],
  };

  // Send error messages to signaling server
  void _sendErrorToServer(String message) {
    socket.emit('error', {
      'userId': userId,
      'peerId': peerId,
      'message': message,
    });
  }

  // Initialize WebRTC (moved from _initializeWebRTC to _joinSignaling)
  Future<void> _joinSignaling() async {
    try {
      // Emit 'join-signaling' event with userId
      socket.emit('join-signaling', {'userId': userId});
      
      // Setup signaling listeners
      socket.on('user-id', (data) {
        print("Successfully joined signaling server with userId: ${data['userId']}");
        _initializeWebRTC();
      });

      socket.on('error', (error) {
        print("Error in signaling: $error");
      });

    } catch (e) {
      _sendErrorToServer('Error joining signaling: $e');
    }
  }

  // Initialize WebRTC and peer connection
  Future<void> _initializeWebRTC() async {
    try {
      await _setupSocketListeners();
      _peerConnection = await _createPeerConnection();

      // Setup data channel for sending and receiving messages
      _dataChannel = await _createDataChannel();
      _setupDataChannelListeners();

      print('WebRTC initialized successfully');
    } catch (e) {
      _sendErrorToServer('Error initializing WebRTC: $e');
    }
  }

  // Create and configure peer connection
  Future<RTCPeerConnection> _createPeerConnection() async {
    try {
      final connection = await createPeerConnection(configuration, {});
      if (connection == null) {
        throw Exception('Failed to create RTCPeerConnection');
      }

      connection.onIceCandidate = (RTCIceCandidate candidate) {
        if (candidate != null) {
          socket.emit('ice-candidate', {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
            'to': peerId,
          });
        }
      };

      connection.onDataChannel = (RTCDataChannel channel) {
        _dataChannel = channel;
        _setupDataChannelListeners();
      };

      return connection;
    } catch (e) {
      _sendErrorToServer('Error creating peer connection: $e');
      rethrow;
    }
  }

  // Create a data channel for messaging
  Future<RTCDataChannel> _createDataChannel() async {
    try {
      RTCDataChannelInit dataChannelInit = RTCDataChannelInit();
      return _peerConnection.createDataChannel('chat', dataChannelInit);
    } catch (e) {
      _sendErrorToServer('Error creating data channel: $e');
      rethrow;
    }
  }

  // Setup listeners for data channel
  void _setupDataChannelListeners() {
  _dataChannel.onMessage = (RTCDataChannelMessage message) {
    print('Received message: ${message.text}');
  };

  // Fix the listener to match the expected function signature
  _dataChannel.onDataChannelState = (RTCDataChannelState state) {
    print('Data channel state: $state');
  };
}


  // Setup listeners for socket events
  Future<void> _setupSocketListeners() async {
    socket.on('offer', _handleOffer);
    socket.on('answer', _handleAnswer);
    socket.on('ice-candidate', _handleIceCandidate);
  }

  // Initialize local media (camera/mic)
  Future<void> initMedia() async {
    try {
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': {'facingMode': 'user'},
      });
      _localStream!.getTracks().forEach((track) {
        _peerConnection.addTrack(track, _localStream!);
      });
    } catch (e) {
      _sendErrorToServer('Error initializing media: $e');
    }
  }

  // Start call and create an offer
  Future<void> startCall() async {
    try {
      await initMedia(); // Ensure media is initialized before creating offer
      RTCSessionDescription offer = await _peerConnection.createOffer();
      await _peerConnection.setLocalDescription(offer);

      socket.emit('offer', {
        'offer': {
          'sdp': offer.sdp,
          'type': offer.type,
        },
        'to': peerId,
      });
    } catch (e) {
      _sendErrorToServer('Error starting call: $e');
    }
  }

  // Handle incoming offer
  Future<void> _handleOffer(data) async {
    try {
      RTCSessionDescription offer = RTCSessionDescription(
        data['offer']['sdp'],
        data['offer']['type'],
      );
      await _peerConnection.setRemoteDescription(offer);

      RTCSessionDescription answer = await _peerConnection.createAnswer();
      await _peerConnection.setLocalDescription(answer);

      socket.emit('answer', {
        'answer': {
          'sdp': answer.sdp,
          'type': answer.type,
        },
        'to': data['from'],
      });
    } catch (e) {
      _sendErrorToServer('Error handling offer: $e');
    }
  }

  // Handle incoming answer
  Future<void> _handleAnswer(data) async {
    try {
      RTCSessionDescription answer = RTCSessionDescription(
        data['answer']['sdp'],
        data['answer']['type'],
      );
      await _peerConnection.setRemoteDescription(answer);
    } catch (e) {
      _sendErrorToServer('Error handling answer: $e');
    }
  }

  // Handle ICE candidates
  Future<void> _handleIceCandidate(data) async {
    try {
      RTCIceCandidate candidate = RTCIceCandidate(
        data['candidate'],
        data['sdpMid'],
        data['sdpMLineIndex'],
      );
      await _peerConnection.addCandidate(candidate);
    } catch (e) {
      _sendErrorToServer('Error handling ICE candidate: $e');
    }
  }

  // Send a message through the data channel
  void sendMessage(String message) {
    if (_dataChannel.state == RTCDataChannelState.RTCDataChannelOpen) {
      _dataChannel.send(RTCDataChannelMessage(message));
    } else {
      _sendErrorToServer('Data channel is not open.');
    }
  }

  // End the call and dispose of resources
  void endCall() {
    _peerConnection.close();
    _peerConnection.dispose();
    _localStream?.dispose();
    _remoteStream?.dispose();
  }
}
