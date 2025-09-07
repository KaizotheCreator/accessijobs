import 'package:accessijobs/modules/dashboard/jobseeker_functions/profile.dart';
import 'package:accessijobs/modules/dashboard/jobseeker_functions/resume_builder.dart';
import 'package:flutter/material.dart';
import 'shared_functions/interactive_map.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JobseekerDashboard extends StatefulWidget {
  const JobseekerDashboard({super.key});

  @override
  State<JobseekerDashboard> createState() => _JobseekerDashboardState();
}

class _JobseekerDashboardState extends State<JobseekerDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? userData;

  final TextEditingController _searchController = TextEditingController();

  int _selectedIndex = 0; // Track selected dashboard tab
  final List<String> _sections = [
    "Profile",
    "Job Listings",
    "Jobs Applied",
    "Resume Builder",
    "Interactive Map",
    "Notifications"
  ];

  @override
  void initState() {
    super.initState();
    _checkLoginAndFetch();
    _loadLastTab();
  }

  /// ✅ Auto-login check
  Future<void> _checkLoginAndFetch() async {
    final User? user = _auth.currentUser;
    if (user == null) {
      // ⚡ Not logged in → go back to login
      if (mounted) {
        Navigator.pushReplacementNamed(context, "/choose_login");
      }
    } else {
      await _fetchUserData();
    }
  }

  /// ✅ Fetch user data or create default profile
  Future<void> _fetchUserData() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          setState(() {
            userData = userDoc.data() as Map<String, dynamic>;
          });
        } else {
          await _firestore.collection('users').doc(user.uid).set({
            "name": "John Doe",
            "title": "Job Title",
            "bio": "No bio added yet.",
            "skills": [],
            "achievements": [],
            "certifications": [],
            "education": [],
            "profileImageUrl": "",
          });

          DocumentSnapshot newUserDoc =
              await _firestore.collection('users').doc(user.uid).get();

          setState(() {
            userData = newUserDoc.data() as Map<String, dynamic>;
          });
        }
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  /// ✅ Save last selected tab
  Future<void> _saveLastTab(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('jobseeker_last_tab', index);
  }

  /// ✅ Load last selected tab
  Future<void> _loadLastTab() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedIndex = prefs.getInt('jobseeker_last_tab') ?? 0;
    });
  }

  /// 🔍 Mock NLP Search Handler
  void _handleSearch(String query) {
    String interpretation;
    if (query.toLowerCase().contains("remote")) {
      interpretation = "Showing remote jobs…";
    } else if (query.toLowerCase().contains("flutter")) {
      interpretation = "Searching Flutter developer jobs…";
    } else {
      interpretation = "Searching for: $query";
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(interpretation)),
    );
  }

  /// ✅ Explicit logout with confirm dialog
  Future<void> _confirmLogout() async {
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

    if (shouldLogout == true) {
      await _auth.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('jobseeker_last_tab');
      if (mounted) {
        Navigator.pushReplacementNamed(context, "/choose_login");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;

    final List<Widget> _pages = [
      _buildProfilePage(),
      _buildPlaceholder("Job Listings"),
      _buildPlaceholder("Jobs Applied"),
      const ResumeBuilderPage(),
      const InteractiveMap(),
      _buildPlaceholder("Notifications"),
    ];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 1,
        backgroundColor: Colors.white,
        title: Text(
          "Jobseeker Dashboard - ${_sections[_selectedIndex]}",
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: Colors.blueAccent),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined, color: Colors.blueAccent),
            tooltip: "View Map",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const InteractiveMap()),
              );
            },
          ),
          Builder(
            builder: (innerCtx) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.blueAccent),
              onPressed: () {
                Scaffold.of(innerCtx).openEndDrawer();
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: "Logout",
            onPressed: _confirmLogout,
          ),
        ],
      ),

      // Drawer
      endDrawer: Drawer(
        child: ListView.builder(
          itemCount: _sections.length,
          itemBuilder: (context, index) {
            return ListTile(
              leading: Icon(
                index == 0
                    ? Icons.person
                    : index == 1
                        ? Icons.work
                        : index == 2
                            ? Icons.check_circle
                            : index == 3
                                ? Icons.description
                                : index == 4
                                    ? Icons.map
                                    : Icons.notifications,
              ),
              title: Text(_sections[index]),
              selected: _selectedIndex == index,
              onTap: () {
                Navigator.pop(context); // close drawer first

                if (index == 0) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const JobseekerProfile()),
                  ).then((_) => _fetchUserData());
                } else {
                  setState(() {
                    _selectedIndex = index;
                  });
                  _saveLastTab(index);
                }
              },
            );
          },
        ),
      ),

      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _pages[_selectedIndex],
      ),
    );
  }

  /// Profile Page (uses Firestore userData)
  Widget _buildProfilePage() {
    final isWide = MediaQuery.of(context).size.width > 800;

    if (userData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Search bar
          Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: _handleSearch,
              decoration: InputDecoration(
                hintText: "Search jobs with natural language…",
                prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(40),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Profile header card
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: (userData?["profileImageUrl"] ?? "").isNotEmpty
                        ? NetworkImage(userData!["profileImageUrl"])
                        : const AssetImage("assets/profile.png")
                            as ImageProvider,
                  ),
                  const SizedBox(height: 12),
                  Text(userData?["name"] ?? "John Doe",
                      style: Theme.of(context).textTheme.titleLarge),
                  Text(userData?["title"] ?? "Job Title",
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  Text(
                    userData?["bio"] ?? "No bio added yet.",
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text("Edit Profile"),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const JobseekerProfile()),
                      ).then((_) => _fetchUserData());
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Grid cards
          Expanded(
            child: GridView.count(
              crossAxisCount: isWide ? 3 : 2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              children: [
                _buildDashboardCard(
                  icon: Icons.person,
                  title: "Profile",
                  color: Colors.blue.shade50,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const JobseekerProfile()),
                    ).then((_) => _fetchUserData());
                  },
                ),
                _buildDashboardCard(
                  icon: Icons.work,
                  title: "Job Listings",
                  color: Colors.green.shade50,
                  onTap: () {},
                ),
                _buildDashboardCard(
                  icon: Icons.check_circle,
                  title: "Jobs Applied",
                  color: Colors.orange.shade50,
                  onTap: () {},
                ),
                _buildDashboardCard(
                  icon: Icons.description,
                  title: "Resume Builder",
                  color: Colors.purple.shade50,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ResumeBuilderPage()),
                    );
                  },
                ),
                _buildDashboardCard(
                  icon: Icons.map,
                  title: "Interactive Map",
                  color: Colors.red.shade50,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const InteractiveMap()),
                    );
                  },
                ),
                _buildDashboardCard(
                  icon: Icons.notifications,
                  title: "Notifications",
                  color: Colors.teal.shade50,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Placeholder for other sections
  Widget _buildPlaceholder(String title) {
    return Center(child: Text("📌 $title Page Coming Soon"));
  }

  // Reusable Card with modern style
  Widget _buildDashboardCard(
      {required IconData icon,
      required String title,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: color,
        elevation: 2,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: Colors.blueAccent),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
