import 'package:flutter/material.dart';
import 'homepage.dart';
import 'devices_page.dart';
import 'fertilizer_screen.dart';
import 'about_us_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  String? selectedDeviceId;
  Map<String, dynamic> fertilizerData = {};

  void navigateToFertilizer(Map<String, dynamic> data) {
    setState(() {
      fertilizerData = data;
      _currentIndex = 2;
    });
  }

  void updateDeviceId(String? deviceId) {
    if (deviceId != null) {
      print("Device selected: $deviceId"); // Debug print
      setState(() {
        selectedDeviceId = deviceId;
        _currentIndex = 0; // Navigate to Home page
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Create screens list inside build to ensure they get rebuilt with the latest selectedDeviceId
    final List<Widget> screens = [
      HomePage(
        onFertilizerRecommendation: navigateToFertilizer,
        deviceId: selectedDeviceId,
        key: ValueKey(selectedDeviceId), // Add key to force rebuild when deviceId changes
      ),
      DevicesPage(onDeviceSelected: updateDeviceId),
      FertilizerScreen(initialData: fertilizerData),
      AboutUsScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.devices), label: 'Devices'),
          BottomNavigationBarItem(icon: Icon(Icons.agriculture), label: 'Fertilizer'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'About Us'),
        ],
      ),
    );
  }
}