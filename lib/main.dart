import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'screens/screens.dart';
import 'firebase_options.dart';
import 'screens/book_notes_screen.dart';
import 'package:pdfrx/pdfrx.dart'; // Add this

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // If a user is already signed in, start at the dashboard; otherwise start at splash
  final initialRoute = FirebaseAuth.instance.currentUser == null ? '/' : '/dashboard';
  await pdfrxFlutterInitialize(); // Initialize the PDF library
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: MyApp(initialRoute: initialRoute),
    ),
  );
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'StudyMate AI',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,

      initialRoute: initialRoute,

      routes: {
        '/': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/subjects': (context) => const SubjectsScreen(),
        '/tasks': (context) => const TasksScreen(),
        '/planner': (context) => const PlannerScreen(),
        '/pomodoro': (context) => const TimerScreen(),
        '/notes': (context) => const NotesScreen(),
        '/flashcards': (context) => const FlashcardsScreen(),
        '/ai': (context) => const AIChatScreen(),
        '/ai-quiz': (context) => const AiQuizScreen(),
        '/analytics': (context) => const AnalyticsScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/notifications': (context) => const NotificationScreen(),
        '/exam': (context) => const ExamsScreen(),
        '/ai_quiz': (context) => const AiQuizScreen(),
        '/book-notes': (context) => const BookNotesScreen(),
      },
    );
  }
}