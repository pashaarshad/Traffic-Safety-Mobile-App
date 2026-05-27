package com.trafficsafety.traffic_safety_app

import android.graphics.Bitmap
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "traffic_safety/detection"
    private lateinit var detector: YoloDetector
    private val tracker = VehicleTracker()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        detector = YoloDetector(this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "detectObjects") {
                try {
                    val imageBytes = call.argument<ByteArray>("imageBytes")
                    val width = call.argument<Int>("width") ?: 640
                    val height = call.argument<Int>("height") ?: 480

                    if (imageBytes == null) {
                        result.error("INVALID_ARGUMENT", "Bytes array is null", null)
                        return@setMethodCallHandler
                    }

                    // 1. OpenCV Preprocessing
                    val preprocessedBitmap = FrameProcessor.preprocessBitmap(imageBytes, width, height)

                    // 2. YOLOv8 TFLite Inference
                    val rawDetections = detector.runInference(preprocessedBitmap)

                    // 3. Multi-frame correlation & motion tracking
                    val trackedResults = tracker.updateAndTrack(rawDetections)

                    val response = mapOf(
                        "status" to "SUCCESS",
                        "detections" to trackedResults
                    )

                    result.success(response)

                } catch (e: Exception) {
                    result.error("INFERENCE_ERROR", e.localizedMessage, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
