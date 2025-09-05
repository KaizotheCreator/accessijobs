import 'package:accessijobs/modules/dashboard/employer_functions/job_posting.dart';
import 'package:accessijobs/modules/dashboard/employer_functions/job_applications.dart';
import 'package:accessijobs/modules/dashboard/employer_functions/job_analytics.dart';
import 'package:accessijobs/modules/dashboard/employer_functions/company_profile.dart';
import 'package:accessijobs/modules/dashboard/shared_functions/interactive_map.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmployerDashboard extends StatefulWidget {
  const EmployerDashboard({super.key});

  @override
  State<EmployerDashboard> createState() => _EmployerDashboardState();
}

class _EmployerDashboardState extends State<EmployerDashboard> {
  int _selectedIndex = 1; // 👈 Default to Map Lobby

  final List<Widget> _pages = [
    const JobPostingModule(), // 👈 Job Posting
    const InteractiveMap(), // 👈 Map lobby
    const JobApplicationsPage(jobId: ""),
    const JobAnalyticsPage(),
    const CompanyProfilePage(),
  ];

  final List<String> _pageTitles = [
    "Post a Job",
    "Map Lobby",
    "Applications",
    "Analytics",
    "Company Profile",
  ];

  @override
  void initState() {
    super.initState();
    _loadLastTab();
    _checkAuth();
  }

  /// 🔑 Restore last opened tab
  Future<void> _loadLastTab() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedIndex = prefs.getInt('employer_last_tab') ?? 1;
    });
  }

  /// 💾 Save last opened tab
  Future<void> _saveLastTab(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('employer_last_tab', index);
  }

  /// 🔒 Check if user is logged in
  Future<void> _checkAuth() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // 👇 If no employer session, go back to login
      Navigator.pushReplacementNamed(context, "/employerLogin");
    }
  }

  void _onSelectPage(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _saveLastTab(index); // 💾 Remember selection
    Navigator.pop(context); // Close the drawer
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // 🚫 removes the back arrow
        title: Text(_pageTitles[_selectedIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // ✅ Show confirmation dialog before logout
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Confirm Logout"),
                  content: const Text("Do you really want to log out?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("No"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Yes"),
                    ),
                  ],
                ),
              );

              if (shouldLogout ?? false) {
                await FirebaseAuth.instance.signOut();
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('employer_last_tab'); // clear saved state
                Navigator.pushReplacementNamed(context, "/employerLogin");
              }
            },
          )
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                "Employer Dashboard",
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.post_add),
              title: const Text("Post Job"),
              onTap: () => _onSelectPage(0),
            ),
            ListTile(
              leading: const Icon(Icons.map),
              title: const Text("Map Lobby"),
              onTap: () => _onSelectPage(1),
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text("Applications"),
              onTap: () => _onSelectPage(2),
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text("Analytics"),
              onTap: () => _onSelectPage(3),
            ),
            ListTile(
              leading: const Icon(Icons.business),
              title: const Text("Company Profile"),
              onTap: () => _onSelectPage(4),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // 👇 Main selected page
          Positioned.fill(
            child: _pages[_selectedIndex],
          ),

          // 👇 Floating map preview (only when not on Map Lobby)
          if (_selectedIndex != 1)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SizedBox(
                  height: 180,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: InteractiveMap(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
