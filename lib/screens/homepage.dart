import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String lastName = "User"; // Default value
  bool isConnected = true; // Simulating connection status (true = connected, false = disconnected)

  @override
  void initState() {
    super.initState();
    _fetchLastName();
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

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final formattedDate = DateFormat('dd/MM/yyyy hh:mm a').format(now);

    return Scaffold(
      backgroundColor: const Color(0xFF88C5A3),
      drawer: Drawer(),
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
      body: SingleChildScrollView(
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
                children: isConnected
                    ? const [
                        InfoCard(label: "Nitrogen", percentage: 80, quality: "Bad Quality", color: Colors.orange),
                        InfoCard(label: "Potassium", percentage: 40, quality: "Critical Quality", color: Colors.red),
                        InfoCard(label: "Phosphorus", percentage: 90, quality: "Good Quality", color: Colors.blue),
                        InfoCard(label: "Moisture", percentage: 90, quality: "Perfect Quality", color: Colors.green),
                      ]
                    : const [
                        NoDataCard(label: "Nitrogen"),
                        NoDataCard(label: "Potassium"),
                        NoDataCard(label: "Phosphorus"),
                        NoDataCard(label: "Moisture"),
                      ],
              ),
              const SizedBox(height: 16),
              if (isConnected)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    "Critical! Need to add more Potassium.",
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                )
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
              if (isConnected)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(formattedDate, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      const RecordRow(label: "Nitrogen", value: "50%", quality: "Critical", color: Colors.red),
                      const RecordRow(label: "Potassium", value: "32%", quality: "Good", color: Colors.blue),
                      const RecordRow(label: "Phosphorus", value: "15%", quality: "Bad", color: Colors.orange),
                      const RecordRow(label: "Moisture", value: "86%", quality: "Perfect", color: Colors.green),
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
    );
  }
}

class InfoCard extends StatelessWidget {
  final String label;
  final int percentage;
  final String quality;
  final Color color;

  const InfoCard({
    super.key,
    required this.label,
    required this.percentage,
    required this.quality,
    required this.color,
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
          Text("$percentage%", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
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