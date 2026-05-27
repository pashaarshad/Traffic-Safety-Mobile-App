import 'package:flutter/material.dart';
import '../widgets/glass_card.dart';
import 'camera_screen.dart';
import 'info_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Premium sleek Slate-900 background
      body: Stack(
        children: [
          // Elegant ambient background overlay
          Positioned.fill(
            child: Image.asset(
              'assets/images/background_overlay.png',
              fit: BoxFit.cover,
            ),
          ),
          // Additional dark overlay to elevate content legibility
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.4),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: AnimatedBuilder(
                  animation: _animController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Application Header / Logo Card
                      GlassCard(
                        padding: const EdgeInsets.all(28.0),
                        child: Column(
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0x3310B981),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  )
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(60.0),
                                child: Image.asset(
                                  'assets/images/app_logo.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              "GUARD CROSS",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 3.0,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              "AI-Powered Crossing Assistant",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 13,
                                letterSpacing: 0.8,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Navigation Control Deck
                      _buildNavigationButton(
                        context,
                        title: "LAUNCH PEDESTRIAN HUD",
                        subtitle: "Start real-time safety analyzer",
                        icon: Icons.camera_front_outlined,
                        color: const Color(0xFF10B981), // Emerald green
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CameraScreen()),
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildNavigationButton(
                        context,
                        title: "DEVELOPER LOGBOOK",
                        subtitle: "Flowcharts, architectures & specs",
                        icon: Icons.assignment_outlined,
                        color: const Color(0xFF3B82F6), // Royal Blue
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const InfoScreen()),
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildNavigationButton(
                        context,
                        title: "CALIBRATION DECK",
                        subtitle: "Fine-tune AI & system thresholds",
                        icon: Icons.tune_rounded,
                        color: const Color(0xFFF59E0B), // Golden yellow
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SettingsScreen()),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Elegant Academic Subtitle
                      Opacity(
                        opacity: 0.6,
                        child: Text(
                          "DEPARTMENT OF COMPUTER SCIENCE & ENGINEERING\nFINAL YEAR CAPSTONE PROTOTYPE",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.12),
            blurRadius: 15,
            spreadRadius: 1,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20.0),
          child: GlassCard(
            padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 22.0),
            borderColor: color.withOpacity(0.25),
            fillColor: Colors.black.withOpacity(0.3),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14.0),
                    border: Border.all(
                      color: color.withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withOpacity(0.4),
                  size: 16,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
