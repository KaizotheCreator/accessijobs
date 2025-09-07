import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class JobseekerProfile extends StatefulWidget {
  const JobseekerProfile({super.key});

  @override
  State<JobseekerProfile> createState() => _JobseekerProfileState();
}

class _JobseekerProfileState extends State<JobseekerProfile> {
  final fb_auth.User? user = fb_auth.FirebaseAuth.instance.currentUser; // ✅ Single user instance
  String profileImageUrl = "";
  String name = "The Jobseeker";
  String title = "The Creator";
  String bio = "asd";
  List<String> skills = ["wala"];
  List<String> achievements = ["wala na naman"];
  List<String> certifications = ["solid wala"];
  bool _uploadingImage = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection("jobseeker_profiles")
          .doc(user!.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          profileImageUrl = data['profileImageUrl']?.toString().isNotEmpty == true
              ? "${data['profileImageUrl']}?t=${DateTime.now().millisecondsSinceEpoch}"
              : "";
          name = data['name'] ?? "The Jobseeker";
          title = data['title'] ?? "The Creator";
          bio = data['bio'] ?? "asd";
          skills = List<String>.from(data['skills'] ?? ["wala"]);
          achievements = List<String>.from(data['achievements'] ?? ["wala na naman"]);
          certifications = List<String>.from(data['certifications'] ?? ["solid wala"]);
        });
      }
    } catch (e) {
      print("Error loading profile: $e");
    }
  }

Future<void> _pickImage() async {
  try {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null && user != null) {
      setState(() => _uploadingImage = true);

      final filePath = result.files.single.path;
      if (filePath == null) throw Exception("File path is null");

      final file = File(filePath); // ✅ use File, not bytes
      final fileName = "${user!.uid}.jpg";
      final supabase = Supabase.instance.client;

      // 1️⃣ Upload (with upsert so it replaces old image)
      await supabase.storage.from("profile_pictures").upload(
            fileName,
            file,
            fileOptions: const FileOptions(upsert: true),
          );

      // 2️⃣ ✅ Get official Supabase public URL
      final publicUrl =
          supabase.storage.from("profile_pictures").getPublicUrl(fileName);

      // 3️⃣ Bust cache for UI reload
      final cacheBustedUrl =
          "$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}";

      // 4️⃣ Save clean URL to Firestore
      await _updateField("profileImageUrl", publicUrl);

      setState(() {
        profileImageUrl = cacheBustedUrl;
        _uploadingImage = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture updated successfully!')),
      );
    }
  } catch (e) {
    setState(() => _uploadingImage = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to upload image: $e')),
    );
    print("Error uploading image: $e");
  }
}

  Future<void> _updateField(String field, dynamic value) async {
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection("jobseeker_profiles")
        .doc(user!.uid)
        .set({field: value}, SetOptions(merge: true));
  }

  void _editListField(String title, List<String> currentValues, String firestoreField) {
    final controller = TextEditingController(text: currentValues.join(", "));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit $title"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "Separate items with commas",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final updatedList = controller.text
                  .split(",")
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();

              setState(() {
                if (firestoreField == "skills") skills = updatedList;
                if (firestoreField == "achievements") achievements = updatedList;
                if (firestoreField == "certifications") certifications = updatedList;
              });

              _updateField(firestoreField, updatedList);
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: profileImageUrl.isNotEmpty
                  ? NetworkImage(profileImageUrl)
                  : null,
              child: profileImageUrl.isEmpty
                  ? const Icon(Icons.person, size: 50)
                  : null,
            ),
            const SizedBox(height: 10),
            _uploadingImage
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Upload Profile Picture"),
                  ),
            const SizedBox(height: 20),
            Text(name, style: Theme.of(context).textTheme.titleLarge),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            Text(bio, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 20),
            _buildEditableSection("Skills", skills, "skills"),
            _buildEditableSection("Achievements", achievements, "achievements"),
            _buildEditableSection("Certifications", certifications, "certifications"),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableSection(String title, List<String> items, String firestoreField) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium!
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editListField(title, items, firestoreField),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: items.map((e) => Chip(label: Text(e))).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
