import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class CallScreen extends StatefulWidget {
  final Map<String, dynamic> callData;
  final IO.Socket socket;
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
  bool _isVideoEnabled = true;
  bool _isAudioEnabled = true;
  bool _isCallAccepted = false;
  late RTCPeerConnection _peerConnection;
  late MediaStream _localStream;

  @override
  void initState() {
    super.initState();
    _initializeRenderers();
    _listenForRejectCall();
    _listenForEndCall(); // Listen for reject-call events
    if (!widget.isIncoming) {
      _startCall();
    }
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _peerConnection.close();
    super.dispose();
  }

  Future<void> _initializeRenderers() async {
    _localRenderer = RTCVideoRenderer();
    _remoteRenderer = RTCVideoRenderer();

    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    // Initialize local media stream
    await _initLocalMedia();
  }

  Future<void> _initLocalMedia() async {
    final mediaConstraints = {
      'audio': true,
      'video': {
        'facingMode': 'user', // Use the front camera
        'width': 1280,
        'height': 720,
      },
    };

    // Get user media (audio and video)
    MediaStream stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);

    // Assign local video to renderer
    _localRenderer.srcObject = stream;

    // Save the local media stream
    _localStream = stream;

    // Create the peer connection and add tracks
    await _createPeerConnection();
  }

  Future<void> _createPeerConnection() async {
    // Configuration for the peer connection
    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    };

    // Create the peer connection
    _peerConnection = await createPeerConnection(config);

    // Add tracks to the peer connection
    for (var track in _localStream.getTracks()) {
      await _peerConnection.addTrack(track, _localStream);
    }

    // Handle ICE candidates
    _peerConnection.onIceCandidate = (candidate) {
      if (candidate != null) {
        widget.socket.emit('ice-candidate', {
          'to': widget.callData['from'],
          'candidate': candidate.toMap(),
        });
      }
    };

    // Handle remote stream
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

    // Set local description with the offer
    await _peerConnection.setLocalDescription(offer);

    // Send the offer to the other peer via the signaling server
    widget.socket.emit('offer', {
      'offer': offer.toMap(),
      'to': widget.callData['to'],
    });
  }

  void _listenForRejectCall() {
    widget.socket.on('reject-call', (_) {
      _cleanupCall(); // Clean up and exit the call
    });
  }

  void _listenForEndCall() {
    widget.socket.on('reject-call', (_) {
      if (mounted) {
        _cleanupCall(); // Handle end call from the other side
      }
    });
  }

  void _acceptCall() async {
    setState(() {
      _isCallAccepted = true;
    });

    final answer = await _peerConnection.createAnswer();

    // Set local description with the answer
    await _peerConnection.setLocalDescription(answer);

    widget.socket.emit('answer', {
      'answer': answer.toMap(),
      'to': widget.callData['from'],
    });
  }

  void _rejectCall() {
    widget.socket.emit('reject-call', widget.callData);
    _cleanupCall();
  }

  void _endCall() {
    widget.socket.emit('reject-call', {
      'to': widget.callData['from'],
    });
    _cleanupCall();
  }

  void _cleanupCall() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _peerConnection.close();
    Navigator.pop(context);
  }

  void _toggleVideo() {
    setState(() {
      _isVideoEnabled = !_isVideoEnabled;
    });

    // Enable or disable video
    _localStream.getVideoTracks().forEach((track) {
      track.enabled = _isVideoEnabled;
    });
  }

  void _toggleAudio() {
    setState(() {
      _isAudioEnabled = !_isAudioEnabled;
    });

    // Enable or disable audio
    _localStream.getAudioTracks().forEach((track) {
      track.enabled = _isAudioEnabled;
    });
  }

  Widget _buildBottomBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: Icon(
            _isVideoEnabled ? Icons.videocam : Icons.videocam_off,
            color: Colors.white,
          ),
          onPressed: _toggleVideo,
        ),
        IconButton(
          icon: Icon(
            _isAudioEnabled ? Icons.mic : Icons.mic_off,
            color: Colors.white,
          ),
          onPressed: _toggleAudio,
        ),
        if (_isCallAccepted || !widget.isIncoming)
          IconButton(
            icon: const Icon(Icons.call_end, color: Colors.red),
            onPressed: _endCall, // End the call
          ),
      ],
    );
  }

  Widget _buildIncomingCallActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        FloatingActionButton(
          backgroundColor: Colors.green,
          onPressed: _acceptCall,
          child: const Icon(Icons.call, color: Colors.white),
        ),
        FloatingActionButton(
          backgroundColor: Colors.red,
          onPressed: _rejectCall,
          child: const Icon(Icons.call_end, color: Colors.white),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Remote video
            Positioned.fill(
              child: RTCVideoView(_remoteRenderer),
            ),

            // Local video (in the corner)
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

            // Bottom bar
            if (_isCallAccepted || !widget.isIncoming)
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: _buildBottomBar(),
              ),

            // Incoming call actions
            if (!_isCallAccepted && widget.isIncoming)
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: _buildIncomingCallActions(),
              ),
          ],
        ),
      ),
    );
  }
}
