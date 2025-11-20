import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class WebRTCService with ChangeNotifier {
  IO.Socket? socket;
  RTCPeerConnection? peerConnection;
  MediaStream? localStream;
  MediaStream? remoteStream;

  bool isInCall = false;
  String? currentCallId;
  String? remoteUserId;
  Map<String, dynamic>? callerInfo;
  
  // Queue for ICE candidates received before peer connection is ready
  final List<RTCIceCandidate> _pendingIceCandidates = [];

  // Dynamic socket URL (will be set from Firestore config)
  String? _socketUrl;
  bool _useFrontCamera = true;

  // Default TURN server config
  static const Map<String, dynamic> _defaultIceServers = {
    'iceServers': [
      {
        'urls': [
          'turn:31.97.188.80:3478',
          'turn:31.97.188.80:3478?transport=tcp',
        ],
        'username': 'coturn_user',
        'credential': 'test123',
      }
    ],
    'iceCandidatePoolSize': 10,
  };

  // ICE servers (STUN/TURN) - will be configured dynamically
  Map<String, dynamic> _iceServers = Map<String, dynamic>.from(_defaultIceServers);

  /// Configure TURN server
  void configureTurnServer(Map<String, dynamic>? turnConfig) {
    if (turnConfig == null) {
      debugPrint('⚠️ No TURN config provided, using defaults');
      return;
    }

    final urls = turnConfig['urls'] as List?;
    final username = turnConfig['username'] as String?;
    final credential = turnConfig['credential'] as String?;

    if (urls == null || urls.isEmpty) {
      debugPrint('⚠️ TURN config missing URLs, using defaults');
      return;
    }

    _iceServers = {
      'iceServers': [
        {
          'urls': urls,
          'username': username,
          'credential': credential,
        }
      ],
      'iceCandidatePoolSize': 10,
    };

    debugPrint('✅ TURN server configured: ${turnConfig['host'] ?? 'custom'}');
  }

  /// Connect to signaling server
  void connect(String userId, String username, {String? socketUrl}) {
    // Use provided socketUrl or fallback to stored one
    final url = socketUrl ?? _socketUrl;
    if (url == null || url.isEmpty) {
      debugPrint('❌ Parent: socketUrl missing, cannot connect');
      return;
    }
    _socketUrl = url;

    debugPrint('🔌 Parent: Connecting to signaling server: $url');

    socket = IO.io(url, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket!.onConnect((_) {
      debugPrint('✅ Parent: Connected to signaling server');
      socket!.emit('join-room', {
        'userId': userId,
        'username': username,
        'role': 'parent',
      });
    });

    socket!.onDisconnect((_) {
      debugPrint('❌ Parent: Disconnected from signaling server');
    });

    _setupSignalingListeners();
  }

  void _setupSignalingListeners() {
    // Incoming call
    socket!.on('webrtc-offer', (data) async {
      debugPrint('📞 Parent: Incoming call from ${data['callerName']}');
      debugPrint('📋 Call data: $data');
      callerInfo = data;
      notifyListeners();
    });

    // Answer received
    socket!.on('webrtc-answer', (data) async {
      debugPrint('✅ Parent: Answer received');
      if (peerConnection != null) {
        await peerConnection!.setRemoteDescription(
          RTCSessionDescription(data['answer']['sdp'], data['answer']['type']),
        );
      }
    });

    // ICE candidate received
    socket!.on('webrtc-ice-candidate', (data) async {
      debugPrint('🧊 Parent: ICE candidate received');

      try {
        // Extract candidate data safely
        final candidateData = data['candidate'];
        final candidateStr = candidateData['candidate']?.toString();
        final sdpMid = candidateData['sdpMid']?.toString();
        final sdpMLineIndex = candidateData['sdpMLineIndex'] as int?;

        if (candidateStr == null) {
          debugPrint('⚠️ Invalid ICE candidate data: candidate string is null');
          return;
        }

        final candidate = RTCIceCandidate(
          candidateStr,
          sdpMid,
          sdpMLineIndex,
        );

        // If peer connection exists, add candidate immediately
        if (peerConnection != null) {
          try {
            await peerConnection!.addCandidate(candidate);
            debugPrint('✅ Parent: ICE candidate added');
          } catch (e) {
            debugPrint('⚠️ Error adding ICE candidate: $e');
          }
        } else {
          // Otherwise, queue it for later
          debugPrint('📦 Queuing ICE candidate (peer connection not ready)');
          _pendingIceCandidates.add(candidate);
        }
      } catch (e) {
        debugPrint('❌ Error processing ICE candidate: $e');
      }
    });

    // Call ended
    socket!.on('webrtc-call-end', (data) {
      debugPrint('📴 Parent: Call ended');
      endCall();
    });

    socket!.on('webrtc-call-rejected', (data) {
      debugPrint('❌ Parent: Call rejected');
      endCall();
    });

    socket!.on('incoming-call-cancelled', (data) {
      debugPrint('ℹ️ Parent: Incoming call cancelled');
      callerInfo = null;
      notifyListeners();
    });
  }

  /// Answer incoming call
  Future<void> answerCall() async {
    if (callerInfo == null) return;

    try {
      final micStatus = await Permission.microphone.request();
      final cameraStatus = await Permission.camera.request();

      if (!micStatus.isGranted || !cameraStatus.isGranted) {
        debugPrint('❌ Parent: Camera/Mic permission denied');
        rejectCall();
        return;
      }

      // Initialize peer connection
      await _initializePeerConnection();

      // Get local media (camera + mic)
      localStream = await navigator.mediaDevices.getUserMedia({
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
        },
        'video': {
          'facingMode': _useFrontCamera ? 'user' : 'environment',
          'width': {'ideal': 1280},
          'height': {'ideal': 720},
        },
      });

      // Enable speakerphone on iOS/Android (not earpiece)
      if (Platform.isAndroid || Platform.isIOS) {
        await Helper.setSpeakerphoneOn(true);
        debugPrint('🔊 Speakerphone enabled');
      }

      // Add local stream to peer connection
      localStream!.getTracks().forEach((track) {
        peerConnection!.addTrack(track, localStream!);
      });

      remoteUserId = callerInfo!['callerId'];

      // Set remote description (offer)
      await peerConnection!.setRemoteDescription(
        RTCSessionDescription(
          callerInfo!['offer']['sdp'],
          callerInfo!['offer']['type'],
        ),
      );

      // Create answer
      final answer = await peerConnection!.createAnswer();
      await peerConnection!.setLocalDescription(answer);

      // Send answer to caller
      socket!.emit('webrtc-answer', {
        'callId': callerInfo!['callId'],
        'answer': {
          'sdp': answer.sdp,
          'type': answer.type,
        },
        'recipientId': callerInfo!['callerId'],
      });

      // Process any pending ICE candidates
      if (_pendingIceCandidates.isNotEmpty) {
        debugPrint('📤 Processing ${_pendingIceCandidates.length} pending ICE candidates');
        for (final candidate in _pendingIceCandidates) {
          try {
            await peerConnection!.addCandidate(candidate);
            debugPrint('✅ Pending ICE candidate added');
          } catch (e) {
            debugPrint('⚠️ Error adding pending ICE candidate: $e');
          }
        }
        _pendingIceCandidates.clear();
      }

      currentCallId = callerInfo!['callId'];
      isInCall = true;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Parent: Error answering call: $e');
      endCall();
    }
  }

  /// Reject incoming call
  void rejectCall() {
    if (callerInfo == null) return;

    socket!.emit('webrtc-call-rejected', {
      'callId': callerInfo!['callId'],
      'recipientId': callerInfo!['callerId'],
      'reason': 'parent-rejected',
    });

    callerInfo = null;
    remoteUserId = null;
    notifyListeners();
  }

  /// End active call
  void endCall() {
    if (currentCallId != null) {
      final payload = {
        'callId': currentCallId,
      };
      if (remoteUserId != null) {
        payload['recipientId'] = remoteUserId;
      }
      socket!.emit('webrtc-call-end', payload);
    }

    // Close peer connection
    peerConnection?.close();
    peerConnection = null;

    // Stop local stream
    localStream?.getTracks().forEach((track) => track.stop());
    localStream?.dispose();
    localStream = null;

    // Stop remote stream
    remoteStream?.getTracks().forEach((track) => track.stop());
    remoteStream?.dispose();
    remoteStream = null;

    // Clear any pending ICE candidates
    if (_pendingIceCandidates.isNotEmpty) {
      debugPrint('🧹 Clearing ${_pendingIceCandidates.length} pending ICE candidates');
      _pendingIceCandidates.clear();
    }

    isInCall = false;
    currentCallId = null;
    callerInfo = null;
    remoteUserId = null;

    notifyListeners();
  }

  Future<void> _initializePeerConnection() async {
    peerConnection = await createPeerConnection(_iceServers);

    // Handle ICE candidates
    peerConnection!.onIceCandidate = (candidate) {
      socket!.emit('webrtc-ice-candidate', {
        'candidate': {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        },
        'recipientId': callerInfo!['callerId'],
      });
    };

    // Handle remote stream
    peerConnection!.onTrack = (event) {
      debugPrint('🎥 Parent: Remote track received');
      if (event.streams.isNotEmpty) {
        remoteStream = event.streams[0];
        notifyListeners();
      }
    };

    // Handle connection state changes
    peerConnection!.onConnectionState = (state) {
      debugPrint('🔗 Parent: Connection state: $state');
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        endCall();
      }
    };
  }

  /// Toggle microphone
  void toggleMicrophone() {
    if (localStream != null) {
      final audioTrack = localStream!.getAudioTracks().firstOrNull;
      if (audioTrack != null) {
        audioTrack.enabled = !audioTrack.enabled;
        notifyListeners();
      }
    }
  }

  /// Toggle camera
  void toggleCamera() {
    if (localStream != null) {
      final videoTrack = localStream!.getVideoTracks().firstOrNull;
      if (videoTrack != null) {
        videoTrack.enabled = !videoTrack.enabled;
        notifyListeners();
      }
    }
  }

  Future<void> switchCamera() async {
    final videoTrack = localStream?.getVideoTracks().firstOrNull;
    if (videoTrack == null) {
      return;
    }
    try {
      await videoTrack.switchCamera();
      _useFrontCamera = !_useFrontCamera;
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ Parent: Failed to switch camera: $e');
    }
  }

  bool get isFrontCamera => _useFrontCamera;

  /// Get microphone state
  bool get isMicrophoneEnabled {
    if (localStream == null) return false;
    final audioTrack = localStream!.getAudioTracks().firstOrNull;
    return audioTrack?.enabled ?? false;
  }

  /// Get camera state
  bool get isCameraEnabled {
    if (localStream == null) return false;
    final videoTrack = localStream!.getVideoTracks().firstOrNull;
    return videoTrack?.enabled ?? false;
  }

  /// Disconnect from signaling server
  void disconnect() {
    endCall();
    socket?.disconnect();
    socket = null;
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
