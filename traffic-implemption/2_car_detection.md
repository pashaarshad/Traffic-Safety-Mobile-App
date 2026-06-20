# 2. Car Detection Implementation Plan

This document outlines the specific implementation plan for detecting, tracking, and calibrating safety heuristics for passenger cars (`car` - COCO Class ID 2) using YOLOv8 and Flutter.

---

## Technical Specifications
*   **Target Category:** Class ID 2 (`car`) inside COCO Labels.
*   **Alternative Training Datasets:** Berkeley DeepDrive (BDD100K), KITTI, or UA-DETRAC.
*   **Average Physical Dimensions:** Width ($W_{\text{car}}$) $\approx 1.8$ meters, Height ($H_{\text{car}}$) $\approx 1.5$ meters.

---

## Step-by-Step Implementation

### Step 1: Python Dataset Selection & Training
1. Prepare a traffic dataset (COCO subset or UA-DETRAC dataset containing vehicle instances).
2. Configure Python training scripts using the `ultralytics` package.
3. Fine-tune YOLOv8 Nano model weights:
   ```python
   from ultralytics import YOLO
   model = YOLO("yolov8n.pt")
   model.train(
       data="car_dataset.yaml",
       epochs=50,
       imgsz=640,
       batch=16,
       device=0  # Use GPU 0
   )
   ```
4. Verify accuracy metrics: Average Precision (AP) for class 2 must exceed 85% at IoU 0.50.
5. Export to INT8 quantized TFLite model using representative dataset images to preserve floating-point coordinates.

### Step 2: Android Assets Integration
1. Place the converted model `yolov8n_car.tflite` inside `android/app/src/main/assets/`.
2. Configure JNI bindings to target class index 2 inside `YoloDetector.kt` and label it as `"car"`.

### Step 3: Custom Distance Estimation Heuristics (Kotlin)
Passenger cars have a predictable aspect ratio. We estimate monocular distance based on the bounding box height ratio ($R_h$) relative to the camera viewport ($R_h = y_{\text{max}} - y_{\text{min}}$):

$$Distance_{\text{meters}} = \frac{k_{\text{car}}}{R_h}$$

Where $k_{\text{car}} \approx 7.0$ (calibrated focal factor for a typical phone camera).
1. Add distance classification logic inside `VehicleTracker.kt`:
   ```kotlin
   val heightRatio = boundingBox.height()
   val estimatedDistance = 7.0 / heightRatio
   val distanceCategory = when {
       heightRatio > 0.48 -> "very_close"  // Distance < 6 meters
       heightRatio > 0.28 -> "close"       // Distance 6 - 12 meters
       heightRatio > 0.12 -> "medium"      // Distance 12 - 25 meters
       else -> "far"
   }
   ```

### Step 4: Approach Velocity & Motion Vectors (Kotlin)
1. For each tracked car, compare the bounding box area $A_t$ in frame $t$ with the area $A_{t-1}$ in frame $t-1$:
   $$A_t = (x_{\text{max}} - x_{\text{min}}) \times (y_{\text{max}} - y_{\text{min}})$$
2. Set `isApproaching = true` if the bounding box area grows by $> 4\%$ over at least 2 consecutive frames:
   ```kotlin
   val currentArea = boundingBox.width() * boundingBox.height()
   val isApproaching = currentArea > previousArea * 1.04
   ```

### Step 5: Flutter Safety Logic Integration (Dart)
1. Parse detections returned by the native bridge inside `safety_engine.dart`.
2. Evaluate rules specific to passenger cars:
   *   **Rule 1:** Any car classified as `very_close` triggers `AlertMode.warning` (DO NOT CROSS), regardless of its speed or trajectory (immediate hazard zone).
   *   **Rule 2:** Any car classified as `close` and `isApproaching == true` triggers `AlertMode.warning` (DO NOT CROSS) to prevent the user from stepping in front of it.
   *   **Rule 3:** A car classified as `medium` and `isApproaching == true` triggers `AlertMode.caution` (yellow overlay), alerting the user of incoming traffic.
   *   **Rule 4:** If the car is receding (`isApproaching == false`), the status remains `safe` (Green).
3. Notify `AlertService` to trigger corresponding audio instructions ("Warning! Car approaching") and haptic vibration patterns.
