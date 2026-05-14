import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'presentation/views/onboarding/onboarding_view.dart';
import 'firebase_options.dart';
import 'presentation/views/main_layout.dart';
import 'presentation/views/auth/auth_view.dart';
import 'data/services/auth_service.dart';
import 'theme/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("❌ Firebase Init Error: $e");
  }

  // 2. Load .env
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("❌ .env Load Error: $e");
  }

  runApp(const VocabApp());
}

class VocabApp extends StatelessWidget {
  const VocabApp({super.key});

  // 3. Helper to check if onboarding was seen
  Future<bool> _isFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    // Returns false if the key doesn't exist yet
    return prefs.getBool('seen_onboarding') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Vocab Story Generator',

// Inside your MaterialApp...
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.arcticWhite,

        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.navy,
          primary: AppColors.navy,
          secondary: AppColors.steelBlue,
          surface: AppColors.iceBlue,
          onPrimary: Colors.white, // Text color on Navy background
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          elevation: 0,
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.steelBlue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      home: StreamBuilder<User?>(
        stream: AuthService().authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator(color: Colors.black)),
            );
          }

          // If snapshot has user data, they are logged in!
          if (snapshot.hasData) {
            // NEW: Check if the user needs to see Onboarding
            return FutureBuilder<bool>(
              future: _isFirstTime(),
              builder: (context, onboardSnapshot) {
                if (onboardSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator(color: Colors.black)),
                  );
                }

                // Show onboarding if they haven't seen it, otherwise MainLayout
                if (onboardSnapshot.data == false) {
                  return const OnboardingView();
                } else {
                  return const MainLayout();
                }
              },
            );
          }

          // Otherwise, show the Login/Signup screen
          return const AuthView();
        },
      ),
    );
  }
}