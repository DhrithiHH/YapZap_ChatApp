import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class WebRTCLogic {
  late RTCPeerConnection _peerConnection;
  late RTCDataChannel _dataChannel;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  final String userId;
  final String peerId;

  late IO.Socket socket; // Signaling server socket

  // Constructor now initializes WebRTC directly
  WebRTCLogic(this.userId, this.peerId, this.socket) {
    initWebRTC(); // Initialize WebRTC when the class is instantiated
  }

  // WebRTC configuration for ICE servers
  final Map<String, dynamic> configuration = {
    'iceServers': [
      {
        'urls': 'stun:stun.l.google.com:19302', // Google public STUN server
      },
    ],
  };

  // Initialize WebRTC peer connection and data channel
  Future<void> initWebRTC() async {
    try {
      // Ensure that socket connection is ready
      if (socket.connected) {
        print('Socket connected');
      } else {
        print('Socket not connected');
        return;
      }

      // Handle incoming signaling messages
      socket.on('offer', (data) => handleOffer(data));
      socket.on('answer', (data) => handleAnswer(data));
      socket.on('ice-candidate', (data) => handleIceCandidate(data));

      // Create peer connection
      _peerConnection = await createPeerConnection(configuration, {});

      // On incoming data channel messages
      _peerConnection.onDataChannel = (RTCDataChannel channel) {
        channel.onMessage = (RTCDataChannelMessage message) {
          print('Received message: ${message.text}');
        };
        _dataChannel = channel;
      };

      // Create a data channel for sending messages
      RTCDataChannelInit dataChannelInit = RTCDataChannelInit();
      _dataChannel = await _peerConnection.createDataChannel('chat', dataChannelInit);

      // Send a test message once the data channel is created
      _dataChannel.send(RTCDataChannelMessage('Hello, peer!'));
    } catch (e) {
      print('Error initializing WebRTC: $e');
    }
  }
 RTCDataChannel get dataChannel => _dataChannel;
  // Initialize media stream (audio/video)
  Future<void> initMedia() async {
    try {
      final stream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': {'facingMode': 'user'},
      });
      _localStream = stream;
      // Add local media stream to the peer connection
      _localStream?.getTracks().forEach((track) {
        _peerConnection.addTrack(track, _localStream!);
      });
    } catch (e) {
      print('Error initializing media stream: $e');
    }
  }

  // Send message through the data channel
  void sendMessage(String message) {
    if (_dataChannel.state == RTCDataChannelState.RTCDataChannelOpen) {
      _dataChannel.send(RTCDataChannelMessage(message));
      print('Message sent: $message');
    } else {
      print('Data channel is not open yet.');
    }
  }

  // Create and send an offer to start a call
  Future<void> startCall() async {
    try {
      if (_localStream == null) {
        await initMedia();
      }

      // Create an offer
      final offer = await _peerConnection.createOffer();
      await _peerConnection.setLocalDescription(offer);

      // Send the offer to the peer via the existing signaling server socket
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

  // Handle incoming offer
  Future<void> handleOffer(Map<String, dynamic> data) async {
    try {
      final offer = data['offer'];
      await _peerConnection.setRemoteDescription(RTCSessionDescription(offer['sdp'], offer['type']));

      final answer = await _peerConnection.createAnswer();
      await _peerConnection.setLocalDescription(answer);

      // Send the answer back to the peer via signaling server
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
  Future<void> handleAnswer(Map<String, dynamic> data) async {
    try {
      final answer = data['answer'];
      await _peerConnection.setRemoteDescription(RTCSessionDescription(answer['sdp'], answer['type']));
    } catch (e) {
      print('Error handling answer: $e');
    }
  }

  // Handle incoming ICE candidates
  Future<void> handleIceCandidate(Map<String, dynamic> data) async {
    try {
      final candidate = RTCIceCandidate(
        data['candidate'],
        data['sdpMid'],
        data['sdpMLineIndex'],
      );
      await _peerConnection.addCandidate(candidate);
    } catch (e) {
      print('Error handling ICE candidate: $e');
    }
  }

  // End the call and clean up resources
  void endCall() {
    try {
      _peerConnection.close();
      _peerConnection.dispose();
      _localStream?.dispose();
      _remoteStream?.dispose();
    } catch (e) {
      print('Error ending call: $e');
    }
  }

  // Dispose of resources when done
  void dispose() {
    _peerConnection.close();
    _peerConnection.dispose();
    _localStream?.dispose();
    _remoteStream?.dispose();
  }
}
