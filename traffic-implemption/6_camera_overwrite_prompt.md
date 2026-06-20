# 6. Real-Time Camera Overwrite Implementation Plan & Prompt

This document provides a step-by-step blueprint and a pre-written, copy-pasteable LLM prompt to transition the codebase from **Simulation Mode** (mock data) to **Live Camera Mode** (real-time, on-device object detection using the phone's camera, OpenCV, and the YOLOv8 TFLite model).

---

## Codebase Analysis: Why the Camera Screen Shows No Real Detections

Currently, the application displays a static mock car or simulated targets because:
1.  **`DetectionService` defaults to Simulation:** In `lib/services/detection_service.dart`, the mode is initialized as `DetectionMode.simulation`.
2.  **`YoloDetector.kt` contains Mock Data:** The native Kotlin file `YoloDetector.kt` has a simulated implementation inside `runInference(bitmap)` which always returns a hardcoded passenger car bounding box (`classId = 2, label = "car"`), instead of executing the TFLite interpreter.
3.  **Missing OpenCV/TFLite Library Links:** Although `MainActivity.kt` handles the MethodChannel, the native packages for TFLite are not fully wired to load the model from assets and read the memory buffer.

---

## Overwrite Roadmap
To enable real-time detection, we must modify three core layers:

```
  [1. Flutter Main Config]          [2. Native Method Handler]          [3. Native TFLite Interpreter]
   - Force Camera mode by            - Read camera frame bytes.          - Load model.tflite.
     default in main.dart.           - Preprocess via OpenCV            - Parse RGB pixels.
   - Stream frames at 10 FPS.          resizing & blurring.              - Apply NMS & return boxes.
```

---

## Pre-Written Prompt for the AI Assistant / IDE

Copy the prompt below and paste it into the Antigravity IDE Chat Interface to execute the overwrite:

```text
Please overwrite the mock simulation layers in the project to enable actual, real-time camera-based object detection using our YOLOv8 TFLite model. Follow these exact steps:

1. Locate and modify `d:\Traffic Safety Mobile App\lib\services\detection_service.dart`:
   - Set the default `DetectionMode` to `camera` instead of `simulation`.
   - Ensure the method `processCameraImage` is fully enabled to send raw frame bytes to the native platform channel.

2. Locate and modify `d:\Traffic Safety Mobile App\lib\screens\camera_screen.dart`:
   - Ensure that when the rear camera is initialized, the camera image stream starts:
     `_cameraController!.startImageStream((CameraImage image) { ... })`
   - Grab the planes, map their bytes into a single list, and call `detectionService.processCameraImage(bytes, image.width, image.height)` every 3rd or 4th frame to throttle the processing rate (minimizing latency).

3. Locate and modify `d:\Traffic Safety Mobile App\android\app\src\main\kotlin\com\trafficsafety\traffic_safety_app\YoloDetector.kt`:
   - Replace the mock detection list inside `runInference(bitmap)` with a real TensorFlow Lite execution block.
   - Initialize the `org.tensorflow.lite.Interpreter` by reading the `yolov8n_int8.tflite` model from the assets folder.
   - Set up the input float ByteBuffer: Allocate a ByteBuffer of size `1 * 640 * 640 * 3 * 4` (floating-point format). Extract R, G, B values from the input Bitmap, normalize them `[0.0f, 1.0f]`, and write them into the buffer.
   - Allocate the output tensor mapping shape `[1][84][8400]`.
   - Run `interpreter.run(inputBuffer, outputBuffer)`.
   - Parse the candidate bounding boxes, extract maximum class confidence scores, filter classes (0, 1, 2, 3, 5, 7), and apply a standard Non-Maximum Suppression (NMS) function to remove overlapping duplicates.

4. Locate and modify `d:\Traffic Safety Mobile App\android\app\src\main\kotlin\com\trafficsafety\traffic_safety_app\MainActivity.kt`:
   - Ensure the method channel handler decodes raw JPEG/YUV byte arrays, reconstructs the Bitmap, passes it to `FrameProcessor.preprocessBitmap()`, runs inference in `YoloDetector`, tracks coordinates in `VehicleTracker`, and returns the detection metadata as a JSON-compatible map.
```
