import 'package:flutter/material.dart';
import 'package:nutriplan/screens/auth/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    // .env file not found, will use environment variables or defaults
    print('Warning: .env file not found. Using environment variables or defaults.');
  }
  
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? const String.fromEnvironment('SUPABASE_URL', defaultValue: ''),
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: ''),
  );
  runApp(const NutriPlan());
}

class NutriPlan extends StatelessWidget {
  const NutriPlan({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutriPlan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50), // Green theme for health/nutrition
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Geist',
        // Responsive text themes for iPhone 11
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),  
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          titleSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(fontSize: 16),
          bodyMedium: TextStyle(fontSize: 14),
          bodySmall: TextStyle(fontSize: 12),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
      },
    );
  }
} 