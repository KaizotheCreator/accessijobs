import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class JobApplicationsPage extends StatelessWidget {
  final String jobId;

  const JobApplicationsPage({Key? key, required this.jobId}) : super(key: key);

  // Function to update application status
  Future<void> updateApplicationStatus(
      String applicationId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('jobs')
          .doc(jobId)
          .collection('applications')
          .doc(applicationId)
          .update({'status': newStatus});

      debugPrint("✅ Status updated to $newStatus");
    } catch (e) {
      debugPrint("❌ Error updating status: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Job Applications"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('jobs')
            .doc(jobId)
            .collection('applications')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No applications yet."),
            );
          }

          final applications = snapshot.data!.docs;

          return ListView.builder(
            itemCount: applications.length,
            itemBuilder: (context, index) {
              final appDoc = applications[index];
              final data = appDoc.data() as Map<String, dynamic>;

              final applicantId = data['applicantId'] ?? "Unknown";
              final status = data['status'] ?? "pending";
              final createdAt = data['createdAt'] != null
                  ? (data['createdAt'] as Timestamp).toDate()
                  : null;

              // 🔥 Fetch user profile from "users" collection
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(applicantId)
                    .get(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const ListTile(
                      leading: CircularProgressIndicator(),
                      title: Text("Loading applicant..."),
                    );
                  }

                  if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                    return ListTile(
                      leading: const Icon(Icons.person),
                      title: Text("Applicant: $applicantId"),
                      subtitle: const Text("Profile not found"),
                    );
                  }

                  final userData =
                      userSnapshot.data!.data() as Map<String, dynamic>;
                  final name = userData['name'] ?? "Unknown";
                  final phone = userData['phone'] ?? "N/A";
                  final resumeUrl = userData['resume'] ?? null;

                  return Card(
                    margin: const EdgeInsets.all(8),
                    child: ListTile(
                      leading: const Icon(Icons.person, size: 40),
                      title: Text(name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Phone: $phone"),
                          Text(
                            "Applied on: ${createdAt != null ? createdAt.toLocal().toString().split(' ')[0] : 'Unknown'}",
                          ),
                          if (resumeUrl != null)
                            Text("📄 Resume available"),
                        ],
                      ),
                      trailing: DropdownButton<String>(
                        value: status,
                        items: ["pending", "reviewing", "accepted", "rejected"]
                            .map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            updateApplicationStatus(appDoc.id, value);
                          }
                        },
                      ),
                      onTap: () {
                        if (resumeUrl != null) {
                          // open resume (e.g., launch PDF link)
                          debugPrint("📄 Open resume: $resumeUrl");
                        }
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
