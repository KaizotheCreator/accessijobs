import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class JobAnalyticsPage extends StatelessWidget {
  const JobAnalyticsPage({super.key});

  Future<Map<String, dynamic>> fetchEmployerAnalytics() async {
    final firestore = FirebaseFirestore.instance;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception("Not logged in");
    }

    // Get employer's UID
    final employerId = user.uid;

    // Fetch jobs that belong to this employer
    final jobsSnapshot = await firestore
        .collection("jobs")
        .where("employerId", isEqualTo: employerId)
        .get();

    int totalJobs = jobsSnapshot.docs.length;
    int totalApplications = 0;
    int totalAccepted = 0;
    int totalRejected = 0;
    int totalPending = 0;

    List<Map<String, dynamic>> jobData = [];

    for (var jobDoc in jobsSnapshot.docs) {
      final jobTitle = jobDoc.data()["title"] ?? "Untitled Job";

      // Count applications (subcollection)
      final applicationsSnapshot =
          await jobDoc.reference.collection("applications").get();

      final applicationsCount = applicationsSnapshot.docs.length;
      int accepted = 0;
      int rejected = 0;
      int pending = 0;

      for (var app in applicationsSnapshot.docs) {
        final status = app.data()["status"] ?? "pending";
        if (status == "accepted") {
          accepted++;
        } else if (status == "rejected") {
          rejected++;
        } else {
          pending++;
        }
      }

      totalApplications += applicationsCount;
      totalAccepted += accepted;
      totalRejected += rejected;
      totalPending += pending;

      jobData.add({
        "title": jobTitle,
        "applications": applicationsCount,
        "accepted": accepted,
        "rejected": rejected,
        "pending": pending,
      });
    }

    return {
      "totalJobs": totalJobs,
      "totalApplications": totalApplications,
      "totalAccepted": totalAccepted,
      "totalRejected": totalRejected,
      "totalPending": totalPending,
      "jobData": jobData,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchEmployerAnalytics(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final data = snapshot.data!;
          final totalJobs = data["totalJobs"] as int;
          final totalApplications = data["totalApplications"] as int;
          final totalAccepted = data["totalAccepted"] as int;
          final totalRejected = data["totalRejected"] as int;
          final totalPending = data["totalPending"] as int;
          final jobData = data["jobData"] as List<Map<String, dynamic>>;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Job Analytics (My Company Only)",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // Summary Cards Row 1
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSummaryCard("Jobs Posted", "$totalJobs",
                        Icons.work_outline, Colors.blue),
                    _buildSummaryCard("Applications", "$totalApplications",
                        Icons.people_alt_outlined, Colors.green),
                  ],
                ),

                const SizedBox(height: 20),

                // Summary Cards Row 2
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSummaryCard("Accepted", "$totalAccepted",
                        Icons.check_circle_outline, Colors.green),
                    _buildSummaryCard("Rejected", "$totalRejected",
                        Icons.cancel_outlined, Colors.red),
                    _buildSummaryCard("Pending", "$totalPending",
                        Icons.hourglass_bottom, Colors.orange),
                  ],
                ),

                const SizedBox(height: 30),
                const Text(
                  "Applications per Job",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Divider(),

                Expanded(
                  child: ListView.builder(
                    itemCount: jobData.length,
                    itemBuilder: (context, index) {
                      final job = jobData[index];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.work,
                              color: Colors.blueAccent),
                          title: Text(job["title"]),
                          subtitle: Text(
                            "Accepted: ${job["accepted"]} | "
                            "Rejected: ${job["rejected"]} | "
                            "Pending: ${job["pending"]}",
                          ),
                          trailing: Text(
                            "${job["applications"]} applied",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 5),
            Text(title,
                style: const TextStyle(fontSize: 14, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}
