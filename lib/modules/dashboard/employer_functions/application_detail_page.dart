import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ApplicationDetailPage extends StatelessWidget {
  final Map<String, dynamic> applicantData;
  final Map<String, dynamic> applicationData;
  final String applicationId;

  const ApplicationDetailPage({
    Key? key,
    required this.applicantData,
    required this.applicationData,
    required this.applicationId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final profilePic = applicantData['profileImageUrl'] ?? "https://via.placeholder.com/150";
    final firstName = applicantData['firstName'] ?? "Unknown";
    final lastName = applicantData['lastName'] ?? "";
    final contactNumber = applicantData['contactNumber'] ?? "N/A";
    final email = applicantData['email'] ?? "N/A";
    final bio = applicantData['bio'] ?? "No bio provided";

    final jobTitle = applicationData['title'] ?? "Untitled Job";
    final company = applicationData['company'] ?? "Unknown Company";
    final description = applicationData['description'] ?? "No description available.";
    final workSetup = applicationData['workSetup'] ?? "N/A";
    final jobType = applicationData['jobType'] ?? "N/A";
    final time = applicationData['time'] ?? "N/A";
    final location = applicationData['location'] ?? "N/A";
    final status = applicationData['status'] ?? "pending";

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D1B2A), Color(0xFF1B4332)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile Section
                CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(profilePic),
                ),
                const SizedBox(height: 16),
                Text(
                  "$firstName $lastName",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text("Phone: $contactNumber", style: const TextStyle(color: Colors.white70)),
                Text("Email: $email", style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 10),
                Text(
                  bio,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const Divider(color: Colors.white38, height: 40),

                // Job Details
                Card(
                  color: Colors.white.withOpacity(0.9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 6,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          jobTitle,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D1B2A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text("Company: $company", style: const TextStyle(fontSize: 16)),
                        Text("Job Type: $jobType"),
                        Text("Work Setup: $workSetup"),
                        Text("Time: $time"),
                        Text("Location: $location"),
                        const SizedBox(height: 10),
                        Text(
                          "Status: ${status[0].toUpperCase()}${status.substring(1)}",
                          style: TextStyle(
                            fontSize: 14,
                            color: status == "accepted"
                                ? Colors.green
                                : status == "rejected"
                                    ? Colors.red
                                    : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          description,
                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
