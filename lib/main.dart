import 'package:accessijobs/modules/auth/choose_login.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'navigator.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

// Import your dashboards
import 'modules/dashboard/jobseeker_dashboard.dart';
import 'modules/dashboard/employer_dashboard.dart';
import 'modules/dashboard/admin_dashboard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ Initialize Supabase (for image storage)
  await sb.Supabase.initialize(
    url: 'https://vndnadirfmipjjfvofbh.supabase.co',  // 🔑 Replace with your Supabase project URL
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZuZG5hZGlyZm1pcGpqZnZvZmJoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTcxNTU0MzksImV4cCI6MjA3MjczMTQzOX0.PWlLOVclbnMf1acUUesL1fn4cLbTyHmDKXW-ux7x_hs',            // 🔑 Replace with anon/public key
  );

  // ✅ Decide initial route based on auth + role
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
    // Firestore persistence setup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFirestore();
    });

    return MaterialApp(
      title: "Accessijobs",
      debugShowCheckedModeBanner: false,
      onGenerateRoute: AppNavigator.generateRoute,
      initialRoute: initialRoute,
      routes: {
        '/choose_login': (context) => const ChooseLoginPage(),
        '/employerDashboard': (context) => const EmployerDashboard(),
        '/jobseekerDashboard': (context) => const JobseekerDashboard(),
        '/adminDashboard': (context) => const AdminDashboardPage(),
      },
    );
  }

  void _initializeFirestore() async {
    try {
      await FirebaseFirestore.instance.enablePersistence();
      print("✅ Firestore offline persistence enabled");
    } catch (e) {
      print("⚠️ Firestore persistence could not be enabled: $e");
    }
  }
}
