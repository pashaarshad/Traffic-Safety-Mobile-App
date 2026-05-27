import 'package:flutter/material.dart';
import '../widgets/glass_card.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          title: const Text(
            "DEVELOPER LOGBOOK",
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
          bottom: TabBar(
            indicatorColor: const Color(0xFF10B981),
            labelColor: const Color(0xFF10B981),
            unselectedLabelColor: Colors.white60,
            tabs: const [
              Tab(icon: Icon(Icons.hub_outlined), text: "Architecture"),
              Tab(icon: Icon(Icons.alt_route_outlined), text: "Flowchart"),
              Tab(icon: Icon(Icons.rule_folder_outlined), text: "Safety Rules"),
            ],
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
              child: TabBarView(
                children: [
                  _buildArchitectureTab(),
                  _buildFlowchartTab(),
                  _buildSafetyRulesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArchitectureTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "System Architecture Overview",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFlowStep("1. FRAME CAPTURE", "Smartphone rear camera streams high-fidelity YUV frames continuously via Camera2 API / Flutter Camera."),
                _buildFlowConnector(),
                _buildFlowStep("2. OPENCV PREPROCESSING", "Native Kotlin pipeline normalizes aspect ratios (640x640), converts BGR to RGB, applies Gaussian filter to eliminate frame noise, and scales pixel bytes."),
                _buildFlowConnector(),
                _buildFlowStep("3. YOLO v8 INFERENCE", "Quantized INT8 YOLOv8 model runs local on-device machine learning inference on the Tensor CPU/NPU, outputting classified vehicle categories and confidence."),
                _buildFlowConnector(),
                _buildFlowStep("4. DECISION ENGINE", "Evaluates bounding box height changes over time (approach vectors) and relative distance heuristics. Decides safe/unsafe crossing state."),
                _buildFlowConnector(),
                _buildFlowStep("5. MULTI-MODAL ALARM", "Audio warning cues spoken aloud via TTS. Vibration alerts trigger haptic patterns. Dynamic high-contrast banner overlays on screen."),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlowchartTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Pedestrian Crossing Algorithm Flowchart",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              children: [
                _buildFlowchartNode("APP ACTIVE / HUDS ACTIVE", Colors.blue, Colors.white),
                _buildDownArrow(),
                _buildFlowchartNode("GRAB LIVE CAMERA FRAME", Colors.grey[800]!, Colors.white),
                _buildDownArrow(),
                _buildFlowchartNode("RUN YOLO v8 VEHICLE DETECTION", Colors.amber[800]!, Colors.white),
                _buildDownArrow(),
                _buildFlowchartNode("ARE VEHICLES PRESENT?", Colors.purple[800]!, Colors.white),
                _buildDownArrow(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const Icon(Icons.arrow_downward, color: Colors.green),
                          const SizedBox(height: 6),
                          const Text("NO", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          _buildFlowchartNode("SAFE TO CROSS ✅", Colors.green[800]!, Colors.white),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        children: [
                          const Icon(Icons.arrow_downward, color: Colors.red),
                          const SizedBox(height: 6),
                          const Text("YES", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          _buildFlowchartNode("EVALUATE MOTION VECTOR", Colors.orange[800]!, Colors.white),
                        ],
                      ),
                    ),
                  ],
                ),
                _buildDownArrow(),
                _buildFlowchartNode("VEHICLE VERY CLOSE OR APPROACHING?", Colors.purple[800]!, Colors.white),
                _buildDownArrow(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const Icon(Icons.arrow_downward, color: Colors.green),
                          const SizedBox(height: 6),
                          const Text("NO (FAR / RECEDING)", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          _buildFlowchartNode("SAFE TO CROSS ✅", Colors.green[800]!, Colors.white),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        children: [
                          const Icon(Icons.arrow_downward, color: Colors.red),
                          const SizedBox(height: 6),
                          const Text("YES (APPROACHING)", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          _buildFlowchartNode("DO NOT CROSS! ❌", Colors.red[800]!, Colors.white),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyRulesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Verdict Matrix Logic Guidelines",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildVerdictCard(
                  title: "CRITICAL ALERT (DO NOT CROSS)",
                  color: const Color(0xFFEF4444),
                  rules: [
                    "• Bounding box ratio height exceeds 48% (extremely close proximity).",
                    "• Bounding box height exceeds 28% (close proximity) AND vehicle width increases over consecutive frames (approaching).",
                    "• More than two vehicles detected at medium proximity (12%-28%) and approaching."
                  ],
                ),
                const SizedBox(height: 20),
                _buildVerdictCard(
                  title: "CAUTION ADVISORY (USE CAUTION)",
                  color: const Color(0xFFF59E0B),
                  rules: [
                    "• Exactly one approaching vehicle detected at medium proximity (12%-28% box height ratio).",
                    "• Soft double-pulse haptics to alert visually impaired users of proximity."
                  ],
                ),
                const SizedBox(height: 20),
                _buildVerdictCard(
                  title: "CLEAR ADVISORY (SAFE TO CROSS)",
                  color: const Color(0xFF10B981),
                  rules: [
                    "• Zero traffic detected in front of the camera.",
                    "• Vehicles detected but bounding boxes are shrinking over consecutive frames (receding / moving away)."
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlowStep(String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.circle, color: Color(0xFF10B981), size: 12),
        const SizedBox(width: 14),
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
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildFlowConnector() {
    return const Padding(
      padding: EdgeInsets.only(left: 5.0, top: 4.0, bottom: 4.0),
      child: Icon(Icons.more_vert, color: Colors.white24, size: 14),
    );
  }

  Widget _buildFlowchartNode(String label, Color color, Color textColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildDownArrow() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Icon(Icons.arrow_downward, color: Colors.white30, size: 20),
    );
  }

  Widget _buildVerdictCard({
    required String title,
    required Color color,
    required List<String> rules,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: color.withOpacity(0.35),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          ...rules.map((rule) => Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: Text(
              rule,
              style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          )),
        ],
      ),
    );
  }
}
