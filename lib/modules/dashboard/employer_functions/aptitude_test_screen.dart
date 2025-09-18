import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AptitudeTestScreen extends StatefulWidget {
  final String jobId;
  final List<String> questions;

  const AptitudeTestScreen({
    super.key,
    required this.jobId,
    required this.questions,
  });

  @override
  State<AptitudeTestScreen> createState() => _AptitudeTestScreenState();
}

class _AptitudeTestScreenState extends State<AptitudeTestScreen> {
  final List<TextEditingController> _answerControllers = [];
  final List<File?> _imageAnswers = [];
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    for (var _ in widget.questions) {
      _answerControllers.add(TextEditingController());
      _imageAnswers.add(null);
    }
  }

  /// Pick image using image_picker and store locally before upload
  Future<void> _pickImage(int index) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imageAnswers[index] = File(picked.path);
      });
    }
  }

  /// Upload image to Supabase bucket and return its public URL
  Future<String?> _uploadImageToSupabase(File image, int index, String userId) async {
    try {
      final fileExt = image.path.split('.').last;
      final fileName = "${widget.jobId}_${userId}_q$index.$fileExt";

      final filePath = "aptitude_answers/$fileName";

      // Upload to Supabase
      await _supabase.storage.from('aptitude_answers').upload(filePath, image);

      // Get public URL
      final publicUrl = _supabase.storage.from('aptitude_answers').getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Image upload failed: $e")),
      );
      return null;
    }
  }

  /// Validate and submit answers
  Future<void> _submitAnswers() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSubmitting = true);

    final Map<String, dynamic> answers = {};

    for (int i = 0; i < widget.questions.length; i++) {
      final textAnswer = _answerControllers[i].text.trim();
      final imageAnswer = _imageAnswers[i];

      // Text validation: no numbers allowed
      if (textAnswer.isNotEmpty && RegExp(r'[0-9]').hasMatch(textAnswer)) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Numbers are not allowed in answer for Q${i + 1}.")),
        );
        return;
      }

      // Upload image to Supabase if available
      String? imageUrl;
      if (imageAnswer != null) {
        imageUrl = await _uploadImageToSupabase(imageAnswer, i, user.uid);
        if (imageUrl == null) {
          setState(() => _isSubmitting = false);
          return; // Stop if upload failed
        }
      }

      // Save both text and image answers
      answers['question_$i'] = {
        'question': widget.questions[i],
        'answerText': textAnswer,
        'answerImage': imageUrl,
      };
    }

    // Save all answers to Firestore under the job document
    await FirebaseFirestore.instance
        .collection('jobs')
        .doc(widget.jobId)
        .collection('aptitude_answers')
        .doc(user.uid)
        .set({
      'userId': user.uid,
      'answers': answers,
      'submittedAt': FieldValue.serverTimestamp(),
    });

    setState(() => _isSubmitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Answers submitted successfully!")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Aptitude Test")),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: widget.questions.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Q${index + 1}: ${widget.questions[index]}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  // TEXT ANSWER
                  TextField(
                    controller: _answerControllers[index],
                    decoration: const InputDecoration(
                      labelText: "Your Answer (Text Only)",
                      border: OutlineInputBorder(),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z\s\?\.]')),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // IMAGE ANSWER PREVIEW
                  if (_imageAnswers[index] != null)
                    Column(
                      children: [
                        Image.file(_imageAnswers[index]!, height: 100),
                        const SizedBox(height: 5),
                      ],
                    ),

                  TextButton.icon(
                    onPressed: () => _pickImage(index),
                    icon: const Icon(Icons.image),
                    label: const Text("Upload Image Answer"),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSubmitting ? null : _submitAnswers,
        icon: _isSubmitting
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.send),
        label: Text(_isSubmitting ? "Submitting..." : "Submit Answers"),
      ),
    );
  }
}
