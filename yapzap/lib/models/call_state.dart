import 'package:flutter/material.dart';

class CallState extends ChangeNotifier {
  bool isVideoCall = true;
  bool isCallAccepted = false;
  bool isCallEnded = false;
  bool isAudioMuted = false;
  bool isVideoMuted = false;

  void toggleVideoCall() {
    isVideoCall = !isVideoCall;
    notifyListeners();
  }

  void acceptCall() {
    isCallAccepted = true;
    notifyListeners();
  }

  void rejectCall() {
    isCallEnded = true;
    notifyListeners();
  }

  void endCall() {
    isCallEnded = true;
    notifyListeners();
  }

  void toggleAudioMute() {
    isAudioMuted = !isAudioMuted;
    notifyListeners();
  }

  void toggleVideoMute() {
    isVideoMuted = !isVideoMuted;
    notifyListeners();
  }
}
