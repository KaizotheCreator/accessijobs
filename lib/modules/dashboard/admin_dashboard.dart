import 'package:accessijobs/modules/dashboard/admin_functions/company_stats_section.dart';
import 'package:accessijobs/modules/dashboard/admin_functions/jobseeker_stats_section.dart';
import 'package:accessijobs/modules/dashboard/admin_functions/employer_stats_section.dart';
import 'package:accessijobs/modules/dashboard/admin_functions/customer_service_section.dart';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ Firestore import

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
    "Jobseekers",
    "Employers",
    "Reports",
    "Customer Service",
    "Settings",
  ];

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadTab();
  }

  Future<void> _checkAuthAndLoadTab() async {
    _currentUser = FirebaseAuth.instance.currentUser;

    if (_currentUser == null) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, "/admindashboard");
      }
      return;
    }

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

  Widget _buildOverviewPage() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        crossAxisCount: MediaQuery.of(context).size.width > 800 ? 3 : 1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: const [
          _DashboardCard(
            title: "Total Jobseekers",
            icon: Icons.people,
            collectionName: "jobseekers", // ✅ Firestore collection
          ),
          _DashboardCard(
            title: "Total Employers",
            icon: Icons.business,
            collectionName: "employers",
          ),
          _DashboardCard(
            title: "Active Jobs",
            icon: Icons.work,
            collectionName: "jobs",
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsPage() {
    return const Center(
      child: Text(
        "⚙️ Settings Page\n(Admin Preferences, Roles, Permissions)",
        textAlign: TextAlign.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildOverviewPage(),
      const JobseekerStatsSection(),
      const EmployerStatsSection(),
      const CompanyStatsSection(),
      const CustomerServiceSection(),
      _buildSettingsPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text("Admin Dashboard - ${_sections[_selectedIndex]}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
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
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  "Admin Panel",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
                                  ? Icons.business
                                  : index == 3
                                      ? Icons.bar_chart
                                      : index == 4
                                          ? Icons.support_agent
                                          : Icons.settings,
                    ),
                    title: Text(_sections[index]),
                    selected: _selectedIndex == index,
                    onTap: () {
                      setState(() {
                        _selectedIndex = index;
                      });
                      _saveLastTab(index);
                      Navigator.pop(context);
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
        child: pages[_selectedIndex],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String collectionName; // ✅ Firestore collection

  const _DashboardCard({
    required this.title,
    required this.icon,
    required this.collectionName,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collectionName).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final count = snapshot.data!.docs.length;

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 48, color: Colors.blue.shade700),
                const SizedBox(height: 12),
                Text(
                  "$count",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 6),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
        );
      },
    );
  }
}

