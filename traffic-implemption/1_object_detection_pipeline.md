# 1. Object Detection Pipeline Integration Plan

This document outlines the step-by-step implementation plan to establish a real-time, on-device object detection pipeline in the Traffic Safety Mobile App using YOLOv8 and TensorFlow Lite (TFLite) running via native Kotlin MethodChannels.

---

## Technical Overview
The live video feed is captured by the Flutter Camera plugin, converted to raw frame bytes, sent over the platform MethodChannel to native Kotlin, preprocessed with OpenCV-like steps (resize, normalize, blur), run through the quantized YOLOv8 TFLite model, processed via Non-Maximum Suppression (NMS), tracked across frames, and returned back to the Flutter UI layer as JSON metadata for rendering bounding boxes and alerts.

```
+---------------------+     Camera Frames     +---------------------------+
|  Flutter UI (Dart)  | --------------------> | MainActivity (Kotlin JNI) |
|                     |                       +---------------------------+
|  - Camera Preview   |                                     |
|  - Neon HUD Paint   |                                     v
|  - Alert Controller |                       +---------------------------+
|                     | <-------------------- |   FrameProcessor.kt       |
|  - State Manager    |      JSON Detections  |   (Resizing & Filtering)  |
+---------------------+                       +---------------------------+
                                                            |
                                                            v
                                              +---------------------------+
                                              |     YoloDetector.kt       |
                                              |   (TFLite Inference & NMS)|
                                              +---------------------------+
                                                            |
                                                            v
                                              +---------------------------+
                                              |    VehicleTracker.kt      |
                                              |   (Temporal IoU Tracking) |
                                              +---------------------------+
```

---

## Detailed Step-by-Step Implementation

### Step 1: Model Export & Optimization (Python)
1. Train/evaluate the YOLOv8 Nano model (`yolov8n.pt`) on PC/Colab.
2. Export the PyTorch model to TensorFlow Lite format using the `ultralytics` package.
3. Configure full INT8 quantization during export to optimize performance on mobile CPUs/NPUs.
   ```python
   from ultralytics import YOLO
   model = YOLO("yolov8n.pt")
   model.export(format="tflite", imgsz=640, int8=True, data="coco.yaml")
   ```
4. Secure the output model named `yolov8n_int8.tflite` and copy it into the Android project assets directory: `android/app/src/main/assets/yolov8n_int8.tflite`.

### Step 2: Build Environment Configurations (Android Gradle)
1. Add TFLite build dependencies to `android/app/build.gradle.kts` to enable Java/Kotlin interpreters:
   ```kotlin
   dependencies {
       implementation("org.tensorflow:tensorflow-lite:2.14.0")
       implementation("org.tensorflow:tensorflow-lite-gpu:2.14.0")
       implementation("org.tensorflow:tensorflow-lite-support:0.4.4")
   }
   ```
2. Disable TFLite model compression in `android/app/build.gradle.kts` to let the interpreter load the model directly from assets via FileDescriptor:
   ```kotlin
   android {
       aaptOptions {
           noCompress("tflite")
       }
   }
   ```

### Step 3: Native Image Preprocessing (Kotlin)
1. Receive raw image bytes from the MethodChannel inside `MainActivity.kt`.
2. Convert the byte buffer (often representing YUV_420_888 camera stream formats) to an ARGB Bitmap using `BitmapFactory` or a custom native conversion buffer.
3. In `FrameProcessor.kt`, resize the bitmap to model dimensions ($640 \times 640$ pixels):
   ```kotlin
   val resized = Bitmap.createScaledBitmap(original, 640, 640, true)
   ```
4. Implement pixel smoothing (Gaussian filter mock or native OpenCV Blur) to filter noise.
5. Allocate a direct `ByteBuffer` of size `1 * 640 * 640 * 3 * 4` bytes (1 batch, 640x640 resolution, 3 channels, 4 bytes per float). Set ByteOrder to `nativeOrder()`.
6. Write normalized pixel values `[0.0, 1.0]` into the buffer. Loop through the pixels, extract R, G, B channels, divide by 255.0f, and write to the ByteBuffer.

### Step 4: Model Inference execution (Kotlin)
1. Load `yolov8n_int8.tflite` from assets inside `YoloDetector.kt` using `AssetFileDescriptor`.
2. Initialize the `Interpreter` with options (use GPU delegate or set `numThreads = 4`).
3. Allocate the output buffer matrix matching YOLOv8 output size: `float[][][] output = new float[1][84][8400]`.
4. Run inference: `interpreter.run(inputBuffer, outputBuffer)`.

### Step 5: Parsing Detections & Non-Maximum Suppression (NMS)
1. Iterate through the 8,400 predictions inside `YoloDetector.kt`.
2. Each prediction contains `[x_center, y_center, width, height, class_0_conf, ..., class_79_conf]`.
3. Filter detections where the maximum class confidence exceeds `confidenceThreshold` (default `0.40`).
4. Apply **Non-Maximum Suppression (NMS)**:
   * Sort detected boxes by confidence score in descending order.
   * Select the box with the highest score and add it to the final detections list.
   * Calculate Intersection-over-Union (IoU) between the selected box and other boxes in the list.
   * Remove any boxes that have an IoU overlap $> 0.45$ with the selected box.
   * Repeat until all candidate boxes are processed.

### Step 6: MethodChannel Integration (Kotlin -> Dart Bridge)
1. Pass the NMS-filtered detections into `VehicleTracker.kt` to update IDs and compute movement vectors.
2. Structure detection properties into a JSON-compatible map list:
   ```kotlin
   val resultList = detections.map { det ->
       mapOf(
           "id" to det.id,
           "label" to det.label,
           "confidence" to det.confidence,
           "xMin" to det.xMin,
           "yMin" to det.yMin,
           "xMax" to det.xMax,
           "yMax" to det.yMax,
           "distance" to det.distance,
           "isApproaching" to det.isApproaching,
           "estimatedDistanceMeters" to det.estimatedDistance
       )
   }
   ```
3. Return the payload over the MethodChannel to `detection_service.dart`.
4. Decode maps inside `DetectedObject.fromMap` in Dart and update the Stream for the camera screen.
