package com.trafficsafety.traffic_safety_app

data class NativeTrackedVehicle(
    val id: Int,
    val label: String,
    var xMin: Double,
    var yMin: Double,
    var xMax: Double,
    var yMax: Double,
    var consecutiveApproachingFrames: Int = 0,
    var previousArea: Double = 0.0
)

class VehicleTracker {
    private val trackedVehicles = mutableListOf<NativeTrackedVehicle>()
    private var nextId = 1

    fun updateAndTrack(rawDetections: List<YoloDetector.NativeDetection>): List<Map<String, Any>> {
        val updatedDetections = mutableListOf<Map<String, Any>>()
        
        for (det in rawDetections) {
            val width = det.xMax - det.xMin
            val height = det.yMax - det.yMin
            val area = width * height

            // IoU Matching against existing tracked objects
            var matchedVehicle = trackedVehicles.firstOrNull { it.label == det.label && calculateIoU(it, det) > 0.35 }
            
            if (matchedVehicle == null) {
                // Register a new vehicle
                matchedVehicle = NativeTrackedVehicle(
                    id = nextId++,
                    label = det.label,
                    xMin = det.xMin,
                    yMin = det.yMin,
                    xMax = det.xMax,
                    yMax = det.yMax,
                    previousArea = area
                )
                trackedVehicles.add(matchedVehicle)
            } else {
                // Update coordinates
                matchedVehicle.xMin = det.xMin
                matchedVehicle.yMin = det.yMin
                matchedVehicle.xMax = det.xMax
                matchedVehicle.yMax = det.yMax
            }

            // Calculate approach vectors: Growing area signifies approaching traffic
            val isApproaching = area > matchedVehicle.previousArea * 1.04
            if (isApproaching) {
                matchedVehicle.consecutiveApproachingFrames++
            } else if (area < matchedVehicle.previousArea * 0.96) {
                matchedVehicle.consecutiveApproachingFrames = 0
            }
            matchedVehicle.previousArea = area

            // Map proximity based on bounding box height relative ratios
            val distanceCategory = when {
                height > 0.48 -> "very_close"
                height > 0.28 -> "close"
                height > 0.12 -> "medium"
                else -> "far"
            }

            updatedDetections.add(mapOf(
                "id" to matchedVehicle.id,
                "label" to matchedVehicle.label,
                "confidence" to det.confidence,
                "xMin" to det.xMin,
                "yMin" to det.yMin,
                "xMax" to det.xMax,
                "yMax" to det.yMax,
                "distance" to distanceCategory,
                "isApproaching" to (matchedVehicle.consecutiveApproachingFrames >= 2),
                "estimatedDistanceMeters" to (25.0 * (1.0 - height)).coerceAtLeast(2.0)
            ))
        }

        // Garbage collection: keep tracked vehicle pool size minimal to avoid memory leaks
        if (trackedVehicles.size > 20) {
            trackedVehicles.removeAt(0)
        }

        return updatedDetections
    }

    private fun calculateIoU(tracked: NativeTrackedVehicle, current: YoloDetector.NativeDetection): Double {
        val interXMin = maxOf(tracked.xMin, current.xMin)
        val interYMin = maxOf(tracked.yMin, current.yMin)
        val interXMax = minOf(tracked.xMax, current.xMax)
        val interYMax = minOf(tracked.yMax, current.yMax)

        if (interXMax <= interXMin || interYMax <= interYMin) return 0.0

        val interArea = (interXMax - interXMin) * (interYMax - interYMin)
        val trackedArea = (tracked.xMax - tracked.xMin) * (tracked.yMax - tracked.yMin)
        val currentArea = (current.xMax - current.xMin) * (current.yMax - current.yMin)

        return interArea / (trackedArea + currentArea - interArea)
    }
}
