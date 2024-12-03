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

  @override
  void initState() {
    super.initState();
    _initializeRenderers();

    if (!widget.isIncoming) {
      _startCall();
    }
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  Future<void> _initializeRenderers() async {
    _localRenderer = RTCVideoRenderer();
    _remoteRenderer = RTCVideoRenderer();

    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  void _startCall() {
    // Logic for initiating a call with WebRTC
    // Send offer to the peer via socket
    widget.socket.emit('start-call', widget.callData);
  }

  void _acceptCall() {
    setState(() {
      _isCallAccepted = true;
    });
    widget.socket.emit('accept-call', widget.callData);
  }

  void _rejectCall() {
    widget.socket.emit('reject-call', widget.callData);
    Navigator.pop(context); // Exit the call screen
  }

  void _toggleVideo() {
    setState(() {
      _isVideoEnabled = !_isVideoEnabled;
    });
    // Add WebRTC logic to enable/disable video stream
  }

  void _toggleAudio() {
    setState(() {
      _isAudioEnabled = !_isAudioEnabled;
    });
    // Add WebRTC logic to enable/disable audio stream
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
            onPressed: () => Navigator.pop(context), // End the call
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
