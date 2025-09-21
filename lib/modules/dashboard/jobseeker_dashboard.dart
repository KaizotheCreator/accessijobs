// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:async';
import 'package:accessijobs/modules/dashboard/jobseeker_functions/job_analytics.dart';
import 'package:accessijobs/modules/dashboard/jobseeker_functions/job_applied.dart';
import 'package:accessijobs/modules/dashboard/jobseeker_functions/job_listing.dart';
import 'package:accessijobs/nlp_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:badges/badges.dart' as badges;
import 'package:accessijobs/modules/dashboard/jobseeker_functions/recommended_jobs_page.dart';

class JobseekerDashboard extends StatefulWidget {
  const JobseekerDashboard({super.key});

  @override
  State<JobseekerDashboard> createState() => _JobseekerDashboardState();
}

class _JobseekerDashboardState extends State<JobseekerDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? jobseekerData;

  int _unreadNotifications = 0;
  int _unreadMessages = 0;
  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> _messages = [];

  List<Map<String, dynamic>> _personalizedJobs = [];
  bool _isLoadingPersonalized = false;


  String _searchQuery = "";
  bool _isSearching = false;

  final TextEditingController _searchController = TextEditingController();
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _jobseekerDocSubscription;

  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadDarkModePref();
    _checkLoginAndFetch();
    _listenToNotifications();
    _listenToJobseekerDoc();
    _listenToEmployerReplies();
     _fetchPersonalizedJobs();
  }

  @override
  void dispose() {
    _jobseekerDocSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDarkModePref() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getBool('jobseeker_dark_mode') ?? false;
    if (mounted) setState(() => _isDarkMode = val);
  }

  Future<void> _toggleDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('jobseeker_dark_mode', !_isDarkMode);
    if (mounted) setState(() => _isDarkMode = !_isDarkMode);
  }

  Future<void> _checkLoginAndFetch() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      _jobseekerDocSubscription?.cancel();
      setState(() {
        jobseekerData = null;
      });
      if (mounted) {
        Navigator.pushReplacementNamed(context, "/choose_login");
      }
    } else {
      _jobseekerDocSubscription?.cancel();
      await _fetchJobseekerData();
      _listenToJobseekerDoc();
    }
  }

  Future<void> _fetchJobseekerData() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot jobseekerDoc =
            await _firestore.collection('jobseekers').doc(user.uid).get();

        if (jobseekerDoc.exists) {
          setState(() {
            jobseekerData = jobseekerDoc.data() as Map<String, dynamic>?;
          });
        }
      }
    } catch (e) {
      print("Error fetching jobseeker data: $e");
    }
  }

  void _listenToJobseekerDoc() {
    final user = _auth.currentUser;
    if (user == null) return;

    _jobseekerDocSubscription?.cancel();

    _jobseekerDocSubscription = _firestore
        .collection('jobseekers')
        .doc(user.uid)
        .snapshots()
        .listen((docSnap) {
      if (docSnap.exists) {
        final data = docSnap.data();
        if (mounted) {
          setState(() {
            jobseekerData = data as Map<String, dynamic>?;
          });
        }
      }
    });
  }

  /// Notifications listener
  void _listenToNotifications() {
    final user = _auth.currentUser;
    if (user == null) return;

    _firestore
        .collection("jobseekers")
        .doc(user.uid)
        .collection("notifications")
        .orderBy("timestamp", descending: true)
        .snapshots()
        .listen((snapshot) {
      final notifs = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          ...data,
          "id": doc.id,
        };
      }).toList();
      final unread = notifs.where((n) => n["read"] == false).length;

      if (mounted) {
        setState(() {
          _notifications = notifs.cast<Map<String, dynamic>>();
          _unreadNotifications = unread;
        });
      }
    });
  }

  /// Listen to employer replies in job_applications
  void _listenToEmployerReplies() {
    final user = _auth.currentUser;
    if (user == null) return;

    _firestore
        .collection("job_applications")
        .where("userId", isEqualTo: user.uid)
        .where("reply", isNotEqualTo: null) // employer has replied
        .snapshots()
        .listen((snapshot) {
      final msgs = snapshot.docs.map((doc) => doc.data()).toList();

      if (mounted) {
        setState(() {
          _messages = msgs.cast<Map<String, dynamic>>();
          _unreadMessages = msgs.length;
        });
      }
    });
  }

  /// NLP-powered job search
  Future<void> _searchJobs() async {
    if (_searchQuery.trim().isEmpty) return;

    setState(() => _isSearching = true);

    try {
      final results = await NLPService.searchJobs(_searchQuery.trim());

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecommendedJobsPage(
              jobs: List<Map<String, dynamic>>.from(results),
            ),
          ),
        );
      }
    } catch (e) {
      print("Error during NLP search: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error searching jobs. Please try again.")),
      );
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Sign Out Confirmation"),
        content: const Text(
            "Are you sure you want to sign out of your account?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Sign Out"),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await _jobseekerDocSubscription?.cancel();
      _jobseekerDocSubscription = null;

      await _auth.signOut();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('jobseeker_last_tab');

      if (mounted) {
        setState(() {
          jobseekerData = null;
        });
        Navigator.pushReplacementNamed(context, "/choose_login");
      }
    }
  }

  /// Show employer replies
  void _showMessages() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Employer Replies"),
        content: SizedBox(
          width: double.maxFinite,
          child: _messages.isEmpty
              ? const Text("No messages yet.")
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    return ListTile(
                      leading: const Icon(Icons.message),
                      title: Text(msg["reply"] ?? "No message"),
                      subtitle: Text(msg["jobTitle"] ?? "Unknown Job"),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchPersonalizedJobs() async {
  final user = _auth.currentUser;
  if (user == null) return;

  setState(() => _isLoadingPersonalized = true);

  try {
    final jobs = await NLPService.getPersonalizedJobs(user.uid);
    if (mounted) {
      setState(() {
        _personalizedJobs = jobs;
      });
    }
  } catch (e) {
    print("Error fetching personalized jobs: $e");
  } finally {
    if (mounted) setState(() => _isLoadingPersonalized = false);
  }
}

  @override
Widget build(BuildContext context) {
  final isWide = MediaQuery.of(context).size.width > 800;

  final bgGradientStart = _isDarkMode
      ? const Color.fromARGB(221, 29, 87, 45)
      : Colors.blue;
  final bgGradientEnd = _isDarkMode ? Colors.grey[900]! : Colors.green;
  final scaffoldBg = Colors.transparent;

  return Container(
    decoration: BoxDecoration(
      image: DecorationImage(
        image: AssetImage(
          _isDarkMode
              ? "assets/background_dark.png"
              : "assets/background.png",
        ),
        fit: BoxFit.cover,
      ),
    ),
    child: Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: const Text("Jobseeker Dashboard"),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [bgGradientStart, bgGradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          // Search Bar
          SizedBox(
            width: 180,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: "Search jobs",
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: _searchJobs,
                        ),
                ),
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),

          // Employer Messages Icon
          badges.Badge(
            position: badges.BadgePosition.topEnd(top: -4, end: -4),
            badgeContent: Text(
              _unreadMessages.toString(),
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
            showBadge: _unreadMessages > 0,
            child: IconButton(
              icon: const Icon(Icons.message, color: Colors.white),
              tooltip: "Employer Replies",
              onPressed: _showMessages,
            ),
          ),

          // Logout Button
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _confirmLogout,
          ),
        ],
      ),
      drawer: _buildDrawer(),

      // MAIN BODY
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // LEFT: Profile Card
                  SizedBox(
                    width: 400, // widened to fit long emails
                    child: _buildProfileCard(),
                  ),
                  const SizedBox(width: 16),

                  // RIGHT: Scrollable content
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    // LEFT: Application History
    Expanded(
      flex: 2,
      child: _buildApplicationHistory(),
    ),
    const SizedBox(width: 16),

    // RIGHT: Personalized Jobs
    SizedBox(
      width: 300, 
      child: _buildPersonalizedJobs(),
    ),
  ],
),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileCard(),
                    const SizedBox(height: 16),
                    _buildApplicationHistory(),
                    const SizedBox(height: 16),
                    _buildPersonalizedJobs(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
      ),
    ),
  );
}

  /// Compact profile card
  Widget _buildProfileCard() {
  if (jobseekerData == null) {
    return const Center(child: CircularProgressIndicator());
  }

  // Basic fields
  final firstName = (jobseekerData!["firstName"] ?? "").toString();
  final lastName = (jobseekerData!["lastName"] ?? "").toString();
  final fullName = "$firstName ${lastName}".trim();
  final profileImageUrl = (jobseekerData!["profileImageUrl"] ?? "").toString();
  final bio = (jobseekerData!["bio"] ?? "").toString();
  final email = (jobseekerData!["email"] ?? "").toString();
  final contact = (jobseekerData!["contactNumber"] ?? "").toString();
  final location = (jobseekerData!["location"] ?? "No location specified").toString();

  // Skills
  final technicalSkills = (jobseekerData!["technicalSkills"] is List)
      ? List<String>.from(jobseekerData!["technicalSkills"])
      : <String>[];
  final personalSkills = (jobseekerData!["personalSkills"] is List)
      ? List<String>.from(jobseekerData!["personalSkills"])
      : <String>[];
  final skillsFromGeneric = (jobseekerData!["skills"] is List)
      ? List<String>.from(jobseekerData!["skills"])
      : <String>[];
  final skills = [
    ...skillsFromGeneric,
    ...technicalSkills,
    ...personalSkills
  ].map((s) => s.toString()).where((s) => s.trim().isNotEmpty).toSet().toList();

  // Education
  final eduRaw = jobseekerData!["education"];
  List<Map<String, dynamic>> education = [];
  if (eduRaw is List) {
    for (var e in eduRaw) {
      if (e is Map) {
        education.add(Map<String, dynamic>.from(e));
      } else if (e is String) {
        education.add({"school": e});
      }
    }
  }

  // Experience
  final expRaw = jobseekerData!["workExperience"] ?? jobseekerData!["experience"];
  List<Map<String, dynamic>> experience = [];
  if (expRaw is List) {
    for (var ex in expRaw) {
      if (ex is Map) {
        experience.add(Map<String, dynamic>.from(ex));
      } else if (ex is String) {
        experience.add({"role": ex});
      }
    }
  }

  // Resume completion calculation
  int _calcCompletion() {
    int total = 4;
    int filled = 0;
    if (profileImageUrl.isNotEmpty) filled++;
    if (bio.isNotEmpty) filled++;
    if (skills.isNotEmpty) filled++;
    if (experience.isNotEmpty || education.isNotEmpty) filled++;
    return ((filled / total) * 100).round();
  }

  final completion = _calcCompletion();

  return SizedBox(
    width: 340, // widened to fit longer email addresses
    child: Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundImage:
                        profileImageUrl.isNotEmpty ? NetworkImage(profileImageUrl) : null,
                    child: profileImageUrl.isEmpty ? const Icon(Icons.person, size: 40) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(fullName.isEmpty ? "No name" : fullName,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          email.isNotEmpty ? email : "No email",
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (contact.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(contact, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(location, style: const TextStyle(color: Colors.grey)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Resume status only
              const Text("Resume Status",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: completion / 100,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      completion >= 80 ? Colors.green : Colors.orange),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "$completion% complete",
                style: const TextStyle(fontSize: 12),
              ),

              const SizedBox(height: 12),
              const Divider(),

              // Skills
              const Text("Skills", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              skills.isNotEmpty
                  ? Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: skills
                          .map((s) => Chip(
                                label: Text(s),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                backgroundColor: Colors.blue.shade50,
                              ))
                          .toList(),
                    )
                  : const Text("No skills added", style: TextStyle(color: Colors.black54)),

              const SizedBox(height: 12),
              const Divider(),

              // Education
              const Text("Education",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              education.isNotEmpty
                  ? Column(
                      children: education.map((edu) {
                        final school = (edu['school'] ?? edu['institution'] ?? edu['name'])
                                ?.toString() ??
                            "Unknown school";
                        final year =
                            (edu['graduationDate'] ?? edu['year'])?.toString() ?? "";
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          leading: const Icon(Icons.school, color: Colors.blue),
                          title: Text(school,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: year.isNotEmpty ? Text("($year)") : null,
                        );
                      }).toList(),
                    )
                  : const Text("No education details added",
                      style: TextStyle(color: Colors.black54)),
            ],
          ),
        ),
      ),
    ),
  );
}
Widget _buildPersonalizedJobs() {
  if (_isLoadingPersonalized) {
    return const Center(child: CircularProgressIndicator());
  }

  if (_personalizedJobs.isEmpty) {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Text(
        "No personalized job matches found yet.",
        style: TextStyle(color: Colors.black54),
      ),
    );
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.0),
        child: Text(
          "Personalized Job Matches",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 180,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _personalizedJobs.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final job = _personalizedJobs[index];
            return _buildJobCard(job);
          },
        ),
      ),
    ],
  );
}

Widget _buildJobCard(Map<String, dynamic> job) {
  final title = job["title"] ?? "Untitled Job";
  final company = job["company"] ?? "Unknown Company";
  final location = job["location"] ?? "Location not specified";

  return GestureDetector(
    onTap: () {
      // Navigate to detailed job page if needed
    },
    child: Container(
      width: 250,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, spreadRadius: 1),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Text(company, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(location,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const Spacer(),
          Align(
            alignment: Alignment.bottomRight,
            child: ElevatedButton(
              onPressed: () {
                // Apply job
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text("View", style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    ),
  );
}


  /// Application history list
  Widget _buildApplicationHistory() {
  final user = _auth.currentUser;
  if (user == null) return const Text("Not logged in.");

  final availableHeight = MediaQuery.of(context).size.height - kToolbarHeight - 80;

  return StreamBuilder<QuerySnapshot>(
    stream: _firestore
        .collection("job_applications")
        .where("userId", isEqualTo: user.uid)
        .orderBy("appliedAt", descending: true)
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Card(
            elevation: 4,
            color: const Color(0xFFEAF4FF),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(child: Text("Recent Applications", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                      TextButton(onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const JobAppliedPage()));
                      }, child: const Text("View all"))
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Center(child: Text("No job applications yet.")),
                ],
              ),
            ),
          ),
        );
      }

      final applications = snapshot.data!.docs;

      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Card(
          elevation: 4,
          color: const Color(0xFFEAF4FF),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: SizedBox(
            height: availableHeight.clamp(240.0, 720.0),
            child: Column(
              children: [
                // header row with title + view all
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      const Expanded(child: Text("Recent Applications", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JobAppliedPage())),
                        child: const Text("View all"),
                      )
                    ],
                  ),
                ),
                const Divider(height: 0),
                // list
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(8),
                    itemCount: applications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final app = applications[index].data() as Map<String, dynamic>;
                      final jobTitle = (app["jobTitle"] ?? "Unknown Job").toString();
                      final company = (app["company"] ?? "Unknown Company").toString();
                      final status = (app["status"] ?? "Pending").toString();
                      final appliedAtTs = app["appliedAt"];
                      String appliedAtText = "";
                      try {
                        if (appliedAtTs is Timestamp) {
                          final dt = appliedAtTs.toDate().toLocal();
                          appliedAtText = "${dt.year}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')} ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}";
                        } else if (appliedAtTs is String) {
                          appliedAtText = appliedAtTs;
                        }
                      } catch (_) {}

                      // tiny status color
                      Color statusColor;
                      final sLower = status.toLowerCase();
                      if (sLower.contains("pend")) {
                        statusColor = Colors.orange;
                      } else if (sLower.contains("interview") || sLower.contains("accepted") || sLower.contains("hired")) {
                        statusColor = Colors.green;
                      } else if (sLower.contains("reject")) {
                        statusColor = Colors.red;
                      } else {
                        statusColor = Colors.grey;
                      }

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, spreadRadius: 0)],
                        ),
                        child: ListTile(
                          dense: true,
                          leading: const Icon(Icons.work, color: Colors.blue),
                          title: Text(jobTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text("$company • $appliedAtText", style: const TextStyle(fontSize: 12, color: Colors.black54)),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                          onTap: (
                          ) {
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}



  /// Drawer with navigation
  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text("${jobseekerData?['firstName'] ?? ''} ${jobseekerData?['lastName'] ?? ''}"),
            accountEmail: Text(jobseekerData?['email'] ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundImage: (jobseekerData?["profileImageUrl"] ?? "").isNotEmpty
                  ? NetworkImage(jobseekerData!["profileImageUrl"])
                  : null,
              child: (jobseekerData?["profileImageUrl"] ?? "").isEmpty
                  ? const Icon(Icons.person, size: 40)
                  : null,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue, Colors.green],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.work),
            title: const Text("Job Listings"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const JobListingPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text("Jobs Applied"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const JobAppliedPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text("Job Analytics"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AnalyticsPage()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(_isDarkMode ? Icons.dark_mode : Icons.light_mode),
            title: Text(_isDarkMode ? "Light Mode" : "Dark Mode"),
            onTap: _toggleDarkMode,
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Logout"),
            onTap: _confirmLogout,
          ),
        ],
      ),
    );
  }
}
