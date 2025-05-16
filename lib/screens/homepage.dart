import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  final Function(Map<String, dynamic>) onFertilizerRecommendation;
  final String? deviceId; // Optional - will be set from route args or default
  const HomePage({super.key, required this.onFertilizerRecommendation, this.deviceId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String lastName = "User";
  bool isConnected = false;
  
  Map<String, dynamic> latestReading = {};
  Map<String, dynamic> previousReading = {};
  String? deviceId;

  @override
  void initState() {
    super.initState();
    _fetchLastName();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    setState(() {
      deviceId = widget.deviceId ?? args?['deviceId'] as String?;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchSoilData();
      }
    });
  }

  Future<void> _fetchLastName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          setState(() {
            lastName = doc.data()?['lastName'] ?? "User";
          });
        }
      }
    } catch (e) {
      print("Error fetching last name: $e");
    }
  }

  Future<void> _fetchSoilData() async {
    if (deviceId == null) {
      setState(() {
        isConnected = false;
        latestReading = {};
        previousReading = {};
      });
      return;
    }

    try {
      final databaseRef = FirebaseDatabase.instance.ref().child('sensor_data');
      final snapshot = await databaseRef.child(deviceId!).get();

      final readings = <Map<String, dynamic>>[];
      if (snapshot.exists) {
        snapshot.children.forEach((DataSnapshot childSnapshot) {
          final value = childSnapshot.value as Map<dynamic, dynamic>?;
          if (value != null) {
            final reading = Map<String, dynamic>.from(
              value.map((key, val) => MapEntry(key.toString(), val)),
            );
            readings.add(reading);
          }
        });

        if (readings.isNotEmpty) {
          // Sort by timestamps using ISO 8601 format
          readings.sort((a, b) {
            try {
              final aTimeStr = a['timestamp']?.toString() ?? '';
              final bTimeStr = b['timestamp']?.toString() ?? '';
              
              if (aTimeStr.isEmpty || bTimeStr.isEmpty) {
                return 0;
              }
              
              final aTime = DateTime.parse(aTimeStr);
              final bTime = DateTime.parse(bTimeStr);
              
              // Sort in descending order (newest first)
              return bTime.compareTo(aTime);
            } catch (e) {
              print("Error comparing timestamps: $e");
              return 0;
            }
          });

          setState(() {
            isConnected = true;
            latestReading = readings[0];
            previousReading = readings.length > 1 ? readings[1] : {};
          });
        } else {
          setState(() {
            isConnected = false;
            latestReading = {};
            previousReading = {};
          });
        }
      } else {
        setState(() {
          isConnected = false;
          latestReading = {};
          previousReading = {};
        });
      }
    } catch (e) {
      print("Error fetching soil data: $e");
      setState(() {
        isConnected = false;
        latestReading = {};
        previousReading = {};
      });
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      print("Error logging out: $e");
    }
  }

  String formatTimestamp(dynamic timestamp) {
    try {
      if (timestamp is String) {
        // Parse the ISO 8601 timestamp
        final dateTime = DateTime.parse(timestamp);
        
        // Apply your timezone offset (5 hours and 29 minutes)
        final localDateTime = dateTime.add(const Duration(hours: 5, minutes: 29));
        
        // Format to display
        return DateFormat('dd/MM/yyyy hh:mm a').format(localDateTime);
      } else {
        // Fallback to current time if timestamp is not in expected format
        return DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now());
      }
    } catch (e) {
      print("Error formatting date: $e");
      return DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now());
    }
  }

  @override
  Widget build(BuildContext context) {      
    
    return Scaffold(
      backgroundColor: const Color(0xFF88C5A3),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.teal),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AGROW',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Hi $lastName!",
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: _logout,
            ),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'AGROW',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                "Hi $lastName!",
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchSoilData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Connection status indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isConnected
                        ? Colors.green.withOpacity(0.3)
                        : Colors.red.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isConnected ? Icons.wifi : Icons.wifi_off,
                        color: isConnected ? Colors.green : Colors.red,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isConnected ? "Connected" : "Disconnected",
                        style: TextStyle(
                          color: isConnected ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Latest Reading section
                Row(
                  children: [
                    const Icon(Icons.update, color: Colors.black),
                    const SizedBox(width: 6),
                    const Text(
                      "Latest Reading",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    if (isConnected && latestReading.containsKey('timestamp'))
                      Text(
                        formatTimestamp(latestReading['timestamp']),
                        style: const TextStyle(fontSize: 12),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Latest reading cards
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: isConnected && latestReading.isNotEmpty
                      ? [
                          InfoCard(
                            label: "Nitrogen",
                            amount: latestReading['n']?.toInt() ?? 0,
                          ),
                          InfoCard(
                            label: "Potassium",
                            amount: latestReading['k']?.toInt() ?? 0,
                          ),
                          InfoCard(
                            label: "Phosphorus",
                            amount: latestReading['p']?.toInt() ?? 0,
                          ),
                          InfoCard(
                            label: "pH",
                            amount: latestReading['ph']?.toInt() ?? 0,
                            value:
                                latestReading['ph']?.toStringAsFixed(2) ?? "0",
                            showDecimal: true,
                          ),
                        ]
                      : const [
                          NoDataCard(label: "Nitrogen"),
                          NoDataCard(label: "Potassium"),
                          NoDataCard(label: "Phosphorus"),
                          NoDataCard(label: "pH"),
                        ],
                ),
                const SizedBox(height: 16),
                // Button to navigate to Fertilizer screen with latest data
                if (isConnected && latestReading.isNotEmpty)
                  Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.agriculture),
                      label: const Text("Get Fertilizer Recommendations"),
                      onPressed: () {
                        widget.onFertilizerRecommendation({
                          'nitrogen': latestReading['n'] ?? 0,
                          'phosphorus': latestReading['p'] ?? 0,
                          'potassium': latestReading['k'] ?? 0,
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                // Last Record section
                Row(
                  children: [
                    const Icon(Icons.history, color: Colors.black),
                    const SizedBox(width: 6),
                    const Text(
                      "Last Record",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    if (isConnected && previousReading.containsKey('timestamp'))
                      Text(
                        formatTimestamp(previousReading['timestamp']),
                        style: const TextStyle(fontSize: 12),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                // Previous reading details
                if (isConnected && previousReading.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [                        
                        const SizedBox(height: 10),
                        RecordRow(
                          label: "Nitrogen",
                          value:
                              "${previousReading['n']?.toStringAsFixed(1) ?? '0'} kg/ha",
                        ),
                        const SizedBox(height: 4),
                        RecordRow(
                          label: "Potassium",
                          value:
                              "${previousReading['k']?.toStringAsFixed(1) ?? '0'} kg/ha",
                        ),
                        const SizedBox(height: 4),
                        RecordRow(
                          label: "Phosphorus",
                          value:
                              "${previousReading['p']?.toStringAsFixed(1) ?? '0'} kg/ha",
                        ),
                        const SizedBox(height: 4),
                        RecordRow(
                          label: "pH",
                          value:
                              "${previousReading['ph']?.toStringAsFixed(2) ?? '0'}",
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        "No previous records available",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- Reusable Widgets ---

class InfoCard extends StatelessWidget {
  final String label;
  final int amount;
  final String? value;
  final bool showDecimal;

  const InfoCard({
    super.key,
    required this.label,
    required this.amount,
    this.value,
    this.showDecimal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.44,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            showDecimal && value != null ? value! : "$amount kg/ha",
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class NoDataCard extends StatelessWidget {
  final String label;

  const NoDataCard({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.44,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          "No Data Available for $label",
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class RecordRow extends StatelessWidget {
  final String label;
  final String value;

  const RecordRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}