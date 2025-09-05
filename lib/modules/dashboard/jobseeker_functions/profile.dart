import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

class JobseekerProfilePage extends StatefulWidget {
  const JobseekerProfilePage({super.key});

  @override
  State<JobseekerProfilePage> createState() => _JobseekerProfilePageState();
}

class _JobseekerProfilePageState extends State<JobseekerProfilePage> {
  File? profileImage;
  final picker = ImagePicker();
  final user = FirebaseAuth.instance.currentUser;

  // Profile Data
  String name = "";
  String title = "";
  String bio = "";
  List<String> skills = [];
  List<String> achievements = [];
  List<String> certifications = [];
  List<Map<String, dynamic>> education = [];
  String profileImageUrl = "";

  bool _loading = true;
  bool _uploadingImage = false;

  final List<String> educationLevels = [
    "Elementary",
    "Junior High School",
    "Senior High School",
    "College",
    "Masters"
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
  if (user == null) return;
  final doc = await FirebaseFirestore.instance.collection("users").doc(user!.uid).get();

  if (doc.exists) {
    final data = doc.data()!;
    setState(() {
      name = data['name']?.toString() ?? "John Doe";
      title = data['title']?.toString() ?? "Job Title";
      bio = data['bio']?.toString() ?? "No bio added yet.";
      
      // Use toList() instead of List.from() for safer conversion
      skills = (data['skills'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
      achievements = (data['achievements'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
      certifications = (data['certifications'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
      
      // Fix education list conversion
      education = (data['education'] as List<dynamic>?)?.map((e) {
        final map = e as Map<String, dynamic>;
        return {
          "level": map["level"]?.toString() ?? "",
          "school": map["school"]?.toString() ?? "",
          "degree": map["degree"]?.toString() ?? "",
          "date": map["date"]?.toString() ?? "",
        };
      }).toList() ?? [];
      
      profileImageUrl = data['profileImageUrl']?.toString() ?? "";
      _loading = false;
    });
  } else {
    // Create empty profile if it doesn't exist
    await FirebaseFirestore.instance.collection("users").doc(user!.uid).set({
      "name": "John Doe",
      "title": "Job Title",
      "bio": "No bio added yet.",
      "skills": [],
      "achievements": [],
      "certifications": [],
      "education": [],
      "profileImageUrl": "",
    });
    setState(() => _loading = false);
  }
}

  Future<void> _updateField(String field, dynamic value) async {
    if (user == null) return;
    await FirebaseFirestore.instance.collection("users").doc(user!.uid).update({
      field: value,
    });
  }

  // Fixed image upload method
  Future<void> _pickImage() async {
  try {
    // Pick image (works for web + mobile + desktop)
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null) {
      setState(() => _uploadingImage = true);

      Uint8List fileBytes = result.files.first.bytes!;
      String fileName = "${user!.uid}.jpg";

      // Upload to Firebase Storage
      final storageRef =
          FirebaseStorage.instance.ref().child("profile_pictures/$fileName");

      await storageRef.putData(fileBytes);

      // Get URL
      String downloadUrl = await storageRef.getDownloadURL();

      // Update Firestore
      await _updateField("profileImageUrl", downloadUrl);

      setState(() {
        profileImageUrl = downloadUrl;
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

  void _editField(String field, String currentValue, Function(String) onSave) {
    final controller = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit $field"),
        content: TextField(controller: controller),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              onSave(controller.text);
              _updateField(field.toLowerCase(), controller.text);
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableSection({
    required String title,
    required List<String> items,
    required String firestoreField,
    required Function(List<String>) onSave,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  final controller = TextEditingController(text: items.join(", "));
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text("Edit $title"),
                      content: TextField(
                        controller: controller,
                        decoration: const InputDecoration(hintText: "Separate items with commas"),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                        ElevatedButton(
                          onPressed: () {
                            final updatedList = controller.text.split(",").map((e) => e.trim()).toList();
                            onSave(updatedList);
                            _updateField(firestoreField, updatedList);
                            Navigator.pop(context);
                          },
                          child: const Text("Save"),
                        ),
                      ],
                    ),
                  );
                },
              )
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: items.map((item) => Chip(label: Text(item))).toList(),
          ),
        ]),
      ),
    );
  }

  Widget _buildEducationSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Education", style: Theme.of(context).textTheme.titleLarge),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.blue),
                  onPressed: () {
                    setState(() {
                      education.add({
                        "level": "Elementary",
                        "school": "",
                        "degree": "",
                      });
                    });
                    _updateField("education", education);
                  },
                )
              ],
            ),
            const SizedBox(height: 8),
            Column(
              children: education.asMap().entries.map((entry) {
                int index = entry.key;
                Map<String, dynamic> edu = entry.value;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        DropdownButtonFormField<String>(
                          value: edu["level"],
                          items: educationLevels
                              .map((level) => DropdownMenuItem(value: level, child: Text(level)))
                              .toList(),
                          onChanged: (val) {
                            setState(() {
                              edu["level"] = val!;
                            });
                            _updateField("education", education);
                          },
                          decoration: const InputDecoration(labelText: "Level"),
                        ),
                        TextFormField(
                          initialValue: edu["school"],
                          decoration: const InputDecoration(labelText: "School"),
                          onChanged: (val) {
                            setState(() => edu["school"] = val);
                            _updateField("education", education);
                          },
                        ),
                        TextFormField(
                          initialValue: edu["degree"],
                          decoration: const InputDecoration(labelText: "Degree / Course"),
                          onChanged: (val) {
                            setState(() => edu["degree"] = val);
                            _updateField("education", education);
                          },
                        ),
                        TextFormField(
                          initialValue: edu["date"],
                          decoration: const InputDecoration(labelText: "Date Attended"),
                          onChanged: (val) {
                            setState(() => edu["date"] = val);
                            _updateField("education", education);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("My Profile"), centerTitle: true),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                children: [
                  // Profile Header
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundImage: profileImageUrl.isNotEmpty
                                    ? NetworkImage(profileImageUrl) as ImageProvider
                                    : const AssetImage('assets/profile.png'),
                                child: profileImageUrl.isEmpty
                                    ? const Icon(Icons.person, size: 50, color: Colors.white)
                                    : null,
                              ),
                              if (_uploadingImage)
                                CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.camera_alt),
                            label: const Text("Upload Profile Picture"),
                            onPressed: _uploadingImage ? null : _pickImage,
                          ),
                          const SizedBox(height: 16),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(name, style: Theme.of(context).textTheme.headlineSmall),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  _editField("Name", name, (val) => setState(() => name = val));
                                },
                              )
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(title, style: Theme.of(context).textTheme.titleMedium),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  _editField("Title", title, (val) => setState(() => title = val));
                                },
                              )
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(child: Text(bio, textAlign: TextAlign.center)),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  _editField("Bio", bio, (val) => setState(() => bio = val));
                                },
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  // Skills, Achievements, Certifications
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                            child: _buildEditableSection(
                                title: "Skills",
                                items: skills,
                                firestoreField: "skills",
                                onSave: (val) => setState(() => skills = val))),
                        const SizedBox(width: 16),
                        Expanded(
                            child: _buildEditableSection(
                                title: "Achievements",
                                items: achievements,
                                firestoreField: "achievements",
                                onSave: (val) => setState(() => achievements = val))),
                      ],
                    )
                  else ...[
                    _buildEditableSection(
                        title: "Skills",
                        items: skills,
                        firestoreField: "skills",
                        onSave: (val) => setState(() => skills = val)),
                    _buildEditableSection(
                        title: "Achievements",
                        items: achievements,
                        firestoreField: "achievements",
                        onSave: (val) => setState(() => achievements = val)),
                  ],

                  const SizedBox(height: 16),
                  _buildEditableSection(
                    title: "Certifications",
                    items: certifications,
                    firestoreField: "certifications",
                    onSave: (val) => setState(() => certifications = val),
                  ),

                  const SizedBox(height: 16),
                  _buildEducationSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}