# 5. Heavy Vehicle (Bus & Truck) Detection Implementation Plan

This document outlines the specific implementation plan for detecting, tracking, and calibrating safety heuristics for heavy transport vehicles (`bus` - COCO Class ID 5, `truck` - COCO Class ID 7) using YOLOv8 and Flutter.

---

## Technical Specifications
*   **Target Categories:** Class ID 5 (`bus`) and Class ID 7 (`truck`) inside COCO Labels.
*   **Alternative Training Datasets:** UA-DETRAC, Berkeley DeepDrive (BDD100K), or custom highway vehicle datasets.
*   **Average Physical Dimensions:**
    *   **Bus:** Width ($W_{\text{bus}}$) $\approx 2.5$ meters, Height ($H_{\text{bus}}$) $\approx 3.0$ meters.
    *   **Truck:** Width ($W_{\text{truck}}$) $\approx 2.6$ meters, Height ($H_{\text{truck}}$) $\approx 3.5$ meters.
*   **Core Heuristics Challenge:**
    *   **Scale Error:** Heavy vehicles have a massive visual footprint. A bus at 18 meters occupies the same screen percentage ($R_h$) as a passenger car at 8 meters. If we use the same distance heuristics as cars, the system will trigger false warnings for far-away trucks, locking the pedestrian in place indefinitely.
    *   **Momentum/Stopping Distance:** Heavy vehicles require double the stopping distance of passenger cars. Thus, safety zones must be extended.

---

## Step-by-Step Implementation

### Step 1: Python Model Training
1. Train/fine-tune the YOLOv8 model using custom weights that emphasize large, multi-axle vehicle bounding boxes.
2. Compile and validation-test:
   ```python
   from ultralytics import YOLO
   model = YOLO("yolov8n.pt")
   model.train(
       data="heavy_vehicle_dataset.yaml",
       epochs=40,
       imgsz=640,
       batch=16,
       device=0
   )
   ```
3. Export the model to INT8 quantized TFLite (`yolov8n_heavy.tflite`).

### Step 2: Native Android Detector Setup
1. Copy the model file to the Android assets directory.
2. Add target classes `5` and `7` to the parsing loop in `YoloDetector.kt` and label them as `"bus"` and `"truck"`.

### Step 3: Calibrated Distance Estimation Heuristics (Kotlin)
Because of the massive profile height, we scale the distance calculations using a larger scaling factor ($k_{\text{heavy}}$):

$$Distance_{\text{meters}} = \frac{k_{\text{heavy}}}{R_h}$$

Where $k_{\text{heavy}} \approx 14.5$ for buses and trucks.
1. Add custom scaling inside `VehicleTracker.kt`:
   ```kotlin
   val heightRatio = boundingBox.height()
   val estimatedDistance = 14.5 / heightRatio
   val distanceCategory = when {
       heightRatio > 0.50 -> "very_close"  // Distance < 15 meters
       heightRatio > 0.25 -> "close"       // Distance 15 - 30 meters
       heightRatio > 0.10 -> "medium"      // Distance 30 - 60 meters
       else -> "far"
   }
   ```

### Step 4: Stopping Distance & Safety Zone Extensions (Kotlin)
1. Calculate velocity vectors by monitoring the frame-by-frame change in distance:
   $$Velocity = \frac{Distance_{t-1} - Distance_t}{\Delta t}$$
2. Heavy vehicles have a large stopping distance. If estimated velocity exceeds $8.3$ m/s ($30$ km/h), the safety zone is extended:
   *   Re-classify a `medium` distance approaching bus/truck as `close`.
   *   This triggers the warning early, compensating for the heavy vehicle's momentum.

### Step 5: Flutter Safety Engine Alerts (Dart)
1. In `safety_engine.dart`, process the `"bus"` and `"truck"` labels.
2. Apply crossing rules:
   *   **Rule 1:** Any heavy vehicle classified as `very_close` or `close` and approaching triggers `AlertMode.warning` (DO NOT CROSS).
   *   **Rule 2:** Any heavy vehicle classified as `medium` and approaching triggers `AlertMode.warning` if its calculated velocity is high.
3. Audio/Haptic Alerts:
   *   TTS announces: "Stop! Heavy vehicle approaching."
   *   Vibration triggers the urgent danger haptic pattern.
