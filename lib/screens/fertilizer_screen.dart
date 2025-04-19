import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FertilizerScreen extends StatefulWidget {
  const FertilizerScreen({super.key});

  @override
  _FertilizerScreenState createState() => _FertilizerScreenState();
}

class _FertilizerScreenState extends State<FertilizerScreen> {
  final TextEditingController _nitrogenController = TextEditingController();
  final TextEditingController _phosphorusController = TextEditingController();
  final TextEditingController _potassiumController = TextEditingController();

  String recommendation = "Select the plant type and Enter NPK values to get recommendations.";
  String selectedPlant = "Unknown Plant";
  String plantType = "vegetables"; // Default plant type

  // Variables to store recommended NPK values
  String recommendedNitrogen = "N/A";
  String recommendedPhosphorus = "N/A";
  String recommendedPotassium = "N/A";

  /// Fetch NPK values for the selected plant from Firebase
  Future<Map<String, dynamic>?> fetchNpkValues(String plantType, String plantName) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final doc = await firestore.collection('fertilizer_recommendations').doc('plants').get();

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
      final plant = plants.firstWhere(
        (p) => p['type'] == plantType && p['name'] == plantName,
        orElse: () => null,
      );

      if (plant == null) {
        print("Plant '$plantName' of type '$plantType' not found.");
        return null;
      }

      return {
        "N": plant['N'],
        "P": plant['P'],
        "K": plant['K'],
      };
    } catch (e) {
      print('Error fetching NPK values: $e');
      return null;
    }
  }

  /// Get fertilizer recommendation
  Future<void> _getRecommendation() async {
    final int nitrogen = int.tryParse(_nitrogenController.text) ?? 0;
    final int phosphorus = int.tryParse(_phosphorusController.text) ?? 0;
    final int potassium = int.tryParse(_potassiumController.text) ?? 0;

    final recommendedNpk = await fetchNpkValues(plantType, selectedPlant);

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
  String calculateFertilizerNeeds(Map<String, dynamic> recommendedNpk, int nitrogen, int phosphorus, int potassium) {
    final int recommendedNitrogen = int.tryParse(recommendedNpk['N'].toString()) ?? 0;
    final int recommendedPhosphorus = int.tryParse(recommendedNpk['P'].toString()) ?? 0;
    final int recommendedPotassium = int.tryParse(recommendedNpk['K'].toString()) ?? 0;

    final int nitrogenNeeded = (recommendedNitrogen - nitrogen).clamp(0, double.infinity).toInt();
    final int phosphorusNeeded = (recommendedPhosphorus - phosphorus).clamp(0, double.infinity).toInt();
    final int potassiumNeeded = (recommendedPotassium - potassium).clamp(0, double.infinity).toInt();

    return 'Need to add Nitrogen: $nitrogenNeeded kg/ha, Phosphorus: $phosphorusNeeded kg/ha, Potassium: $potassiumNeeded kg/ha';
  }

  /// Show a dialog to select a plant
  Future<void> _selectPlant() async {
    final plant = await showPlantSearchDialog(context, plantType);
    if (plant != null) {
      setState(() {
        selectedPlant = plant; // Update the selected plant in the state
      });

      // Fetch recommended NPK values for the selected plant
      final recommendedNpk = await fetchNpkValues(plantType, plant);
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
  Future<String?> showPlantSearchDialog(BuildContext context, String plantType) async {
    final firestore = FirebaseFirestore.instance;
    final doc = await firestore.collection('fertilizer_recommendations').doc('plants').get();

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
    final List<String> plantNames = plants
        .where((p) => p['type'] == plantType)
        .map<String>((p) => p['name'])
        .toList();

    if (plantNames.isEmpty) {
      print("No plants found for type '$plantType'.");
      return null;
    }

    String selectedPlant = plantNames.first;

    return showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Select Plant'),
              content: DropdownButton<String>(
                value: selectedPlant,
                items: plantNames.map((plant) {
                  return DropdownMenuItem(
                    value: plant,
                    child: Text(plant),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedPlant = value!;
                  });
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(selectedPlant),
                  child: const Text('Select'),
                ),
              ],
            );
          },
        );
      },
    );
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
              Row(
                children: [
                  const Icon(Icons.grass, color: Colors.blue),
                  const SizedBox(width: 6),
                  Text(
                    "Plant: $selectedPlant",
                    style: const TextStyle(
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
              const SizedBox(height: 16),
              const Text(
                "Recommended NPK Values (kg/ha):",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text("Nitrogen: $recommendedNitrogen kg/ha"),
              Text("Phosphorus: $recommendedPhosphorus kg/ha"),
              Text("Potassium: $recommendedPotassium kg/ha"),
              const SizedBox(height: 16),
              TextField(
                controller: _nitrogenController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Measured Nitrogen (kg/ha)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phosphorusController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Measured Phosphorus (kg/ha)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _potassiumController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Measured Potassium (kg/ha)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _getRecommendation,
                child: const Text("Get Recommendation"),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  recommendation,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}