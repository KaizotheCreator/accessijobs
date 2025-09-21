import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:accessijobs/modules/dashboard/jobseeker_functions/job_listing.dart'; // Import JobListingPage

/// Available modes
enum MapMode { pickLocation, manageJobs, viewJobs }

class InteractiveMap extends StatefulWidget {
  final MapMode mode;

  const InteractiveMap({super.key, required this.mode});

  @override
  State<InteractiveMap> createState() => _InteractiveMapState();
}

class _InteractiveMapState extends State<InteractiveMap>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  LatLng? _userLocation;
  LatLng? _selectedLocation;
  String? _userRole;
  String? _userId;

  final String mapboxToken =
      "pk.eyJ1IjoicmVpamkyMDAyIiwiYSI6ImNsdnV6b2Q5YzFzMjgya214ZW5rZnFwZTEifQ.pEJZ0EOKW3tMR0wxmr--cQ";

  /// Philippine bounding box
  final LatLngBounds philippinesBounds = LatLngBounds(
    const LatLng(4.6, 116.0), // Southwest
    const LatLng(21.3, 127.0), // Northeast
  );

  /// Track selected job marker
  String? _selectedJobId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadLocation();
  }

  /// Load user data to determine role
  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

    if (userDoc.exists) {
      setState(() {
        _userId = user.uid;
        _userRole = userDoc['role']; // 'employer' or 'jobseeker'
      });
    }
  }

  /// Get current user location
  Future<void> _loadLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      LatLng userLatLng = LatLng(position.latitude, position.longitude);

      // Default to PH center if location is outside PH bounds
      if (!philippinesBounds.contains(userLatLng)) {
        userLatLng = const LatLng(13.41, 122.56);
      }

      setState(() {
        _userLocation = userLatLng;
      });
    } catch (e) {
      debugPrint("❌ Error getting location: $e");
    }
  }

  /// Delete a job (for employers)
  Future<void> _deleteJob(String jobId) async {
    try {
      await FirebaseFirestore.instance.collection('jobs').doc(jobId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Job deleted successfully")),
      );
    } catch (e) {
      debugPrint("❌ Failed to delete job: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to delete job")),
      );
    }
  }

  /// Apply for a job (for jobseekers) -> Navigate with slide transition
  void _applyForJob(String jobId) {
  Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => JobListingPage(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0); // Slide from right
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    if (_userLocation == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: widget.mode != MapMode.viewJobs, // Remove back button in Explore Jobs
        title: Text(
          widget.mode == MapMode.pickLocation
              ? "Pick Job Location"
              : widget.mode == MapMode.manageJobs
                  ? "Manage Jobs"
                  : "Explore Jobs",
        ),
        backgroundColor: Colors.blue,
        actions: [
          if (widget.mode == MapMode.pickLocation && _selectedLocation != null)
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context, {
                  'lat': _selectedLocation!.latitude,
                  'lng': _selectedLocation!.longitude,
                });
              },
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text(
                "Confirm",
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('jobs').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final jobs = snapshot.data!.docs;

          List<Marker> jobMarkers = jobs.map((job) {
            final data = job.data() as Map<String, dynamic>;
            final double lat = (data['lat'] ?? 0).toDouble();
            final double lng = (data['lng'] ?? 0).toDouble();
            final String jobId = job.id;
            final String jobTitle = data['title'] ?? "Untitled Job";
            final String employerId = data['employerId'] ?? "";

            return Marker(
              point: LatLng(lat, lng),
              width: 100,
              height: 100,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedJobId = jobId; // Highlight this job
                    _selectedLocation = LatLng(lat, lng);
                  });

                  if (widget.mode == MapMode.manageJobs && employerId == _userId) {
                    // Employer managing their job
                    showModalBottomSheet(
                      context: context,
                      builder: (ctx) => Wrap(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.edit, color: Colors.blue),
                            title: const Text("Edit Job"),
                            onTap: () {
                              Navigator.pop(ctx);
                              Navigator.pushNamed(context, '/editJob',
                                  arguments: {'jobId': jobId});
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.delete, color: Colors.red),
                            title: const Text("Delete Job"),
                            onTap: () async {
                              Navigator.pop(ctx);
                              await _deleteJob(jobId);
                            },
                          ),
                        ],
                      ),
                    );
                  } else if (widget.mode == MapMode.viewJobs) {
                    // Jobseeker viewing jobs
                    showModalBottomSheet(
                      context: context,
                      builder: (ctx) => Wrap(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.info, color: Colors.green),
                            title: Text(jobTitle),
                            subtitle: const Text("Tap to apply for this job"),
                          ),
                          ListTile(
                            leading: const Icon(Icons.check, color: Colors.blue),
                            title: const Text("Apply for Job"),
                            onTap: () {
                              Navigator.pop(ctx);
                              _applyForJob(jobId); // Slide to JobListingPage
                            },
                          ),
                        ],
                      ),
                    );
                  }
                },
                child: AnimatedScale(
                  scale: _selectedJobId == jobId ? 1.4 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_pin,
                        color: widget.mode == MapMode.manageJobs &&
                                employerId == _userId
                            ? Colors.orange // Employer's own jobs
                            : Colors.red,
                        size: 40,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          jobTitle,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList();

          return FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _userLocation!,
              initialZoom: 12,
              minZoom: 8,
              maxZoom: 25,
              interactionOptions:
                  const InteractionOptions(flags: InteractiveFlag.all),
              onTap: (tapPosition, point) {
                if (widget.mode == MapMode.pickLocation) {
                  setState(() {
                    _selectedLocation = point;
                    _selectedJobId = null;
                  });
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    "https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/256/{z}/{x}/{y}@2x?access_token={accessToken}",
                additionalOptions: {'accessToken': mapboxToken},
                userAgentPackageName: 'com.accessijobs.app',
              ),
              MarkerLayer(markers: jobMarkers),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _userLocation!,
                    width: 60,
                    height: 60,
                    child: const Icon(
                      Icons.my_location,
                      color: Colors.blue,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: widget.mode == MapMode.pickLocation &&
              _selectedLocation != null
          ? Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Text(
                "Selected Location: "
                "Lat: ${_selectedLocation!.latitude.toStringAsFixed(5)}, "
                "Lng: ${_selectedLocation!.longitude.toStringAsFixed(5)}",
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
