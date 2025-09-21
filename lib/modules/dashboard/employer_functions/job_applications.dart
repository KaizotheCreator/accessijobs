import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class JobApplicationsPage extends StatelessWidget {
  const JobApplicationsPage({Key? key}) : super(key: key);

  final Color backgroundTop = const Color(0xFF0D1B2A);
  final Color backgroundBottom = const Color(0xFF1B4332);

  /// ✅ Update the application status in both collections
  Future<void> updateApplicationStatus({
    required String jobId,
    required String applicationId,
    required String newStatus,
    required String applicantId,
  }) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      // Update in job subcollection
      final jobAppRef = firestore
          .collection('jobs')
          .doc(jobId)
          .collection('applications')
          .doc(applicationId);
      batch.update(jobAppRef, {'status': newStatus});

      // Update in global job_applications collection
      final globalAppRef = firestore.collection('job_applications').doc(applicationId);
      batch.update(globalAppRef, {'status': newStatus});

      await batch.commit();
      debugPrint("✅ Status updated to $newStatus for $applicationId");
    } catch (e) {
      debugPrint("❌ Error updating status: $e");
    }
  }

  /// ✅ Delete a job and all its applications
  Future<void> deleteJob(String jobId) async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Delete applications inside the job
      final appsSnapshot = await firestore
          .collection('jobs')
          .doc(jobId)
          .collection('applications')
          .get();
      for (var doc in appsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete the job document
      await firestore.collection('jobs').doc(jobId).delete();

      debugPrint("🗑️ Job deleted successfully: $jobId");
    } catch (e) {
      debugPrint("❌ Error deleting job: $e");
    }
  }

  /// Count online users
  Stream<int> _onlineUsersStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .where('isOnline', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [backgroundTop, backgroundBottom],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 🔹 Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Job Applications",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    StreamBuilder<int>(
                      stream: _onlineUsersStream(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox();
                        return Row(
                          children: [
                            const Icon(Icons.circle, color: Colors.green, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              "${snapshot.data} online",
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white24, thickness: 1),

              // 🔹 Jobs List
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('jobs')
                      .where('postedBy', isEqualTo: currentUserId)
                      .snapshots(),
                  builder: (context, jobSnapshot) {
                    if (jobSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.white));
                    }

                    if (!jobSnapshot.hasData || jobSnapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                          "You haven't posted any jobs yet.",
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      );
                    }

                    final jobs = jobSnapshot.data!.docs;

                    return ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: jobs.length,
                      itemBuilder: (context, jobIndex) {
                        final jobDoc = jobs[jobIndex];
                        final jobId = jobDoc.id;
                        final jobData = jobDoc.data() as Map<String, dynamic>;

                        final title = jobData['title'] ?? 'Untitled Job';
                        final description = jobData['description'] ?? 'No description';

                        return Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          color: Colors.white.withOpacity(0.95),
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            title: Text(
                              title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A)),
                            ),
                            subtitle: Text(
                              description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  // TODO: Implement edit job functionality
                                  debugPrint("✏️ Edit job: $jobId");
                                } else if (value == 'delete') {
                                  deleteJob(jobId);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit'),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete'),
                                ),
                              ],
                            ),

                            // 🔹 Nested Applications List
                            children: [
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('jobs')
                                    .doc(jobId)
                                    .collection('applications')
                                    .orderBy('createdAt', descending: true)
                                    .snapshots(),
                                builder: (context, appSnapshot) {
                                  if (appSnapshot.connectionState == ConnectionState.waiting) {
                                    return const Padding(
                                      padding: EdgeInsets.all(12.0),
                                      child: Center(child: CircularProgressIndicator()),
                                    );
                                  }

                                  if (!appSnapshot.hasData || appSnapshot.data!.docs.isEmpty) {
                                    return const Padding(
                                      padding: EdgeInsets.all(12.0),
                                      child: Text("No applications yet."),
                                    );
                                  }

                                  final applications = appSnapshot.data!.docs;

                                  return Column(
                                    children: applications.map((appDoc) {
                                      final appData = appDoc.data() as Map<String, dynamic>;
                                      final applicantId = appData['applicantId'] ?? 'Unknown';
                                      final status = appData['status'] ?? 'pending';
                                      final createdAt = appData['createdAt'] != null
                                          ? (appData['createdAt'] as Timestamp).toDate()
                                          : null;

                                      return FutureBuilder<DocumentSnapshot>(
                                        future: FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(applicantId)
                                            .get(),
                                        builder: (context, userSnapshot) {
                                          if (!userSnapshot.hasData ||
                                              !userSnapshot.data!.exists) {
                                            return const ListTile(
                                              title: Text("Applicant profile not found"),
                                            );
                                          }

                                          final userData = userSnapshot.data!.data()
                                              as Map<String, dynamic>;
                                          final fullName =
                                              "${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}".trim();
                                          final phone = userData['contactNumber'] ?? 'N/A';
                                          final profilePic =
                                              userData['profileImageUrl'] ?? '';

                                          return ListTile(
                                            leading: CircleAvatar(
                                              backgroundImage: profilePic.isNotEmpty
                                                  ? NetworkImage(profilePic)
                                                  : null,
                                              child: profilePic.isEmpty
                                                  ? const Icon(Icons.person)
                                                  : null,
                                            ),
                                            title: Text(fullName),
                                            subtitle: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text("Phone: $phone"),
                                                Text(
                                                  "Applied: ${createdAt != null ? createdAt.toLocal().toString().split(' ')[0] : 'Unknown'}",
                                                ),
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
                                                  updateApplicationStatus(
                                                    jobId: jobId,
                                                    applicationId: appDoc.id,
                                                    newStatus: value,
                                                    applicantId: applicantId,
                                                  );
                                                }
                                              },
                                            ),
                                          );
                                        },
                                      );
                                    }).toList(),
                                  );
                                },
                              ),
                            ],
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
}
