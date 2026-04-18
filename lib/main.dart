import 'package:flutter/material.dart';
import 'screens/screens.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'StudyMate AI',

      // ✅ Modern Theme (Material 3 safe)
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,

        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),

        // ✅ FIXED (new Flutter)
        cardTheme: const CardThemeData(
          elevation: 4,
        ),
      ),

      initialRoute: '/',

      routes: {
        '/': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/subjects': (context) => const SubjectsScreen(),
        '/tasks': (context) => const TasksScreen(),
        '/planner': (context) => const PlannerScreen(),
        '/pomodoro': (context) => const PomodoroScreen(),
        '/notes': (context) => const NotesScreen(),
        '/flashcards': (context) => const FlashcardsScreen(),
        '/ai': (context) => const AIChatScreen(),
        '/analytics': (context) => const AnalyticsScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}