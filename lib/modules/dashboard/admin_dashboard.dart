import 'package:accessijobs/modules/dashboard/admin_functions/company_stats_section.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;
  User? _currentUser;

  final List<String> _sections = [
    "Overview",
    "Users",
    "Jobs",
    "Reports",
    "Settings",
  ];

  final List<Widget> _pages = [
    const Center(child: Text("📊 Overview Page")),
    const Center(child: Text("👤 Manage Users")),
    const Center(child: Text("💼 Manage Jobs")),
    const CompanyStatsSection(),
    const Center(child: Text("⚙️ Settings")),
  ];

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadTab();
  }

  Future<void> _checkAuthAndLoadTab() async {
    // 🔐 check FirebaseAuth session
    _currentUser = FirebaseAuth.instance.currentUser;

    if (_currentUser == null) {
      // no logged in admin → redirect to login
      if (mounted) {
        Navigator.pushReplacementNamed(context, "/adminLogin");
      }
      return;
    }

    // ✅ restore last tab
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _selectedIndex = prefs.getInt('admin_last_tab') ?? 0;
      });
    }
  }

  Future<void> _saveLastTab(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('admin_last_tab', index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Admin Dashboard - ${_sections[_selectedIndex]}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // 🔐 proper Firebase logout
              await FirebaseAuth.instance.signOut();

              if (mounted) {
                Navigator.pushReplacementNamed(context, "/adminLogin");
              }
            },
          )
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade700, Colors.blue.shade400],
                ),
              ),
              child: const Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  "Admin Panel",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _sections.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Icon(
                      index == 0
                          ? Icons.dashboard
                          : index == 1
                              ? Icons.people
                              : index == 2
                                  ? Icons.work
                                  : index == 3
                                      ? Icons.bar_chart
                                      : Icons.settings,
                    ),
                    title: Text(_sections[index]),
                    selected: _selectedIndex == index,
                    onTap: () {
                      setState(() {
                        _selectedIndex = index;
                      });
                      _saveLastTab(index); // 💾 save last section
                      Navigator.pop(context); // close drawer
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _pages[_selectedIndex],
      ),
    );
  }
}
