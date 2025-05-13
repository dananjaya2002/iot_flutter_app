import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart'; // Needed for Firebase.app()
import 'dart:async';

class AboutUsScreen extends StatefulWidget {
  @override
  _AboutUsScreenState createState() => _AboutUsScreenState();
}

class _AboutUsScreenState extends State<AboutUsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Reference to Firebase database with custom region
  late final DatabaseReference _contactRef;

  @override
  void initState() {
    super.initState();
    _contactRef = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL:
          'https://iot-app-6153d-default-rtdb.asia-southeast1.firebasedatabase.app',
    ).ref('contact_submissions');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD5F5E3),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(icon: Icon(Icons.menu), onPressed: () {}),
                  const Text(
                    'AGROW',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // About Us Section
              const Text(
                'About Us',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Agrow, We are a NSBM group that is mainly focused on next level of agriculture with technological evolution. This is the beginning of implementation of modern tech with farms and by this product we are trying to ensure that every farmer could simply check the soil and analyze nutrients real-time with easy few steps.',
                  textAlign: TextAlign.justify,
                ),
              ),
              const SizedBox(height: 20),

              // Contact Us Section
              const Text(
                'Contact Us',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Center(
                child: Image.asset(
                  'assets/images/logo-black.png',
                  width: 300,
                  height: 250,
                ),
              ),
              const SizedBox(height: 1),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        filled: true,
                        fillColor: Colors.grey[300],
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Enter email' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _subjectController,
                      decoration: InputDecoration(
                        labelText: 'Subject',
                        filled: true,
                        fillColor: Colors.grey[300],
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Enter subject'
                          : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        filled: true,
                        fillColor: Colors.grey[300],
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Enter description'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        FocusScope.of(context).unfocus();

                        if (_formKey.currentState!.validate()) {
                          try {
                            final newEntry = _contactRef.push();
                            final submissionData = {
                              'email': _emailController.text.trim(),
                              'subject': _subjectController.text.trim(),
                              'description':
                                  _descriptionController.text.trim(),
                              'timestamp': DateTime.now().toIso8601String(),
                            };

                            print("Attempting to submit data...");

                            await newEntry
                                .set(submissionData)
                                .timeout(const Duration(seconds: 20));

                            print("✅ Successfully submitted data");

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Submitted successfully!'),
                              ),
                            );

                            _emailController.clear();
                            _subjectController.clear();
                            _descriptionController.clear();
                          } on TimeoutException catch (_) {
                            print("❌ Timeout while submitting data");
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Error: Connection timed out'),
                              ),
                            );
                          } catch (e) {
                            print("❌ Unknown error: $e");
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to submit: $e')),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Submit'),
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
