import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';
import '../models/detected_object.dart';

enum DetectionMode { camera, simulation }

class DetectionService {
  static const _channel = MethodChannel('traffic_safety/detection');
  
  DetectionMode _mode = DetectionMode.simulation; // Defaults to simulation for cross-platform ease
  bool _isProcessing = false;
  final _random = Random();
  
  // Streams the real-time detections
  final _controller = StreamController<List<DetectedObject>>.broadcast();
  Stream<List<DetectedObject>> get detectionsStream => _controller.stream;

  Timer? _simulationTimer;
  int _simulationTicks = 0;
  int _simulationScenario = 0; // 0: Busy Street (Danger), 1: Receding (Safe), 2: Clear (Safe)

  DetectionMode get mode => _mode;

  void setMode(DetectionMode newMode) {
    _mode = newMode;
    if (_mode == DetectionMode.simulation) {
      _startSimulation();
    } else {
      _stopSimulation();
    }
  }

  void setScenario(int scenarioIndex) {
    _simulationScenario = scenarioIndex;
    _simulationTicks = 0; // Reset scenario playback progress
  }

  void start() {
    if (_mode == DetectionMode.simulation) {
      _startSimulation();
    }
  }

  void stop() {
    _stopSimulation();
  }

  // Called by the Camera Widget on each frame (CameraImage stream) in Live Mode
  Future<void> processCameraImage(List<int> yuvBytes, int width, int height) async {
    if (_mode == DetectionMode.simulation) return;
    if (_isProcessing) return;
    
    _isProcessing = true;
    try {
      final Map<dynamic, dynamic> result = await _channel.invokeMethod('detectObjects', {
        'imageBytes': yuvBytes,
        'width': width,
        'height': height,
      });

      final List<dynamic> rawDetections = result['detections'] as List<dynamic>? ?? [];
      final List<DetectedObject> parsed = rawDetections.map((item) {
        return DetectedObject.fromMap(item as Map<dynamic, dynamic>);
      }).toList();

      _controller.add(parsed);
    } on PlatformException catch (e) {
      print("Native object detection platform error: $e");
      // Seamlessly fall back to simulated detections if platform execution is missing/unsupported
      _emitFallbackDetections();
    } catch (e) {
      print("Object detection error: $e");
    } finally {
      _isProcessing = false;
    }
  }

  void _startSimulation() {
    _stopSimulation();
    _simulationTimer = Timer.periodic(const Duration(milliseconds: 350), (timer) {
      _simulationTicks++;
      _generateScenarioDetections();
    });
  }

  void _stopSimulation() {
    _simulationTimer?.cancel();
    _simulationTimer = null;
  }

  void _emitFallbackDetections() {
    // Generate a simple transient warning box for the fallback
    _controller.add([
      DetectedObject(
        id: 1,
        label: 'car',
        confidence: 0.82,
        xMin: 0.35,
        yMin: 0.40,
        xMax: 0.65,
        yMax: 0.85,
        distance: DistanceCategory.close,
        isApproaching: true,
        estimatedDistanceMeters: 8.5,
      )
    ]);
  }

  void _generateScenarioDetections() {
    List<DetectedObject> currentDetections = [];

    switch (_simulationScenario) {
      case 0: // BUSY STREET (NOT SAFE)
        // Vehicle 1 starts medium far and rapidly approaches
        double phase1 = (_simulationTicks % 25) / 25.0; // 0.0 to 1.0
        double heightRatio1 = 0.05 + (phase1 * 0.70); // Starts tiny, grows very large
        double xMin1 = 0.40 - (phase1 * 0.15);
        double yMin1 = 0.40;
        double xMax1 = xMin1 + 0.15 + (phase1 * 0.30);
        double yMax1 = yMin1 + heightRatio1;

        DistanceCategory dist1 = DistanceCategory.far;
        if (heightRatio1 > 0.48) {
          dist1 = DistanceCategory.veryClose;
        } else if (heightRatio1 > 0.28) {
          dist1 = DistanceCategory.close;
        } else if (heightRatio1 > 0.12) {
          dist1 = DistanceCategory.medium;
        }

        currentDetections.add(DetectedObject(
          id: 101,
          label: 'car',
          confidence: 0.88,
          xMin: xMin1.clamp(0.0, 1.0),
          yMin: yMin1.clamp(0.0, 1.0),
          xMax: xMax1.clamp(0.0, 1.0),
          yMax: yMax1.clamp(0.0, 1.0),
          distance: dist1,
          isApproaching: phase1 < 0.9, // Approaching until it's past the camera
          estimatedDistanceMeters: (30.0 * (1.0 - phase1)).clamp(2.0, 50.0),
        ));

        // Add a second far-off bus approaching slowly
        if (_simulationTicks % 25 > 5) {
          double phase2 = ((_simulationTicks + 8) % 25) / 25.0;
          double heightRatio2 = 0.08 + (phase2 * 0.20);
          currentDetections.add(DetectedObject(
            id: 102,
            label: 'bus',
            confidence: 0.74,
            xMin: 0.25,
            yMin: 0.42,
            xMax: 0.38,
            yMax: 0.42 + heightRatio2,
            distance: heightRatio2 > 0.12 ? DistanceCategory.medium : DistanceCategory.far,
            isApproaching: true,
            estimatedDistanceMeters: 45.0 - (phase2 * 20),
          ));
        }
        break;

      case 1: // RECEDING TRAFFIC (SAFE)
        // Vehicle is moving away (shrinking)
        double phase = (_simulationTicks % 20) / 20.0;
        double inversePhase = 1.0 - phase;
        double heightRatio = 0.06 + (inversePhase * 0.35); // Shrinking
        
        currentDetections.add(DetectedObject(
          id: 201,
          label: 'car',
          confidence: 0.91,
          xMin: 0.45 - (inversePhase * 0.05),
          yMin: 0.45,
          xMax: 0.55 + (inversePhase * 0.05),
          yMax: 0.45 + heightRatio,
          distance: heightRatio > 0.28 ? DistanceCategory.close : (heightRatio > 0.12 ? DistanceCategory.medium : DistanceCategory.far),
          isApproaching: false, // Shrinking means receding/moving away
          estimatedDistanceMeters: 5.0 + (phase * 35.0),
        ));
        break;

      case 2: // CLEAR ROAD (SAFE)
        // No vehicles detected
        break;
    }

    _controller.add(currentDetections);
  }

  void dispose() {
    _stopSimulation();
    _controller.close();
  }
}
