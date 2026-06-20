# 3. Bike & Motorcycle Detection Implementation Plan

This document outlines the specific implementation plan for detecting, tracking, and calibrating safety heuristics for two-wheelers (`bicycle` - COCO Class ID 1, `motorcycle` - COCO Class ID 3) using YOLOv8 and Flutter.

---

## Technical Specifications
*   **Target Categories:** Class ID 1 (`bicycle`) and Class ID 3 (`motorcycle`) inside COCO Labels.
*   **Average Physical Dimensions:** Width ($W_{\text{bike}}$) $\approx 0.8$ meters, Height ($H_{\text{bike}}$) $\approx 1.1$ meters.
*   **Core Challenges:**
    1.  **High Lateral Mobility:** Two-wheelers often weave between lanes or cross lanes laterally.
    2.  **Smaller Visual Profile:** A smaller bounding box compared to passenger cars requires lower distance scaling factors to prevent false security feelings.

---

## Step-by-Step Implementation

### Step 1: Python Model Fine-Tuning
1. Construct a dataset containing diverse annotations of bicycles and motorcycles (COCO dataset filter or BDD100K).
2. Configure Python training:
   ```python
   from ultralytics import YOLO
   model = YOLO("yolov8n.pt")
   model.train(
       data="bike_dataset.yaml",
       epochs=45,
       imgsz=640,
       batch=16,
       device=0
   )
   ```
3. Set confidence score floor to $0.40$ during post-training validation to minimize background false alarms.
4. Export the weights to an optimized INT8 TFLite model.

### Step 2: Native Android Detector Integration
1. Place the optimized model `yolov8n_bikes.tflite` inside `android/app/src/main/assets/`.
2. Configure class IDs `1` and `3` inside `YoloDetector.kt` to map to the label `"bicycle"` and `"motorcycle"`.

### Step 3: Monocular Distance Calibration (Kotlin)
Because two-wheelers have smaller dimensions than cars, the scaling factor ($k_{\text{bike}}$) is set lower to prevent underestimating threat distance:

$$Distance_{\text{meters}} = \frac{k_{\text{bike}}}{R_h}$$

Where $k_{\text{bike}} \approx 4.5$.
1. Configure threat thresholds inside `VehicleTracker.kt`:
   ```kotlin
   val heightRatio = boundingBox.height()
   val estimatedDistance = 4.5 / heightRatio
   val distanceCategory = when {
       heightRatio > 0.40 -> "very_close"  // Distance < 5 meters
       heightRatio > 0.22 -> "close"       // Distance 5 - 10 meters
       heightRatio > 0.10 -> "medium"      // Distance 10 - 20 meters
       else -> "far"
   }
   ```

### Step 4: Lateral Movement Vector Evaluation (Kotlin)
Unlike passenger cars, which mostly approach linearly, bikes frequently cross lanes laterally. We monitor horizontal position changes:
1. Track the horizontal center of the bounding box ($X_{\text{center}}$):
   $$X_{\text{center}} = \frac{x_{\text{min}} + x_{\text{max}}}{2}$$
2. Calculate the horizontal displacement vector per frame:
   $$\Delta X = |X_{\text{center}, t} - X_{\text{center}, t-1}|$$
3. If $\Delta X > 0.08$ (moving laterally at high speed) and distance is `close` or `medium`, classify the target as approaching a collision vector (`isApproaching = true`).

### Step 5: Flutter Safety Logic & Alarms (Dart)
1. Parse bike detections inside `safety_engine.dart`.
2. Apply crossing rules:
   *   **Rule 1:** Any bike classified as `very_close` or `close` with lateral movement triggers `AlertMode.warning` (DO NOT CROSS).
   *   **Rule 2:** Any approaching bike at `medium` distance triggers `AlertMode.caution` (Yellow display banner).
3. Connect output to `AlertService`:
   *   Voice alert announces: "Caution! Bike approaching."
   *   Generate a double-pulse haptic vibration sequence to immediately warn visually impaired pedestrians of fast-approaching two-wheelers.
