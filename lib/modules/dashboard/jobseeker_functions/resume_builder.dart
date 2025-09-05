import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ResumeBuilderPage extends StatefulWidget {
  const ResumeBuilderPage({super.key});

  @override
  State<ResumeBuilderPage> createState() => _ResumeBuilderPageState();
}

class _ResumeBuilderPageState extends State<ResumeBuilderPage> {
  final Resume _resume = Resume();
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isLoading = false;

  // Controllers
  final _educationController = TextEditingController();
  final _experienceController = TextEditingController();
  final _skillsController = TextEditingController();

  // Template selector
  String _selectedTemplate = "Classic";

  @override
  void initState() {
    super.initState();
    _listenToProfile();
  }

  void _listenToProfile() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((doc) {
      if (!doc.exists) return;
      final data = doc.data()!;
      setState(() {
        _resume.fullName = data['name'] ?? '';
        _resume.email = data['email'] ?? '';
        _resume.phone = data['phone'] ?? '';
        _resume.address = data['address'] ?? '';
        _resume.objective = data['bio'] ?? '';

        _skillsController.text =
            (data['skills'] as List<dynamic>?)?.join(", ") ?? '';
        _experienceController.text =
            (data['achievements'] as List<dynamic>?)?.join(", ") ?? '';
        _educationController.text =
            (data['certifications'] as List<dynamic>?)?.join(", ") ?? '';
      });
    });
  }

  Future<void> _updateProfileField(String field, dynamic value) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
      {field: value},
      SetOptions(merge: true),
    );
  }

  @override
  void dispose() {
    _educationController.dispose();
    _experienceController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/modules.png', fit: BoxFit.cover),
          Container(color: Colors.black.withOpacity(0.5)),
          SafeArea(
            child: Column(
              children: [
                AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  title: const Text('Resume Builder',
                      style: TextStyle(color: Colors.white)),
                  actions: [
                    IconButton(
                        icon:
                            const Icon(Icons.preview, color: Colors.white),
                        onPressed: _previewResume),
                    IconButton(
                        icon:
                            const Icon(Icons.download, color: Colors.white),
                        onPressed: _generateAndSavePDF),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DropdownButton<String>(
                    value: _selectedTemplate,
                    dropdownColor: Colors.white,
                    items: ["Classic", "Modern", "Minimal"].map((style) {
                      return DropdownMenuItem(
                          value: style, child: Text("Template: $style"));
                    }).toList(),
                    onChanged: (val) => setState(() {
                      _selectedTemplate = val!;
                    }),
                  ),
                ),
                Expanded(
                  child: Stepper(
                    currentStep: _currentStep,
                    onStepContinue: () {
                      if (_currentStep < 4) setState(() => _currentStep++);
                    },
                    onStepCancel: () {
                      if (_currentStep > 0) setState(() => _currentStep--);
                    },
                    steps: [
                      _buildCompactStep(
                          'Personal Info', _buildPersonalInfoForm()),
                      _buildCompactStep('Education', _buildEducationForm()),
                      _buildCompactStep(
                          'Experience', _buildExperienceForm()),
                      _buildCompactStep('Skills', _buildSkillsForm()),
                      _buildCompactStep('Preview', _buildCompactPreview()),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                  child: CircularProgressIndicator(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  Step _buildCompactStep(String title, Widget content) {
    return Step(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      content: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: content,
      ),
    );
  }

  Widget _buildPersonalInfoForm() => Form(
        key: _formKey,
        child: Column(
          children: [
            _textField(
              'Full Name',
              (v) {
                _resume.fullName = v ?? '';
                _updateProfileField('name', _resume.fullName);
              },
              initialValue: _resume.fullName,
              required: true,
            ),
            const SizedBox(height: 10),
            _textField(
              'Email',
              (v) {
                _resume.email = v ?? '';
                _updateProfileField('email', _resume.email);
              },
              initialValue: _resume.email,
              required: true,
            ),
            const SizedBox(height: 10),
            _textField(
              'Phone',
              (v) {
                _resume.phone = v ?? '';
                _updateProfileField('phone', _resume.phone);
              },
              initialValue: _resume.phone,
            ),
            const SizedBox(height: 10),
            _textField(
              'Address',
              (v) {
                _resume.address = v ?? '';
                _updateProfileField('address', _resume.address);
              },
              initialValue: _resume.address,
            ),
            const SizedBox(height: 10),
            _textField(
              'Career Objective',
              (v) {
                _resume.objective = v ?? '';
                _updateProfileField('bio', _resume.objective);
              },
              initialValue: _resume.objective,
              maxLines: 3,
            ),
          ],
        ),
      );

  Widget _textField(
    String label,
    Function(String?) onChanged, {
    bool required = false,
    int maxLines = 1,
    String initialValue = '',
  }) {
    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(
          labelText: label, border: const OutlineInputBorder()),
      validator: required
          ? (v) => v == null || v.isEmpty ? 'Required' : null
          : null,
      onChanged: onChanged,
      maxLines: maxLines,
    );
  }

  Widget _buildEducationForm() => TextField(
        controller: _educationController,
        onChanged: (val) => _updateProfileField(
            'certifications', val.split(",").map((e) => e.trim()).toList()),
        decoration: const InputDecoration(
            labelText: 'Education', border: OutlineInputBorder()),
      );

  Widget _buildExperienceForm() => TextField(
        controller: _experienceController,
        onChanged: (val) => _updateProfileField(
            'achievements', val.split(",").map((e) => e.trim()).toList()),
        decoration: const InputDecoration(
            labelText: 'Experience', border: OutlineInputBorder()),
      );

  Widget _buildSkillsForm() => TextField(
        controller: _skillsController,
        onChanged: (val) => _updateProfileField(
            'skills', val.split(",").map((e) => e.trim()).toList()),
        decoration: const InputDecoration(
            labelText: 'Skills', border: OutlineInputBorder()),
      );

  Widget _buildCompactPreview() => Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Preview',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Divider(),
              Text('Name: ${_resume.fullName}'),
              Text('Email: ${_resume.email}'),
              Text('Education: ${_educationController.text}'),
              Text('Experience: ${_experienceController.text}'),
              Text('Skills: ${_skillsController.text}'),
              Text('Template: $_selectedTemplate'),
            ],
          ),
        ),
      );

  void _previewResume() {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState!.save();
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Resume Preview'),
          content: _buildCompactPreview(),
        ),
      );
    }
  }

  Future<void> _generateAndSavePDF() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    try {
      final pdf = pw.Document();

      // Choose template
      pw.Widget pdfContent;
      if (_selectedTemplate == "Classic") {
        pdfContent = _classicTemplate();
      } else if (_selectedTemplate == "Modern") {
        pdfContent = _modernTemplate();
      } else {
        pdfContent = _minimalTemplate();
      }

      pdf.addPage(pw.Page(build: (context) => pdfContent));

      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/${_resume.fullName.isNotEmpty ? _resume.fullName.replaceAll(' ', '_') : 'resume'}.pdf');
      await file.writeAsBytes(await pdf.save());

      final user = FirebaseAuth.instance.currentUser;
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('resumes/${user?.uid ?? 'guest'}.pdf');
      await storageRef.putFile(file);

      await OpenFile.open(file.path);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('PDF saved locally and uploaded to Firebase!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ---------- TEMPLATES ----------
  pw.Widget _classicTemplate() => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(_resume.fullName,
              style: pw.TextStyle(
                  fontSize: 24, fontWeight: pw.FontWeight.bold)),
          pw.Text(_resume.email),
          pw.SizedBox(height: 10),
          pw.Text("Objective:",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(_resume.objective),
          pw.SizedBox(height: 10),
          pw.Text("Education: ${_educationController.text}"),
          pw.Text("Experience: ${_experienceController.text}"),
          pw.Text("Skills: ${_skillsController.text}"),
        ],
      );

  pw.Widget _modernTemplate() => pw.Container(
        padding: const pw.EdgeInsets.all(20),
        decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.blue, width: 2)),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(_resume.fullName,
                style: pw.TextStyle(
                    fontSize: 26,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue)),
            pw.Divider(),
            pw.Text("📧 ${_resume.email}  |  📞 ${_resume.phone}"),
            pw.SizedBox(height: 12),
            pw.Text("🎯 Objective",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text(_resume.objective),
            pw.SizedBox(height: 12),
            pw.Text("🎓 Education: ${_educationController.text}"),
            pw.Text("💼 Experience: ${_experienceController.text}"),
            pw.Text("⚡ Skills: ${_skillsController.text}"),
          ],
        ),
      );

  pw.Widget _minimalTemplate() => pw.Center(
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text(_resume.fullName,
                style: pw.TextStyle(
                    fontSize: 30, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 5),
            pw.Text(_resume.email),
            pw.SizedBox(height: 20),
            pw.Text("Education: ${_educationController.text}"),
            pw.Text("Experience: ${_experienceController.text}"),
            pw.Text("Skills: ${_skillsController.text}"),
          ],
        ),
      );
}

class Resume {
  String fullName = '',
      email = '',
      phone = '',
      address = '',
      objective = '';
}
