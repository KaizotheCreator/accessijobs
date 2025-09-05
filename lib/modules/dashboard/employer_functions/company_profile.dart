import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';

class CompanyProfilePage extends StatefulWidget {
  const CompanyProfilePage({super.key});

  @override
  State<CompanyProfilePage> createState() => _CompanyProfilePageState();
}

class _CompanyProfilePageState extends State<CompanyProfilePage> {
  final user = FirebaseAuth.instance.currentUser;

  // Company Data
  String companyName = "";
  String industry = "";
  String about = "";
  List<String> services = [];
  List<String> achievements = [];
  List<String> certifications = [];
  String headquarters = "";
  String foundedDate = "";
  String employees = "";
  String logoUrl = "";

  bool _loading = true;
  bool _uploadingLogo = false;

  int _totalJobs = 0; // <-- stats value

  @override
  void initState() {
    super.initState();
    _loadCompanyProfile();
    _loadCompanyStats(); // <-- load stats
  }

  Future<void> _loadCompanyProfile() async {
    if (user == null) return;
    final doc =
        await FirebaseFirestore.instance.collection("companies").doc(user!.uid).get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        companyName = data['companyName']?.toString() ?? "My Company";
        industry = data['industry']?.toString() ?? "Industry";
        about = data['about']?.toString() ?? "No description added yet.";
        services = (data['services'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
        achievements = (data['achievements'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
        certifications = (data['certifications'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
        headquarters = data['headquarters']?.toString() ?? "Not set";
        foundedDate = data['foundedDate']?.toString() ?? "Not set";
        employees = data['employees']?.toString() ?? "Not set";
        logoUrl = data['logoUrl']?.toString() ?? "";
        _loading = false;
      });
    } else {
      // Create empty profile if it doesn't exist
      await FirebaseFirestore.instance.collection("companies").doc(user!.uid).set({
        "companyName": "My Company",
        "industry": "Industry",
        "about": "No description added yet.",
        "services": [],
        "achievements": [],
        "certifications": [],
        "headquarters": "",
        "foundedDate": "",
        "employees": "",
        "logoUrl": "",
      });
      setState(() => _loading = false);
    }
  }

  // ✅ Fetch how many jobs the company posted
  Future<void> _loadCompanyStats() async {
    if (user == null) return;
    final jobsSnapshot = await FirebaseFirestore.instance
        .collection("jobs")
        .where("companyId", isEqualTo: user!.uid)
        .get();

    setState(() {
      _totalJobs = jobsSnapshot.size;
    });
  }

  Future<void> _updateField(String field, dynamic value) async {
    if (user == null) return;
    await FirebaseFirestore.instance.collection("companies").doc(user!.uid).update({
      field: value,
    });
  }

  // Upload company logo
  Future<void> _pickLogo() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null) {
        setState(() => _uploadingLogo = true);

        Uint8List fileBytes = result.files.first.bytes!;
        String fileName = "${user!.uid}.jpg";

        final storageRef =
            FirebaseStorage.instance.ref().child("company_logos/$fileName");

        await storageRef.putData(fileBytes);

        String downloadUrl = await storageRef.getDownloadURL();

        await _updateField("logoUrl", downloadUrl);

        setState(() {
          logoUrl = downloadUrl;
          _uploadingLogo = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Company logo updated successfully!')),
        );
      }
    } catch (e) {
      setState(() => _uploadingLogo = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload logo: $e')),
      );
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
              _updateField(field, controller.text);
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

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Company Profile"), centerTitle: true),
      body: Container(
        color: Colors.grey.shade100,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                children: [
                  // Company Header
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
                                backgroundImage: logoUrl.isNotEmpty
                                    ? NetworkImage(logoUrl) as ImageProvider
                                    : const AssetImage('assets/company.png'),
                                child: logoUrl.isEmpty
                                    ? const Icon(Icons.business, size: 50, color: Colors.white)
                                    : null,
                              ),
                              if (_uploadingLogo)
                                CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.camera_alt),
                            label: const Text("Upload Company Logo"),
                            onPressed: _uploadingLogo ? null : _pickLogo,
                          ),
                          const SizedBox(height: 16),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(companyName, style: Theme.of(context).textTheme.headlineSmall),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  _editField("companyName", companyName, (val) => setState(() => companyName = val));
                                },
                              )
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(industry, style: Theme.of(context).textTheme.titleMedium),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  _editField("industry", industry, (val) => setState(() => industry = val));
                                },
                              )
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(child: Text(about, textAlign: TextAlign.center)),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  _editField("about", about, (val) => setState(() => about = val));
                                },
                              )
                            ],
                          ),
                          const SizedBox(height: 16),
                          ListTile(
                            leading: const Icon(Icons.location_city),
                            title: Text("Headquarters: $headquarters"),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                _editField("headquarters", headquarters, (val) => setState(() => headquarters = val));
                              },
                            ),
                          ),
                          ListTile(
                            leading: const Icon(Icons.calendar_today),
                            title: Text("Founded: $foundedDate"),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                _editField("foundedDate", foundedDate, (val) => setState(() => foundedDate = val));
                              },
                            ),
                          ),
                          ListTile(
                            leading: const Icon(Icons.people),
                            title: Text("Employees: $employees"),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                _editField("employees", employees, (val) => setState(() => employees = val));
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  // Services, Achievements, Certifications
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                            child: _buildEditableSection(
                                title: "Services",
                                items: services,
                                firestoreField: "services",
                                onSave: (val) => setState(() => services = val))),
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
                        title: "Services",
                        items: services,
                        firestoreField: "services",
                        onSave: (val) => setState(() => services = val)),
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
                  // ✅ Company Stats Section
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("📊 Company Stats", style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 8),
                          Text("Total Jobs Posted: $_totalJobs",
                              style: Theme.of(context).textTheme.bodyLarge),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
