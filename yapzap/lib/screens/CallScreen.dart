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
  bool _isMuted = false;
  bool _isVideoEnabled = true;

  @override
  void initState() {
    super.initState();
    _initializeRenderers();
    if (!widget.isIncoming) {
      _connectToSignaling();
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
    if (offer == null || offer['sdp'] == null || offer['type'] == null) {
      widget.socket.emit('error', {'message': 'Invalid offer received'});
      return;
    }

    await _peerConnection.setRemoteDescription(RTCSessionDescription(offer['sdp'], offer['type']));
    final answer = await _peerConnection.createAnswer();
    await _peerConnection.setLocalDescription(answer);

    widget.socket.emit('answer', {
      'answer': answer.toMap(),
      'from': widget.callData['to'],
      'to': widget.callData['from'],
    });
  }

  void _rejectCall() {
    widget.socket.emit('reject-call', {
      'from': widget.callData['to'],
      'to': widget.callData['from'],
    });
    Navigator.pop(context);
  }

  void _endCall() {
    widget.socket.emit('end-call', {
      'from': widget.callData['from'],
      'to': widget.callData['to'],
    });
    Navigator.pop(context);
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    _localStream.getAudioTracks().forEach((track) {
      track.enabled = !_isMuted;
    });
  }

  void _toggleVideo() {
    setState(() {
      _isVideoEnabled = !_isVideoEnabled;
    });
    _localStream.getVideoTracks().forEach((track) {
      track.enabled = _isVideoEnabled;
    });
  }

  void _connectToSignaling() {
    widget.socket.on('offer', (data) {
        _acceptCall(data['offer']);
    });

    widget.socket.on('answer', (data) {
        _peerConnection.setRemoteDescription(RTCSessionDescription(data['answer']['sdp'], data['answer']['type']));
    });

    widget.socket.on('ice-candidate', (data) {
        final candidate = RTCIceCandidate(
          data['candidate']['candidate'],
          data['candidate']['sdpMid'],
          data['candidate']['sdpMLineIndex'],
        );
        _peerConnection.addCandidate(candidate);
    });

    widget.socket.on('end-call', (data) {
      // if (data['to'] == widget.callData['from']) {
        _endCall();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: widget.isIncoming
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Incoming Call", style: TextStyle(color: Colors.white)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(Icons.call, color: Colors.green, size: 40),
                          onPressed: () {
                            _connectToSignaling();
                          },
                        ),
                        SizedBox(width: 20),
                        IconButton(
                          icon: Icon(Icons.call_end, color: Colors.red, size: 40),
                          onPressed: _rejectCall,
                        ),
                      ],
                    ),
                  ],
                ),
              )
            : Stack(
                children: [
                  Positioned.fill(child: RTCVideoView(_remoteRenderer)),
                  Positioned(
                    top: 20,
                    right: 20,
                    width: 100,
                    height: 150,
                    child: RTCVideoView(_localRenderer, mirror: true),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(_isMuted ? Icons.mic_off : Icons.mic, color: Colors.white),
                          onPressed: _toggleMute,
                        ),
                        IconButton(
                          icon: Icon(_isVideoEnabled ? Icons.videocam : Icons.videocam_off, color: Colors.white),
                          onPressed: _toggleVideo,
                        ),
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
}
