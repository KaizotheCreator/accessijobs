import 'package:flutter/material.dart';
import 'package:accessijobs/modules/auth/jobseeker_login_page.dart';
import 'package:accessijobs/modules/auth/signup_page.dart';
import 'package:accessijobs/modules/auth/admin_login_page.dart';

class ChooseLoginPage extends StatefulWidget {
  const ChooseLoginPage({Key? key}) : super(key: key);

  @override
  State<ChooseLoginPage> createState() => _ChooseLoginPageState();
}

class _ChooseLoginPageState extends State<ChooseLoginPage> {
  bool hoverA = false;
  bool hoverC = false;
  bool hoverDrawerIcon = false;

  int hoveredTileIndex = -1; // for drawer hover effect

  Widget buildFeatureBox(
      String imagePath, String title, String description, double width, double fontScale) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(imagePath, height: 60 * fontScale * 1.3), // 30% bigger
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 16 * fontScale,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: TextStyle(fontSize: 12 * fontScale),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;

        double fontScale = screenWidth < 400
            ? 0.9
            : screenWidth < 800
                ? 1.0
                : 1.2;

        final boxWidth = screenWidth > 1000
            ? screenWidth / 3 - 40
            : screenWidth > 700
                ? screenWidth / 2 - 30
                : screenWidth - 60;

        return Scaffold(
          // ✅ Black Drawer with hover effect
          endDrawer: Drawer(
            backgroundColor: Colors.black,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue, Colors.teal],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      "AccessiJobs",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
                _buildHoverTile(
                  index: 0,
                  icon: Icons.login,
                  label: "Login",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const JobseekerLoginPage()),
                    );
                  },
                ),
                _buildHoverTile(
                  index: 1,
                  icon: Icons.person_add,
                  label: "Sign Up",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const UnifiedSignupPage()),
                    );
                  },
                ),
                const Divider(color: Colors.white54),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "About AccessiJobs",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "AccessiJobs is a multiplatform localized job seeker system "
                        "that connects employers and job seekers through a safe, "
                        "efficient, and intelligent matching process.",
                        style: TextStyle(fontSize: 14, height: 1.5, color: Colors.white70),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "It uses AI-powered job matching and interactive mapping "
                        "to provide tailored opportunities and location-based listings, "
                        "making it easier for applicants to find jobs that fit their skills "
                        "and for employers to discover qualified candidates.",
                        style: TextStyle(fontSize: 14, height: 1.5, color: Colors.white70),
                      ),
                      SizedBox(height: 16),
                      Text(
                        "Team Members:",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text("• Project Manager: King Jordan Lorenzo", style: TextStyle(color: Colors.white)),
                      Text("• Programmer: James Arhil Riazo", style: TextStyle(color: Colors.white)),
                      Text("• System Analyst: Dale Tirazona", style: TextStyle(color: Colors.white)),
                      Text("• Quality Assurance: Danella Mae Acal", style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          appBar: AppBar(
            elevation: 0,
            automaticallyImplyLeading: false,
            iconTheme: const IconThemeData(color: Colors.white, size: 32),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ✅ Hover effect on "A"
                MouseRegion(
                  onEnter: (_) => setState(() => hoverA = true),
                  onExit: (_) => setState(() => hoverA = false),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AdminLoginPage()),
                      );
                    },
                    child: AnimatedScale(
                      scale: hoverA ? 1.2 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        "A",
                        style: TextStyle(
                          fontFamily: 'Times New Roman',
                          fontSize: screenWidth < 500 ? 32 : 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.tealAccent.shade400,
                          shadows: const [
                            Shadow(
                              blurRadius: 6,
                              color: Colors.black54,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ✅ Hover effect on "ccessiJobs"
                MouseRegion(
                  onEnter: (_) => setState(() => hoverC = true),
                  onExit: (_) => setState(() => hoverC = false),
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontFamily: 'Times New Roman',
                      fontSize: screenWidth < 500 ? 28 : 45,
                      fontWeight: FontWeight.bold,
                      color: hoverC ? Colors.tealAccent : Colors.white,
                      shadows: const [
                        Shadow(
                          blurRadius: 6,
                          color: Colors.black54,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                    child: const Text("ccessiJobs"),
                  ),
                ),
              ],
            ),
            centerTitle: false,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.green],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            actions: [
              // ✅ Hover effect on drawer icon
              Builder(
                builder: (context) => MouseRegion(
                  onEnter: (_) => setState(() => hoverDrawerIcon = true),
                  onExit: (_) => setState(() => hoverDrawerIcon = false),
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => Scaffold.of(context).openEndDrawer(),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: AnimatedScale(
                        scale: hoverDrawerIcon ? 1.3 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(Icons.menu,
                            color: Colors.white, size: 32),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/modules.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/computer.png',
                      height: screenWidth < 500 ? 120 : 160,
                    ),
                    const SizedBox(height: 25),

                    Text(
                      "A Multiplatform Localized Job Seeker System",
                      style: TextStyle(
                        fontSize: screenWidth < 500 ? 22 : 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: const [
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

                    Text(
                      "AI Matching Algorithm using Natural Language Processing\nand Interactive Map",
                      style: TextStyle(
                        fontSize: screenWidth < 500 ? 13 : 15,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        buildFeatureBox(
                          'assets/verified-unscreen.gif',
                          "Verification Process",
                          "Safe and reliable, with system-assisted verification.",
                          boxWidth,
                          fontScale,
                        ),
                        buildFeatureBox(
                          'assets/ai-matching.gif',
                          "AI-Powered Job Matching",
                          "Smart job recommendations using NLP.",
                          boxWidth,
                          fontScale,
                        ),
                        buildFeatureBox(
                          'assets/mapping-unscreen.gif',
                          "Interactive Mapping",
                          "Find jobs near you with location-based listings.",
                          boxWidth,
                          fontScale,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ✅ Custom hoverable ListTile for Drawer
  Widget _buildHoverTile({
    required int index,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isHovered = hoveredTileIndex == index;
    return MouseRegion(
      onEnter: (_) => setState(() => hoveredTileIndex = index),
      onExit: (_) => setState(() => hoveredTileIndex = -1),
      child: ListTile(
        leading: Icon(icon, color: isHovered ? Colors.tealAccent : Colors.white),
        title: Text(
          label,
          style: TextStyle(
            color: isHovered ? Colors.tealAccent : Colors.white,
            fontWeight: isHovered ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
