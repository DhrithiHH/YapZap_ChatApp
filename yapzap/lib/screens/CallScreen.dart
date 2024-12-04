import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class CallScreen extends StatefulWidget {
  final IO.Socket socket;
  final Map<String, dynamic> callData;
  final bool isIncoming;

  const CallScreen({
    Key? key,
    required this.callData,
    required this.socket,
    this.isIncoming = false,
  }) : super(key: key);

  @override
  _CallScreenState createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  late RTCVideoRenderer _localRenderer;
  late RTCVideoRenderer _remoteRenderer;
  late RTCPeerConnection _peerConnection;
  late MediaStream _localStream;
  late Timer _callTimer;

  @override
  void initState() {
     super.initState();
    _initializeRenderers();
    _connectToSignaling();

    // Start timer for call duration
    _startCallTimer();
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _peerConnection.close();
    super.dispose();
  }
void _startCallTimer() {
     _callTimer = Timer(Duration(seconds: 30), () {
      _endCall(); // Automatically end the call after 30 seconds
    });
  }
  Future<void> _initializeRenderers() async {
    _localRenderer = RTCVideoRenderer();
    _remoteRenderer = RTCVideoRenderer();

    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    // Get local media
    await _initLocalMedia();
  }

  Future<void> _initLocalMedia() async {
    final mediaConstraints = {
      'audio': true,
      'video': {
        'facingMode': 'user',
        'width': 1280,
        'height': 720,
      },
    };

    MediaStream stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    _localRenderer.srcObject = stream;
    _localStream = stream;

    await _createPeerConnection();
  }

  Future<void> _createPeerConnection() async {
    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    };

    _peerConnection = await createPeerConnection(config);

    // Add local tracks to the peer connection
    _localStream.getTracks().forEach((track) {
      _peerConnection.addTrack(track, _localStream);
    });

    _peerConnection.onIceCandidate = (candidate) {
      if (candidate != null) {
        widget.socket.emit('ice-candidate', {
          'candidate': candidate.toMap(),
          'to': widget.callData['to'],
          'from': widget.callData['from'],
        });
      }
    };

    _peerConnection.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        setState(() {
          _remoteRenderer.srcObject = event.streams.first;
        });
      }
    };
  }

  void _startCall() async {
    final offer = await _peerConnection.createOffer();
    await _peerConnection.setLocalDescription(offer);

    widget.socket.emit('offer', {
      'offer': offer.toMap(),
      'to': widget.callData['to'],
      'from': widget.callData['from'],
      'type': widget.callData['type'],
    });
  }

 void _acceptCall(Map<String, dynamic>? offer) async {
  if (offer == null || offer.isEmpty || offer['sdp'] == null || offer['type'] == null) {
    print("Invalid or empty offer received");
    widget.socket.emit('error', {
      'message': 'Invalid offer received',
      'from': widget.callData['to'], // Receiver
      'to': widget.callData['from'], // Original caller
    });
    return;
  }

  await _peerConnection.setRemoteDescription(RTCSessionDescription(offer['sdp'], offer['type']));
  final answer = await _peerConnection.createAnswer();
  await _peerConnection.setLocalDescription(answer);

  widget.socket.emit('answer', {
    'answer': answer.toMap(),
    'from': widget.callData['to'], // Receiver sends back
    'to': widget.callData['from'], // Original caller
  });
}

  void _endCall() {
  if (_callTimer.isActive) _callTimer.cancel();

  // Emit end-call signal
  widget.socket.emit('end-call', {
    'from': widget.callData['from'],
    'to': widget.callData['to'],
  });

  // Cleanup connections
  _peerConnection.close();
  _peerConnection.dispose();

  _localStream.getTracks().forEach((track) {
    track.stop(); // Stops audio/video tracks
  });
  _localStream.dispose();

  _localRenderer.dispose();
  _remoteRenderer.dispose();

  // Remove socket listeners
  widget.socket.off('offer');
  widget.socket.off('answer');
  widget.socket.off('ice-candidate');
  widget.socket.off('end-call');

  Navigator.pop(context); // Return to the previous screen
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: RTCVideoView(_remoteRenderer),
            ),
            Positioned(
              top: 20,
              right: 20,
              width: 100,
              height: 150,
              child: RTCVideoView(
                _localRenderer,
                mirror: true,
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.call_end, color: Colors.red),
                    onPressed: _endCall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _connectToSignaling() {
    widget.socket.on('offer', (data) {
    print("Received offer data: $data");  // Check what is being received
    if (data != null && data['to'] == widget.callData['from']) {
    _acceptCall(data['offer']);
  } else {
    // Handle the case where data is invalid
    widget.socket.emit('error',{
      'message' : "null",
    });
  }
});

    widget.socket.on('answer', (data) {
      if (data['to'] == widget.callData['from']) {
        _peerConnection.setRemoteDescription(RTCSessionDescription(data['answer']['sdp'], data['answer']['type']));
      }
    });

    widget.socket.on('ice-candidate', (data) {
      if (data['to'] == widget.callData['from']) {
        final candidate = RTCIceCandidate(
          data['candidate']['candidate'],
          data['candidate']['sdpMid'],
          data['candidate']['sdpMLineIndex'],
        );
        _peerConnection.addCandidate(candidate); // Updated method
      }
    });

    widget.socket.on('end-call', (data) {
      if (data['to'] == widget.callData['from']) {
        _endCall();
      }
    });

    if (widget.isIncoming) {
      _acceptCall(widget.callData['offer']);
    } else {
      _startCall();
    }
  }
  
  
}
