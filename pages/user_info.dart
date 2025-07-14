import 'dart:convert';
import 'dart:io'; // Use dart:io for WebSocket on desktop
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class UserInfoPage extends StatefulWidget {
  final String communityName;
  final String email;
  final bool isPrivateCommunity;

  const UserInfoPage({
    Key? key,
    required this.communityName,
    required this.email,
    required this.isPrivateCommunity,
  }) : super(key: key);

  @override
  _UserInfoPageState createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  final _formKey = GlobalKey<FormState>();
  String? name;
  String? phoneNumber;
  LocationData? locationData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.isPrivateCommunity
            ? 'Create Private Community'
            : 'Join ${widget.communityName}'),
        backgroundColor: Colors.red,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'logout',
                child: Text('Logout'),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.isPrivateCommunity
                    ? 'Enter details to create a private community'
                    : 'Enter your details to join',
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[800],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              if (widget.isPrivateCommunity)
                ..._buildPrivateCommunityForm()
              else
                ..._buildJoinCommunityForm(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPrivateCommunityForm() {
    return [
      TextFormField(
        decoration: InputDecoration(
          labelText: 'Name',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.red[50],
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your name';
          }
          return null;
        },
        onSaved: (value) => name = value,
      ),
      const SizedBox(height: 20),
      TextFormField(
        decoration: InputDecoration(
          labelText: 'Phone Number',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.red[50],
        ),
        keyboardType: TextInputType.phone,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your phone number';
          }
          return null;
        },
        onSaved: (value) => phoneNumber = value,
      ),
      const SizedBox(height: 20),
      ElevatedButton(
        onPressed: _handleCreatePrivateCommunity,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[800],
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text(
          'Create Private Community',
          style: TextStyle(fontSize: 18),
        ),
      ),
    ];
  }

  List<Widget> _buildJoinCommunityForm() {
    return [
      TextFormField(
        decoration: InputDecoration(
          labelText: 'Name',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.red[50],
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your name';
          }
          return null;
        },
        onSaved: (value) => name = value,
      ),
      const SizedBox(height: 20),
      TextFormField(
        decoration: InputDecoration(
          labelText: 'Phone Number',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.red[50],
        ),
        keyboardType: TextInputType.phone,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your phone number';
          }
          return null;
        },
        onSaved: (value) => phoneNumber = value,
      ),
      const SizedBox(height: 40),
      ElevatedButton(
        onPressed: _handleJoin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[800],
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text(
          'Get Location & Join',
          style: TextStyle(fontSize: 18),
        ),
      ),
    ];
  }

  Future<void> _handleCreatePrivateCommunity() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      // Prompt for additional members
      List<Map<String, String>> additionalMembers = [];
      for (int i = 1; i <= 3; i++) {
        final memberDetails = await _showMemberInputDialog(i);
        if (memberDetails != null) {
          additionalMembers.add(memberDetails);
        }
      }

      // Save user info and additional members
      await _savePrivateCommunityInfo(additionalMembers);
      _navigateToBroadcastPage();
    }
  }

  Future<Map<String, String>?> _showMemberInputDialog(int index) async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final relationController = TextEditingController();

    return showDialog<Map<String, String>>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter details for member $index'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
              ),
              TextField(
                controller: relationController,
                decoration: InputDecoration(labelText: 'Relationship'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop({
                  'name': nameController.text,
                  'phoneNumber': phoneController.text,
                  'relation': relationController.text,
                });
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _savePrivateCommunityInfo(List<Map<String, String>> additionalMembers) async {
    final response = await http.post(
      Uri.parse('http://localhost:3000/savePrivateCommunityInfo'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': widget.email,
        'communityName': widget.communityName,
        'members': additionalMembers,
      }),
    );

    if (response.statusCode != 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create private community')),
      );
    }
  }

  Future<void> _handleJoin() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      // Check if user already joined the community
      final isMember = await _checkMembership();
      if (isMember) {
        _navigateToBroadcastPage();
      } else {
        await _getLocationPermission();
        await _saveUserInfo();
        _navigateToBroadcastPage();
      }
    }
  }

  Future<void> _getLocationPermission() async {
    Location location = Location();

    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    locationData = await location.getLocation();
  }

  Future<bool> _checkMembership() async {
    final response = await http.post(
      Uri.parse('http://localhost:3000/checkMembership'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': widget.email,
        'communityName': widget.communityName,
      }),
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      return result['isMember'];
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to check membership')),
      );
      return false;
    }
  }

  Future<void> _saveUserInfo() async {
    if (locationData == null) {
      await _getLocationPermission();
    }

    final response = await http.post(
      Uri.parse('http://localhost:3000/saveUserInfo'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': widget.email,
        'communityName': widget.communityName,
        'phoneNumber': phoneNumber,
        'location': {
          'lat': locationData?.latitude,
          'lng': locationData?.longitude,
        },
      }),
    );

    if (response.statusCode != 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save user info')),
      );
    }
  }

  void _navigateToBroadcastPage() {
    Navigator.of(context).pushReplacementNamed('/broadcast', arguments: {
      'email': widget.email,
      'communityName': widget.communityName,
      'isPrivateCommunity': widget.isPrivateCommunity,
    });
  }

  void _logout() {
    // Implement your logout logic here
    Navigator.of(context).pushReplacementNamed('/login');
  }
}
