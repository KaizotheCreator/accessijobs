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

    Query jobsQuery = firestore.collection("jobs");

    // If employerId is provided → company stats
    if (employerId != null) {
      jobsQuery = jobsQuery.where("employerId", isEqualTo: employerId);
    }

    final jobsSnapshot = await jobsQuery.get();
    totalJobs = jobsSnapshot.docs.length;

    for (var jobDoc in jobsSnapshot.docs) {
  final jobData = jobDoc.data() as Map<String, dynamic>;

  final appsSnapshot =
      await jobDoc.reference.collection("applications").get();
  totalApplications += appsSnapshot.size;

  if ((jobData["status"] ?? "") == "active") {
    activeJobs++;
  }
}

    // Employees collection (optional: store companyId on user docs)
    if (employerId != null) {
      final employeesSnapshot = await firestore
          .collection("users")
          .where("companyId", isEqualTo: employerId)
          .get();
      totalEmployees = employeesSnapshot.size;
    } else {
      final employeesSnapshot = await firestore.collection("users").get();
      totalEmployees = employeesSnapshot.size;
    }

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
