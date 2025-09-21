import 'package:flutter/material.dart';

class RecommendedJobsPage extends StatelessWidget {
  final List<Map<String, dynamic>> jobs;

  const RecommendedJobsPage({Key? key, required this.jobs}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F2EF),
      appBar: AppBar(
        title: const Text(
          "Recommended Jobs",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[800],
        elevation: 0,
      ),
      body: jobs.isEmpty
          ? const Center(
              child: Text(
                "No job recommendations found.",
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: jobs.length,
              itemBuilder: (context, index) {
                final job = jobs[index];

                // ✅ Firestore doc.id is required for navigation
                final jobId = job['id'] ?? job['jobId'];
                final title = job['title'] ?? 'Untitled Job';
                final company = job['company'] ?? 'Unknown Company';
                final location = job['location'] ?? 'No location specified';
                final description =
                    job['description'] ?? 'No description available.';
                final salary = job['salary'] ?? '';
                final companyLogo = job['companyLogo'];

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Job title and company
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.grey[300],
                              backgroundImage:
                                  companyLogo != null ? NetworkImage(companyLogo) : null,
                              child: companyLogo == null
                                  ? const Icon(Icons.business, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 12),

                            // Title and company
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    company,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    location,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Description snippet
                        Text(
                          description.length > 120
                              ? '${description.substring(0, 120)}...'
                              : description,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Salary (only if available)
                        if (salary.isNotEmpty)
                          Text(
                            "Salary: $salary",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),

                        const SizedBox(height: 12),

                        // Apply button
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[800],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              if (jobId == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Error: Job ID not found."),
                                  ),
                                );
                                return;
                              }

                              // ✅ Navigate to JobListing and scroll to exact job
                              Navigator.pushNamed(
                                context,
                                '/job_listing',
                                arguments: {
                                  'scrollToJobId': jobId,
                                },
                              );
                            },
                            child: const Text("Apply"),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
