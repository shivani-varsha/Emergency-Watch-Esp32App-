import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'signup.dart'; // Ensure this path is correct

class Signin extends StatefulWidget {
  const Signin({Key? key}) : super(key: key);

  @override
  _SigninState createState() => _SigninState();
}

class _SigninState extends State<Signin> {
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';

  Future<void> signIn() async {
    var url = Uri.parse('http://localhost:3000/signin');
    try {
      var response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': email,
          'password': password,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);

        // Ensure proper handling of booleans
        bool isPublicCommunity = responseData['isPublicCommunity'] ?? false;
        bool isPrivateCommunity = responseData['isPrivateCommunity'] ?? false;
        String name = responseData['name'] ?? 'Unknown';

        print('Signin successful: $name');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Welcome, $name!')),
        );

        Navigator.pushReplacementNamed(
          context,
          '/dashboard',
          arguments: {
            'name': name,
            'email': email,
            'isPublicCommunity': isPublicCommunity,
            'isPrivateCommunity': isPrivateCommunity,
          },
        );
      } else {
        print('Signin failed: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Signin failed: ${response.body}')),
        );
      }
    } catch (e) {
      print('Error during sign in: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during sign in: $e')),
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
                  'LOGIN',
                  style: TextStyle(
                    color: Color.fromARGB(255, 235, 226, 226),
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
                          labelText: 'Username',
                          labelStyle: const TextStyle(color: Color.fromARGB(255, 15, 15, 15)),
                          prefixIcon: const Icon(Icons.person, color: Color.fromARGB(255, 14, 11, 11)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: const TextStyle(color: Colors.black), // Changed to black
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
                          labelStyle: const TextStyle(color: Color.fromARGB(255, 8, 7, 7)),
                          prefixIcon: const Icon(Icons.lock, color: Color.fromARGB(255, 10, 8, 8)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: const TextStyle(color: Colors.black), // Changed to black
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
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            signIn();
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
                          'Login',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const Signup()),
                          );
                        },
                        child: const Text(
                          'Create a new account? Signup',
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
