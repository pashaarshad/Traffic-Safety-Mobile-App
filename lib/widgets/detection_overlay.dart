import 'package:flutter/material.dart';
import '../models/detected_object.dart';

class DetectionOverlay extends StatelessWidget {
  final List<DetectedObject> detections;
  final Size previewSize;

  const DetectionOverlay({
    required this.detections,
    required this.previewSize,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _DetectionsPainter(
        detections: detections,
        previewSize: previewSize,
      ),
    );
  }
}

class _DetectionsPainter extends CustomPainter {
  final List<DetectedObject> detections;
  final Size previewSize;

  _DetectionsPainter({
    required this.detections,
    required this.previewSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var detection in detections) {
      // Calculate scaling coordinates based on real preview dimensions vs canvas size
      final double scaleX = size.width;
      final double scaleY = size.height;

      final double left = detection.xMin * scaleX;
      final double top = detection.yMin * scaleY;
      final double right = detection.xMax * scaleX;
      final double bottom = detection.yMax * scaleY;
      final double width = right - left;
      final double height = bottom - top;

      // Select high-fidelity colors based on threat level (distance + movement direction)
      Color boxColor;
      Color fillColor;
      switch (detection.distance) {
        case DistanceCategory.veryClose:
          boxColor = const Color(0xFFEF4444); // Crimson danger
          fillColor = const Color(0x22EF4444);
          break;
        case DistanceCategory.close:
          boxColor = const Color(0xFFF59E0B); // Amber caution
          fillColor = const Color(0x11F59E0B);
          break;
        case DistanceCategory.medium:
          boxColor = const Color(0xFF10B981); // Emerald green
          fillColor = const Color(0x0A10B981);
          break;
        case DistanceCategory.far:
        default:
          boxColor = const Color(0xFF3B82F6); // Royal blue far
          fillColor = const Color(0x063B82F6);
          break;
      }

      // Draw bounding box translucent background
      final fillPaint = Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, width, height),
          const Radius.circular(8.0),
        ),
        fillPaint,
      );

      // Draw bounding box outline
      final borderPaint = Paint()
        ..color = boxColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = detection.isApproaching ? 3.0 : 1.5;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, width, height),
          const Radius.circular(8.0),
        ),
        borderPaint,
      );

      // Draw vector approach indicators (glowing arrows towards screen bottom)
      if (detection.isApproaching) {
        final arrowPaint = Paint()
          ..color = boxColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

        final double centerX = left + (width / 2);
        
        // Draw vertical vector line
        canvas.drawLine(
          Offset(centerX, top - 25),
          Offset(centerX, top - 10),
          arrowPaint,
        );
        // Draw arrowhead pointing down towards screen center
        final arrowPath = Path()
          ..moveTo(centerX - 6, top - 16)
          ..lineTo(centerX, top - 10)
          ..lineTo(centerX + 6, top - 16);
        canvas.drawPath(arrowPath, arrowPaint);
      }

      // Draw high-contrast text metadata label header
      final textSpan = TextSpan(
        text: "${detection.label.toUpperCase()} (${(detection.confidence * 100).toStringAsFixed(0)}%) - ${detection.distance.name.toUpperCase()}",
        style: TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          backgroundColor: boxColor,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout(minWidth: 0, maxWidth: size.width);

      textPainter.paint(
        canvas,
        Offset(left + 2, (top - textPainter.height - 2).clamp(0.0, size.height)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DetectionsPainter oldDelegate) {
    return oldDelegate.detections != detections || oldDelegate.previewSize != previewSize;
  }
}
