import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class CallPage extends StatefulWidget {
  final Map<String, dynamic> data; // Contains 'to', 'from', and 'type'
  final bool incoming;
  final dynamic socket;

  CallPage({required this.data, required this.socket, this.incoming = false});

  @override
  _CallPageState createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  late RTCPeerConnection _peerConnection;
  late MediaStream _localStream;
  late RTCVideoRenderer _localRenderer;
  late String peerId;
  late String userId;
  late String callType;

  bool isCallAccepted = false;
  bool isAudioMuted = false;
  bool isVideoMuted = false;

  @override
  void initState() {
    super.initState();
    // Initialize peerId, userId, and callType from data map
    peerId = widget.data['to'];
    userId = widget.data['from'];
    callType = widget.data['type'];

    _localRenderer = RTCVideoRenderer();
    _localRenderer.initialize().catchError((e) {
      print("Error initializing local renderer: $e");
    });

    initWebRTC();
  }

  void initWebRTC() async {
    try {
      // Request media stream (audio and video)
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': callType == 'video',
      }).catchError((e) {
        print("Error accessing media devices: $e");
      });

      // If the local stream is null, display error message
      if (_localStream == null) {
        print("Failed to get local stream.");
        return;
      }

      // Create WebRTC peer connection
      _peerConnection = await createPeerConnection({
        'iceServers': [
          {
            'urls': 'stun:stun.l.google.com:19302', // STUN server for NAT traversal
          },
        ],
      }).catchError((e) {
        print("Error creating peer connection: $e");
      });

      // Add local stream to peer connection
      _peerConnection.addStream(_localStream);

      // Handle ICE candidate gathering
      _peerConnection.onIceCandidate = (RTCIceCandidate candidate) {
        if (candidate != null) {
          // Send candidate to the other peer via signaling server
          widget.socket.emit('candidate', {'candidate': candidate.toMap(), 'to': peerId});
        }
      };

      // Handle remote stream (for receiving video/audio from peer)
      _peerConnection.onAddStream = (MediaStream stream) {
        print("Remote stream added");
        // Handle remote stream here (update UI or pass to renderer)
      };
    } catch (e) {
      print("Error during WebRTC initialization: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isVideoCall = callType == 'video';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.incoming ? "Incoming Call" : "Outgoing Call"),
      ),
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    color: Colors.black,
                    child: isVideoCall
                        ? RTCVideoView(_localRenderer) // Render local video using the renderer
                        : Center(child: Icon(Icons.phone, size: 100, color: Colors.green)),
                  ),
                ),
              ],
            ),
          ),
          if (widget.incoming && !isCallAccepted)
            _buildIncomingCallButtons(),
          if (isCallAccepted || !widget.incoming)
            _buildCallControls(),
        ],
      ),
    );
  }

  Widget _buildIncomingCallButtons() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            setState(() {
              isCallAccepted = true;
            });
            widget.socket.emit('accept-call', {'from': userId, 'to': peerId});
            // Send the offer or answer message to the peer
          },
          child: Text("Accept"),
        ),
        ElevatedButton(
          onPressed: () {
            setState(() {
              isCallAccepted = false;
            });
            widget.socket.emit('reject-call', {'from': userId, 'to': peerId});
            Navigator.pop(context); // Close the call page
          },
          child: Text("Reject"),
        ),
      ],
    );
  }

  Widget _buildCallControls() {
    return Column(
      children: [
        if (callType == 'video') RTCVideoView(_localRenderer), // Your local video display
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(isAudioMuted ? Icons.mic_off : Icons.mic),
              onPressed: () {
                setState(() {
                  isAudioMuted = !isAudioMuted;
                });
                // Handle WebRTC audio mute/unmute
                _localStream.getAudioTracks().forEach((track) {
                  track.enabled = !isAudioMuted;
                });
              },
            ),
            IconButton(
              icon: Icon(isVideoMuted ? Icons.videocam_off : Icons.videocam),
              onPressed: () {
                setState(() {
                  isVideoMuted = !isVideoMuted;
                });
                // Handle WebRTC video mute/unmute
                _localStream.getVideoTracks().forEach((track) {
                  track.enabled = !isVideoMuted;
                });
              },
            ),
            IconButton(
              icon: Icon(Icons.call_end),
              onPressed: () {
                widget.socket.emit('end-call', {'from': userId, 'to': peerId});
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    // Cleanup resources
    _localRenderer.dispose();
    _localStream.dispose();
    _peerConnection.close();
    super.dispose();
  }
}
