import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:simpleattendancechecker/constants/app_sizing.dart';
import 'package:simpleattendancechecker/constants/color_palatte.dart';
import 'package:simpleattendancechecker/firebase_options.dart';
import 'package:simpleattendancechecker/screen/home/pages/splash_logo.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ── 📴 Offline persistence (para gumana kahit walang internet) ───────────
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // ── 🔐 Anonymous auth (para pumasa sa security rules natin) ───────────
  if (FirebaseAuth.instance.currentUser == null) {
    await FirebaseAuth.instance.signInAnonymously();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'K2D',

        // ── ColorScheme ───────────────────────────
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colorpalatte.accentcolor,
          primary: Colorpalatte.secondary,
          surface: Colorpalatte.maincolor,
        ),

        // ── Scaffold background color ───────────────────────────
        scaffoldBackgroundColor: Colorpalatte.maincolor,

        // ── Text Selection Theme ───────────────────────────
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Colorpalatte.secondary,
          selectionColor: Colorpalatte.secondary.withValues(alpha: 0.3),
          selectionHandleColor: Colorpalatte.secondary,
        ),

        // ── ChoiceChip Theme ───────────────────────────
        chipTheme: ChipThemeData(
          checkmarkColor: Colorpalatte.maincolor,
          selectedColor: Colorpalatte.secondary,
          backgroundColor: Colorpalatte.containercolor,
          labelStyle: TextStyle(fontFamily: 'K2D', fontWeight: FontWeight.w700),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
      ),
      title: 'Attendance Checker',
      debugShowCheckedModeBanner: false,
      home: SplashLogo(),
    );
  }
}
