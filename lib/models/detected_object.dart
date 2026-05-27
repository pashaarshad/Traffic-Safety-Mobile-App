import 'dart:math';

enum DistanceCategory { veryClose, close, medium, far }

class DetectedObject {
  final int id;
  final String label;
  final double confidence;
  
  // Normalized bounding box coordinates [0.0, 1.0]
  final double xMin;
  final double yMin;
  final double xMax;
  final double yMax;

  // Analysis properties
  final DistanceCategory distance;
  final bool isApproaching;
  final double estimatedDistanceMeters;

  DetectedObject({
    required this.id,
    required this.label,
    required this.confidence,
    required this.xMin,
    required this.yMin,
    required this.xMax,
    required this.yMax,
    required this.distance,
    required this.isApproaching,
    required this.estimatedDistanceMeters,
  });

  // Calculate box height relative to frame height (normalized)
  double get heightRatio => yMax - yMin;

  // Calculate box width relative to frame width (normalized)
  double get widthRatio => xMax - xMin;

  // Convert to JSON / Map for platform channel compatibility
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'confidence': confidence,
      'xMin': xMin,
      'yMin': yMin,
      'xMax': xMax,
      'yMax': yMax,
      'distance': distance.name,
      'isApproaching': isApproaching,
      'estimatedDistanceMeters': estimatedDistanceMeters,
    };
  }

  factory DetectedObject.fromMap(Map<dynamic, dynamic> map) {
    return DetectedObject(
      id: map['id'] as int? ?? 0,
      label: map['label'] as String? ?? 'unknown',
      confidence: (map['confidence'] as num? ?? 0.0).toDouble(),
      xMin: (map['xMin'] as num? ?? 0.0).toDouble(),
      yMin: (map['yMin'] as num? ?? 0.0).toDouble(),
      xMax: (map['xMax'] as num? ?? 1.0).toDouble(),
      yMax: (map['yMax'] as num? ?? 1.0).toDouble(),
      distance: _parseDistance(map['distance'] as String?),
      isApproaching: map['isApproaching'] as bool? ?? false,
      estimatedDistanceMeters: (map['estimatedDistanceMeters'] as num? ?? 100.0).toDouble(),
    );
  }

  static DistanceCategory _parseDistance(String? value) {
    switch (value?.toLowerCase()) {
      case 'very_close':
      case 'veryclose':
        return DistanceCategory.veryClose;
      case 'close':
        return DistanceCategory.close;
      case 'medium':
        return DistanceCategory.medium;
      case 'far':
      default:
        return DistanceCategory.far;
    }
  }

  // Create a copy with optional updates
  DetectedObject copyWith({
    int? id,
    String? label,
    double? confidence,
    double? xMin,
    double? yMin,
    double? xMax,
    double? yMax,
    DistanceCategory? distance,
    bool? isApproaching,
    double? estimatedDistanceMeters,
  }) {
    return DetectedObject(
      id: id ?? this.id,
      label: label ?? this.label,
      confidence: confidence ?? this.confidence,
      xMin: xMin ?? this.xMin,
      yMin: yMin ?? this.yMin,
      xMax: xMax ?? this.xMax,
      yMax: yMax ?? this.yMax,
      distance: distance ?? this.distance,
      isApproaching: isApproaching ?? this.isApproaching,
      estimatedDistanceMeters: estimatedDistanceMeters ?? this.estimatedDistanceMeters,
    );
  }
}
