import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/detection_service.dart';
import '../services/alert_service.dart';
import '../services/safety_engine.dart';
import '../widgets/glass_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final detectionService = Provider.of<DetectionService>(context);
    final alertService = Provider.of<AlertService>(context);
    final safetyEngine = Provider.of<SafetyEngine>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text(
          "CALIBRATION HUB",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/background_overlay.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.55),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(24.0),
              children: [
                // SECTION: Mode Selector (Sim vs Live Camera)
                _buildSectionHeader("SYSTEM OPERATIONS MODE"),
                const SizedBox(height: 12),
                GlassCard(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Live Feed Source",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Use live camera or sim scenarios",
                                style: TextStyle(color: Colors.white60, fontSize: 12),
                              )
                            ],
                          ),
                          Switch(
                            value: detectionService.mode == DetectionMode.camera,
                            activeColor: const Color(0xFF10B981),
                            activeTrackColor: const Color(0x3310B981),
                            inactiveThumbColor: const Color(0xFF3B82F6),
                            inactiveTrackColor: const Color(0x333B82F6),
                            onChanged: (isCamera) {
                              detectionService.setMode(
                                isCamera ? DetectionMode.camera : DetectionMode.simulation
                              );
                            },
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white12, height: 24),
                      Text(
                        detectionService.mode == DetectionMode.camera
                            ? "ACTIVE: Native Android Camera stream & TFLite detection"
                            : "ACTIVE: Dynamic Presentation Simulation Sandbox",
                        style: TextStyle(
                          color: detectionService.mode == DetectionMode.camera
                              ? const Color(0xFF10B981)
                              : const Color(0xFF3B82F6),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // SECTION: Simulation Scenarios (if in Sim Mode)
                if (detectionService.mode == DetectionMode.simulation) ...[
                  _buildSectionHeader("SANDBOX SIMULATION FEED"),
                  const SizedBox(height: 12),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Select Road Crossing Scenario",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildScenarioRadioTile(
                          context: context,
                          title: "Scenario A: Busy Urban Street",
                          subtitle: "Fast vehicles approaching (Danger alert)",
                          value: 0,
                          icon: Icons.warning_amber_rounded,
                          color: const Color(0xFFEF4444),
                        ),
                        const SizedBox(height: 8),
                        _buildScenarioRadioTile(
                          context: context,
                          title: "Scenario B: Receding Traffic",
                          subtitle: "Vehicles moving away (Safe alert)",
                          value: 1,
                          icon: Icons.check_circle_outline,
                          color: const Color(0xFF10B981),
                        ),
                        const SizedBox(height: 8),
                        _buildScenarioRadioTile(
                          context: context,
                          title: "Scenario C: Quiet Residential Lane",
                          subtitle: "Clear road with zero vehicles (Safe alert)",
                          value: 2,
                          icon: Icons.thumb_up_alt_outlined,
                          color: const Color(0xFF3B82F6),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // SECTION: AI Calibration Sliders
                _buildSectionHeader("AI & SAFETY CALIBRATION"),
                const SizedBox(height: 12),
                GlassCard(
                  child: Column(
                    children: [
                      _buildSliderTile(
                        title: "YOLO v8 Confidence Floor",
                        subtitle: "Min confidence for target detection",
                        value: safetyEngine.confidenceThreshold,
                        min: 0.25,
                        max: 0.85,
                        divisions: 12,
                        activeColor: const Color(0xFFF59E0B),
                        onChanged: (val) {
                          setState(() {
                            safetyEngine.confidenceThreshold = val;
                          });
                        },
                      ),
                      const Divider(color: Colors.white12, height: 24),
                      _buildSliderTile(
                        title: "Critical Range Threshold (Very Close)",
                        subtitle: "Target occupying % height",
                        value: safetyEngine.veryCloseRatio,
                        min: 0.35,
                        max: 0.65,
                        divisions: 6,
                        activeColor: const Color(0xFFEF4444),
                        onChanged: (val) {
                          setState(() {
                            safetyEngine.veryCloseRatio = val;
                          });
                        },
                      ),
                      const Divider(color: Colors.white12, height: 24),
                      _buildSliderTile(
                        title: "Proximity Warning Threshold (Close)",
                        subtitle: "Target occupying % height",
                        value: safetyEngine.closeRatio,
                        min: 0.18,
                        max: 0.34,
                        divisions: 8,
                        activeColor: const Color(0xFFF59E0B),
                        onChanged: (val) {
                          setState(() {
                            safetyEngine.closeRatio = val;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // SECTION: Audio & Voice Volume
                _buildSectionHeader("VOICE GUIDANCE & AUDIO"),
                const SizedBox(height: 12),
                GlassCard(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Announcements Mute Toggle",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Switch(
                            value: alertService.isMuted,
                            activeColor: const Color(0xFFEF4444),
                            onChanged: (mute) {
                              setState(() {
                                alertService.setMute(mute);
                              });
                            },
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white12, height: 24),
                      _buildSliderTile(
                        title: "Text-To-Speech Volume",
                        subtitle: "Volume levels of vocal alerts",
                        value: alertService.volume,
                        min: 0.0,
                        max: 1.0,
                        divisions: 10,
                        activeColor: const Color(0xFF3B82F6),
                        onChanged: (val) {
                          setState(() {
                            alertService.setVolume(val);
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildScenarioRadioTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required int value,
    required IconData icon,
    required Color color,
  }) {
    final detectionService = Provider.of<DetectionService>(context);
    final bool isSelected = detectionService.simulationScenario == value;
    
    return InkWell(
      onTap: () {
        detectionService.setScenario(value);
        setState(() {});
      },
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.08) : Colors.black.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.15),
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? color : Colors.white38, size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? color : Colors.white24,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderTile({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required Color activeColor,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                  ),
                ],
              ),
            ),
            Text(
              value.toStringAsFixed(2),
              style: TextStyle(
                color: activeColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            )
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          activeColor: activeColor,
          inactiveColor: Colors.white12,
          onChanged: onChanged,
        )
      ],
    );
  }
}
