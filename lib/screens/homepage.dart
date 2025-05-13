import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String lastName = "User"; // Default value
  bool isConnected = false; // Connection status
  final String deviceId = "NPK-C4A95AFD"; // Your IoT device ID
  
  // Data for live information (latest reading)
  Map<String, dynamic> latestReading = {};
  
  // Data for last record (previous reading)
  Map<String, dynamic> previousReading = {};

  @override
  void initState() {
    super.initState();
    _fetchLastName();
    // Add a short delay to ensure Firebase is initialized properly
    Future.delayed(const Duration(milliseconds: 500), () {
      _fetchSoilData();
    });
  }

  Future<void> _fetchLastName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          setState(() {
            lastName = doc.data()?['lastName'] ?? "User"; // Fallback to "User" if lastName is null
          });
        }
      }
    } catch (e) {
      print("Error fetching last name: $e");
    }
  }
  
  Future<void> _fetchSoilData() async {
    try {
      // Reference to the sensor data in Firebase Realtime Database
      final databaseRef = FirebaseDatabase.instance.ref().child('sensor_data');
      
      // Debug log to check reference path
      print("Trying to fetch data from: ${databaseRef.path}");
      
      // Get the data snapshot
      final snapshot = await databaseRef.get();
      
      if (snapshot.exists) {
        print("Data exists at path: ${databaseRef.path}");
        
        // Parse the data structure based on your provided example
        if (snapshot.hasChild(deviceId)) {
          print("Found device: $deviceId");
          
          // Get the device-specific data
          final deviceSnapshot = snapshot.child(deviceId);
          
          // Convert to a list of readings
          List<Map<String, dynamic>> readings = [];
          
          // Iterate through device readings
          deviceSnapshot.children.forEach((DataSnapshot readingSnapshot) {
            if (readingSnapshot.value != null) {
              // Convert to map and add key
              Map<String, dynamic> reading = Map<String, dynamic>.from(readingSnapshot.value as Map);
              reading['key'] = readingSnapshot.key;
              readings.add(reading);
              print("Added reading with timestamp: ${reading['timestamp']}");
            }
          });
          
          if (readings.isNotEmpty) {
            print("Found ${readings.length} readings");
            
            // Sort readings by timestamp (most recent first)
            readings.sort((a, b) {
              int timeA = a['timestamp'] is int ? a['timestamp'] : int.parse(a['timestamp'].toString());
              int timeB = b['timestamp'] is int ? b['timestamp'] : int.parse(b['timestamp'].toString());
              return timeB.compareTo(timeA);
            });
            
            setState(() {
              isConnected = true;
              latestReading = readings[0];
              print("Latest reading: $latestReading");
              
              // If there are at least 2 readings, get the second one as previous reading
              if (readings.length > 1) {
                previousReading = readings[1];
              } else {
                // If only one reading, use it for both
                previousReading = readings[0];
              }
            });
          } else {
            print("No readings found for device: $deviceId");
            setState(() {
              isConnected = false;
            });
          }
        } else {
          print("Device not found: $deviceId");
          setState(() {
            isConnected = false;
          });
        }
      } else {
        print("No data found at path: ${databaseRef.path}");
        setState(() {
          isConnected = false;
        });
      }
    } catch (e) {
      print("Error fetching soil data: $e");
      setState(() {
        isConnected = false;
      });
    }
  }

  // Helper function to determine quality based on nutrient values
  String getNitrogenQuality(double value) {
    if (value >= 80) return "Good Quality";
    if (value >= 50) return "Moderate Quality";
    return "Critical Quality";
  }
  
  String getPhosphorusQuality(double value) {
    if (value >= 20) return "Good Quality";
    if (value >= 10) return "Moderate Quality";
    return "Critical Quality";
  }
  
  String getPotassiumQuality(double value) {
    if (value >= 100) return "Good Quality";
    if (value >= 50) return "Moderate Quality";
    return "Critical Quality";
  }
  
  String getPhQuality(double value) {
    if (value >= 6.0 && value <= 7.5) return "Perfect Quality";
    if ((value >= 5.5 && value < 6.0) || (value > 7.5 && value <= 8.0)) return "Moderate Quality";
    return "Critical Quality";
  }
  
  // Helper function to determine color based on quality
  Color getQualityColor(String quality) {
    switch (quality) {
      case "Good Quality":
        return Colors.blue;
      case "Perfect Quality":
        return Colors.green;
      case "Moderate Quality":
        return Colors.orange;
      case "Critical Quality":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushReplacementNamed('/login'); // Redirect to login screen
    } catch (e) {
      print("Error logging out: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final formattedDate = DateFormat('dd/MM/yyyy hh:mm a').format(now);
    
    // Get formatted date from timestamp if available
    String previousDate = formattedDate;
    if (previousReading.isNotEmpty && previousReading.containsKey('timestamp')) {
      try {
        final timestamp = previousReading['timestamp'] as int;
        // Adjust this multiplier based on your timestamp format (milliseconds vs seconds)
        final previousDateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
        previousDate = DateFormat('dd/MM/yyyy hh:mm a').format(previousDateTime);
      } catch (e) {
        print("Error formatting previous date: $e");
      }
    }

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
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
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
        title: const Text('AGROW', style: TextStyle(fontWeight: FontWeight.bold)),
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
          )
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
                Row(
                  children: [
                    Icon(
                      Icons.circle,
                      color: isConnected ? Colors.green : Colors.red,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isConnected ? "Connected" : "Disconnected",
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: const [
                    Icon(Icons.wifi, color: Colors.blue),
                    SizedBox(width: 6),
                    Text("Live Information", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.2,
                  physics: const NeverScrollableScrollPhysics(),
                  children: isConnected && latestReading.isNotEmpty
                      ? [
                          // Nitrogen
                          InfoCard(
                            label: "Nitrogen", 
                            amount: latestReading['n']?.toInt() ?? 0,
                            quality: getNitrogenQuality(latestReading['n']?.toDouble() ?? 0),
                            color: getQualityColor(getNitrogenQuality(latestReading['n']?.toDouble() ?? 0)),
                          ),
                          // Potassium
                          InfoCard(
                            label: "Potassium", 
                            amount: latestReading['k']?.toInt() ?? 0,
                            quality: getPotassiumQuality(latestReading['k']?.toDouble() ?? 0),
                            color: getQualityColor(getPotassiumQuality(latestReading['k']?.toDouble() ?? 0)),
                          ),
                          // Phosphorus
                          InfoCard(
                            label: "Phosphorus", 
                            amount: latestReading['p']?.toInt() ?? 0,
                            quality: getPhosphorusQuality(latestReading['p']?.toDouble() ?? 0),
                            color: getQualityColor(getPhosphorusQuality(latestReading['p']?.toDouble() ?? 0)),
                          ),
                          // pH (as Moisture in UI)
                          InfoCard(
                            label: "pH", 
                            amount: latestReading['ph']?.toInt() ?? 0,
                            value: latestReading['ph']?.toStringAsFixed(2) ?? "0",
                            quality: getPhQuality(latestReading['ph']?.toDouble() ?? 0),
                            color: getQualityColor(getPhQuality(latestReading['ph']?.toDouble() ?? 0)),
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
                if (isConnected && latestReading.isNotEmpty)
                  _buildRecommendation()
                else
                  const Center(
                    child: Text(
                      "No data available. Please check your connection.",
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ),
                const SizedBox(height: 24),
                Row(
                  children: const [
                    Icon(Icons.history, color: Colors.black),
                    SizedBox(width: 6),
                    Text("Last Record", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 10),
                if (isConnected && previousReading.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(previousDate, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        RecordRow(
                          label: "Nitrogen", 
                          value: "${previousReading['n']?.toStringAsFixed(1) ?? '0'} kg/ha", 
                          quality: getNitrogenQuality(previousReading['n']?.toDouble() ?? 0),
                          color: getQualityColor(getNitrogenQuality(previousReading['n']?.toDouble() ?? 0)),
                        ),
                        RecordRow(
                          label: "Potassium", 
                          value: "${previousReading['k']?.toStringAsFixed(1) ?? '0'} kg/ha", 
                          quality: getPotassiumQuality(previousReading['k']?.toDouble() ?? 0),
                          color: getQualityColor(getPotassiumQuality(previousReading['k']?.toDouble() ?? 0)),
                        ),
                        RecordRow(
                          label: "Phosphorus", 
                          value: "${previousReading['p']?.toStringAsFixed(1) ?? '0'} kg/ha", 
                          quality: getPhosphorusQuality(previousReading['p']?.toDouble() ?? 0),
                          color: getQualityColor(getPhosphorusQuality(previousReading['p']?.toDouble() ?? 0)),
                        ),
                        RecordRow(
                          label: "pH", 
                          value: previousReading['ph']?.toStringAsFixed(2) ?? "0", 
                          quality: getPhQuality(previousReading['ph']?.toDouble() ?? 0),
                          color: getQualityColor(getPhQuality(previousReading['ph']?.toDouble() ?? 0)),
                        ),
                      ],
                    ),
                  )
                else
                  const Center(
                    child: Text(
                      "No data available. Please check your connection.",
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildRecommendation() {
    // Check nutrient levels for recommendations
    final nValue = latestReading['n']?.toDouble() ?? 0;
    final pValue = latestReading['p']?.toDouble() ?? 0;
    final kValue = latestReading['k']?.toDouble() ?? 0;
    final phValue = latestReading['ph']?.toDouble() ?? 0;
    
    List<String> recommendations = [];
    Color recommendationColor = Colors.green;
    
    // Nitrogen recommendation
    if (nValue < 50) {
      recommendations.add("Critical! Need to add more Nitrogen.");
      recommendationColor = Colors.red;
    } else if (nValue < 80) {
      recommendations.add("Moderate! Consider adding more Nitrogen.");
      if (recommendationColor != Colors.red) recommendationColor = Colors.orange;
    }
    
    // Phosphorus recommendation
    if (pValue < 10) {
      recommendations.add("Critical! Need to add more Phosphorus.");
      recommendationColor = Colors.red;
    } else if (pValue < 20) {
      recommendations.add("Moderate! Consider adding more Phosphorus.");
      if (recommendationColor != Colors.red) recommendationColor = Colors.orange;
    }
    
    // Potassium recommendation
    if (kValue < 50) {
      recommendations.add("Critical! Need to add more Potassium.");
      recommendationColor = Colors.red;
    } else if (kValue < 100) {
      recommendations.add("Moderate! Consider adding more Potassium.");
      if (recommendationColor != Colors.red) recommendationColor = Colors.orange;
    }
    
    // pH recommendation
    if (phValue < 5.5 || phValue > 8.0) {
      recommendations.add("Critical! Adjust soil pH level.");
      recommendationColor = Colors.red;
    } else if (phValue < 6.0 || phValue > 7.5) {
      recommendations.add("Moderate! Consider adjusting soil pH level.");
      if (recommendationColor != Colors.red) recommendationColor = Colors.orange;
    }
    
    // If no recommendations, everything is good
    if (recommendations.isEmpty) {
      recommendations.add("All nutrient levels are good! Keep up the good work.");
      recommendationColor = Colors.green;
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(25),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: recommendations.map((rec) => 
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text(
              rec,
              style: TextStyle(color: recommendationColor, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          )
        ).toList(),
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final String label;
  final int amount;
  final String quality;
  final Color color;
  final String? value;  // Optional value for decimal display
  final bool showDecimal;  // Whether to display decimal value instead of integer

  const InfoCard({
    super.key,
    required this.label,
    required this.amount,
    required this.quality,
    required this.color,
    this.value,
    this.showDecimal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha((0.3 * 255).toInt()),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.white)),
          Text(
            showDecimal && value != null ? value! : "$amount kg/ha", 
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)
          ),
          Text(quality, style: TextStyle(color: color)),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha((0.3 * 255).toInt()),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          "No Data Available for $label",
          style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class RecordRow extends StatelessWidget {
  final String label;
  final String value;
  final String quality;
  final Color color;

  const RecordRow({
    super.key,
    required this.label,
    required this.value,
    required this.quality,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(quality, style: TextStyle(color: color)),
        ],
      ),
    );
  }
}