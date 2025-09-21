import 'package:accessijobs/modules/dashboard/employer_functions/job_posting.dart';
import 'package:accessijobs/modules/dashboard/employer_functions/job_applications.dart';
import 'package:accessijobs/modules/dashboard/employer_functions/job_analytics.dart';
import 'package:accessijobs/modules/dashboard/shared_functions/interactive_map.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmployerDashboard extends StatefulWidget {
  const EmployerDashboard({super.key});

  @override
  State<EmployerDashboard> createState() => _EmployerDashboardState();
}

class _EmployerDashboardState extends State<EmployerDashboard> {
  int _selectedIndex = 0;
  bool _darkMode = false;

  final List<String> _pageTitles = [
    "Home",
    "Post a Job",
    "Map Lobby",
    "Applications",
    "Analytics",
  ];

  late final List<Widget> _pages = [
    const EmployerLandingPage(),
    const JobPostingModule(),
    InteractiveMap(mode: MapMode.manageJobs),
    const JobApplicationsPage(),
    const JobAnalyticsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _checkAuth();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedIndex = prefs.getInt('employer_last_tab') ?? 0;
      _darkMode = prefs.getBool('employer_dark_mode') ?? false;
    });
  }

  Future<void> _saveLastTab(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('employer_last_tab', index);
  }

  Future<void> _saveDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('employer_dark_mode', value);
  }

  Future<void> _checkAuth() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.pushReplacementNamed(context, "/employerLogin");
    }
  }

  void _onSelectPage(int index) {
    setState(() => _selectedIndex = index);
    _saveLastTab(index);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = _darkMode ? ThemeData.dark() : ThemeData.light();

    return Theme(
      data: theme,
      child: WillPopScope(
        onWillPop: () async {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) return false;
          return true;
        },
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            leading: Builder(builder: (context) {
              return IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              );
            }),
            title: Text(_pageTitles[_selectedIndex]),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  final shouldLogout = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Confirm Logout"),
                      content: const Text("Do you really want to log out?"),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("No")),
                        TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text("Yes")),
                      ],
                    ),
                  );
                  if (shouldLogout == true) {
                    await FirebaseAuth.instance.signOut();
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove('employer_last_tab');
                    await prefs.remove('employer_dark_mode');
                    Navigator.pushReplacementNamed(context, "/choose_login");
                  }
                },
              )
            ],
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0B3D91), Color(0xFF00C853)],
                ),
              ),
            ),
            foregroundColor: Colors.white,
          ),
          drawer: Drawer(
            child: ListView(
              children: [
                const DrawerHeader(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [Color(0xFF0B3D91), Color(0xFF00C853)])),
                  child: Text("Employer Dashboard",
                      style: TextStyle(color: Colors.white, fontSize: 20)),
                ),
                ListTile(
                    leading: const Icon(Icons.home),
                    title: const Text("Home"),
                    onTap: () => _onSelectPage(0)),
                ListTile(
                    leading: const Icon(Icons.business),
                    title: const Text("Company Profile"),
                    onTap: () => _onSelectPage(1)),
                ListTile(
                    leading: const Icon(Icons.post_add),
                    title: const Text("Post Job"),
                    onTap: () => _onSelectPage(2)),
                ListTile(
                    leading: const Icon(Icons.map),
                    title: const Text("Map Lobby"),
                    onTap: () => _onSelectPage(3)),
                ListTile(
                    leading: const Icon(Icons.people),
                    title: const Text("Applications"),
                    onTap: () => _onSelectPage(4)),
                ListTile(
                    leading: const Icon(Icons.analytics),
                    title: const Text("Analytics"),
                    onTap: () => _onSelectPage(5)),
                const Divider(),
                SwitchListTile(
                  title: const Text("Dark Mode"),
                  value: _darkMode,
                  onChanged: (value) {
                    setState(() => _darkMode = value);
                    _saveDarkMode(value);
                  },
                  secondary: const Icon(Icons.brightness_6),
                ),
              ],
            ),
          ),
          body: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  "assets/background.png",
                  fit: BoxFit.cover,
                ),
              ),
              Positioned.fill(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.1, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: _pages[_selectedIndex],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EmployerLandingPage extends StatelessWidget {
  const EmployerLandingPage({super.key});

  /// Fetch only users with `role == jobseeker`
  Stream<QuerySnapshot<Map<String, dynamic>>> _recommendedJobseekers() {
    return FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'jobseeker')
        .snapshots();
  }

  /// Fetch company details for logged-in employer
Future<DocumentSnapshot<Map<String, dynamic>>> _fetchCompanyDetails() async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) {
    throw Exception("No authenticated user found");
  }
  return FirebaseFirestore.instance
      .collection('companies') // Fetch from companies collection
      .doc(currentUser.uid)
      .get();
}

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: _buildCompanyCard(context)),
                const SizedBox(width: 12),
                Expanded(flex: 3, child: _buildJobseekerCard(context)),
              ],
            )
          : Column(
              children: [
                _buildCompanyCard(context),
                const SizedBox(height: 12),
                _buildJobseekerCard(context),
              ],
            ),
    );
  }

  /// Left side - Company details
Widget _buildCompanyCard(BuildContext context) {
  return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
    future: _fetchCompanyDetails(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (!snapshot.hasData || !snapshot.data!.exists) {
        return const Center(child: Text("Company profile not found."));
      }

      final data = snapshot.data!.data()!;
      final logoUrl = data['logoUrl'] ?? '';
      final companyName = data['companyName'] ?? 'Unnamed Company';
      final about = data['about'] ?? 'No description provided';
      final industry = data['industry'] ?? 'Not specified';
      final services = List<String>.from(data['services'] ?? []);
      final headquarters = data['headquarters'] ?? 'Not specified';
      final foundedDate = data['foundedDate'] ?? 'Not specified';

      return Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      companyName,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (logoUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: Image.network(
                        logoUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    const CircleAvatar(
                      radius: 30,
                      child: Icon(Icons.business, size: 30),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text("About Us:",
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(about),
              const Divider(height: 20),
              Text("Industry: $industry"),
              const SizedBox(height: 8),
              Text("Services Offered: ${services.join(', ')}"),
              const SizedBox(height: 8),
              Text("Headquarters: $headquarters"),
              const SizedBox(height: 8),
              Text("Founded: $foundedDate"),
            ],
          ),
        ),
      );
    },
  );
}

  /// Right side - Recommended jobseekers
Widget _buildJobseekerCard(BuildContext context) {
  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Recommended Jobseekers",
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder(
              stream: _recommendedJobseekers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No jobseekers found."));
                }

                final docs = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final jobseekerId = docs[index].id;

                    // ✅ Combine first and last name
                    final firstName = data['firstName'] ?? '';
                    final lastName = data['lastName'] ?? '';
                    final fullName = '$firstName $lastName'.trim();

                    // ✅ Combine technical & personal skills
                    final technicalSkills =
                        List<String>.from(data['technicalSkills'] ?? []);
                    final personalSkills =
                        List<String>.from(data['personalSkills'] ?? []);
                    final allSkills = [...technicalSkills, ...personalSkills];
                    final skills = allSkills.isNotEmpty
                        ? allSkills.join(', ')
                        : (data['skills'] ?? []).join(', ');

                    // ✅ Work experience
                    final experience = data['workExperience'] ?? 'No experience listed';

                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(fullName.isNotEmpty ? fullName : 'Unknown'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(skills.isNotEmpty ? skills : "No skills listed"),
                          const SizedBox(height: 4),
                          Text("Experience: $experience",
                              style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => JobseekerProfileView(
                              jobseekerId: jobseekerId,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    ),
  );
}
}

/// Read-only Jobseeker Profile View
class JobseekerProfileView extends StatelessWidget {
  final String jobseekerId;

  const JobseekerProfileView({super.key, required this.jobseekerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Jobseeker Profile"),
        backgroundColor: const Color(0xFF0B3D91),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(jobseekerId)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;

          if (data == null) {
            return const Center(child: Text("Profile not found."));
          }

          final name = data['name'] ?? "Unknown";
          final email = data['email'] ?? "No email provided";

          final technicalSkills =
              List<String>.from(data['technicalSkills'] ?? []);
          final personalSkills =
              List<String>.from(data['personalSkills'] ?? []);
          final allSkills = [...technicalSkills, ...personalSkills];

          final skills = allSkills.isNotEmpty
              ? allSkills.join(', ')
              : (data['skills'] ?? []).join(', ');

          final experience = data['workExperience'] ?? "Not specified";
          final education = data['education'] ?? "Not specified";

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 50,
                        child: Text(
                          name.isNotEmpty ? name[0] : "?",
                          style: const TextStyle(
                              fontSize: 40, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(name,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 24),
                    Text("📧 Email: $email",
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 12),
                    Text("💼 Experience: $experience",
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 12),
                    Text("🎓 Education: $education",
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 12),
                    Text("🛠 Skills: $skills",
                        style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
