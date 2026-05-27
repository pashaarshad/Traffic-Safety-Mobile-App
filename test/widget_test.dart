import 'package:flutter_test/flutter_test.dart';
import 'package:traffic_safety_app/models/detected_object.dart';
import 'package:traffic_safety_app/services/alert_service.dart';
import 'package:traffic_safety_app/services/safety_engine.dart';

void main() {
  group('SafetyEngine Decision Matrix Verification Suite', () {
    late SafetyEngine engine;

    setUp(() {
      engine = SafetyEngine();
    });

    test('Rule 1: Clear road should be SAFE TO CROSS', () {
      final verdict = engine.evaluate([]);
      expect(verdict, equals(AlertMode.safe));
    });

    test('Rule 2: Receding vehicles should be SAFE TO CROSS', () {
      final recedingCar = DetectedObject(
        id: 1,
        label: 'car',
        confidence: 0.90,
        xMin: 0.40,
        yMin: 0.40,
        xMax: 0.60,
        yMax: 0.60,
        distance: DistanceCategory.close,
        isApproaching: false, // receding
        estimatedDistanceMeters: 15.0,
      );

      final verdict = engine.evaluate([recedingCar]);
      expect(verdict, equals(AlertMode.safe));
    });

    test('Rule 3: Any VERY CLOSE vehicle is danger (DO NOT CROSS)', () {
      final veryCloseRecedingCar = DetectedObject(
        id: 1,
        label: 'car',
        confidence: 0.85,
        xMin: 0.20,
        yMin: 0.20,
        xMax: 0.80,
        yMax: 0.80,
        distance: DistanceCategory.veryClose,
        isApproaching: false, // receding but extremely close
        estimatedDistanceMeters: 3.0,
      );

      final verdict = engine.evaluate([veryCloseRecedingCar]);
      expect(verdict, equals(AlertMode.warning));
    });

    test('Rule 4: Any CLOSE approaching vehicle is danger (DO NOT CROSS)', () {
      final approachingCloseCar = DetectedObject(
        id: 2,
        label: 'car',
        confidence: 0.85,
        xMin: 0.30,
        yMin: 0.30,
        xMax: 0.70,
        yMax: 0.70,
        distance: DistanceCategory.close,
        isApproaching: true, // approaching and close
        estimatedDistanceMeters: 7.5,
      );

      final verdict = engine.evaluate([approachingCloseCar]);
      expect(verdict, equals(AlertMode.warning));
    });

    test('Rule 5: Single approaching MEDIUM vehicle is CAUTION', () {
      final approachingMediumCar = DetectedObject(
        id: 3,
        label: 'car',
        confidence: 0.80,
        xMin: 0.40,
        yMin: 0.40,
        xMax: 0.60,
        yMax: 0.55, // height ratio = 0.15 (medium)
        distance: DistanceCategory.medium,
        isApproaching: true,
        estimatedDistanceMeters: 20.0,
      );

      final verdict = engine.evaluate([approachingMediumCar]);
      expect(verdict, equals(AlertMode.caution));
    });

    test('Rule 6: Multiple approaching MEDIUM vehicles are warning (DO NOT CROSS)', () {
      final car1 = DetectedObject(
        id: 4,
        label: 'car',
        confidence: 0.80,
        xMin: 0.40,
        yMin: 0.40,
        xMax: 0.60,
        yMax: 0.55,
        distance: DistanceCategory.medium,
        isApproaching: true,
        estimatedDistanceMeters: 20.0,
      );

      final car2 = DetectedObject(
        id: 5,
        label: 'motorcycle',
        confidence: 0.75,
        xMin: 0.20,
        yMin: 0.40,
        xMax: 0.35,
        yMax: 0.56,
        distance: DistanceCategory.medium,
        isApproaching: true,
        estimatedDistanceMeters: 18.0,
      );

      final verdict = engine.evaluate([car1, car2]);
      expect(verdict, equals(AlertMode.warning));
    });
  });
}
