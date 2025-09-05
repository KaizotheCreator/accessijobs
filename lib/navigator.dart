import 'package:flutter/material.dart';
import 'modules/auth/jobseeker_login_page.dart';
import 'modules/auth/signup_page.dart';
import 'modules/auth/admin_login_page.dart';
import 'modules/dashboard/jobseeker_dashboard.dart';
import 'modules/dashboard/admin_dashboard.dart';
import 'modules/auth/employer_login_page.dart';
import 'modules/dashboard/employer_dashboard.dart';
import 'modules/auth/choose_login.dart';

class AppNavigator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/choose_login':
        return MaterialPageRoute(builder: (_) => const ChooseLoginPage());
      case '/jobseeker_login':
        return MaterialPageRoute(builder: (_) => const JobseekerLoginPage());
      case '/employer_login':
        return MaterialPageRoute(builder: (_) => const EmployerLoginPage());
      case '/jobseeker_dashboard':
        return MaterialPageRoute(builder: (_) => const JobseekerDashboard());
      case '/employer_dashboard':
        return MaterialPageRoute(builder: (_) => const EmployerDashboard());
      case '/signup':
        return MaterialPageRoute(builder: (_) => const SignUpPage());
      case '/admin':
        return MaterialPageRoute(builder: (_) => const AdminLoginPage());
      case '/admindashboard':
        return MaterialPageRoute(builder: (_) => const AdminDashboardPage());
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text("Page not found")),
          ),
        );
    }
  }
}
