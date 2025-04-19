import 'package:flutter/material.dart';
import 'homepage.dart';
import 'devices_page.dart';
import 'fertilizer_screen.dart';
import 'about_us_screen.dart'; // Import the Profile Page

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // List of screens for each tab
  final List<Widget> _screens = [
    HomePage(), // Home tab
    DevicesPage(), // Devices tab
    FertilizerScreen(), // Fertilizer tab
    AboutUsScreen(), // Profile tab
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex], // Display the selected screen
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index; // Update the selected tab
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