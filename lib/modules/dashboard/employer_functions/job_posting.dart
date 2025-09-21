import 'dart:io';
import 'package:accessijobs/modules/dashboard/shared_functions/interactive_map.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class JobPostingModule extends StatefulWidget {
  const JobPostingModule({super.key});

  @override
  State<JobPostingModule> createState() => _JobPostingModuleState();
}

class _JobPostingModuleState extends State<JobPostingModule> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _salaryController = TextEditingController();
  final TextEditingController _benefitsController = TextEditingController();

  // Time Pickers
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  // Coordinates
  double? _lat;
  double? _lng;

  // Dropdown values
  String? _selectedJobType;
  String? _selectedWorkSetup;

  // Company details
  String? _companyName;
  String? _companyId;

  // Salary
  bool _isSalaryDisclosed = true;

  // Aptitude test
  final List<TextEditingController> _questionControllers = [];

  @override
  void initState() {
    super.initState();
    _fetchCompanyDetails();
    _addNewQuestion();
  }

  /// Fetch company name and companyId based on logged-in employer
  Future<void> _fetchCompanyDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('companies')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        setState(() {
          _companyName = doc['companyName'] ?? "Unknown Company";
          _companyId = doc.id; // Employer UID is also companyId
        });
      }
    }
  }

  void _addNewQuestion() {
    setState(() {
      _questionControllers.add(TextEditingController());
    });
  }

  /// Post a new job
  Future<void> _postJob() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_formKey.currentState!.validate()) {
      if (_lat == null || _lng == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("📍 Please select a location on the map")),
        );
        return;
      }

      if (_selectedJobType == null || _selectedWorkSetup == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠️ Please select job type and work setup")),
        );
        return;
      }

      if (_startTime == null || _endTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("🕒 Please select both start and end time")),
        );
        return;
      }

      final List<String> aptitudeQuestions = [];
      for (final controller in _questionControllers) {
        final text = controller.text.trim();
        if (text.isNotEmpty) {
          if (RegExp(r'[0-9]').hasMatch(text)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("❌ Aptitude questions cannot contain numbers.")),
            );
            return;
          }
          aptitudeQuestions.add(text);
        }
      }

      final timeRange =
          "${_startTime!.format(context)} - ${_endTime!.format(context)}";

      // 🔹 Generate jobId first
      final jobRef = FirebaseFirestore.instance.collection('jobs').doc();
      final jobId = jobRef.id;

      await jobRef.set({
        'jobId': jobId,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'location': "Lat: ${_lat?.toStringAsFixed(5)}, Lng: ${_lng?.toStringAsFixed(5)}",
        'lat': _lat,
        'lng': _lng,
        'time': timeRange,
        'salary': _isSalaryDisclosed ? "PHP ${_salaryController.text.trim()}" : "Not Disclosed",
        'benefits': _benefitsController.text.trim(),
        'aptitudeQuestions': aptitudeQuestions,
        'jobType': _selectedJobType,
        'workSetup': _selectedWorkSetup,
        'company': _companyName ?? "Unknown Company",
        'companyId': _companyId,
        'postedBy': user.uid, // 🔹 Updated field
        'createdAt': FieldValue.serverTimestamp(),
        'applicationCount': 0,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Job posted successfully!")),
      );

      // Clear form
      _titleController.clear();
      _descriptionController.clear();
      _locationController.clear();
      _salaryController.clear();
      _benefitsController.clear();
      for (var controller in _questionControllers) {
        controller.clear();
      }
      _lat = null;
      _lng = null;
      _selectedJobType = null;
      _selectedWorkSetup = null;
      _startTime = null;
      _endTime = null;
      _isSalaryDisclosed = true;

      setState(() {});
    }
  }

  /// Open the interactive map to select a location
  Future<void> _pickLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const InteractiveMap(mode: MapMode.pickLocation),
      ),
    );

    if (result != null && result is Map<String, double>) {
      setState(() {
        _lat = result['lat'];
        _lng = result['lng'];
        _locationController.text =
            "Lat: ${_lat!.toStringAsFixed(4)}, Lng: ${_lng!.toStringAsFixed(4)}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF001F54), // Dark Blue
              Color(0xFF0077B6), // Light Blue
              Color(0xFF00FF87), // Green
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  children: [
                    // 👔 Company Name
                    if (_companyName != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          "👔 Company: $_companyName",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    Expanded(
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          // Job Posting Form
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                _buildHoverInput(
                                  controller: _titleController,
                                  label: "Job Title",
                                  icon: Icons.work_outline,
                                  validator: "Please enter a valid job title",
                                ),
                                const SizedBox(height: 10),
                                _buildHoverInput(
                                  controller: _descriptionController,
                                  label: "Job Description",
                                  icon: Icons.description_outlined,
                                  maxLines: 3,
                                  validator: "Please enter a valid description",
                                ),
                                const SizedBox(height: 10),

                                // Start and End Time
                                Row(
                                  children: [
                                    Expanded(
                                      child: ListTile(
                                        leading: const Icon(Icons.access_time),
                                        title: Text(
                                          _startTime == null
                                              ? "Start Time"
                                              : "Start: ${_startTime!.format(context)}",
                                          style: const TextStyle(color: Colors.white),
                                        ),
                                        onTap: () async {
                                          final picked = await showTimePicker(
                                            context: context,
                                            initialTime: _startTime ?? TimeOfDay.now(),
                                          );
                                          if (picked != null) {
                                            setState(() {
                                              _startTime = picked;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                    Expanded(
                                      child: ListTile(
                                        leading: const Icon(Icons.access_time_filled),
                                        title: Text(
                                          _endTime == null
                                              ? "End Time"
                                              : "End: ${_endTime!.format(context)}",
                                          style: const TextStyle(color: Colors.white),
                                        ),
                                        onTap: () async {
                                          final picked = await showTimePicker(
                                            context: context,
                                            initialTime: _endTime ?? TimeOfDay.now(),
                                          );
                                          if (picked != null) {
                                            setState(() {
                                              _endTime = picked;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                // Location Picker
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14, horizontal: 24),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    backgroundColor: Colors.blueAccent,
                                  ),
                                  icon: const Icon(Icons.map, color: Colors.white),
                                  label: Text(
                                    _lat != null && _lng != null
                                        ? "Location Selected (Lat: ${_lat!.toStringAsFixed(4)}, Lng: ${_lng!.toStringAsFixed(4)})"
                                        : "Pick Location",
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  onPressed: _pickLocation,
                                ),
                                const SizedBox(height: 10),

                                SwitchListTile(
                                  title: const Text(
                                    "Disclose Salary",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  value: _isSalaryDisclosed,
                                  onChanged: (value) {
                                    setState(() {
                                      _isSalaryDisclosed = value;
                                    });
                                  },
                                ),

                                if (_isSalaryDisclosed)
                                  _buildHoverInput(
                                    controller: _salaryController,
                                    label: "Salary",
                                    icon: Icons.money,
                                    validator: "Please enter a valid salary",
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly
                                    ],
                                    prefixText: "PHP ",
                                  ),
                                const SizedBox(height: 10),

                                // Dropdowns
                                _buildDropdown(
                                  label: "Job Type",
                                  value: _selectedJobType,
                                  icon: Icons.work,
                                  items: const [
                                    "Full-time",
                                    "Part-time",
                                    "Remote",
                                    "Internship",
                                  ],
                                  onChanged: (value) => setState(() {
                                    _selectedJobType = value;
                                  }),
                                ),
                                const SizedBox(height: 10),
                                _buildDropdown(
                                  label: "Work Setup",
                                  value: _selectedWorkSetup,
                                  icon: Icons.computer,
                                  items: const ["On-site", "Remote", "Online"],
                                  onChanged: (value) => setState(() {
                                    _selectedWorkSetup = value;
                                  }),
                                ),
                                const SizedBox(height: 20),

                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14, horizontal: 24),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    backgroundColor: Colors.tealAccent[700],
                                  ),
                                  icon: const Icon(Icons.send, color: Colors.white),
                                  label: const Text("Post Job",
                                      style: TextStyle(color: Colors.white)),
                                  onPressed: _postJob,
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Custom text input field
  Widget _buildHoverInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? validator,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? prefixText,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator != null
          ? (value) => value!.isEmpty ? validator : null
          : null,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white),
        prefixText: prefixText,
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.black.withOpacity(0.3),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Custom dropdown widget
  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required List<String> items,
    required String? value,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      dropdownColor: Colors.black87,
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white),
        filled: true,
        fillColor: Colors.black.withOpacity(0.3),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: items
          .map((e) => DropdownMenuItem(
              value: e,
              child: Text(e, style: const TextStyle(color: Colors.white))))
          .toList(),
      onChanged: onChanged,
      validator: (value) => value == null ? "Please select $label" : null,
    );
  }
}
