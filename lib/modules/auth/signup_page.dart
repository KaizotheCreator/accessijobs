import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // for kIsWeb

class UnifiedSignupPage extends StatefulWidget {
  const UnifiedSignupPage({Key? key}) : super(key: key);

  @override
  State<UnifiedSignupPage> createState() => _UnifiedSignupPageState();
}

class _UnifiedSignupPageState extends State<UnifiedSignupPage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Uint8List? jobseekerProfileImageBytes;
  Uint8List? employerLogoBytes;
  String? jobseekerProfileUrl;
  String? employerLogoUrl;

  /// Role toggle (Jobseeker or Employer)
  String selectedRole = 'jobseeker';

  /// Common controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // -------------------- JOBSEEKER FIELDS --------------------
  File? jobseekerProfileImage;
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final bioController = TextEditingController();
  final contactNumberController = TextEditingController();

  List<String> technicalSkills = [];
  List<String> personalSkills = [];

  List<Map<String, dynamic>> workExperience = [];
  List<Map<String, dynamic>> education = [];
  List<String> certificationImages = [];

  // -------------------- EMPLOYER FIELDS --------------------
  File? employerLogo;
  final companyNameController = TextEditingController();
  final aboutController = TextEditingController();
  final industryController = TextEditingController();
  final employerContactController = TextEditingController();
  final headquartersController = TextEditingController();

  DateTime? foundedDate;
  List<String> services = [];
  List<String> documents = [];

  final List<String> industries = [
    'Information Technology (IT)',
    'Tech',
    'Healthcare',
    'Education',
    'Accounting',
    'Pharmaceutical',
    'Finance',
    'Engineering',
    'Real Estate',
    'Higher Education',
    'Sales',
    'Government',
    'Energy',
    'Retail',
    'Manufacturing',
    'Architecture',
    'Human Resources',
    'Nonprofit',
    'Transportation',
    'Hospitality',
  ];

  String? selectedIndustry;

  final supabase = Supabase.instance.client;

  // -------------------- HELPERS --------------------

  @override
  void initState() {
    super.initState();
    contactNumberController.text = '+639'; // Prefill
  }

  Future<void> _pickImage(bool isJobseeker) async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      if (kIsWeb) {
        // ✅ Web: use bytes for preview & upload
        final imageBytes = await pickedFile.readAsBytes();
        setState(() {
          if (isJobseeker) {
            jobseekerProfileImageBytes = imageBytes;
            jobseekerProfileImage = null; // Clear File
          } else {
            employerLogoBytes = imageBytes;
            employerLogo = null;
          }
        });
      } else {
        // ✅ Mobile/Desktop: use File for preview & upload
        final imageFile = File(pickedFile.path);
        setState(() {
          if (isJobseeker) {
            jobseekerProfileImage = imageFile;
            jobseekerProfileImageBytes = null; // Clear Bytes
          } else {
            employerLogo = imageFile;
            employerLogoBytes = null;
          }
        });
      }
    }
  }

  Widget requiredLabel(String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(text),
        const Text(
          ' *',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      setState(() {
        documents.addAll(result.files.map((file) => file.name));
      });
    }
  }

  Future<void> _selectDate(BuildContext context, Function(DateTime) onSelected) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) onSelected(picked);
  }

  void _addSkill(List<String> skillList) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Skill"),
        content: TextField(
          controller: controller,
          inputFormatters: [TextAndPunctuationFormatter()],
          decoration: const InputDecoration(hintText: "Enter skill"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() => skillList.add(controller.text.trim()));
              }
              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _addWorkExperience() {
    final companyController = TextEditingController();
    final roleController = TextEditingController();
    DateTime? startDate;
    DateTime? endDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text("Add Work Experience"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: companyController, inputFormatters: [TextAndPunctuationFormatter()], decoration: const InputDecoration(labelText: "Company")),
              TextField(controller: roleController, inputFormatters: [TextAndPunctuationFormatter()], decoration: const InputDecoration(labelText: "Role")),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) setStateDialog(() => startDate = date);
                      },
                      child: Text(startDate == null ? "Start Date" : DateFormat.yMd().format(startDate!)),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) setStateDialog(() => endDate = date);
                      },
                      child: Text(endDate == null ? "End Date" : DateFormat.yMd().format(endDate!)),
                    ),
                  ),
                ],
              )
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                if (companyController.text.isNotEmpty && roleController.text.isNotEmpty) {
                  setState(() => workExperience.add({
                        'company': companyController.text.trim(),
                        'role': roleController.text.trim(),
                        'startDate': DateFormat('yyyy-MM-dd').format(startDate!),
                        'endDate': DateFormat('yyyy-MM-dd').format(endDate!),
                      }));
                }
                Navigator.pop(context);
              },
              child: const Text("Add"),
            ),
          ],
        ),
      ),
    );
  }

  void _addEducation() {
    final schoolController = TextEditingController();
    String? selectedLevel;
    DateTime? graduationDate;

    final List<String> educationLevels = [
      'Elementary',
      'Junior High School',
      'Senior High School',
      'College',
      'Masters',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text("Add Education"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: schoolController,
                inputFormatters: [TextAndPunctuationFormatter()],
                decoration: InputDecoration(label: requiredLabel("School")),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: selectedLevel,
                decoration: InputDecoration(label: requiredLabel("Level")),
                items: educationLevels
                    .map((level) => DropdownMenuItem(
                          value: level,
                          child: Text(level),
                        ))
                    .toList(),
                onChanged: (value) => setStateDialog(() => selectedLevel = value),
                validator: (val) => val == null ? "Please select a level" : null,
              ),
              const SizedBox(height: 12),

              TextButton(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) setStateDialog(() => graduationDate = date);
                },
                child: Text(graduationDate == null
                    ? "Select Graduation Date"
                    : DateFormat.yMd().format(graduationDate!)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (schoolController.text.isNotEmpty &&
                    selectedLevel != null &&
                    graduationDate != null) {
                  setState(() => education.add({
                        'school': schoolController.text.trim(),
                        'level': selectedLevel,
                        'graduationDate': DateFormat('yyyy-MM-dd').format(graduationDate!),
                      }));
                  Navigator.pop(context);
                }
              },
              child: const Text("Add"),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------- VALIDATION --------------------
  bool get _isFormValid {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) return false;

    if (selectedRole == 'jobseeker') {
      return firstNameController.text.isNotEmpty &&
          lastNameController.text.isNotEmpty &&
          emailController.text.isNotEmpty &&
          passwordController.text.isNotEmpty &&
          confirmPasswordController.text.isNotEmpty &&
          technicalSkills.isNotEmpty &&
          personalSkills.isNotEmpty;
    } else {
      return companyNameController.text.isNotEmpty &&
          aboutController.text.isNotEmpty &&
          emailController.text.isNotEmpty &&
          passwordController.text.isNotEmpty &&
          confirmPasswordController.text.isNotEmpty &&
          services.isNotEmpty;
    }
  }

  // -------------------- SIGN UP --------------------
  Future<void> _confirmAndSignup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Details"),
        content: const Text("Are you sure with all the details? You cannot change it if you're unverified."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Yes")),
        ],
      ),
    );

    if (confirmed == true) {
      _handleSignup();
    }
  }

  Future<String> _uploadImageToSupabase(dynamic imageFile, String bucketName) async {
    try {
      final fileName = "${DateTime.now().millisecondsSinceEpoch}_${imageFile is File ? imageFile.path.split('/').last : 'web_upload'}";
      debugPrint("Uploading to bucket: $bucketName | file: $fileName");

      final storage = supabase.storage.from(bucketName);

      if (imageFile is Uint8List) {
        await storage.uploadBinary(fileName, imageFile);
      } else if (imageFile is File) {
        await storage.upload(fileName, imageFile);
      } else {
        throw Exception("Unsupported image type for upload.");
      }

      final publicUrl = storage.getPublicUrl(fileName);
      debugPrint("Uploaded Image URL: $publicUrl");
      return publicUrl;
    } catch (e) {
      debugPrint("Supabase upload error: $e");
      throw Exception("Supabase upload error: $e");
    }
  }

  Future<void> _handleSignup() async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final uid = credential.user!.uid;

      String? profileImageUrl;
      String? employerLogoUrl;
      List<String> certificationImageUrls = [];

      // ✅ Upload images to Supabase
      if (selectedRole == 'jobseeker') {
        if (jobseekerProfileImageBytes != null) {
          profileImageUrl = await _uploadImageToSupabase(jobseekerProfileImageBytes!, "profile_pictures");
        } else if (jobseekerProfileImage != null) {
          profileImageUrl = await _uploadImageToSupabase(jobseekerProfileImage!, "profile_pictures");
        }
      }

      if (selectedRole == 'employer') {
        if (employerLogoBytes != null) {
          employerLogoUrl = await _uploadImageToSupabase(employerLogoBytes!, "company_logos");
        } else if (employerLogo != null) {
          employerLogoUrl = await _uploadImageToSupabase(employerLogo!, "company_logos");
        }
      }

      for (final certPath in certificationImages) {
        final certFile = File(certPath);
        final url = await _uploadImageToSupabase(certFile, "documents");
        certificationImageUrls.add(url);
      }

      if (selectedRole == 'jobseeker') {
        await _firestore.collection('jobseekers').doc(uid).set({
          'firstName': firstNameController.text.trim(),
          'lastName': lastNameController.text.trim(),
          'bio': bioController.text.trim(),
          'email': emailController.text.trim(),
          'contactNumber': contactNumberController.text.trim(),
          'profileImageUrl': profileImageUrl ?? '',
          'technicalSkills': technicalSkills,
          'personalSkills': personalSkills,
          'workExperience': workExperience,
          'education': education,
          'certificationImages': certificationImageUrls,
          'createdAt': FieldValue.serverTimestamp(),
        });

        await _firestore.collection('users').doc(uid).set({
          'role': 'jobseeker',
          'email': emailController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });

        Navigator.pushNamedAndRemoveUntil(context, '/jobseeker_login', (route) => false);
      } else {
        await _firestore.collection('employers').doc(uid).set({
          'companyName': companyNameController.text.trim(),
          'about': aboutController.text.trim(),
          'industry': selectedIndustry ?? '',
          'foundedDate': foundedDate?.toIso8601String() ?? '',
          'headquarters': headquartersController.text.trim(),
          'services': services,
          'documents': documents,
          'email': emailController.text.trim(),
          'contactNumber': employerContactController.text.trim(),
          'logoUrl': employerLogoUrl ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });

        await _firestore.collection('users').doc(uid).set({
          'role': 'employer',
          'email': emailController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });

        Navigator.pushNamedAndRemoveUntil(context, '/employer_login', (route) => false);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Signup successful! Please login.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  // -------------------- UI WIDGETS --------------------
  Widget _buildSkillSection(String title, List<String> skillList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            requiredLabel(title),
            IconButton(icon: const Icon(Icons.add), onPressed: () => _addSkill(skillList)),
          ],
        ),
        Wrap(
          spacing: 8,
          children: skillList
              .map((skill) => Chip(
                    label: Text(skill),
                    deleteIcon: const Icon(Icons.close),
                    onDeleted: () => setState(() => skillList.remove(skill)),
                  ))
              .toList(),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildJobseekerForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: firstNameController,
          inputFormatters: [TextAndPunctuationFormatter()],
          decoration: InputDecoration(label: requiredLabel("First Name")),
          validator: (val) => val!.isEmpty ? "Required" : null,
        ),
        const SizedBox(height: 12),

        TextFormField(
          controller: lastNameController,
          inputFormatters: [TextAndPunctuationFormatter()],
          decoration: InputDecoration(label: requiredLabel("Last Name")),
          validator: (val) => val!.isEmpty ? "Required" : null,
        ),
        const SizedBox(height: 12),

        TextFormField(
          controller: bioController,
          decoration: InputDecoration(label: requiredLabel("Bio")),
          maxLines: 2,
          validator: (val) => val!.isEmpty ? "Required" : null,
        ),
        const SizedBox(height: 12),

        TextFormField(
          controller: contactNumberController,
          keyboardType: TextInputType.phone,
          inputFormatters: [PhilippinesNumberFormatter()],
          decoration: InputDecoration(label: requiredLabel("Contact Number"), hintText: "+639XXXXXXXXX"),
          validator: (val) {
            if (val == null || val.isEmpty) return "Required";
            if (!RegExp(r'^\+639\d{9}$').hasMatch(val)) {
              return "Enter a valid PH number (+639XXXXXXXXX)";
            }
            return null;
          },
        ),
        const SizedBox(height: 12),

        _buildSkillSection("Technical Skills", technicalSkills),
        _buildSkillSection("Personal Skills", personalSkills),

        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Work Experience (Optional)"),
            IconButton(onPressed: _addWorkExperience, icon: const Icon(Icons.add)),
          ],
        ),
        Wrap(
          children: workExperience
              .map((exp) => Chip(
                    label: Text("${exp['company']} - ${exp['role']}"),
                    deleteIcon: const Icon(Icons.close),
                    onDeleted: () => setState(() => workExperience.remove(exp)),
                  ))
              .toList(),
        ),
        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            requiredLabel("Education"),
            IconButton(onPressed: _addEducation, icon: const Icon(Icons.add)),
          ],
        ),
        Wrap(
          children: education
              .map((edu) => Chip(
                    label: Text("${edu['school']} - ${edu['level']}"),
                    deleteIcon: const Icon(Icons.close),
                    onDeleted: () => setState(() => education.remove(edu)),
                  ))
              .toList(),
        ),
        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Certifications (Optional)"),
            IconButton(
              onPressed: () async {
                final result = await FilePicker.platform.pickFiles(allowMultiple: true);
                if (result != null) {
                  setState(() {
                    certificationImages.addAll(result.paths.whereType<String>());
                  });
                }
              },
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        Wrap(
          children: certificationImages
              .map((cert) => Chip(
                    label: Text(cert.split('/').last),
                    deleteIcon: const Icon(Icons.close),
                    onDeleted: () => setState(() => certificationImages.remove(cert)),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildEmployerForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: companyNameController,
          inputFormatters: [TextAndPunctuationFormatter()],
          decoration: InputDecoration(label: requiredLabel("Company Name")),
          validator: (val) => val!.isEmpty ? "Required" : null,
        ),
        const SizedBox(height: 12),

        TextFormField(
          controller: aboutController,
          decoration: InputDecoration(label: requiredLabel("About Company")),
          maxLines: 3,
          validator: (val) => val!.isEmpty ? "Required" : null,
        ),
        const SizedBox(height: 12),

        DropdownButtonFormField<String>(
          value: selectedIndustry,
          decoration: InputDecoration(label: requiredLabel("Industry")),
          items: industries
              .map((industry) => DropdownMenuItem(value: industry, child: Text(industry)))
              .toList(),
          onChanged: (value) => setState(() => selectedIndustry = value),
          validator: (val) => val == null ? "Please select an industry" : null,
        ),
        const SizedBox(height: 12),

        TextButton(
          onPressed: () => _selectDate(context, (date) => setState(() => foundedDate = date)),
          child: Text(
            foundedDate == null
                ? "Select Founded Date"
                : "Founded: ${DateFormat.yMd().format(foundedDate!)}",
          ),
        ),
        const SizedBox(height: 12),

        TextFormField(
          controller: headquartersController,
          inputFormatters: [TextAndPunctuationFormatter()],
          decoration: InputDecoration(label: requiredLabel("Headquarters")),
          validator: (val) => val!.isEmpty ? "Required" : null,
        ),
        const SizedBox(height: 12),

        TextFormField(
          controller: employerContactController,
          keyboardType: TextInputType.phone,
          inputFormatters: [PhilippinesNumberFormatter()],
          decoration: InputDecoration(label: requiredLabel("Contact Number"), hintText: "+639XXXXXXXXX"),
          validator: (val) {
            if (val == null || val.isEmpty) return "Required";
            if (!RegExp(r'^\+639\d{9}$').hasMatch(val)) {
              return "Enter a valid PH number (+639XXXXXXXXX)";
            }
            return null;
          },
        ),
        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            requiredLabel("Services"),
            IconButton(
              onPressed: () => _addSkill(services),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          children: services
              .map((service) => Chip(
                    label: Text(service),
                    deleteIcon: const Icon(Icons.close),
                    onDeleted: () => setState(() => services.remove(service)),
                  ))
              .toList(),
        ),
        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Documents (Optional)"),
            IconButton(onPressed: _pickDocument, icon: const Icon(Icons.add)),
          ],
        ),
        Wrap(
          children: documents
              .map((doc) => Chip(
                    label: Text(doc),
                    deleteIcon: const Icon(Icons.close),
                    onDeleted: () => setState(() => documents.remove(doc)),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback toggleVisibility,
    required String label,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        label: requiredLabel(label),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: toggleVisibility,
        ),
      ),
      validator: (val) {
        if (val == null || val.isEmpty) return "Required";
        if (val.length < 6) return "Password must be at least 6 characters";
        return null;
      },
    );
  }

  // -------------------- VISUAL LAYOUT (beautification only) --------------------
  @override
  Widget build(BuildContext context) {
    // Colors for gradient and card
    const Color darkBlue = Color(0xFF0D1B2A);
    const Color midBlue = Color(0xFF1B263B);
    const Color green = Color(0xFF2E8B57);
    final Color fadedOrange = Colors.orange.withOpacity(0.06); // very subtle

    // RESPONSIVENESS: determine layout based on width
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 900; // you can tweak this breakpoint

    return Scaffold(
      // no AppBar to match a modern landing/sign-up look
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [darkBlue, midBlue, green],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            child: ConstrainedBox(
              // LinkedIn-like constrained card width for desktop
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Main faded-orange card containing the form
                  Container(
                    decoration: BoxDecoration(
                      color: fadedOrange,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 18, offset: const Offset(0, 8)),
                      ],
                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(28.0),
                      child: isMobile
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Form card (full width)
                                Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  color: Colors.white,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 20.0),
                                    child: Form(
                                      key: _formKey,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Header
                                          Text(
                                            'Create your account',
                                            style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Join our community — set up your profile and get discovered.',
                                            style: Theme.of(context).textTheme.bodyMedium,
                                          ),
                                          const SizedBox(height: 18),

                                          // Role Toggle
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[100],
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: ToggleButtons(
                                              isSelected: [selectedRole == 'jobseeker', selectedRole == 'employer'],
                                              onPressed: (index) {
                                                setState(() => selectedRole = index == 0 ? 'jobseeker' : 'employer');
                                              },
                                              borderRadius: BorderRadius.circular(8),
                                              fillColor: const Color(0xFF2E8B57),
                                              selectedColor: Colors.white,
                                              color: Colors.black87,
                                              children: const [
                                                Padding(padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8), child: Text("Jobseeker")),
                                                Padding(padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8), child: Text("Employer")),
                                              ],
                                            ),
                                          ),

                                          const SizedBox(height: 18),

                                          // Role-specific form
                                          if (selectedRole == 'jobseeker') _buildJobseekerForm() else _buildEmployerForm(),

                                          const SizedBox(height: 18),

                                          // Common fields
                                          TextFormField(
                                            controller: emailController,
                                            keyboardType: TextInputType.emailAddress,
                                            decoration: InputDecoration(label: requiredLabel("Email")),
                                            validator: (val) {
                                              if (val == null || val.isEmpty) return "Required";
                                              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(val)) return "Enter a valid email";
                                              return null;
                                            },
                                          ),
                                          const SizedBox(height: 12),

                                          _buildPasswordField(
                                            controller: passwordController,
                                            obscure: _obscurePassword,
                                            toggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                                            label: "Password",
                                          ),
                                          const SizedBox(height: 12),

                                          _buildPasswordField(
                                            controller: confirmPasswordController,
                                            obscure: _obscureConfirmPassword,
                                            toggleVisibility: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                            label: "Confirm Password",
                                          ),

                                          const SizedBox(height: 18),

                                          // Footer actions
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              TextButton(
                                                onPressed: () {
                                                  // keep functionality unchanged — placeholder
                                                },
                                                child: const Text("Need help?"),
                                              ),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFF2E8B57),
                                                  padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                ),
                                                onPressed: _isFormValid ? _confirmAndSignup : null,
                                                child: const Text("Create account", style: TextStyle(fontSize: 16)),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 18),

                                // Right/branding card under form on mobile
                                Card(
                                  color: Colors.white.withOpacity(0.06),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Text(
                                          'Welcome to AccessiJobs',
                                          style: Theme.of(context).textTheme.titleMedium!.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                                          textAlign: TextAlign.left,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Find talent. Get hired. Build your company.',
                                          style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.white70),
                                          textAlign: TextAlign.left,
                                        ),
                                        const SizedBox(height: 12),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            onPressed: () {},
                                            icon: const Icon(Icons.info_outline),
                                            label: const Text('Why join?'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.white.withOpacity(0.18),
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // LEFT: Form area
                                Expanded(
                                  flex: 7,
                                  child: Card(
                                    elevation: 4,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    color: Colors.white,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 20.0),
                                      child: Form(
                                        key: _formKey,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Header
                                            Text(
                                              'Create your account',
                                              style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              'Join our community — set up your profile and get discovered.',
                                              style: Theme.of(context).textTheme.bodyMedium,
                                            ),
                                            const SizedBox(height: 18),

                                            // Role Toggle
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[100],
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: ToggleButtons(
                                                isSelected: [selectedRole == 'jobseeker', selectedRole == 'employer'],
                                                onPressed: (index) {
                                                  setState(() => selectedRole = index == 0 ? 'jobseeker' : 'employer');
                                                },
                                                borderRadius: BorderRadius.circular(8),
                                                fillColor: const Color(0xFF2E8B57),
                                                selectedColor: Colors.white,
                                                color: Colors.black87,
                                                children: const [
                                                  Padding(padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8), child: Text("Jobseeker")),
                                                  Padding(padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8), child: Text("Employer")),
                                                ],
                                              ),
                                            ),

                                            const SizedBox(height: 18),

                                            // Role-specific form
                                            if (selectedRole == 'jobseeker') _buildJobseekerForm() else _buildEmployerForm(),

                                            const SizedBox(height: 18),

                                            // Common fields
                                            TextFormField(
                                              controller: emailController,
                                              keyboardType: TextInputType.emailAddress,
                                              decoration: InputDecoration(label: requiredLabel("Email")),
                                              validator: (val) {
                                                if (val == null || val.isEmpty) return "Required";
                                                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(val)) return "Enter a valid email";
                                                return null;
                                              },
                                            ),
                                            const SizedBox(height: 12),

                                            _buildPasswordField(
                                              controller: passwordController,
                                              obscure: _obscurePassword,
                                              toggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                                              label: "Password",
                                            ),
                                            const SizedBox(height: 12),

                                            _buildPasswordField(
                                              controller: confirmPasswordController,
                                              obscure: _obscureConfirmPassword,
                                              toggleVisibility: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                              label: "Confirm Password",
                                            ),

                                            const SizedBox(height: 18),

                                            // Footer actions
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                TextButton(
                                                  onPressed: () {
                                                    // keep functionality unchanged — placeholder
                                                  },
                                                  child: const Text("Need help?"),
                                                ),
                                                ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: const Color(0xFF2E8B57),
                                                    padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                  ),
                                                  onPressed: _isFormValid ? _confirmAndSignup : null,
                                                  child: const Text("Create account", style: TextStyle(fontSize: 16)),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 24),

                                // RIGHT: Visual / branding column (smaller on mobile)
                                Expanded(
                                  flex: 4,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      // Intentionally left blank to allow the avatar to overlap from the top-right via Positioned
                                      const SizedBox(height: 40),
                                      Card(
                                        color: Colors.white.withOpacity(0.06),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                'Welcome to AccessiJobs',
                                                style: Theme.of(context).textTheme.titleMedium!.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                                                textAlign: TextAlign.right,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Find talent. Get hired. Build your company.',
                                                style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.white70),
                                                textAlign: TextAlign.right,
                                              ),
                                              const SizedBox(height: 12),
                                              SizedBox(
                                                width: double.infinity,
                                                child: ElevatedButton.icon(
                                                  onPressed: () {},
                                                  icon: const Icon(Icons.info_outline),
                                                  label: const Text('Why join?'),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.white.withOpacity(0.18),
                                                    foregroundColor: Colors.white,
                                                    elevation: 0,
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                  ),
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  // Positioned avatar/profile in the top-right of the orange container
                  Positioned(
                    top: -36,
                    right: 18,
                    child: GestureDetector(
                      onTap: () => _pickImage(selectedRole == 'jobseeker'),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 6)),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 56, // bigger picture as requested
                          backgroundColor: Colors.white,
                          backgroundImage: selectedRole == 'jobseeker'
                              ? (jobseekerProfileImageBytes != null
                                  ? MemoryImage(jobseekerProfileImageBytes!)
                                  : (jobseekerProfileImage != null ? FileImage(jobseekerProfileImage!) as ImageProvider : (jobseekerProfileUrl != null && jobseekerProfileUrl!.isNotEmpty ? NetworkImage(jobseekerProfileUrl!) : null)))
                              : (employerLogoBytes != null
                                  ? MemoryImage(employerLogoBytes!)
                                  : (employerLogo != null ? FileImage(employerLogo!) as ImageProvider : (employerLogoUrl != null && employerLogoUrl!.isNotEmpty ? NetworkImage(employerLogoUrl!) : null))),
                          child: (selectedRole == 'jobseeker'
                                      ? (jobseekerProfileImageBytes == null && jobseekerProfileImage == null && (jobseekerProfileUrl == null || jobseekerProfileUrl!.isEmpty))
                                      : (employerLogoBytes == null && employerLogo == null && (employerLogoUrl == null || employerLogoUrl!.isEmpty)))
                                  ? const Icon(Icons.camera_alt, size: 32, color: Colors.grey)
                                  : null,
                        ),
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

// -------------------- CUSTOM FORMATTERS --------------------
class PhilippinesNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;

    // ✅ Allow empty input while typing
    if (text.isEmpty) return newValue;

    // ✅ Must always start with "+639"
    if (!text.startsWith('+639')) {
      return oldValue;
    }

    // ✅ Only allow numbers after "+639"
    final afterPrefix = text.substring(4); // Get characters after "+639"
    if (!RegExp(r'^[0-9]*$').hasMatch(afterPrefix)) {
      return oldValue; // Reject if contains letters or symbols
    }

    // ✅ Limit total length to "+639" + 9 digits = 13
    if (text.length > 13) {
      return oldValue;
    }

    return newValue;
  }
}

class TextAndPunctuationFormatter extends TextInputFormatter {
  final RegExp _regExp = RegExp(r'^[a-zA-Z\s.,-]*$');

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (_regExp.hasMatch(newValue.text)) {
      return newValue;
    }
    return oldValue;
  }
}
