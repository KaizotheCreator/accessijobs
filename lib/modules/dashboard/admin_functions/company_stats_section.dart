import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CompanyStatsSection extends StatelessWidget {
  final String? employerId; // optional: if null, fetch global stats for admin

  const CompanyStatsSection({super.key, this.employerId});

  Future<Map<String, int>> _fetchStats() async {
    final firestore = FirebaseFirestore.instance;

    int totalJobs = 0;
    int totalApplications = 0;
    int totalEmployees = 0;
    int activeJobs = 0;

    // --- JOBS COUNT ---
    Query jobsQuery = firestore.collection("jobs");
    if (employerId != null) {
      jobsQuery = jobsQuery.where("employerId", isEqualTo: employerId);
    }
    final jobsSnap = await jobsQuery.count().get();
    totalJobs = jobsSnap.count ?? 0;

    // --- ACTIVE JOBS COUNT ---
    Query activeJobsQuery = firestore.collection("jobs").where("status", isEqualTo: "active");
    if (employerId != null) {
      activeJobsQuery = activeJobsQuery.where("employerId", isEqualTo: employerId);
    }
    final activeJobsSnap = await activeJobsQuery.count().get();
    activeJobs = activeJobsSnap.count ?? 0;

    // --- APPLICATIONS COUNT ---
    Query appsQuery = firestore.collection("applications");
    if (employerId != null) {
      appsQuery = appsQuery.where("employerId", isEqualTo: employerId);
    }
    final appsSnap = await appsQuery.count().get();
    totalApplications = appsSnap.count ?? 0;

    // --- EMPLOYEES COUNT ---
    Query employeesQuery = firestore.collection("users");
    if (employerId != null) {
      employeesQuery = employeesQuery.where("companyId", isEqualTo: employerId);
    }
    final employeesSnap = await employeesQuery.count().get();
    totalEmployees = employeesSnap.count ?? 0;

    return {
      "totalJobs": totalJobs,
      "totalApplications": totalApplications,
      "totalEmployees": totalEmployees,
      "activeJobs": activeJobs,
    };
  }

  Widget _buildCard(String title, String value, IconData icon, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Container(
        width: 160,
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: _fetchStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        final stats = snapshot.data ?? {
          "totalJobs": 0,
          "totalApplications": 0,
          "totalEmployees": 0,
          "activeJobs": 0,
        };

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: [
            _buildCard("Jobs Posted", "${stats["totalJobs"]}", Icons.work, Colors.blue),
            _buildCard("Applications", "${stats["totalApplications"]}", Icons.people, Colors.green),
            _buildCard("Employees", "${stats["totalEmployees"]}", Icons.group, Colors.orange),
            _buildCard("Active Jobs", "${stats["activeJobs"]}", Icons.check_circle, Colors.purple),
          ],
        );
      },
    );
  }
}
