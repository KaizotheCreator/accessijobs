import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';

class JobListingPage extends StatefulWidget {
  const JobListingPage({Key? key}) : super(key: key);

  @override
  State<JobListingPage> createState() => _JobListingPageState();
}

class _JobListingPageState extends State<JobListingPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ScrollController _scrollController = ScrollController();

  String searchQuery = "";

  String? selectedJobType = "All";
  String? selectedCompany = "All";
  String? selectedWorkSetup = "All";

  String? scrollToJobId;
  bool hasScrolled = false;

  final Map<String, String> _addressCache = {};

  final List<String> jobTypes = ["All", "Full-time", "Part-time", "Internship"];
  final List<String> workSetups = ["All", "On-site", "Remote", "Hybrid"];
  final List<String> companies = ["All", "Accessijobs", "Other"];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['scrollToJobId'] != null) {
      scrollToJobId = args['scrollToJobId'];
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _scrollToJob(int index) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        index * 220.0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<String> _getAddressFromLatLng(double lat, double lng, String jobId) async {
  if (_addressCache.containsKey(jobId)) return _addressCache[jobId]!;
  
  try {
    // Ensure proper handling for valid coordinates
    if (lat == 0.0 && lng == 0.0) return "Unknown location";

    final placemarks = await placemarkFromCoordinates(lat, lng);
    if (placemarks.isNotEmpty) {
      final place = placemarks.first;
      final address =
          "${place.street ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}, ${place.country ?? ''}"
              .trim();
      _addressCache[jobId] = address;
      return address;
    } else {
      return "Unknown location";
    }
  } catch (e) {
    print("❌ Geocoding error: $e"); // Debugging log
    return "Unknown location";
  }
}

  Future<bool> _hasAlreadyApplied(String jobId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final applications = await FirebaseFirestore.instance
        .collection('job_applications')
        .where('jobId', isEqualTo: jobId)
        .where('userId', isEqualTo: user.uid)
        .get();

    return applications.docs.isNotEmpty;
  }

  Future<void> _applyForJob(String jobId, Map<String, dynamic> jobData) async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (await _hasAlreadyApplied(jobId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ You have already applied for this job."),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final applicationData = {
      'jobId': jobId,
      'jobTitle': jobData['title'],
      'company': jobData['company'],
      'userId': user.uid,
      'status': 'Pending',
      'appliedAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('jobs')
        .doc(jobId)
        .collection('applications')
        .add(applicationData);

    await FirebaseFirestore.instance.collection('job_applications').add(applicationData);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("✅ Application submitted successfully!"),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Job Listings"),
        backgroundColor: const Color(0xFF1B4D8C),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/jobseeker_dashboard');
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D1B2A), Color(0xFF1B4D8C), Color(0xFF1B4332)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Search jobs...",
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value.toLowerCase();
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        _buildDropdownFilter(
                          label: "Job Type",
                          value: selectedJobType,
                          items: jobTypes,
                          onChanged: (val) => setState(() => selectedJobType = val),
                        ),
                        const SizedBox(width: 8),
                        _buildDropdownFilter(
                          label: "Work Setup",
                          value: selectedWorkSetup,
                          items: workSetups,
                          onChanged: (val) => setState(() => selectedWorkSetup = val),
                        ),
                        const SizedBox(width: 8),
                        _buildDropdownFilter(
                          label: "Company",
                          value: selectedCompany,
                          items: companies,
                          onChanged: (val) => setState(() => selectedCompany = val),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('jobs')
                          .orderBy("createdAt", descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: Colors.white));
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(
                            child: Text(
                              "No jobs available.",
                              style: TextStyle(color: Colors.white),
                            ),
                          );
                        }

                        final jobs = snapshot.data!.docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final title = (data['title'] ?? '').toString().toLowerCase();
                          final company = (data['company'] ?? '').toString();
                          final type = (data['jobType'] ?? '').toString();
                          final setup = (data['workSetup'] ?? '').toString();

                          final matchesSearch = title.contains(searchQuery);
                          final matchesType = (selectedJobType == null || selectedJobType == "All")
                              ? true
                              : type == selectedJobType;
                          final matchesCompany = (selectedCompany == null || selectedCompany == "All")
                              ? true
                              : company == selectedCompany;
                          final matchesSetup = (selectedWorkSetup == null || selectedWorkSetup == "All")
                              ? true
                              : setup == selectedWorkSetup;

                          return matchesSearch && matchesType && matchesCompany && matchesSetup;
                        }).toList();

                        if (jobs.isEmpty) {
                          return const Center(
                            child: Text(
                              "No jobs found with the applied filters.",
                              style: TextStyle(color: Colors.white70),
                            ),
                          );
                        }

                        if (scrollToJobId != null && !hasScrolled) {
                          final index = jobs.indexWhere((doc) => doc.id == scrollToJobId);
                          if (index != -1) {
                            hasScrolled = true;
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _scrollToJob(index);
                            });
                          }
                        }

                        return ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(8),
                          itemCount: jobs.length,
                          itemBuilder: (context, index) {
                            final jobDoc = jobs[index];
                            final job = jobDoc.data() as Map<String, dynamic>;

                            return FutureBuilder<bool>(
                              future: _hasAlreadyApplied(jobDoc.id),
                              builder: (context, snapshot) {
                                final hasApplied = snapshot.data ?? false;
                                return _buildLinkedInStyleCard(
                                  context,
                                  jobDoc.id,
                                  job,
                                  hasApplied,
                                  highlight: jobDoc.id == scrollToJobId,
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownFilter({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButton<String>(
      value: value,
      dropdownColor: Colors.white,
      style: const TextStyle(color: Colors.black),
      items: items.map((item) {
        return DropdownMenuItem(value: item, child: Text(item));
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildLinkedInStyleCard(
    BuildContext context,
    String jobId,
    Map<String, dynamic> job,
    bool hasApplied, {
    bool highlight = false,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      color: highlight ? Colors.yellow.shade100 : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job['title'] ?? "Untitled",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      job['company'] ?? "Unknown Company",
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
                Icon(Icons.work_outline, color: Colors.blue.shade700),
              ],
            ),
            const SizedBox(height: 8),

            Text(
              job['description'] ?? "No description available.",
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),

            if (job['lat'] != null && job['lng'] != null)
              FutureBuilder<String>(
                future: _getAddressFromLatLng(job['lat'], job['lng'], jobId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text(
                      "Fetching location...",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    );
                  }
                  return Text(
                    snapshot.data ?? "Unknown location",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  );
                },
              ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => JobDetailsPage(
                          jobId: jobId,
                          jobData: job,
                          getAddressFromLatLng: _getAddressFromLatLng,
                        ),
                      ),
                    );
                  },
                  child: const Text("More Details"),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: hasApplied ? null : () => _applyForJob(jobId, job),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                  child: Text(hasApplied ? "Applied" : "Apply"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class JobDetailsPage extends StatelessWidget {
  final String jobId;
  final Map<String, dynamic> jobData;
  final Future<String> Function(double, double, String) getAddressFromLatLng;

  const JobDetailsPage({
    Key? key,
    required this.jobId,
    required this.jobData,
    required this.getAddressFromLatLng,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double? lat = jobData['lat'];
    final double? lng = jobData['lng'];

    final dynamic salary = jobData['salary'];
    final String salaryText =
        (salary != null && salary.toString().trim().isNotEmpty)
            ? "PHP ${salary.toString()}"
            : "Not Disclosed";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Job Details"),
        backgroundColor: const Color(0xFF1B4D8C),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D1B2A), Color(0xFF1B4D8C), Color(0xFF1B4332)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      jobData['title'] ?? "Untitled",
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      jobData['company'] ?? "Unknown Company",
                      style: const TextStyle(fontSize: 18, color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      jobData['description'] ?? "No description provided.",
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text("Job Type: ${jobData['jobType'] ?? 'N/A'}",
                        style: const TextStyle(color: Colors.white)),
                    Text("Work Setup: ${jobData['workSetup'] ?? 'N/A'}",
                        style: const TextStyle(color: Colors.white)),
                    Text("Time: ${jobData['time'] ?? 'N/A'}",
                        style: const TextStyle(color: Colors.white)),
                    const SizedBox(height: 8),
                    Text(
                      "Salary: $salaryText",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                    ),
                    const SizedBox(height: 16),
                    lat != null && lng != null
                        ? FutureBuilder<String>(
                            future: getAddressFromLatLng(lat, lng, jobId),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Text(
                                  "Fetching location...",
                                  style: TextStyle(fontSize: 14, color: Colors.white70),
                                );
                              }
                              return Text(
                                "Location: ${snapshot.data}",
                                style: const TextStyle(fontSize: 14, color: Colors.white),
                              );
                            },
                          )
                        : const Text(
                            "Location: Not available",
                            style: TextStyle(color: Colors.white),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
