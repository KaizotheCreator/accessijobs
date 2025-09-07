import 'package:flutter/material.dart';
import 'package:accessijobs/modules/auth/jobseeker_login_page.dart';
import 'package:accessijobs/modules/auth/signup_page.dart';
import 'package:accessijobs/modules/auth/admin_login_page.dart';

class ChooseLoginPage extends StatelessWidget {
  const ChooseLoginPage({Key? key}) : super(key: key);

  Widget buildFeatureBox(String imagePath, String title, String description, double width) {
    return Container(
      width: width, // Responsive width
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(imagePath, height: 60),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Make each feature box take about 1/3 of screen width on large screens, 1/2 on smaller
    final boxWidth = screenWidth > 900
        ? screenWidth / 3 - 40
        : screenWidth > 600
            ? screenWidth / 2 - 30
            : screenWidth - 60;

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/modules.png',
              fit: BoxFit.cover,
            ),
          ),

          // Top Left: Bigger Logo (clickable) + Bigger App Name
          Positioned(
            top: 30,
            left: 20,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AdminLoginPage()),
                    );
                  },
                  child: Image.asset(
                    'assets/logo.png',
                    height: 80,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  "AccessiJobs",
                  style: TextStyle(
                    fontFamily: 'Times New Roman',
                    fontSize: 45,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 6,
                        color: Colors.black54,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Top Right: Login & Sign Up Buttons
          Positioned(
            top: 40,
            right: 20,
            child: Row(
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const JobseekerLoginPage()),
                    );
                  },
                  child: const Text("Login"),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SignUpPage()),
                    );
                  },
                  child: const Text("Sign Up"),
                ),
              ],
            ),
          ),

          // Main content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Big Illustration
                  Image.asset(
                    'assets/computer.png',
                    height: 160,
                  ),
                  const SizedBox(height: 25),

                  // Title
                  const Text(
                    "A Multiplatform Localized Job Seeker System",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          blurRadius: 4,
                          color: Colors.black45,
                          offset: Offset(2, 2),
                        )
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    "AI Matching Algorithm using Natural Language Processing\nand Interactive Map",
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 40),

                  // Responsive Feature Sections
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      buildFeatureBox(
                        'assets/verification.png',
                        "Verification Process",
                        "Safe and reliable, with system-assisted verification.",
                        boxWidth,
                      ),
                      buildFeatureBox(
                        'assets/ai_matching.png',
                        "AI-Powered Job Matching",
                        "Smart job recommendations using NLP.",
                        boxWidth,
                      ),
                      buildFeatureBox(
                        'assets/mapping.png',
                        "Interactive Mapping",
                        "Find jobs near you with location-based listings.",
                        boxWidth,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
