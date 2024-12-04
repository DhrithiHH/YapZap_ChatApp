import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../models/call_state.dart';

class CallPage extends StatefulWidget {
  final Map<String, dynamic> data; // Contains 'to', 'from', and 'type'
  final bool incoming;
  final dynamic socket;

  CallPage({required this.data, required this.socket, this.incoming=false});
  
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

  @override
  void initState() {
    super.initState();
    // Initialize peerId, userId, and callType from data map
    peerId = widget.data['to'];
    userId = widget.data['from'];
    callType = widget.data['type'];

    _localRenderer = RTCVideoRenderer();
    _localRenderer.initialize();

    initWebRTC();
  }

  void initWebRTC() async {
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': callType == 'video',
    });

    // Create WebRTC peer connection
    _peerConnection = await createPeerConnection({
      'iceServers': [
        {
          'urls': 'stun:stun.l.google.com:19302', // STUN server for NAT traversal
        },
      ],
      // Add WebRTC configuration here (e.g., TURN servers)
    });

    // Add local stream to peer connection
    _peerConnection.addStream(_localStream);

    // Optionally, handle ICE candidate gathering
    _peerConnection.onIceCandidate = (RTCIceCandidate candidate) {
      if (candidate != null) {
        // Send candidate to the other peer via signaling server
        widget.socket.emit('candidate', {'candidate': candidate.toMap(), 'to': peerId});
      }
    };

    // Optionally, handle remote stream (for receiving video/audio from peer)
    _peerConnection.onAddStream = (MediaStream stream) {
      // Handle remote stream
    };
  }

  @override
  Widget build(BuildContext context) {
    final callState = Provider.of<CallState>(context);
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
          if (widget.incoming && !callState.isCallAccepted)
            _buildIncomingCallButtons(callState),
          if (callState.isCallAccepted || !widget.incoming)
            _buildCallControls(callState),
        ],
      ),
    );
  }

  Widget _buildIncomingCallButtons(CallState callState) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            callState.acceptCall();
            widget.socket.emit('accept-call', {'from': userId, 'to': peerId});
            // Send the offer or answer message to the peer
          },
          child: Text("Accept"),
        ),
        ElevatedButton(
          onPressed: () {
            callState.rejectCall();
            widget.socket.emit('reject-call', {'from': userId, 'to': peerId});
            Navigator.pop(context); // Close the call page
          },
          child: Text("Reject"),
        ),
      ],
    );
  }

  Widget _buildCallControls(CallState callState) {
    return Column(
      children: [
        if (callState.isVideoCall)
          RTCVideoView(_localRenderer), // Your local video display
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(callState.isAudioMuted ? Icons.mic_off : Icons.mic),
              onPressed: () {
                callState.toggleAudioMute();
                // Handle WebRTC audio mute/unmute
              },
            ),
            IconButton(
              icon: Icon(callState.isVideoMuted ? Icons.videocam_off : Icons.videocam),
              onPressed: () {
                callState.toggleVideoMute();
                // Handle WebRTC video mute/unmute
              },
            ),
            IconButton(
              icon: Icon(Icons.call_end),
              onPressed: () {
                callState.endCall();
                widget.socket.emit('end-call', {'from': userId, 'to': peerId});
                Navigator.pop(context); // Close the call page
              },
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _localStream.dispose();
    _peerConnection.close();
    super.dispose();
  }
}
