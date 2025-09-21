// ignore_for_file: deprecated_member_use

import 'package:accessijobs/modules/auth/choose_login.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'navigator.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

// Dashboards
import 'modules/dashboard/jobseeker_dashboard.dart';
import 'modules/dashboard/employer_dashboard.dart';
import 'modules/dashboard/admin_dashboard.dart';
import 'modules/dashboard/jobseeker_functions/job_listing.dart';
import 'modules/dashboard/shared_functions/interactive_map.dart';
import 'modules/auth/signup_page.dart';
import 'modules/auth/employer_login_page.dart';
import 'modules/auth/jobseeker_login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ Enable Firestore persistence BEFORE using Firestore
  try {
    await FirebaseFirestore.instance.enablePersistence();
    print("✅ Firestore offline persistence enabled");
  } catch (e) {
    print("⚠️ Firestore persistence could not be enabled: $e");
  }

  // ✅ Initialize Supabase
  await sb.Supabase.initialize(
    url: 'https://vndnadirfmipjjfvofbh.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZuZG5hZGlyZm1pcGpqZnZvZmJoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTcxNTU0MzksImV4cCI6MjA3MjczMTQzOX0.PWlLOVclbnMf1acUUesL1fn4cLbTyHmDKXW-ux7x_hs',
  );

  // ✅ Decide initial route based on user role
  String initialRoute = '/choose_login';
  fb_auth.User? currentUser = fb_auth.FirebaseAuth.instance.currentUser;

  if (currentUser != null) {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (doc.exists && doc.data()!.containsKey('role')) {
        final role = doc['role'];
        if (role == 'employer') {
          initialRoute = '/employerDashboard';
        } else if (role == 'jobseeker') {
          initialRoute = '/jobseekerDashboard';
        } else if (role == 'admin') {
          initialRoute = '/adminDashboard';
        }
      }
    } catch (e) {
      print("Error checking user role: $e");
    }
  }

  runApp(MyApp(initialRoute: initialRoute));
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Accessijobs",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'NotoSans',
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontFamily: 'NotoSans'),
          bodyMedium: TextStyle(fontFamily: 'NotoSans'),
          titleLarge: TextStyle(fontFamily: 'NotoSans'),
        ),
      ),
      onGenerateRoute: AppNavigator.generateRoute,
      initialRoute: initialRoute,
      routes: {
        '/choose_login': (context) => const ChooseLoginPage(),
        '/employer_login': (context) => const EmployerLoginPage(),
        '/jobseeker_login': (context) => const JobseekerLoginPage(),
        '/employerDashboard': (context) => const EmployerDashboard(),
        '/jobseekerDashboard': (context) => const JobseekerDashboard(),
        '/adminDashboard': (context) => const AdminDashboardPage(),
        '/': (context) => const InteractiveMap(mode: MapMode.viewJobs),
        '/job_listing': (context) => const JobListingPage(),
        '/signup': (context) => const UnifiedSignupPage(),
      },
    );
  }
}
