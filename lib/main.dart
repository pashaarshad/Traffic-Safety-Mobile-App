import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/detection_service.dart';
import 'services/alert_service.dart';
import 'services/safety_engine.dart';
import 'screens/home_screen.dart';

void main() {
  // Ensure Flutter engine integrations are initialized before launching Services
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<DetectionService>(
          create: (_) => DetectionService(),
          dispose: (_, service) => service.dispose(),
        ),
        Provider<AlertService>(
          create: (_) => AlertService(),
          dispose: (_, service) => service.stop(),
        ),
        Provider<SafetyEngine>(
          create: (_) => SafetyEngine(),
        ),
      ],
      child: MaterialApp(
        title: 'Guard Cross AI',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0F172A),
          colorScheme: ColorScheme.fromSeed(
            brightness: Brightness.dark,
            seedColor: const Color(0xFF10B981), // Emerald accent
            primary: const Color(0xFF10B981),
            secondary: const Color(0xFF3B82F6),
            surface: const Color(0x0CFFFFFF),
          ),
          fontFamily: 'Inter', // Sleek modern typography
          textTheme: const TextTheme(
            displayLarge: TextStyle(fontSize: 32.0, fontWeight: FontWeight.bold, color: Colors.white),
            bodyLarge: TextStyle(fontSize: 16.0, color: Colors.white70),
            bodyMedium: TextStyle(fontSize: 14.0, color: Colors.white60),
          ),
          switchTheme: SwitchThemeData(
            thumbColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return const Color(0xFF10B981);
              return Colors.grey;
            }),
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
