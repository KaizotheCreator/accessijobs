import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _benefitsController = TextEditingController();
  final TextEditingController _aptitudeTestController = TextEditingController();

  // Coordinates
  double? _lat;
  double? _lng;

  Future<void> _postJob() async {
    if (_formKey.currentState!.validate()) {
      if (_lat == null || _lng == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("📍 Please select a location on the map")),
        );
        return;
      }

      await FirebaseFirestore.instance.collection('jobs').add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'lat': _lat,
        'lng': _lng,
        'time': _timeController.text.trim(),
        'benefits': _benefitsController.text.trim(),
        'aptitudeTest': _aptitudeTestController.text.trim().isEmpty
            ? null
            : _aptitudeTestController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Job posted successfully!")),
      );

      // Reset fields
      _titleController.clear();
      _descriptionController.clear();
      _locationController.clear();
      _timeController.clear();
      _benefitsController.clear();
      _aptitudeTestController.clear();
      _lat = null;
      _lng = null;
    }
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MapPickerScreen(),
      ),
    );

    if (result != null && result is LatLng) {
      setState(() {
        _lat = result.latitude;
        _lng = result.longitude;
        _locationController.text =
            "Lat: ${_lat!.toStringAsFixed(5)}, Lng: ${_lng!.toStringAsFixed(5)}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Job Posting"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const JobsMapScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildInput(
                controller: _titleController,
                label: "Job Title",
                icon: Icons.work_outline,
                validator: "Please enter a job title",
              ),
              _buildInput(
                controller: _descriptionController,
                label: "Job Description",
                icon: Icons.description_outlined,
                maxLines: 3,
                validator: "Please enter a description",
              ),
              Row(
                children: [
                  Expanded(
                    child: _buildInput(
                      controller: _locationController,
                      label: "Job Location (Lat/Lng)",
                      icon: Icons.location_on_outlined,
                      validator: "Please pick a location",
                    ),
                  ),
                  IconButton(
                    onPressed: _pickLocation,
                    icon: const Icon(Icons.map_outlined),
                    tooltip: "Pick on Map",
                    color: isDark ? Colors.tealAccent : Colors.blueAccent,
                  ),
                ],
              ),
              _buildInput(
                controller: _timeController,
                label: "Job Time",
                icon: Icons.schedule_outlined,
                validator: "Please enter job time",
              ),
              _buildInput(
                controller: _benefitsController,
                label: "Benefits",
                icon: Icons.card_giftcard_outlined,
              ),
              _buildInput(
                controller: _aptitudeTestController,
                label: "Aptitude Test (optional)",
                icon: Icons.quiz_outlined,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.send),
                label: const Text("Post Job"),
                onPressed: _postJob,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Reusable input widget
  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? validator,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator != null
            ? (value) => value!.isEmpty ? validator : null
            : null,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          labelText: label,
          filled: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  LatLng _selectedPoint = LatLng(14.5995, 120.9842); // Default: Manila

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pick Location")),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: _selectedPoint,
          initialZoom: 13,
          onTap: (tapPosition, point) {
            setState(() {
              _selectedPoint = point;
            });
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          ),
          MarkerLayer(
            markers: [
              Marker(
                width: 40,
                height: 40,
                point: _selectedPoint,
                child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pop(context, _selectedPoint);
        },
        label: const Text("Select"),
        icon: const Icon(Icons.check),
      ),
    );
  }
}

/// 🔥 New Jobs Map screen for jobseekers
class JobsMapScreen extends StatelessWidget {
  const JobsMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Available Jobs")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('jobs').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final jobs = snapshot.data!.docs;

          List<Marker> markers = jobs.map((doc) {
            final job = doc.data() as Map<String, dynamic>;
            final lat = (job['lat'] ?? 14.5995).toDouble();
            final lng = (job['lng'] ?? 120.9842).toDouble();
            final title = job['title'] ?? "Job";
            final company = job['location'] ?? "Unknown Location";

            return Marker(
              point: LatLng(lat, lng),
              width: 60,
              height: 60,
              child: GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text(title),
                      content: Text("📍 $company\nLat: $lat, Lng: $lng"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Close"),
                        ),
                        TextButton(
                          onPressed: () {
                            // TODO: Navigate to job application form
                            Navigator.pop(context);
                          },
                          child: const Text("Apply"),
                        ),
                      ],
                    ),
                  );
                },
                child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
              ),
            );
          }).toList();

          return FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(14.5995, 120.9842),
              initialZoom: 12,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              ),
              MarkerLayer(markers: markers),
            ],
          );
        },
      ),
    );
  }
}
