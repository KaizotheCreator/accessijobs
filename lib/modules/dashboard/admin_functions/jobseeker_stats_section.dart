import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class JobseekerStatsSection extends StatelessWidget {
  const JobseekerStatsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('jobseekers').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No jobseekers found."));
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return Card(
              child: ListTile(
                leading: const Icon(Icons.person, color: Colors.blue),
                title: Text(data['name'] ?? "Unknown"),
                subtitle: Text(data['email'] ?? ""),
                trailing: Text(
                  data['status'] ?? "active",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
