import '../models/detected_object.dart';
import 'alert_service.dart';

class SafetyEngine {
  // Configurable thresholds (can be updated from settings screen)
  double confidenceThreshold = 0.40;
  double veryCloseRatio = 0.48; // Bounding box occupies > 48% height
  double closeRatio = 0.28;     // Bounding box occupies > 28% height
  double mediumRatio = 0.12;    // Bounding box occupies > 12% height

  AlertMode evaluate(List<DetectedObject> detections) {
    // Filter out irrelevant categories and low-confidence boxes
    final activeVehicles = detections.where((obj) {
      final isVehicle = ['car', 'truck', 'bus', 'motorcycle', 'bicycle', 'vehicle', 'van'].contains(obj.label.toLowerCase());
      return isVehicle && obj.confidence >= confidenceThreshold;
    }).toList();

    if (activeVehicles.isEmpty) {
      return AlertMode.safe;
    }

    // Rule 1: Any vehicle VERY CLOSE is extreme danger
    final hasVeryClose = activeVehicles.any((v) => v.distance == DistanceCategory.veryClose);
    if (hasVeryClose) {
      return AlertMode.warning;
    }

    // Rule 2: Any CLOSE vehicle that is approaching is extremely dangerous
    final hasCloseApproaching = activeVehicles.any((v) => v.distance == DistanceCategory.close && v.isApproaching);
    if (hasCloseApproaching) {
      return AlertMode.warning;
    }

    // Rule 3: Multiple MEDIUM vehicles approaching represents high risk
    final approachingMediumCount = activeVehicles.where((v) => v.distance == DistanceCategory.medium && v.isApproaching).length;
    if (approachingMediumCount >= 2) {
      return AlertMode.warning;
    }

    // Rule 4: Single MEDIUM vehicle approaching calls for Caution
    if (approachingMediumCount == 1) {
      return AlertMode.caution;
    }

    // Rule 5: If there are vehicles but they are far away or moving away (receding)
    return AlertMode.safe;
  }
}
