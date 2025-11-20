import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';

import '../services/webrtc_service.dart';

class VideoCallScreen extends StatefulWidget {
  const VideoCallScreen({super.key});

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  bool _renderersReady = false;
  bool _isMuted = false;
  bool _isVideoOff = false;
  bool _isSpeakerOn = true;
  bool _isRemotePortrait = false;
  double _remoteAspectRatio = 16 / 9;
  bool _isFrontCamera = true;

  WebRTCService? _webrtcService;

  @override
  void initState() {
    super.initState();
    _initRenderers();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _webrtcService = Provider.of<WebRTCService>(context, listen: false);
  }

  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    if (!mounted) {
      return;
    }

    final webrtcService = Provider.of<WebRTCService>(context, listen: false);

    if (webrtcService.localStream != null) {
      _localRenderer.srcObject = webrtcService.localStream;
      final audioTracks = webrtcService.localStream!.getAudioTracks();
      final videoTracks = webrtcService.localStream!.getVideoTracks();
      if (audioTracks.isNotEmpty) {
        _isMuted = !audioTracks.first.enabled;
      }
      _isVideoOff = !webrtcService.isCameraEnabled;
    }
    _isFrontCamera = webrtcService.isFrontCamera;

    if (webrtcService.remoteStream != null) {
      _remoteRenderer.srcObject = webrtcService.remoteStream;
      _detectRemoteAspectRatio(webrtcService.remoteStream!);
    }

    webrtcService.addListener(_updateStreams);

    setState(() {
      _renderersReady = true;
    });
  }

  void _updateStreams() {
    if (!mounted) {
      return;
    }

    final webrtcService = Provider.of<WebRTCService>(context, listen: false);
    bool updated = false;

    if (webrtcService.localStream != null && _localRenderer.srcObject == null) {
      _localRenderer.srcObject = webrtcService.localStream;
      updated = true;
    }

    if (webrtcService.remoteStream != null && _remoteRenderer.srcObject == null) {
      _remoteRenderer.srcObject = webrtcService.remoteStream;
      _detectRemoteAspectRatio(webrtcService.remoteStream!);
      updated = true;
    }

    if (updated) {
      setState(() {});
    }
  }

  void _detectRemoteAspectRatio(MediaStream stream) {
    final track = stream.getVideoTracks().firstOrNull;
    if (track == null) {
      return;
    }

    _remoteRenderer.onResize = () {
      if (!mounted) {
        return;
      }
      final width = _remoteRenderer.videoWidth;
      final height = _remoteRenderer.videoHeight;
      if (width <= 0 || height <= 0) {
        return;
      }
      final portrait = height > width;
      final aspect = width / height;
      if (_isRemotePortrait != portrait || (_remoteAspectRatio - aspect).abs() > 0.1) {
        setState(() {
          _isRemotePortrait = portrait;
          _remoteAspectRatio = aspect;
        });
      }
    };

    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) {
        return;
      }
      final width = _remoteRenderer.videoWidth;
      final height = _remoteRenderer.videoHeight;
      if (width > 0 && height > 0) {
        setState(() {
          _isRemotePortrait = height > width;
          _remoteAspectRatio = width / height;
        });
      }
    });
  }

  @override
  void dispose() {
    _webrtcService?.removeListener(_updateStreams);
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  void _toggleMute() {
    final service = Provider.of<WebRTCService>(context, listen: false);
    final track = service.localStream?.getAudioTracks().firstOrNull;
    if (track == null) {
      return;
    }
    setState(() {
      _isMuted = !_isMuted;
      track.enabled = !_isMuted;
    });
  }

  void _toggleVideo() {
    final service = Provider.of<WebRTCService>(context, listen: false);
    final track = service.localStream?.getVideoTracks().firstOrNull;
    if (track == null) {
      return;
    }
    final wasEnabled = track.enabled;
    track.enabled = !wasEnabled;
    setState(() {
      _isVideoOff = !track.enabled;
    });
  }

  void _toggleSpeaker() async {
    final nextState = !_isSpeakerOn;
    setState(() {
      _isSpeakerOn = nextState;
    });
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        await Helper.setSpeakerphoneOn(nextState);
      } catch (_) {}
    }
  }

  void _endCall() {
    final service = Provider.of<WebRTCService>(context, listen: false);
    service.endCall();
    Navigator.of(context).pop();
  }

  Future<void> _switchCamera() async {
    final service = Provider.of<WebRTCService>(context, listen: false);
    await service.switchCamera();
    setState(() {
      _isFrontCamera = service.isFrontCamera;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_renderersReady) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 900;
        return isDesktop ? _buildDesktopLayout() : _buildMobileLayout();
      },
    );
  }

  Widget _buildMobileLayout() {
    final webrtcService = Provider.of<WebRTCService>(context);
    final callerName = webrtcService.callerInfo?['callerName'] ?? 'Teacher';
    final studentName = webrtcService.callerInfo?['studentName'] ?? '';

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                color: Colors.black,
                child: RTCVideoView(
                  _remoteRenderer,
                  objectFit: _isRemotePortrait
                      ? RTCVideoViewObjectFit.RTCVideoViewObjectFitCover
                      : RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                ),
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          callerName,
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        if (studentName.isNotEmpty)
                          Text(
                            studentName,
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (webrtcService.localStream != null && webrtcService.isCameraEnabled)
              Positioned(
                top: 24,
                right: 16,
                width: 120,
                height: 160,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: RTCVideoView(
                    _localRenderer,
                    mirror: true,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  ),
                ),
              ),
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildRoundButton(
                    icon: _isMuted ? Icons.mic_off : Icons.mic,
                    color: _isMuted ? Colors.red : Colors.white.withOpacity(0.3),
                    onPressed: _toggleMute,
                  ),
                  _buildRoundButton(
                    icon: _isVideoOff ? Icons.videocam_off : Icons.videocam,
                    color: _isVideoOff ? Colors.red : Colors.white.withOpacity(0.3),
                    onPressed: _toggleVideo,
                  ),
                  _buildRoundButton(
                    icon: Icons.cameraswitch,
                    color: Colors.white.withOpacity(0.3),
                    onPressed: _switchCamera,
                  ),
                  _buildRoundButton(
                    icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                    color: _isSpeakerOn ? Colors.white.withOpacity(0.3) : Colors.red,
                    onPressed: _toggleSpeaker,
                  ),
                  _buildRoundButton(
                    icon: Icons.call_end,
                    color: Colors.red,
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

  Widget _buildDesktopLayout() {
    final webrtcService = Provider.of<WebRTCService>(context);
    final callerName = webrtcService.callerInfo?['callerName'] ?? 'Teacher';
    final studentName = webrtcService.callerInfo?['studentName'] ?? '';

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                margin: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: RTCVideoView(
                    _remoteRenderer,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                  ),
                ),
              ),
            ),
            Container(
              width: 320,
              margin: const EdgeInsets.only(top: 24, bottom: 24, right: 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Live Session',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        callerName,
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      if (studentName.isNotEmpty)
                        Text(
                          studentName,
                          style: const TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (webrtcService.localStream != null && webrtcService.isCameraEnabled)
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24, width: 1),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: RTCVideoView(
                          _localRenderer,
                          mirror: true,
                          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildDesktopControlButton(
                        icon: _isMuted ? Icons.mic_off : Icons.mic,
                        label: _isMuted ? 'Unmute' : 'Mute',
                        isActive: !_isMuted,
                        onPressed: _toggleMute,
                        activeColor: Colors.green,
                        inactiveColor: Colors.red,
                      ),
                      _buildDesktopControlButton(
                        icon: _isVideoOff ? Icons.videocam_off : Icons.videocam,
                        label: _isVideoOff ? 'Start Video' : 'Stop Video',
                        isActive: !_isVideoOff,
                        onPressed: _toggleVideo,
                        activeColor: Colors.blue,
                        inactiveColor: Colors.red,
                      ),
                      _buildDesktopControlButton(
                        icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                        label: _isSpeakerOn ? 'Speaker On' : 'Speaker Off',
                        isActive: _isSpeakerOn,
                        onPressed: _toggleSpeaker,
                        activeColor: Colors.orange,
                        inactiveColor: Colors.red,
                      ),
                      _buildDesktopControlButton(
                        icon: Icons.cameraswitch,
                        label: _isFrontCamera ? 'Front Cam' : 'Rear Cam',
                        isActive: _isFrontCamera,
                        onPressed: _switchCamera,
                        activeColor: Colors.purple,
                        inactiveColor: Colors.red,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _endCall,
                      icon: const Icon(Icons.call_end),
                      label: const Text('End Call'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildRoundButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildDesktopControlButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onPressed,
    Color activeColor = Colors.green,
    Color inactiveColor = Colors.red,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 90,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.2) : inactiveColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isActive ? activeColor : inactiveColor, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? activeColor : inactiveColor, size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? activeColor : inactiveColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            )
          ],
        ),
      ),
    );
  }
}
