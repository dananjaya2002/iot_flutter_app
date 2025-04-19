import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> uploadJsonToFirestore() async {
  try {
    // Load the JSON file from assets
    final String jsonString = await rootBundle.loadString('assets/fertilizer_data.json');
    final Map<String, dynamic> jsonData = json.decode(jsonString);

    // Upload the JSON data to Firestore
    final firestore = FirebaseFirestore.instance;
    await firestore.collection('fertilizer_recommendations').doc('plants').set(jsonData);

    print('JSON data uploaded successfully!');
  } catch (e) {
    print('Error uploading JSON data: $e');
  }
}

Stream<List<Map<String, dynamic>>> getFertilizers() {
  return FirebaseFirestore.instance
      .collection('fertilizers')
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => doc.data()).toList());
}