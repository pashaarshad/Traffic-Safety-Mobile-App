import 'package:flutter/material.dart';
import '../services/alert_service.dart';

class SafetyBanner extends StatelessWidget {
  final AlertMode mode;

  const SafetyBanner({required this.mode, super.key});

  @override
  Widget build(BuildContext context) {
    Color glowColor;
    Color baseColor;
    String titleText;
    String subtitleText;
    IconData icon;
    bool showLoading = false;

    switch (mode) {
      case AlertMode.safe:
        baseColor = const Color(0xE610B981); // Emerald Green
        glowColor = const Color(0x3310B981);
        titleText = "SAFE TO CROSS";
        subtitleText = "No imminent traffic detected";
        icon = Icons.check_circle_outline;
        break;
      case AlertMode.warning:
        baseColor = const Color(0xE6EF4444); // Crimson/Ruby Red
        glowColor = const Color(0x33EF4444);
        titleText = "DO NOT CROSS";
        subtitleText = "Fast vehicle approaching!";
        icon = Icons.warning_amber_rounded;
        break;
      case AlertMode.caution:
        baseColor = const Color(0xE6F59E0B); // Amber Yellow
        glowColor = const Color(0x33F59E0B);
        titleText = "CAUTION REQUIRED";
        subtitleText = "Nearby slow vehicle detected";
        icon = Icons.info_outline_rounded;
        break;
      case AlertMode.scanning:
      default:
        baseColor = const Color(0xE63B82F6); // Soft Royal Blue
        glowColor = const Color(0x333B82F6);
        titleText = "SCANNING ROADWAY";
        subtitleText = "AI safety analyzer active...";
        icon = Icons.wifi_protected_setup_sharp;
        showLoading = true;
        break;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 24.0),
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(22.0),
        boxShadow: [
          BoxShadow(
            color: glowColor,
            blurRadius: 25,
            spreadRadius: 4,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          if (showLoading)
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            )
          else
            Icon(
              icon,
              color: Colors.white,
              size: 38,
            ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  titleText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitleText,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
