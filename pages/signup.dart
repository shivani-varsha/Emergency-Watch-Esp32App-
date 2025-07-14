import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'signin.dart';
import '/pages/medical_details.dart';

class Signup extends StatefulWidget {
  const Signup({Key? key}) : super(key: key);

  @override
  _SignupState createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final _formKey = GlobalKey<FormState>();
  String name = '';
  String age = '';
  String phoneNumber = '';
  String email = '';
  String password = '';
  String confirmPassword = '';

  Future<void> signUp() async {
    var url = Uri.parse('http://localhost:3000/signup');
    var response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'name': name,
        'age': age,
        'phoneNumber': phoneNumber,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 201) {
      print('User signed up successfully');
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MedicalDetailsPage(email: email)),
      );
    } else {
      print('Signup failed: ${response.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signup failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/images/red.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Container(
            width: 450,
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
                  'SIGN UP',
                  style: TextStyle(
                    color: Color.fromARGB(255, 227, 223, 223),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color.fromARGB(255, 207, 206, 206),
                          labelText: 'Name',
                          labelStyle: const TextStyle(color: Color.fromARGB(255, 10, 9, 9)),
                          prefixIcon: const Icon(Icons.person, color: Color.fromARGB(255, 8, 7, 7)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: const TextStyle(color: Color.fromARGB(255, 10, 10, 10)),
                        onChanged: (value) {
                          name = value;
                        },
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color.fromARGB(255, 207, 206, 206),
                          labelText: 'Age',
                          labelStyle: const TextStyle(color: Color.fromARGB(255, 8, 6, 6)),
                          prefixIcon: const Icon(Icons.cake, color: Color.fromARGB(255, 5, 4, 4)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: const TextStyle(color: Color.fromARGB(255, 6, 6, 6)),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          age = value;
                        },
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please enter your age';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color.fromARGB(255, 207, 206, 206),
                          labelText: 'Phone Number',
                          labelStyle: const TextStyle(color: Color.fromARGB(255, 10, 8, 8)),
                          prefixIcon: const Icon(Icons.phone, color: Color.fromARGB(255, 13, 9, 9)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: const TextStyle(color: Color.fromARGB(255, 10, 10, 10)),
                        keyboardType: TextInputType.phone,
                        onChanged: (value) {
                          phoneNumber = value;
                        },
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please enter your phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color.fromARGB(255, 207, 206, 206),
                          labelText: 'Email',
                          labelStyle: const TextStyle(color: Color.fromARGB(255, 7, 6, 6)),
                          prefixIcon: const Icon(Icons.email, color: Color.fromARGB(255, 7, 6, 6)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: const TextStyle(color: Color.fromARGB(255, 3, 3, 3)),
                        onChanged: (value) {
                          email = value;
                        },
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please enter your email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color.fromARGB(255, 207, 206, 206),
                          labelText: 'Password',
                          labelStyle: const TextStyle(color: Color.fromARGB(255, 6, 5, 5)),
                          prefixIcon: const Icon(Icons.lock, color: Color.fromARGB(255, 7, 5, 5)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: const TextStyle(color: Color.fromARGB(255, 8, 8, 8)),
                        obscureText: true,
                        onChanged: (value) {
                          password = value;
                        },
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color.fromARGB(255, 207, 206, 206),
                          labelText: 'Confirm Password',
                          labelStyle: const TextStyle(color: Color.fromARGB(255, 12, 10, 10)),
                          prefixIcon: const Icon(Icons.lock, color: Color.fromARGB(255, 8, 6, 6)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: const TextStyle(color: Color.fromARGB(255, 9, 9, 9)),
                        obscureText: true,
                        onChanged: (value) {
                          confirmPassword = value;
                        },
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != password) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            signUp();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[700],
                          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const Signin()),
                          );
                        },
                        child: const Text(
                          'Already have an account? Sign In',
                          style: TextStyle(color: Colors.white),
                        ),
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
  }
}
