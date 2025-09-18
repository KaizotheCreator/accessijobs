import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class JobAppliedPage extends StatelessWidget {
  const JobAppliedPage({super.key});

  // Stream to fetch the logged-in user's job applications
  Stream<QuerySnapshot<Map<String, dynamic>>> _applicationsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('job_applications')
        .where('userId', isEqualTo: user.uid)
        .orderBy('appliedAt', descending: true)
        .snapshots();
  }

  // Format Firestore Timestamp into readable date
  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return "Unknown";
    try {
      final date = timestamp.toDate();
      return DateFormat('yyyy-MM-dd').format(date);
    } catch (_) {
      return "Invalid date";
    }
  }

  // Dynamic color for status
  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case "accepted":
        return Colors.green.shade600;
      case "rejected":
        return Colors.red.shade600;
      case "pending":
        return Colors.orange.shade600;
      case "reviewing":
        return Colors.blue.shade600;
      default:
        return Colors.blueGrey.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Gradient background
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D1B2A), Color(0xFF1B4332)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Gradient App Bar
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF56CCF2), Color(0xFF2F9E44), Color(0xFFF9D423)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  title: const Text(
                    "Jobs Applied",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  centerTitle: true,
                  automaticallyImplyLeading: true,
                  iconTheme: const IconThemeData(color: Colors.white),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _applicationsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          "Error: ${snapshot.error}",
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return const Center(
                        child: Text(
                          "You have not applied to any jobs yet.",
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data();

                        final jobTitle = data['jobTitle'] ?? "Untitled";
                        final company = data['company'] ?? "Unknown Company";
                        final appliedAt = data['appliedAt'] as Timestamp?;
                        final status = data['status'] ?? "Pending";
                        final jobId = data['jobId'];

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => JobDetailsPage(
                                  jobId: jobId,
                                  applicationData: data,
                                ),
                              ),
                            );
                          },
                          child: _buildApplicationCard(
                            jobTitle: jobTitle,
                            company: company,
                            status: status,
                            appliedAt: appliedAt,
                          ),
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
    );
  }

  // Custom card UI
  Widget _buildApplicationCard({
    required String jobTitle,
    required String company,
    required String status,
    required Timestamp? appliedAt,
  }) {
    return Stack(
      children: [
        // Main Card
        Card(
          margin: const EdgeInsets.symmetric(vertical: 10),
          color: Colors.white.withOpacity(0.95),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 6,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Job Details Section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        jobTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D1B2A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        company,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Applied on: ${_formatDate(appliedAt)}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Status Badge positioned outside the card
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _statusColor(status),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(12),
              ),
            ),
            child: Text(
              status,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Job Details Page
class JobDetailsPage extends StatelessWidget {
  final String jobId;
  final Map<String, dynamic> applicationData;

  const JobDetailsPage({
    super.key,
    required this.jobId,
    required this.applicationData,
  });

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return "Unknown";
    final date = timestamp.toDate();
    return DateFormat('yyyy-MM-dd').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('jobs').doc(jobId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: Text("Job details not found")),
          );
        }

        final jobData = snapshot.data!.data() as Map<String, dynamic>;

        return Scaffold(
          appBar: AppBar(
            title: const Text("Job Details"),
            backgroundColor: const Color(0xFF2F9E44),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                Text(
                  jobData['title'] ?? "Untitled",
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  "Company: ${jobData['company'] ?? "Unknown"}",
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  "Status: ${applicationData['status'] ?? "Pending"}",
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 8),
                Text(
                  "Applied On: ${_formatDate(applicationData['appliedAt'] as Timestamp?)}",
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const Divider(height: 30),
                const Text(
                  "Job Description",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  jobData['description'] ?? "No description available.",
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Additional Details",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text("Job Type: ${jobData['jobType'] ?? 'N/A'}"),
                Text("Work Setup: ${jobData['workSetup'] ?? 'N/A'}"),
                Text("Location: ${jobData['location'] ?? 'N/A'}"),
                Text("Time: ${jobData['time'] ?? 'N/A'}"),
              ],
            ),
          ),
        );
      },
    );
  }
}
