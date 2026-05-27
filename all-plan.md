# Traffic Safety Mobile App — Full Project Documentation

> **Project Type:** Final Year / Student Capstone Project  
> **Domain:** Mobile Development · Computer Vision · AI/ML  
> **Target Platform:** Android (Primary), iOS (Optional)  
> **Core Goal:** Real-time pedestrian road-crossing safety detection using phone camera + AI

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Technology Stack](#2-technology-stack)
3. [System Architecture](#3-system-architecture)
4. [Development Environment Setup](#4-development-environment-setup)
5. [Phase-by-Phase Development Guide](#5-phase-by-phase-development-guide)
   - Phase 1: Project Setup
   - Phase 2: Camera Integration
   - Phase 3: Computer Vision (OpenCV)
   - Phase 4: AI Object Detection (YOLOv8)
   - Phase 5: Traffic Analysis Logic
   - Phase 6: Safety Decision Engine
   - Phase 7: Voice & Alert System
   - Phase 8: Testing & Debugging
   - Phase 9: Documentation & Presentation
6. [Folder Structure](#6-folder-structure)
7. [Key Libraries & Dependencies](#7-key-libraries--dependencies)
8. [API & Data Flow](#8-api--data-flow)
9. [YOLOv8 Model Integration Details](#9-yolov8-model-integration-details)
10. [Safety Decision Logic](#10-safety-decision-logic)
11. [UI/UX Design Guidelines](#11-uiux-design-guidelines)
12. [Testing Strategy](#12-testing-strategy)
13. [Known Challenges & Mitigation](#13-known-challenges--mitigation)
14. [Deliverables Checklist](#14-deliverables-checklist)
15. [Glossary](#15-glossary)

---

## 1. Project Overview

### What the App Does
This mobile application uses the smartphone's rear camera to capture a live video feed of a road. It then applies:

- **OpenCV** for frame preprocessing and image optimization
- **YOLOv8 (via TensorFlow Lite)** for real-time object detection of vehicles and pedestrians
- A custom **Traffic Analysis Engine** to estimate vehicle speed, distance, and direction
- A **Safety Decision System** that outputs a clear SAFE / NOT SAFE verdict
- **Voice + Vibration + On-Screen Alerts** to communicate the verdict to the user

### Who Uses It
Visually impaired pedestrians, elderly users, and everyday pedestrians in high-traffic areas who need an AI-assisted second opinion before crossing the road.

### Project Scope (Student / Prototype Level)
- Detect 5 vehicle classes: car, bike, bus, truck, motorcycle
- Estimate approaching vehicle proximity using bounding box heuristics
- Output binary safety status (SAFE TO CROSS / NOT SAFE TO CROSS)
- Works offline (no internet required after model download)

---

## 2. Technology Stack

| Layer | Technology | Language | Purpose |
|---|---|---|---|
| Mobile Framework | Flutter | Dart | App UI, navigation, state management |
| Native Android Integration | Android SDK | Kotlin / Java | Camera2 API, hardware access, JNI bridge |
| Computer Vision | OpenCV (Android) | Kotlin / Java | Frame preprocessing, image filtering |
| AI Object Detection | YOLOv8 → TFLite | Python (training) | Detect vehicles and pedestrians |
| ML Runtime | TensorFlow Lite | Dart / Kotlin | On-device inference |
| Model Training (optional) | Python + Ultralytics | Python | Custom model fine-tuning |
| Alert System | Flutter TTS, Vibration pkg | Dart | Audio + haptic alerts |
| Optional Backend | Firebase / AWS Lambda | — | Logging, analytics, remote config |

### Language Responsibilities

**Dart (Flutter)**
- Full UI layer (screens, widgets, state)
- App lifecycle management
- Calling into platform channels (to Kotlin/Java)
- Rendering detection overlay on camera preview
- Voice alerts and vibration triggers

**Kotlin / Java (Android Native)**
- Camera2 API integration for low-latency frame capture
- Passing raw frames to OpenCV
- OpenCV preprocessing pipeline
- TFLite model inference
- Sending results back to Flutter via Platform Channels

**Python**
- YOLOv8 model training and evaluation (offline, on PC/Colab)
- Dataset preparation and augmentation
- Model export to `.tflite` format
- Testing scripts for model accuracy

---

## 3. System Architecture

```
┌─────────────────────────────────────────────────────┐
│                FLUTTER APP (Dart)                    │
│  ┌──────────────┐   ┌──────────────┐  ┌──────────┐  │
│  │  Camera View │   │ Detection UI │  │ Alert UI │  │
│  │  (Preview)   │   │  (Overlay)   │  │ (TTS/Vib)│  │
│  └──────┬───────┘   └──────▲───────┘  └────▲─────┘  │
│         │   Platform Channel (MethodChannel)│        │
└─────────┼───────────────────────────────────┼────────┘
          ▼                                   │
┌─────────────────────────────────────────────────────┐
│           ANDROID NATIVE LAYER (Kotlin/Java)         │
│  ┌───────────────┐   ┌────────────┐  ┌───────────┐  │
│  │ Camera2 API   │──▶│  OpenCV    │──▶│ TFLite    │  │
│  │ (Frame Grab)  │   │ Preprocess │  │ Inference │  │
│  └───────────────┘   └────────────┘  └─────┬─────┘  │
└──────────────────────────────────────────────┼───────┘
                                               ▼
                               ┌───────────────────────┐
                               │  Traffic Analysis &   │
                               │  Safety Decision Logic│
                               │  (Kotlin + Dart)      │
                               └──────────┬────────────┘
                                          ▼
                               ┌───────────────────────┐
                               │  SAFE / NOT SAFE      │
                               │  → Voice Alert        │
                               │  → Screen Banner      │
                               │  → Vibration Pattern  │
                               └───────────────────────┘
```

---

## 4. Development Environment Setup

### 4.1 Required Software (Your PC/Laptop)

| Software | Version | Download |
|---|---|---|
| Flutter SDK | ≥ 3.19 | flutter.dev |
| Android Studio | ≥ Giraffe (2022.3) | developer.android.com |
| Android NDK | ≥ r25c | Via SDK Manager |
| Python | ≥ 3.10 | python.org |
| Git | Latest | git-scm.com |
| VS Code (optional) | Latest | code.visualstudio.com |

### 4.2 Android Studio Plugins to Install
- Flutter plugin
- Dart plugin
- Android SDK Platform 33 or 34
- Android Emulator (API 31+) or physical Android device (recommended)

### 4.3 Python Packages (for Model Training)

```bash
pip install ultralytics          # YOLOv8
pip install tensorflow           # TFLite export
pip install opencv-python        # Image testing
pip install numpy matplotlib     # Data utilities
```

### 4.4 Flutter Packages (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  camera: ^0.10.5                  # Camera access
  flutter_tts: ^3.8.3              # Text-to-speech
  vibration: ^1.8.4                # Haptic feedback
  tflite_flutter: ^0.10.4          # TFLite model inference
  image: ^4.1.3                    # Image manipulation in Dart
  provider: ^6.1.1                 # State management
  permission_handler: ^11.1.0      # Runtime permissions

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
```

### 4.5 Android Permissions (AndroidManifest.xml)

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" /> <!-- only if using Firebase -->

<uses-feature android:name="android.hardware.camera" android:required="true" />
<uses-feature android:name="android.hardware.camera.autofocus" />
```

---

## 5. Phase-by-Phase Development Guide

---

### Phase 1 — Project Setup

**Goal:** Create the Flutter project, configure Android integration, and set up folder structure.

**Steps:**
1. Run `flutter create traffic_safety_app` in terminal
2. Open in Android Studio
3. Set `minSdkVersion 24` in `android/app/build.gradle` (required for Camera2 + TFLite)
4. Set `targetSdkVersion 34`
5. Enable multidex: `multiDexEnabled true`
6. Add all Flutter packages to `pubspec.yaml` and run `flutter pub get`
7. Test: run `flutter run` — blank app should launch on emulator/device

**Deliverable:** Running blank Flutter app with permissions granted

---

### Phase 2 — Camera Integration

**Goal:** Open the rear camera, display live feed, and grab frames for processing.

#### 2.1 Flutter Camera Preview (Dart)

```dart
// main_camera_screen.dart
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final rearCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
    );
    _controller = CameraController(
      rearCamera,
      ResolutionPreset.medium, // 640x480 recommended for real-time inference
      enableAudio: false,
    );
    await _controller!.initialize();
    setState(() {});

    // Stream frames to native layer
    _controller!.startImageStream((CameraImage image) {
      _processFrame(image);
    });
  }

  void _processFrame(CameraImage image) {
    // Pass to Platform Channel → Kotlin/Java → OpenCV → TFLite
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return CameraPreview(_controller!);
  }
}
```

#### 2.2 Platform Channel Setup (Dart ↔ Kotlin)

```dart
// platform_channel.dart
import 'package:flutter/services.dart';

class DetectionChannel {
  static const _channel = MethodChannel('traffic_safety/detection');

  static Future<Map<String, dynamic>> detectObjects(List<int> imageBytes) async {
    final result = await _channel.invokeMethod('detectObjects', {
      'imageBytes': imageBytes,
      'width': 640,
      'height': 480,
    });
    return Map<String, dynamic>.from(result);
  }
}
```

```kotlin
// MainActivity.kt
class MainActivity : FlutterActivity() {
  private val CHANNEL = "traffic_safety/detection"

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
      if (call.method == "detectObjects") {
        val imageBytes = call.argument<ByteArray>("imageBytes")!!
        val detectionResult = runDetection(imageBytes)
        result.success(detectionResult)
      } else {
        result.notImplemented()
      }
    }
  }
}
```

**Key considerations:**
- Use `ResolutionPreset.medium` (not high) — keeps inference fast
- Frame rate: target 10–15 fps for detection (camera runs at 30 fps; process every 2nd or 3rd frame)
- Convert YUV_420_888 (CameraImage format) to RGB before passing to OpenCV

---

### Phase 3 — Computer Vision Integration (OpenCV)

**Goal:** Preprocess each captured frame to improve detection accuracy and reduce noise.

#### 3.1 Adding OpenCV to Android

Add to `android/app/build.gradle`:
```gradle
dependencies {
    implementation 'com.quickbirdstudios:opencv:4.5.3.0'
}
```

Or add the OpenCV Android SDK manually as a module.

#### 3.2 Frame Preprocessing Pipeline (Kotlin)

```kotlin
import org.opencv.android.Utils
import org.opencv.core.*
import org.opencv.imgproc.Imgproc

object FrameProcessor {

  fun preprocessFrame(inputBitmap: Bitmap): Mat {
    val mat = Mat()
    Utils.bitmapToMat(inputBitmap, mat)

    // Step 1: Resize to model input size (640x640 for YOLOv8)
    val resized = Mat()
    Imgproc.resize(mat, resized, Size(640.0, 640.0))

    // Step 2: Convert BGR → RGB (OpenCV uses BGR by default)
    Imgproc.cvtColor(resized, resized, Imgproc.COLOR_BGR2RGB)

    // Step 3: Gaussian blur to reduce noise
    Imgproc.GaussianBlur(resized, resized, Size(3.0, 3.0), 0.0)

    // Step 4: Normalize pixel values to [0, 1]
    resized.convertTo(resized, CvType.CV_32F, 1.0 / 255.0)

    return resized
  }
}
```

**Why these steps?**
- **Resize:** YOLO models expect a fixed input (e.g., 640×640)
- **Color convert:** Neural networks trained on RGB; OpenCV loads as BGR
- **Blur:** Reduces JPEG artifacts and noise — fewer false detections
- **Normalize:** Model weights expect [0,1] float input, not [0,255] uint8

---

### Phase 4 — AI Object Detection (YOLOv8)

**Goal:** Detect vehicles and pedestrians in each preprocessed frame.

#### 4.1 Model Preparation (Python — done on PC, not phone)

```python
# export_model.py
from ultralytics import YOLO

# Load pretrained YOLOv8n (nano — fastest, good for mobile)
model = YOLO("yolov8n.pt")

# Export to TFLite (INT8 quantized for speed on Android)
model.export(
    format="tflite",
    imgsz=640,
    int8=True,          # Quantize for faster inference
    data="coco.yaml"    # Calibration dataset
)
# Output: yolov8n_int8.tflite
```

**Model Variants (choose based on your phone's capability):**

| Model | Size | Speed (Pixel 6) | mAP |
|---|---|---|---|
| YOLOv8n (nano) | ~6 MB | ~40ms/frame | 37.3 |
| YOLOv8s (small) | ~22 MB | ~80ms/frame | 44.9 |
| YOLOv8m (medium) | ~52 MB | ~150ms/frame | 50.2 |

> **Recommendation:** Use `yolov8n` for the prototype. It's fast enough for real-time use.

**COCO Classes You Need (filter these from detections):**

| Class ID | Label |
|---|---|
| 0 | person (pedestrian) |
| 1 | bicycle |
| 2 | car |
| 3 | motorcycle |
| 5 | bus |
| 7 | truck |

#### 4.2 TFLite Inference (Kotlin)

```kotlin
import org.tensorflow.lite.Interpreter
import java.nio.ByteBuffer
import java.nio.ByteOrder

class YoloDetector(context: Context) {

  private val interpreter: Interpreter

  init {
    val model = loadModelFile(context, "yolov8n_int8.tflite")
    interpreter = Interpreter(model, Interpreter.Options().apply {
      numThreads = 4         // Use all CPU cores
      useNNAPI = true        // Hardware acceleration if available
    })
  }

  data class Detection(
    val classId: Int,
    val label: String,
    val confidence: Float,
    val boundingBox: RectF   // x1, y1, x2, y2 normalized [0,1]
  )

  fun detect(inputBuffer: ByteBuffer): List<Detection> {
    inputBuffer.rewind()
    val outputBuffer = Array(1) { Array(84) { FloatArray(8400) } }
    interpreter.run(inputBuffer, outputBuffer)
    return parseOutput(outputBuffer)
  }

  private fun parseOutput(output: Array<Array<FloatArray>>): List<Detection> {
    val detections = mutableListOf<Detection>()
    val CONF_THRESHOLD = 0.45f
    val targetClasses = setOf(0, 1, 2, 3, 5, 7)

    for (i in 0 until 8400) {
      val x = output[0][0][i]
      val y = output[0][1][i]
      val w = output[0][2][i]
      val h = output[0][3][i]

      var maxConf = 0f
      var maxClass = -1
      for (c in 4 until 84) {
        if (output[0][c][i] > maxConf) {
          maxConf = output[0][c][i]
          maxClass = c - 4
        }
      }

      if (maxConf > CONF_THRESHOLD && maxClass in targetClasses) {
        detections.add(Detection(
          classId = maxClass,
          label = COCO_LABELS[maxClass],
          confidence = maxConf,
          boundingBox = RectF(x - w/2, y - h/2, x + w/2, y + h/2)
        ))
      }
    }
    return applyNMS(detections)
  }

  private fun applyNMS(detections: List<Detection>): List<Detection> {
    // Non-Maximum Suppression: remove duplicate boxes for same object
    // Sort by confidence, remove boxes with IoU > 0.45
    // ... (implement standard NMS algorithm)
    return detections
  }
}
```

#### 4.3 Copy TFLite Model to Assets

Place `yolov8n_int8.tflite` in `android/app/src/main/assets/` and declare in `build.gradle`:

```gradle
android {
  aaptOptions {
    noCompress "tflite"
  }
}
```

---

### Phase 5 — Traffic Analysis Logic

**Goal:** From raw detections, determine if any vehicle is close and moving toward the pedestrian.

#### 5.1 Distance Estimation (Bounding Box Heuristics)

Since we don't have depth sensors, we estimate distance using bounding box height:

```kotlin
object TrafficAnalyzer {

  // Approximate: larger bounding box = closer vehicle
  fun estimateDistance(boundingBox: RectF, frameHeight: Int): String {
    val boxHeightRatio = (boundingBox.bottom - boundingBox.top) // normalized [0,1]

    return when {
      boxHeightRatio > 0.5f -> "VERY_CLOSE"   // Box occupies >50% of frame height
      boxHeightRatio > 0.25f -> "CLOSE"
      boxHeightRatio > 0.10f -> "MEDIUM"
      else -> "FAR"
    }
  }

  // Detect if vehicle is approaching (box getting larger over frames)
  fun isApproaching(currentBox: RectF, previousBox: RectF): Boolean {
    val currentSize = (currentBox.bottom - currentBox.top) * (currentBox.right - currentBox.left)
    val previousSize = (previousBox.bottom - previousBox.top) * (previousBox.right - previousBox.left)
    return currentSize > previousSize * 1.05f  // Growing by more than 5%
  }
}
```

#### 5.2 Vehicle Tracking Across Frames

To track the same vehicle across multiple frames (required for approach detection):

```kotlin
data class TrackedVehicle(
  val id: Int,
  val label: String,
  var currentBox: RectF,
  var previousBox: RectF?,
  var isApproaching: Boolean = false,
  var distanceCategory: String = "FAR"
)

class VehicleTracker {
  private val trackedVehicles = mutableMapOf<Int, TrackedVehicle>()
  private var nextId = 0

  fun update(detections: List<Detection>): List<TrackedVehicle> {
    // Simple IoU-based matching of detections to existing tracked vehicles
    val matched = mutableSetOf<Int>()

    detections.forEach { detection ->
      val matchedVehicle = trackedVehicles.values
        .filter { it.id !in matched }
        .maxByOrNull { iou(it.currentBox, detection.boundingBox) }

      if (matchedVehicle != null && iou(matchedVehicle.currentBox, detection.boundingBox) > 0.3f) {
        matchedVehicle.previousBox = matchedVehicle.currentBox
        matchedVehicle.currentBox = detection.boundingBox
        matched.add(matchedVehicle.id)
      } else {
        trackedVehicles[nextId] = TrackedVehicle(
          id = nextId++,
          label = detection.label,
          currentBox = detection.boundingBox,
          previousBox = null
        )
      }
    }
    return trackedVehicles.values.toList()
  }

  private fun iou(boxA: RectF, boxB: RectF): Float {
    val intersection = RectF()
    if (!intersection.setIntersect(boxA, boxB)) return 0f
    val intersectionArea = intersection.width() * intersection.height()
    val unionArea = boxA.width() * boxA.height() + boxB.width() * boxB.height() - intersectionArea
    return intersectionArea / unionArea
  }
}
```

---

### Phase 6 — Safety Decision Engine

**Goal:** Combine all analysis signals into one binary SAFE / NOT SAFE verdict.

```dart
// safety_engine.dart

enum SafetyStatus { safe, notSafe, analyzing }

class SafetyEngine {
  static SafetyStatus evaluate(List<TrackedVehicle> vehicles) {
    // Rule 1: Any very close vehicle = NOT SAFE
    final veryClose = vehicles.any((v) => v.distanceCategory == 'VERY_CLOSE');
    if (veryClose) return SafetyStatus.notSafe;

    // Rule 2: Any close AND approaching vehicle = NOT SAFE
    final closeAndApproaching = vehicles.any(
      (v) => v.distanceCategory == 'CLOSE' && v.isApproaching
    );
    if (closeAndApproaching) return SafetyStatus.notSafe;

    // Rule 3: Multiple medium-distance approaching vehicles = NOT SAFE
    final multipleApproaching = vehicles
        .where((v) => v.distanceCategory == 'MEDIUM' && v.isApproaching)
        .length;
    if (multipleApproaching >= 2) return SafetyStatus.notSafe;

    // Rule 4: No vehicles detected at all, or all vehicles are far/receding
    return SafetyStatus.safe;
  }
}
```

**Decision Matrix:**

| Vehicle Distance | Approaching? | Verdict |
|---|---|---|
| VERY_CLOSE (any) | Any | ❌ NOT SAFE |
| CLOSE | Yes | ❌ NOT SAFE |
| CLOSE | No (receding) | ✅ SAFE |
| MEDIUM | Yes (multiple) | ❌ NOT SAFE |
| MEDIUM | Yes (single) | ⚠️ CAUTION (treat as NOT SAFE) |
| FAR / None | Any | ✅ SAFE |

---

### Phase 7 — Voice & Alert System

**Goal:** Communicate the safety decision clearly to the user via multiple channels.

```dart
// alert_service.dart
import 'package:flutter_tts/flutter_tts.dart';
import 'package:vibration/vibration.dart';

class AlertService {
  final FlutterTts _tts = FlutterTts();

  Future<void> init() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.5);   // Slower = clearer
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  Future<void> announceSafe() async {
    await _tts.speak("Safe to cross.");
    // Single short vibration
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 200);
    }
  }

  Future<void> announceNotSafe() async {
    await _tts.speak("Warning! Do not cross. Vehicles approaching.");
    // Rapid repeated vibration — urgent pattern
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(pattern: [0, 300, 200, 300, 200, 300]);
    }
  }

  Future<void> stop() async {
    await _tts.stop();
    Vibration.cancel();
  }
}
```

**On-Screen Alert Widget (Dart):**

```dart
// safety_banner.dart
class SafetyBanner extends StatelessWidget {
  final SafetyStatus status;
  const SafetyBanner({required this.status, super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: status == SafetyStatus.safe
          ? Colors.green.withOpacity(0.85)
          : Colors.red.withOpacity(0.85),
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            status == SafetyStatus.safe ? Icons.check_circle : Icons.warning,
            color: Colors.white,
            size: 40,
          ),
          const SizedBox(width: 12),
          Text(
            status == SafetyStatus.safe ? "SAFE TO CROSS" : "DO NOT CROSS",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
```

---

### Phase 8 — Testing & Debugging

See Section 12 for the full Testing Strategy.

**Quick checklist for Phase 8:**
- [ ] Test on 3+ real-world traffic conditions (busy intersection, quiet lane, highway overpass)
- [ ] Verify camera works in: bright sunlight, overcast, night/low light
- [ ] Verify TFLite inference time < 100ms per frame on target device
- [ ] Verify voice alerts trigger within 1 second of status change
- [ ] Verify no app crash on 30+ minutes of continuous use (memory leak check)

---

### Phase 9 — Documentation & Presentation

Deliverables:
- Project Report (this document, reformatted for college submission)
- PowerPoint (10–12 slides: Problem → Solution → Architecture → Demo → Results → Future Work)
- Working APK for live demo
- 2–3 minute video demonstration recorded on actual device

---

## 6. Folder Structure

```
traffic_safety_app/
│
├── android/
│   ├── app/
│   │   ├── src/main/
│   │   │   ├── assets/
│   │   │   │   └── yolov8n_int8.tflite      ← TFLite model file
│   │   │   ├── java/com/yourname/trafficsafety/
│   │   │   │   ├── MainActivity.kt
│   │   │   │   ├── YoloDetector.kt           ← TFLite inference
│   │   │   │   ├── FrameProcessor.kt         ← OpenCV preprocessing
│   │   │   │   ├── VehicleTracker.kt         ← Multi-frame tracking
│   │   │   │   └── TrafficAnalyzer.kt        ← Distance/speed logic
│   │   │   └── AndroidManifest.xml
│   │   └── build.gradle
│   └── build.gradle
│
├── lib/
│   ├── main.dart                              ← App entry point
│   ├── screens/
│   │   ├── camera_screen.dart                ← Main live camera view
│   │   ├── home_screen.dart                  ← Welcome / start screen
│   │   └── settings_screen.dart             ← Sensitivity, language, etc.
│   ├── services/
│   │   ├── alert_service.dart               ← TTS + vibration
│   │   ├── detection_channel.dart           ← Platform channel bridge
│   │   └── safety_engine.dart              ← Safety verdict logic
│   ├── widgets/
│   │   ├── safety_banner.dart               ← SAFE / NOT SAFE overlay
│   │   ├── detection_overlay.dart           ← Bounding box painter
│   │   └── loading_screen.dart
│   └── models/
│       ├── detection.dart                   ← Detection data class
│       └── tracked_vehicle.dart            ← Tracker data class
│
├── python/
│   ├── export_model.py                      ← YOLOv8 → TFLite export
│   ├── train_custom.py                      ← Optional: custom training
│   ├── test_inference.py                    ← PC-side model testing
│   └── dataset/                            ← Training images (optional)
│
├── pubspec.yaml
└── README.md
```

---

## 7. Key Libraries & Dependencies

### Flutter / Dart

| Package | Version | Purpose |
|---|---|---|
| `camera` | ^0.10.5 | Live camera feed + frame streaming |
| `flutter_tts` | ^3.8.3 | Text-to-speech voice alerts |
| `vibration` | ^1.8.4 | Haptic feedback patterns |
| `tflite_flutter` | ^0.10.4 | Run TFLite model from Dart |
| `image` | ^4.1.3 | Image format conversion |
| `provider` | ^6.1.1 | App-wide state management |
| `permission_handler` | ^11.1.0 | Runtime permission requests |

### Android / Kotlin

| Library | Version | Purpose |
|---|---|---|
| `TensorFlow Lite` | 2.14.0 | On-device ML inference |
| `OpenCV Android` | 4.8.0 | Image preprocessing |
| `Camera2` | (built-in) | Low-latency camera access |

### Python (PC only)

| Package | Purpose |
|---|---|
| `ultralytics` | YOLOv8 training + export |
| `tensorflow` | TFLite conversion |
| `opencv-python` | Image processing tests |
| `numpy` | Numerical operations |

---

## 8. API & Data Flow

### Frame Processing Pipeline

```
Camera Frame (YUV_420_888)
        ↓
  [Convert YUV → Bitmap]  (Kotlin)
        ↓
  [OpenCV Preprocess]      (Kotlin)
  → Resize to 640×640
  → BGR → RGB
  → Gaussian blur
  → Normalize [0,1]
        ↓
  [TFLite Inference]       (Kotlin)
  → Input: float32[1, 640, 640, 3]
  → Output: float32[1, 84, 8400]
        ↓
  [Parse Detections]       (Kotlin)
  → Filter by confidence > 0.45
  → Filter by target classes
  → Apply NMS
        ↓
  [Vehicle Tracking]       (Kotlin)
  → IoU matching across frames
  → Compute isApproaching
  → Compute distanceCategory
        ↓
  [Platform Channel]       (Kotlin → Dart)
  → JSON: { detections: [...], status: "NOT_SAFE" }
        ↓
  [Safety Engine]          (Dart)
  → Evaluate rules
  → Emit SafetyStatus
        ↓
  [Alert Service]          (Dart)
  → TTS announcement
  → Vibration pattern
  → Update SafetyBanner UI
```

### Platform Channel Data Format

**Dart → Kotlin (input):**
```json
{
  "imageBytes": [/* raw pixel bytes */],
  "width": 640,
  "height": 480
}
```

**Kotlin → Dart (output):**
```json
{
  "status": "NOT_SAFE",
  "detections": [
    {
      "classId": 2,
      "label": "car",
      "confidence": 0.87,
      "bbox": { "x1": 0.2, "y1": 0.4, "x2": 0.7, "y2": 0.9 },
      "distance": "CLOSE",
      "approaching": true
    }
  ],
  "inferenceTimeMs": 42
}
```

---

## 9. YOLOv8 Model Integration Details

### Training Your Own Model (Optional Enhancement)

If you want to fine-tune YOLOv8 on traffic-specific data:

```python
# train_custom.py
from ultralytics import YOLO

model = YOLO("yolov8n.pt")  # Start from pretrained

results = model.train(
  data="custom_traffic.yaml",  # Your dataset config
  epochs=50,
  imgsz=640,
  batch=16,
  device=0,           # GPU (0) or 'cpu'
  project="runs/traffic",
  name="exp1"
)

# Export to TFLite after training
model.export(format="tflite", int8=True)
```

**Dataset YAML format (`custom_traffic.yaml`):**
```yaml
path: ./dataset
train: images/train
val: images/val
test: images/test

nc: 6  # number of classes
names: ['person', 'bicycle', 'car', 'motorcycle', 'bus', 'truck']
```

### Recommended Public Datasets
- **COCO 2017** (pre-trained weights already include all needed classes)
- **BDD100K** (Berkeley DeepDrive — dashcam footage, ideal for this project)
- **KITTI** (autonomous driving dataset)

### Model Input/Output Specification

| Property | Value |
|---|---|
| Input shape | `[1, 640, 640, 3]` (float32) |
| Input range | `[0.0, 1.0]` |
| Output shape | `[1, 84, 8400]` |
| Output format | `[x_center, y_center, w, h, class_0_conf, ..., class_79_conf]` |
| Confidence threshold | 0.45 (tunable) |
| NMS IoU threshold | 0.45 |

---

## 10. Safety Decision Logic

### Complete Decision Flow

```
Input: List of TrackedVehicle objects
            │
            ▼
   ┌─────────────────────────────┐
   │  Any vehicle VERY_CLOSE?   │──Yes──► NOT SAFE ❌
   └──────────No────────────────┘
            │
            ▼
   ┌─────────────────────────────┐
   │  Any CLOSE + Approaching?  │──Yes──► NOT SAFE ❌
   └──────────No────────────────┘
            │
            ▼
   ┌─────────────────────────────┐
   │  2+ MEDIUM + Approaching?  │──Yes──► NOT SAFE ❌
   └──────────No────────────────┘
            │
            ▼
   ┌─────────────────────────────┐
   │  1 MEDIUM + Approaching?   │──Yes──► CAUTION ⚠️ (treat as NOT SAFE)
   └──────────No────────────────┘
            │
            ▼
        SAFE TO CROSS ✅
```

### Calibration Parameters (Tunable)

| Parameter | Default | Description |
|---|---|---|
| `CONF_THRESHOLD` | 0.45 | Min confidence to count a detection |
| `VERY_CLOSE_RATIO` | 0.50 | Bounding box height > 50% of frame |
| `CLOSE_RATIO` | 0.25 | Bounding box height > 25% of frame |
| `MEDIUM_RATIO` | 0.10 | Bounding box height > 10% of frame |
| `APPROACH_GROWTH` | 1.05 | Box must grow by 5% per frame to be "approaching" |
| `NMS_IOU` | 0.45 | Non-maximum suppression threshold |

---

## 11. UI/UX Design Guidelines

### Main Camera Screen Layout

```
┌──────────────────────────────────┐
│   [Status: SAFE / NOT SAFE]      │  ← Full-width banner, top
│   Green / Red background          │
├──────────────────────────────────┤
│                                  │
│      LIVE CAMERA PREVIEW         │
│                                  │
│   ┌─────┐                        │
│   │ Car │ ← Bounding box overlay │
│   └─────┘                        │
│                                  │
│             🚶                   │
│                                  │
├──────────────────────────────────┤
│  [🔊 Voice ON]  [⚙ Settings]    │  ← Bottom toolbar
└──────────────────────────────────┘
```

### Color Coding
- **Green (`#4CAF50`):** Safe to cross
- **Red (`#F44336`):** Not safe / Warning
- **Amber (`#FFC107`):** Analyzing / Loading
- **White text** on all status banners for maximum contrast

### Accessibility Requirements
- Minimum button size: 48×48 dp (Android accessibility guideline)
- Voice alert default: ON
- Font size: minimum 18sp for status text
- High contrast mode support

---

## 12. Testing Strategy

### Unit Tests

| Module | What to Test |
|---|---|
| `SafetyEngine` | All decision rule combinations |
| `VehicleTracker` | IoU calculation, ID persistence across frames |
| `TrafficAnalyzer` | Distance category thresholds |
| `AlertService` | TTS triggers, vibration pattern correctness |

### Integration Tests

| Test Scenario | Expected Result |
|---|---|
| Empty frame (no vehicles) | SAFE alert |
| Single large bounding box (close car) | NOT SAFE alert |
| Small bounding box (far car) | SAFE alert |
| Box growing across 5 frames | Approaching = true |
| Box shrinking across 5 frames | Approaching = false |

### Real-World Test Scenarios

| Scenario | Pass Criteria |
|---|---|
| Quiet residential street | SAFE within 2 seconds |
| Busy urban intersection | NOT SAFE consistently |
| Vehicle passing laterally (not approaching) | SAFE (lateral = not approaching) |
| Night-time / low light | Detection still functional (may be lower accuracy) |
| Partly cloudy / variable lighting | No excessive flickering between SAFE/NOT SAFE |

### Performance Benchmarks

| Metric | Target |
|---|---|
| Inference latency (YOLOv8n) | < 100ms per frame |
| End-to-end alert latency | < 500ms from frame to alert |
| App startup time | < 3 seconds |
| Memory usage | < 300 MB |
| Battery drain | < 15% per hour of use |

---

## 13. Known Challenges & Mitigation

| Challenge | Risk Level | Mitigation |
|---|---|---|
| Low-light detection accuracy | High | Add `CAUTION` mode in dark conditions; optionally enable phone flashlight |
| Occlusion (vehicle hidden behind another) | Medium | Track multiple vehicles; assume worst case |
| Camera shake (phone not held steady) | Medium | Bounding box smoothing using moving average over 3 frames |
| False positives (parked cars flagged as approaching) | Medium | Apply approach detection: only flag if box is growing |
| YUV→RGB conversion latency | Low | Use native Kotlin for conversion; avoid doing it in Dart |
| TFLite model not found crash | Low | Add try-catch on model load; show friendly error screen |
| Simultaneous TTS and next frame inference lag | Low | Run inference on background thread; TTS on main thread |

---

## 14. Deliverables Checklist

### Core Application
- [ ] Flutter app runs on Android without crash
- [ ] Rear camera opens and streams live feed
- [ ] OpenCV preprocessing applied per frame
- [ ] YOLOv8 detects cars, bikes, buses, trucks, motorcycles, pedestrians
- [ ] Bounding boxes displayed correctly on screen overlay
- [ ] Vehicle approach detection works across frames
- [ ] SAFE / NOT SAFE decision computed correctly
- [ ] Voice alert triggers for each status change
- [ ] Vibration pattern triggers for NOT SAFE
- [ ] On-screen banner shows SAFE / NOT SAFE clearly

### Code Quality
- [ ] Platform Channel wired correctly (Flutter ↔ Kotlin)
- [ ] No memory leaks on extended run
- [ ] TFLite model loaded from assets correctly
- [ ] Error handling for camera permission denied
- [ ] App does not crash if TFLite model fails to load

### Documentation
- [ ] Project Report written
- [ ] PowerPoint presentation ready (10–12 slides)
- [ ] README with setup instructions committed to Git
- [ ] APK exported and installable

### Presentation
- [ ] Live demo works on real Android device
- [ ] Backup screen-recorded video if live demo fails
- [ ] Team can explain the YOLOv8 inference pipeline
- [ ] Team can explain the safety decision logic
- [ ] Team can answer: "Why YOLOv8 over other models?"

---

## 15. Glossary

| Term | Definition |
|---|---|
| **TFLite** | TensorFlow Lite — a lightweight version of TensorFlow for mobile/embedded devices |
| **YOLOv8** | You Only Look Once v8 — a real-time object detection model by Ultralytics |
| **OpenCV** | Open Source Computer Vision Library — used for image preprocessing |
| **Bounding Box** | A rectangle drawn around a detected object (x, y, width, height) |
| **Confidence Score** | The model's probability that a detection is correct (0.0 to 1.0) |
| **NMS** | Non-Maximum Suppression — removes duplicate detections of the same object |
| **IoU** | Intersection over Union — metric for how much two bounding boxes overlap |
| **Platform Channel** | Flutter's mechanism to call native Android/iOS code from Dart |
| **INT8 Quantization** | Converting model weights from 32-bit floats to 8-bit integers for faster inference |
| **NNAPI** | Neural Networks API — Android's hardware-accelerated ML inference layer |
| **mAP** | Mean Average Precision — standard metric for object detection model accuracy |
| **CameraImage (YUV_420_888)** | The raw image format produced by Flutter's camera plugin |

---

*Document Version: 1.0 | Generated for Traffic Safety Mobile App Project*