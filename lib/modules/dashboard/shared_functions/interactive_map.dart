import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InteractiveMap extends StatefulWidget {
  const InteractiveMap({super.key});

  @override
  State<InteractiveMap> createState() => _InteractiveMapState();
}

class _InteractiveMapState extends State<InteractiveMap> {
  final MapController _mapController = MapController();
  final LatLng _defaultCenter = LatLng(14.5995, 120.9842); // Manila, PH

  // 🔑 Your Mapbox API key
  final String mapboxToken =
      "pk.eyJ1IjoicmVpamkyMDAyIiwiYSI6ImNsdnV6b2Q5YzFzMjgya214ZW5rZnFwZTEifQ.pEJZ0EOKW3tMR0wxmr--cQ";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading:
            false, // 🚫 removes the back button in the AppBar
        title: const Text("Jobs Map"),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              _mapController.move(_defaultCenter, 13);
            },
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

          List<Marker> markers = jobs.map((job) {
            final data = job.data() as Map<String, dynamic>;

            // Expect job data to have: latitude, longitude, jobTitle, company
            double lat = (data['latitude'] ?? 14.5995).toDouble();
            double lng = (data['longitude'] ?? 120.9842).toDouble();
            String jobTitle = data['jobTitle'] ?? "Job";
            String company = data['company'] ?? "Company";

            return Marker(
              point: LatLng(lat, lng),
              width: 60,
              height: 60,
              child: GestureDetector(
                onTap: () {
                  // Show popup with job details
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(jobTitle),
                      content: Text("Company: $company\nLocation: ($lat, $lng)"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Close"),
                        ),
                        TextButton(
                          onPressed: () async {
                            final user = FirebaseAuth.instance.currentUser;

                            if (user == null) {
                              // Not logged in → alert instead of snackbar
                              showDialog(
                                context: context,
                                builder: (_) => const AlertDialog(
                                  title: Text("Login Required"),
                                  content: Text(
                                      "You must be logged in to apply for jobs."),
                                ),
                              );
                              return;
                            }

                            try {
                              await FirebaseFirestore.instance
                                  .collection('jobs')
                                  .doc(job.id) // the job document ID
                                  .collection('applications')
                                  .doc(user.uid) // user applies only once
                                  .set({
                                'userId': user.uid,
                                'appliedAt': FieldValue.serverTimestamp(),
                                'status': 'pending', // employer updates later
                              });

                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text("Success"),
                                  content: Text(
                                      "Application submitted for $jobTitle"),
                                ),
                              );
                            } catch (e) {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text("Error"),
                                  content: Text("Error applying: $e"),
                                ),
                              );
                            }

                            Navigator.pop(context); // close job details dialog
                          },
                          child: const Text("Apply"),
                        ),
                      ],
                    ),
                  );
                },
                child: const Icon(Icons.location_pin,
                    color: Colors.red, size: 40),
              ),
            );
          }).toList();

          return FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _defaultCenter,
              initialZoom: 12,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    "https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/256/{z}/{x}/{y}@2x?access_token={accessToken}",
                additionalOptions: {
                  'accessToken': mapboxToken, // ✅ correct key
                },
                userAgentPackageName: 'com.accesijobs.app',
              ),
              MarkerLayer(markers: markers),
            ],
          );
        },
      ),
    );
  }
}
