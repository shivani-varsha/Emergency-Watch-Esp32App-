import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MedicalDetailsPage extends StatefulWidget {
  final String email;

  const MedicalDetailsPage({Key? key, required this.email}) : super(key: key);

  @override
  _MedicalDetailsPageState createState() => _MedicalDetailsPageState();
}

class _MedicalDetailsPageState extends State<MedicalDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  String city = '';
  String state = '';
  String medicalHistory = '';
  bool isPrivateCommunity = false;
  bool isPublicCommunity = false;

  Future<void> saveMedicalDetails(BuildContext context) async {
    var url = Uri.parse('http://localhost:3000/saveMedicalDetails');
    var response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'email': widget.email,
        'city': city,
        'state': state,
        'medicalHistory': medicalHistory,
        'isPrivateCommunity': isPrivateCommunity,
        'isPublicCommunity': isPublicCommunity,
      }),
    );

    if (response.statusCode == 200) {
      print('Medical details saved successfully');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medical details saved successfully!')),
      );
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pushReplacementNamed(context, '/signin');
      });
    } else {
      print('Failed to save medical details: ${response.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save medical details')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: Container(
              height: constraints.maxHeight,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('lib/images/red.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Center(
                child: Container(
                  width: 450,  // Increased width from 300 to 350
                  padding: const EdgeInsets.all(32.0),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(0, 0, 0, 0.5),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Medical Details',
                        style: TextStyle(
                          color: Color.fromARGB(255, 255, 255, 255),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color.fromARGB(255, 207, 206, 206),
                                labelText: 'City',
                                labelStyle: const TextStyle(color: Color.fromARGB(255, 9, 8, 8)),
                                prefixIcon: const Icon(Icons.location_city, color: Color.fromARGB(255, 11, 8, 8)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                              onChanged: (value) {
                                setState(() {
                                  city = value;
                                });
                              },
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return 'Please enter your city';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color.fromARGB(255, 207, 206, 206),
                                labelText: 'State',
                                labelStyle: const TextStyle(color: Color.fromARGB(255, 9, 8, 8)),
                                prefixIcon: const Icon(Icons.map, color: Color.fromARGB(255, 12, 9, 9)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                              onChanged: (value) {
                                setState(() {
                                  state = value;
                                });
                              },
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return 'Please enter your state';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color.fromARGB(255, 207, 206, 206),
                                labelText: 'Medical History',
                                labelStyle: const TextStyle(color: Color.fromARGB(255, 12, 9, 9)),
                                prefixIcon: const Icon(Icons.medical_services, color: Color.fromARGB(255, 10, 7, 7)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                              maxLines: 3,
                              onChanged: (value) {
                                setState(() {
                                  medicalHistory = value;
                                });
                              },
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return 'Please enter your medical history';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Checkbox(
                                        value: isPrivateCommunity,
                                        onChanged: (value) {
                                          setState(() {
                                            isPrivateCommunity = value!;
                                          });
                                        },
                                        fillColor: WidgetStateProperty.resolveWith((states) {
                                          if (states.contains(WidgetState.selected)) {
                                            return Colors.red.shade400;
                                          }
                                          return Colors.red.withOpacity(0.1);
                                        }),
                                      ),
                                      const Text('Private Community', style: TextStyle(color: Color.fromARGB(255, 255, 240, 240))),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Checkbox(
                                        value: isPublicCommunity,
                                        onChanged: (value) {
                                          setState(() {
                                            isPublicCommunity = value!;
                                          });
                                        },
                                        fillColor: WidgetStateProperty.resolveWith((states) {
                                          if (states.contains(WidgetState.selected)) {
                                            return Colors.red.shade400;
                                          }
                                          return Colors.red.withOpacity(0.1);
                                        }),
                                      ),
                                      const Text('Public Community', style: TextStyle(color: Color.fromARGB(255, 255, 255, 255))),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  saveMedicalDetails(context);
                                }
                              },
                              style: ButtonStyle(
                                backgroundColor: WidgetStateProperty.all(Colors.red),
                                foregroundColor: WidgetStateProperty.all(Colors.white),
                                padding: WidgetStateProperty.all(
                                  const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                                ),
                              ),
                              child: const Text('Save Medical Details'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
