import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:task_master_2_0/models/task_model.dart';
import 'package:task_master_2_0/screens/login_screen.dart';
import 'package:task_master_2_0/services/auth_service.dart';
import 'package:task_master_2_0/services/task_service.dart';
import 'package:task_master_2_0/home_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  
  static MyAppState of(BuildContext context) => 
      context.findAncestorStateOfType<MyAppState>()!;
      
  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;
  
  void toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark 
          ? ThemeMode.light 
          : ThemeMode.dark;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    // Custom color scheme for light theme
    final lightColorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: const Color(0xFF6366F1),       // Indigo
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFEEF2FF), // Light indigo for containers
      onPrimaryContainer: const Color(0xFF4338CA),
      secondary: const Color(0xFFEC4899),     // Pink
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFFCE7F3),
      onSecondaryContainer: const Color(0xFFDB2777),
      tertiary: const Color(0xFF14B8A6),      // Teal
      onTertiary: Colors.white,
      tertiaryContainer: const Color(0xFFE6FFFA),
      onTertiaryContainer: const Color(0xFF0D9488),
      error: const Color(0xFFEF4444),
      onError: Colors.white,
      errorContainer: const Color(0xFFFEE2E2),
      onErrorContainer: const Color(0xFFDC2626),
      background: const Color(0xFFFAFAFA),
      onBackground: const Color(0xFF1F2937),
      surface: Colors.white,
      onSurface: const Color(0xFF1F2937),
      surfaceTint: const Color(0xFF6366F1).withOpacity(0.05),
      surfaceVariant: const Color(0xFFF3F4F6),
      onSurfaceVariant: const Color(0xFF4B5563),
      outline: const Color(0xFFD1D5DB),
    );
    
    // Custom color scheme for dark theme
    final darkColorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: const Color(0xFF818CF8),       // Lighter indigo for dark theme
      onPrimary: Colors.black,
      primaryContainer: const Color(0xFF312E81).withOpacity(0.7),
      onPrimaryContainer: const Color(0xFFC7D2FE),
      secondary: const Color(0xFFF472B6),     // Pink
      onSecondary: Colors.black,
      secondaryContainer: const Color(0xFF831843).withOpacity(0.7),
      onSecondaryContainer: const Color(0xFFFBCFE8),
      tertiary: const Color(0xFF2DD4BF),      // Teal
      onTertiary: Colors.black,
      tertiaryContainer: const Color(0xFF115E59).withOpacity(0.7),
      onTertiaryContainer: const Color(0xFFA7F3D0),
      error: const Color(0xFFF87171),
      onError: Colors.black,
      errorContainer: const Color(0xFF7F1D1D).withOpacity(0.7),
      onErrorContainer: const Color(0xFFFECACA),
      background: const Color(0xFF111827),
      onBackground: const Color(0xFFF9FAFB),
      surface: const Color(0xFF1F2937),
      onSurface: const Color(0xFFF9FAFB),
      surfaceTint: const Color(0xFF818CF8).withOpacity(0.1),
      surfaceVariant: const Color(0xFF374151),
      onSurfaceVariant: const Color(0xFFD1D5DB),
      outline: const Color(0xFF4B5563),
    );

    return MaterialApp(
      title: 'TaskMaster',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: lightColorScheme,
        useMaterial3: true,
        fontFamily: 'Poppins',
        appBarTheme: AppBarTheme(
          centerTitle: false,
          elevation: 0,
          backgroundColor: lightColorScheme.background,
          foregroundColor: lightColorScheme.onBackground,
          titleTextStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        cardTheme: CardTheme(
          elevation: 0,
          color: lightColorScheme.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: lightColorScheme.outline.withOpacity(0.3), width: 1),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: lightColorScheme.surfaceVariant.withOpacity(0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: lightColorScheme.primary, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            foregroundColor: lightColorScheme.onPrimary,
            backgroundColor: lightColorScheme.primary,
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: darkColorScheme,
        useMaterial3: true,
        fontFamily: 'Poppins',
        appBarTheme: AppBarTheme(
          centerTitle: false,
          elevation: 0,
          backgroundColor: darkColorScheme.background,
          foregroundColor: darkColorScheme.onBackground,
          titleTextStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        cardTheme: CardTheme(
          elevation: 0,
          color: darkColorScheme.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: darkColorScheme.outline.withOpacity(0.2), width: 1),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: darkColorScheme.surfaceVariant.withOpacity(0.3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: darkColorScheme.primary, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            foregroundColor: darkColorScheme.onPrimary,
            backgroundColor: darkColorScheme.primary,
          ),
        ),
      ),
      themeMode: _themeMode,
      home: const AuthCheckScreen(),
    );
  }
}

class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final isLoggedIn = await _authService.isLoggedIn();
    setState(() {
      _isLoggedIn = isLoggedIn;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_isLoggedIn) {
      return const HomeScreen();
    }

    return const LoginScreen();
  }
}
