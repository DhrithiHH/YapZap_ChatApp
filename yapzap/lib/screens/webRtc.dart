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
    _initializeWebRTC();
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

  // Initialize WebRTC
  Future<void> _initializeWebRTC() async {
    try {
      socket.on('offer', _handleOffer);
      socket.on('answer', _handleAnswer);
      socket.on('ice-candidate', _handleIceCandidate);

      _peerConnection = await createPeerConnection(configuration, {});
      _peerConnection.onIceCandidate = (RTCIceCandidate candidate) {
        if (candidate != null) {
          socket.emit('ice-candidate', {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
            'to': peerId,
          });
        }
      };

      _peerConnection.onDataChannel = (RTCDataChannel channel) {
        _dataChannel = channel;
        _dataChannel.onMessage = (RTCDataChannelMessage message) {
          print('Received message: ${message.text}');
        };
      };
    } catch (e) {
      _sendErrorToServer('Error initializing WebRTC: $e');
    }
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

  // Create and send an offer
  Future<void> startCall() async {
    try {
      await initMedia();
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
  void _handleOffer(data) async {
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
  void _handleAnswer(data) async {
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
  void _handleIceCandidate(data) async {
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

  // End the call
  void endCall() {
    _peerConnection.close();
    _peerConnection.dispose();
    _localStream?.dispose();
    _remoteStream?.dispose();
  }
}
