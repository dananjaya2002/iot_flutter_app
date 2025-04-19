import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class DevicesPage extends StatefulWidget {
  const DevicesPage({super.key});

  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  final List<DiscoveredDevice> _devicesList = [];
  late Stream<DiscoveredDevice> _scanStream;
  bool isScanning = false;

  @override
  void initState() {
    super.initState();
    _scanStream = _ble.scanForDevices(withServices: []);
  }

  void _startBluetoothScan() {
    setState(() {
      isScanning = true;
      _devicesList.clear(); // Clear the list before starting a new scan
    });

    _scanStream.listen((device) {
      if (!_devicesList.any((d) => d.id == device.id)) {
        setState(() {
          _devicesList.add(device);
        });
      }
    }).onDone(() {
      setState(() {
        isScanning = false;
      });
    });
  }

  void _showAddDeviceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Device'),
          content: SizedBox(
            width: double.maxFinite,
            child: isScanning
                ? const Center(child: CircularProgressIndicator())
                : _devicesList.isEmpty
                    ? const Center(child: Text('No devices found.'))
                    : ListView.builder(
                        itemCount: _devicesList.length,
                        itemBuilder: (context, index) {
                          final device = _devicesList[index];
                          return ListTile(
                            title: Text(device.name.isNotEmpty ? device.name : "Unknown Device"),
                            subtitle: Text(device.id),
                            onTap: () {
                              _connectToDevice(device);
                              Navigator.of(context).pop();
                            },
                          );
                        },
                      ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _connectToDevice(DiscoveredDevice device) async {
    try {
      _ble.connectToDevice(id: device.id).listen((connectionState) {
        if (connectionState.connectionState == DeviceConnectionState.connected) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Connected to ${device.name}')),
            );
          }
        }
      }, onError: (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to connect to ${device.name}: $error')),
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to connect to ${device.name}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(),
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
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 20),
            child: Center(
              child: Text(
                'Hi Sehara!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          )
        ],
      ),
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
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
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
            _buildDeviceCard('Tea Estate Device 1', '0h 20min', '68%', true),
            _buildDeviceCard('Tea Estate Device 2', '0h 10min', '38%', true),
            const SizedBox(height: 10),
            Row(
              children: const [
                Text('Disconnected', style: TextStyle(fontSize: 16)),
                SizedBox(width: 5),
                Icon(Icons.circle, size: 12, color: Colors.red),
              ],
            ),
            const SizedBox(height: 10),
            _buildDeviceCard('Tea Estate Device 3', '0h 10min', '38%', false),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _startBluetoothScan();
          _showAddDeviceDialog(context);
        },
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDeviceCard(String name, String time, String battery, bool isConnected) {
    return Card(
      color: isConnected ? const Color(0xFF1F3E2D) : const Color(0xFF2F3F35),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: const TextStyle(color: Colors.white70),
            ),
            Text(
              '$battery Battery Remaining',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}