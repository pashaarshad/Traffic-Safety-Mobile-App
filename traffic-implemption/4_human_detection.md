# 4. Pedestrian & Human Detection Implementation Plan

This document outlines the specific implementation plan for detecting, tracking, and calibrating safety heuristics for pedestrians (`person` - COCO Class ID 0) using YOLOv8 and Flutter.

---

## Technical Specifications
*   **Target Category:** Class ID 0 (`person`) inside COCO Labels.
*   **Alternative Training Datasets:** CrowdHuman, WiderPerson, or LVIS.
*   **Average Physical Dimensions:** Width ($W_{\text{human}}$) $\approx 0.55$ meters, Height ($H_{\text{human}}$) $\approx 1.75$ meters.
*   **Functional Purpose:**
    1.  **Collision Prevention:** Prevent pedestrian-to-pedestrian collisions at crosswalks.
    2.  **Social Proof Assistance:** Detect other pedestrians crossing in the same direction, providing auditory cues to help visually impaired users follow the crowd safely.

---

## Step-by-Step Implementation

### Step 1: Python Model Training & Dataset Preparation
1. Utilize the CrowdHuman dataset to fine-tune YOLOv8 on heavily occluded pedestrian scenarios (common at busy city crossings).
2. Configure Python training script:
   ```python
   from ultralytics import YOLO
   model = YOLO("yolov8n.pt")
   model.train(
       data="pedestrian_dataset.yaml",
       epochs=50,
       imgsz=640,
       batch=16,
       device=0
   )
   ```
3. Optimize the detection accuracy under low-light conditions (dusk/night scenarios).
4. Export the weights to an INT8 quantized TFLite model.

### Step 2: Native Android Detector Integration
1. Place the optimized model `yolov8n_pedestrian.tflite` inside `android/app/src/main/assets/`.
2. Map Class ID `0` inside `YoloDetector.kt` to the label `"person"`.

### Step 3: Pedestrian Distance Calibration Heuristics (Kotlin)
We estimate distance using the aspect ratio of a standing human ($R_h = y_{\text{max}} - y_{\text{min}}$):

$$Distance_{\text{meters}} = \frac{k_{\text{human}}}{R_h}$$

Where $k_{\text{human}} \approx 8.0$.
1. Configure proximity thresholds inside `VehicleTracker.kt`:
   ```kotlin
   val heightRatio = boundingBox.height()
   val estimatedDistance = 8.0 / heightRatio
   val distanceCategory = when {
       heightRatio > 0.55 -> "very_close"  // Distance < 5 meters
       heightRatio > 0.30 -> "close"       // Distance 5 - 10 meters
       heightRatio > 0.15 -> "medium"      // Distance 10 - 20 meters
       else -> "far"
   }
   ```

### Step 4: Tracking & Occlusion Compensation (Kotlin)
Pedestrians are frequently occluded behind vehicles or other road signs.
1. Implement occlusion monitoring in `VehicleTracker.kt` by calculating box intersections:
   $$\text{Overlap}_{\text{ratio}} = \frac{\text{Area}(Box_{\text{person}} \cap Box_{\text{vehicle}})}{\text{Area}(Box_{\text{person}})}$$
2. If $\text{Overlap}_{\text{ratio}} > 0.65$, preserve the pedestrian's tracking state and predict their exit position using a linear movement velocity vector:
   $$X_{\text{pred}} = X_{\text{center}} + V_x \Delta t$$
   $$Y_{\text{pred}} = Y_{\text{center}} + V_y \Delta t$$

### Step 5: Flutter Crowd Guidance System (Dart)
1. Parse pedestrian detections inside `safety_engine.dart`.
2. Apply the **Crowd-Following Guide** logic:
   *   If other pedestrians (`person`) are detected at `medium` or `far` distances, moving away from the phone camera, set a guidance state.
   *   Auditory feedback: Speak "Pedestrians crossing. Crosswalk active."
   *   Haptic feedback: Generate a gentle haptic heartbeat pulse pattern (one soft pulse every 1.5 seconds) to give visually impaired users confidence that they are crossing along with a crowd.
