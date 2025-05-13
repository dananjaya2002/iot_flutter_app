import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';

class DevicesPage extends StatefulWidget {
  final Function(String?) onDeviceSelected; // Callback for device selection

  const DevicesPage({
    super.key,
    required this.onDeviceSelected,
  });

  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  final List<Map<String, dynamic>> _connectedDevices = [];

  late final DatabaseReference _databaseRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://iot-app-6153d-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref('sensor_data');

  late StreamSubscription _deviceListener;

  @override
  void initState() {
    super.initState();
    _startListeningToDevices();
  }

  void _startListeningToDevices() {
    _deviceListener = _databaseRef.onValue.listen((event) {
      final snapshot = event.snapshot;
      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value as Map<dynamic, dynamic>;

        setState(() {
          _connectedDevices.clear();

          data.forEach((deviceKey, deviceData) {
            if (deviceData is Map<dynamic, dynamic>) {
              int latestTimestamp = 0;

              deviceData.forEach((readingKey, readingValue) {
                if (readingValue is Map<dynamic, dynamic> &&
                    readingValue.containsKey('timestamp')) {
                  int ts = readingValue['timestamp'] ?? 0;
                  if (ts > latestTimestamp) {
                    latestTimestamp = ts;
                  }
                }
              });

              _connectedDevices.add({
                'id': deviceKey.toString(),
                'latestTimestamp': latestTimestamp,
              });
            }
          });
        });
      } else {
        setState(() {
          _connectedDevices.clear();
        });
      }
    }, onError: (error) {
      print("Firebase error: $error");
    });
  }

  void _showAddDeviceDialog(BuildContext context) {
    final TextEditingController deviceIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add New Device"),
        content: TextField(
          controller: deviceIdController,
          decoration: const InputDecoration(labelText: "Device ID"),
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              final id = deviceIdController.text.trim();
              if (id.isNotEmpty) {
                setState(() {
                  _connectedDevices.add({'id': id, 'latestTimestamp': 0});
                });
                Navigator.of(context).pop();
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _deviceListener.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'AGROW',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      drawer: const Drawer(),
      backgroundColor: const Color(0xFF90D7B6),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Text(
                  'Devices ',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Icon(Icons.battery_charging_full),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              children: const [
                Text('Connected', style: TextStyle(fontSize: 16)),
                SizedBox(width: 5),
                Icon(Icons.circle, size: 12, color: Colors.green),
              ],
            ),
            const SizedBox(height: 10),

            Expanded(
              child: _connectedDevices.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.device_unknown, size: 48, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            "No devices connected",
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Add a device using the button below",
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _connectedDevices.length,
                      itemBuilder: (context, index) {
                        final device = _connectedDevices[index];
                        return _buildDeviceCard(device['id'], device['latestTimestamp']);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddDeviceDialog(context);
        },
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDeviceCard(String? id, dynamic timestamp) {
    String formattedTime = "Never";

    if (timestamp is int && timestamp > 0) {
      // The timestamp is millis() from Arduino, which is uptime in milliseconds
      formattedTime = _formatUptime(timestamp);
    }

    return InkWell(
      onTap: () {
        if (id != null) {
          // Call the callback with the selected device ID
          widget.onDeviceSelected(id);
        }
      },
      child: Card(
        color: const Color(0xFF1F3E2D),
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    id ?? 'Unknown Device',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Icon(Icons.arrow_forward, color: Colors.white70),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Last Reading(since device powerd on): $formattedTime',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatUptime(int millis) {
    int seconds = (millis ~/ 1000) % 60;
    int minutes = (millis ~/ 60000) % 60;
    int hours = (millis ~/ 3600000) % 24;
    int days = (millis ~/ 86400000);

    if (days > 0) {
      return "$days days, $hours hrs";
    } else if (hours > 0) {
      return "$hours hrs, $minutes mins";
    } else if (minutes > 0) {
      return "$minutes mins, $seconds secs";
    } else {
      return "$seconds secs";
    }
  }
}