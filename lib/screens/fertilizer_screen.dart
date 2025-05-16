import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FertilizerScreen extends StatefulWidget {
  final Map<String, dynamic> initialData;

  const FertilizerScreen({super.key, this.initialData = const {}});

  @override
  _FertilizerScreenState createState() => _FertilizerScreenState();
}

class _FertilizerScreenState extends State<FertilizerScreen> {
  final TextEditingController _nitrogenController = TextEditingController();
  final TextEditingController _phosphorusController = TextEditingController();
  final TextEditingController _potassiumController = TextEditingController();

  String recommendation =
      "Select the plant type and Enter NPK values to get recommendations.";
  String selectedPlant = "No Plant selected"; // Default plant name

  // Variables to store recommended NPK values
  String recommendedNitrogen = "N/A";
  String recommendedPhosphorus = "N/A";
  String recommendedPotassium = "N/A";

  @override
  void initState() {
    super.initState();
    // We'll initialize the controllers with the passed values in didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get the arguments from the route
    final Map<String, dynamic>? args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    // Use either route arguments or widget initial data
    final Map<String, dynamic> data = args ?? widget.initialData;

    if (data.isNotEmpty) {
      // Set the controllers with the passed values
      _nitrogenController.text = data['nitrogen']?.toString() ?? '';
      _phosphorusController.text = data['phosphorus']?.toString() ?? '';
      _potassiumController.text = data['potassium']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _nitrogenController.dispose();
    _phosphorusController.dispose();
    _potassiumController.dispose();
    super.dispose();
  }

  /// Fetch NPK values for the selected plant from Firebase
  Future<Map<String, dynamic>?> fetchNpkValues(String plantName) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final doc =
          await firestore
              .collection('fertilizer_recommendations')
              .doc('plants')
              .get();

      if (!doc.exists) {
        print("Document does not exist.");
        return null;
      }

      final data = doc.data();
      if (data == null || data['plants'] == null) {
        print("No plants data found in Firestore.");
        return null;
      }

      final List<dynamic> plants = data['plants'];

      // Find the plant by name without considering type
      final Map<String, dynamic>? plant = plants.firstWhere(
        (p) => p['name'] == plantName,
        orElse: () => null,
      );

      if (plant == null) {
        print("Plant '$plantName' not found.");
        return null;
      }

      return {"N": plant['N'], "P": plant['P'], "K": plant['K']};
    } catch (e) {
      print('Error fetching NPK values: $e');
      return null;
    }
  }

  /// Get fertilizer recommendation
  Future<void> _getRecommendation() async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Get values from controllers
    final double nitrogen = double.tryParse(_nitrogenController.text) ?? 0;
    final double phosphorus = double.tryParse(_phosphorusController.text) ?? 0;
    final double potassium = double.tryParse(_potassiumController.text) ?? 0;

    final recommendedNpk = await fetchNpkValues(selectedPlant);

    // Close loading indicator
    Navigator.of(context).pop();

    if (recommendedNpk != null) {
      setState(() {
        recommendation = calculateFertilizerNeeds(
          recommendedNpk,
          nitrogen,
          phosphorus,
          potassium,
        );
      });
    } else {
      setState(() {
        recommendation = "No recommendations found for $selectedPlant.";
      });
    }
  }

  /// Calculate fertilizer needs based on the difference between measured and recommended values
  String calculateFertilizerNeeds(
    Map<String, dynamic> recommendedNpk,
    double nitrogen,
    double phosphorus,
    double potassium,
  ) {
    final double recommendedNitrogen =
        double.tryParse(recommendedNpk['N'].toString()) ?? 0;
    final double recommendedPhosphorus =
        double.tryParse(recommendedNpk['P'].toString()) ?? 0;
    final double recommendedPotassium =
        double.tryParse(recommendedNpk['K'].toString()) ?? 0;

    final double nitrogenNeeded =
        (recommendedNitrogen - nitrogen).clamp(0, double.infinity);
    final double phosphorusNeeded =
        (recommendedPhosphorus - phosphorus).clamp(0, double.infinity);
    final double potassiumNeeded =
        (recommendedPotassium - potassium).clamp(0, double.infinity);

  return 'Need to add:\nNitrogen: $nitrogenNeeded kg/ha\nPhosphorus: $phosphorusNeeded kg/ha\nPotassium: $potassiumNeeded kg/ha';
}

  // Show a dialog to select a plant
  Future<void> _selectPlant() async {
    final plant = await showPlantSearchDialog(context);
    if (plant != null) {
      setState(() {
        selectedPlant = plant;
      });

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final recommendedNpk = await fetchNpkValues(plant);

      // Close loading indicator
      Navigator.of(context).pop();

      if (recommendedNpk != null) {
        setState(() {
          recommendedNitrogen = recommendedNpk['N'].toString();
          recommendedPhosphorus = recommendedNpk['P'].toString();
          recommendedPotassium = recommendedNpk['K'].toString();
        });
      }
    }
  }

  /// Show a search dialog for selecting a plant
  Future<String?> showPlantSearchDialog(BuildContext context) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final firestore = FirebaseFirestore.instance;
    final doc =
        await firestore
            .collection('fertilizer_recommendations')
            .doc('plants')
            .get();

    // Close loading indicator
    Navigator.of(context).pop();

    if (!doc.exists) {
      print("Document does not exist.");
      return null;
    }

    final data = doc.data();
    if (data == null || data['plants'] == null) {
      print("No plants data found in Firestore.");
      return null;
    }

    final List<dynamic> plants = data['plants'];
    final List<String> plantNames =
        plants.map<String>((p) => p['name']).toList();

    if (plantNames.isEmpty) {
      print("No plants found.");
      return null;
    }

    String? selectedPlant;

    return await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Plant'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: plantNames.first,
                  items:
                      plantNames.map((plant) {
                        return DropdownMenuItem(
                          value: plant,
                          child: Text(plant),
                        );
                      }).toList(),
                  onChanged: (value) {
                    selectedPlant = value;
                  },
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: "Select a plant",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: Navigator.of(context).pop,
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(selectedPlant);
              },
              child: const Text('Select'),
            ),
          ],
        );
      },
    );
  }

  void _resetAll() {
    setState(() {
      // Clear input fields
      _nitrogenController.clear();
      _phosphorusController.clear();
      _potassiumController.clear();

      // Reset selected plant
      selectedPlant = "No Plant Selected";

      // Reset recommended NPK
      recommendedNitrogen = "N/A";
      recommendedPhosphorus = "N/A";
      recommendedPotassium = "N/A";

      // Reset recommendation
      recommendation = "Select a plant and enter NPK values.";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF88C5A3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Fertilizer Recommendations',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(       
        
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Plant selection section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.grass, color: Colors.green),
                          const SizedBox(width: 8),
                          const Text(
                            "Selected Plant:",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          ElevatedButton(
                            onPressed: _selectPlant,
                            child: const Text("Select Plant"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          selectedPlant,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Recommended NPK Values:",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text("Nitrogen: $recommendedNitrogen kg/ha"),
                      Text("Phosphorus: $recommendedPhosphorus kg/ha"),
                      Text("Potassium: $recommendedPotassium kg/ha"),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Measurements input section
                const Text(
                  "Enter your soil measurements:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nitrogenController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Measured Nitrogen (kg/ha)",
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white70,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _phosphorusController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Measured Phosphorus (kg/ha)",
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white70,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _potassiumController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Measured Potassium (kg/ha)",
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white70,
                  ),
                ),
                const SizedBox(height: 24),
                // Calculate button
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.calculate),
                    label: const Text("Calculate Recommendation"),
                    onPressed: _getRecommendation,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Reset button
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text("Reset Inputs"),
                    onPressed: _resetAll,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Recommendation section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.teal.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Recommendation",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        recommendation,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),        
      ),
    );
  }
}
