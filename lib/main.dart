import 'package:accessijobs/modules/auth/choose_login.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'navigator.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Import your dashboards
import 'modules/dashboard/jobseeker_dashboard.dart';
import 'modules/dashboard/employer_dashboard.dart';
import 'modules/dashboard/admin_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ Decide initial route based on auth + role
  String initialRoute = '/choose_login';
  User? currentUser = FirebaseAuth.instance.currentUser;

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
      title: "Accessijob",
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
      print("Offline persistence enabled");
    } catch (e) {
      print("Offline persistence could not be enabled: $e");
    }
  }
}
