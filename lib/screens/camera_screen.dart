import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import '../services/detection_service.dart';
import '../services/alert_service.dart';
import '../services/safety_engine.dart';
import '../models/detected_object.dart';
import '../widgets/safety_banner.dart';
import '../widgets/glass_card.dart';
import '../widgets/detection_overlay.dart';
import 'settings_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  List<DetectedObject> _currentDetections = [];
  AlertMode _currentAlertMode = AlertMode.scanning;
  StreamSubscription<List<DetectedObject>>? _detectionsSubscription;
  DateTime? _lastAlertTime;

  @override
  void initState() {
    super.initState();
    _startProcessing();
  }

  void _startProcessing() {
    final detectionService = Provider.of<DetectionService>(context, listen: false);
    
    // Subscribe to real-time object detection streams
    _detectionsSubscription = detectionService.detectionsStream.listen((detections) {
      if (!mounted) return;
      
      final safetyEngine = Provider.of<SafetyEngine>(context, listen: false);
      final alertService = Provider.of<AlertService>(context, listen: false);

      final newMode = safetyEngine.evaluate(detections);

      setState(() {
        _currentDetections = detections;
        _currentAlertMode = newMode;
      });

      // Throttle speech loop to prevent overlapping speech triggers
      final now = DateTime.now();
      if (_lastAlertTime == null || now.difference(_lastAlertTime!) > const Duration(seconds: 4)) {
        alertService.announce(newMode);
        _lastAlertTime = now;
      }
    });

    detectionService.start();

    // If Camera Mode is selected, initialize the camera sensor
    if (detectionService.mode == DetectionMode.camera) {
      _initCameraSensor();
    }
  }

  Future<void> _initCameraSensor() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      final rearCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        rearCamera,
        ResolutionPreset.medium, // 640x480 keeps CPU load and TFLite latency minimal
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (!mounted) return;

      setState(() {
        _isCameraInitialized = true;
      });

      // Stream frames directly to OpenCV & TFLite Native channel pipeline
      int frameCounter = 0;
      _cameraController!.startImageStream((CameraImage image) {
        frameCounter++;
        // Downsample frames: process every 3rd camera frame to maintain high UI FPS
        if (frameCounter % 3 == 0) {
          final detectionService = Provider.of<DetectionService>(context, listen: false);
          // Convert plane buffers (e.g. YUV420) to linear list
          final List<int> bytes = image.planes.map((p) => p.bytes).expand((b) => b).toList();
          detectionService.processCameraImage(bytes, image.width, image.height);
        }
      });
    } catch (e) {
      print("Camera Sensor initialization failed: $e");
      // Gracefully fall back to simulation mode if hardware is missing/blocked
      final detectionService = Provider.of<DetectionService>(context, listen: false);
      detectionService.setMode(DetectionMode.simulation);
    }
  }

  void _stopProcessing() {
    _detectionsSubscription?.cancel();
    _detectionsSubscription = null;
    
    try {
      if (_cameraController != null && _cameraController!.value.isStreamingImages) {
        _cameraController!.stopImageStream();
      }
      _cameraController?.dispose();
    } catch (e) {
      print("Error disposing camera: $e");
    }
    _cameraController = null;
    _isCameraInitialized = false;

    final detectionService = Provider.of<DetectionService>(context, listen: false);
    detectionService.stop();
  }

  @override
  void dispose() {
    _stopProcessing();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detectionService = Provider.of<DetectionService>(context);
    final alertService = Provider.of<AlertService>(context);

    // Dynamic color accents based on verdict modes
    Color themeColor;
    switch (_currentAlertMode) {
      case AlertMode.safe:
        themeColor = const Color(0xFF10B981);
        break;
      case AlertMode.warning:
        themeColor = const Color(0xFFEF4444);
        break;
      case AlertMode.caution:
        themeColor = const Color(0xFFF59E0B);
        break;
      case AlertMode.scanning:
      default:
        themeColor = const Color(0xFF3B82F6);
        break;
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. LIVE CAMERA SENSOR STREAM OR SIMULATION VIEWPORT
          Positioned.fill(
            child: (detectionService.mode == DetectionMode.camera && _isCameraInitialized && _cameraController != null)
                ? CameraPreview(_cameraController!)
                : _buildSimulationViewport(themeColor),
          ),

          // 2. REAL-TIME AI BOUNDING BOX OVERLAYS
          Positioned.fill(
            child: DetectionOverlay(
              detections: _currentDetections,
              previewSize: const Size(640, 480),
            ),
          ),

          // 3. FULL SCREEN PULSING BORDER GLOW IN WARNING STATES
          if (_currentAlertMode == AlertMode.warning)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFFEF4444).withOpacity(0.5),
                      width: 8.0,
                    ),
                  ),
                ),
              ),
            ),

          // 4. FLOATING DYNAMIC HUD INTERFACE OVERLAYS
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // TOP ACTION ROW: Back Button, Dynamic Verdict Banner, Mute Selector
                  Row(
                    children: [
                      ClipOval(
                        child: Material(
                          color: Colors.black45,
                          child: InkWell(
                            onTap: () => Navigator.pop(context),
                            child: const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SafetyBanner(mode: _currentAlertMode),
                      ),
                    ],
                  ),

                  // BOTTOM ACTIONS PANEL: Glassmorphism Calibration Shortcuts
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GlassCard(
                        borderColor: themeColor.withOpacity(0.2),
                        fillColor: Colors.black.withOpacity(0.5),
                        padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Left Details: Status and Active Mode labels
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: themeColor,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      detectionService.mode == DetectionMode.camera
                                          ? "LIVE CAMERA FEED"
                                          : "SIMULATION CONSOLE",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  "Tracked targets: ${_currentDetections.length}",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),

                            // Right Details: Sound & Tuning controls
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    alertService.isMuted
                                        ? Icons.volume_off_rounded
                                        : Icons.volume_up_rounded,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      alertService.setMute(!alertService.isMuted);
                                    });
                                  },
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.settings_suggest_outlined, color: Colors.white),
                                  onPressed: () async {
                                    // Stop processing during config adjustment to prevent thread locks
                                    _stopProcessing();
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                                    );
                                    // Resume with updated calibration configurations
                                    _startProcessing();
                                  },
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulationViewport(Color activeColor) {
    return Container(
      color: const Color(0xFF020617), // Deep slate-950 screen backdrop
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Radial visual cyber mesh background
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: Image.asset(
                'assets/images/background_overlay.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Dynamic cyber target crosshairs visual overlay
          Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: activeColor.withOpacity(0.15),
                width: 2.0,
              ),
            ),
          ),
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: activeColor.withOpacity(0.25),
                width: 1.5,
              ),
            ),
          ),
          // Bounded scan sweep line visualization
          _ScanningBar(color: activeColor),
          
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.radar_rounded,
                color: activeColor.withOpacity(0.65),
                size: 70,
              ),
              const SizedBox(height: 16),
              Text(
                "AI RADAR HUD ACTIVE",
                style: TextStyle(
                  color: activeColor,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  fontSize: 14,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _ScanningBar extends StatefulWidget {
  final Color color;
  const _ScanningBar({required this.color});

  @override
  State<_ScanningBar> createState() => _ScanningBarState();
}

class _ScanningBarState extends State<_ScanningBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: -180.0, end: 180.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: Container(
            height: 3,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  widget.color.withOpacity(0.0),
                  widget.color.withOpacity(0.6),
                  widget.color.withOpacity(0.0),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
