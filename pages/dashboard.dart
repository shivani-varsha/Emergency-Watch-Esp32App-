import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'user_info.dart'; // Import user_info.dart for navigation

class Dashboard extends StatefulWidget {
  final bool isPublicCommunity;
  final bool isPrivateCommunity;
  final String email;
  final String name;

  const Dashboard({
    Key? key,
    required this.isPublicCommunity,
    required this.isPrivateCommunity,
    required this.email,
    required this.name,
  }) : super(key: key);

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
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
                Text(
                  'Welcome, ${widget.name}!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                if (widget.isPublicCommunity) ...[
                  _buildCommunityCard(
                    context,
                    title: 'PSG iTech Community',
                    icon: Icons.school,
                    communityName: 'PSG iTech Community',
                    isPrivateCommunity: widget.isPrivateCommunity,
                  ),
                  const SizedBox(height: 10),
                  _buildCommunityCard(
                    context,
                    title: 'Neelambur Community',
                    icon: Icons.location_city,
                    communityName: 'Neelambur Community',
                    isPrivateCommunity: widget.isPrivateCommunity,
                  ),
                ],
                if (widget.isPrivateCommunity) ...[
                  _buildCommunityCard(
                    context,
                    title: 'Private Community',
                    icon: Icons.lock,
                    communityName: 'Private Community',
                    isPrivateCommunity: widget.isPrivateCommunity,
                  ),
                ],
                if (!widget.isPublicCommunity && !widget.isPrivateCommunity) ...[
                  const Center(
                    child: Text(
                      'No communities available',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCommunityCard(
      BuildContext context, {
        required String title,
        required IconData icon,
        required String communityName,
        required bool isPrivateCommunity,
      }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: const Color.fromARGB(255, 207, 206, 206),
      child: ListTile(
        leading: Icon(icon, size: 40, color: Colors.red),
        title: Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.black),
        ),
        onTap: () => _handleCommunityTap(context, communityName, isPrivateCommunity),
      ),
    );
  }

  void _handleCommunityTap(BuildContext context, String communityName, bool isPrivateCommunity) async {
    final isMember = await _checkMembership(context, communityName);

    if (isMember) {
      // Navigate directly to the BroadcastPage if the user is already a member
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BroadcastPage(communityName: communityName),
        ),
      );
    } else {
      // Navigate to the CommunityDetailPage if the user is not a member
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CommunityDetailPage(
            communityName: communityName,
            name: widget.name,
            email: widget.email,
            isPrivateCommunity: isPrivateCommunity,
          ),
        ),
      );
    }
  }

  Future<bool> _checkMembership(BuildContext context, String communityName) async {
    final url = Uri.parse('http://localhost:3000/checkMembership');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': widget.email, 'communityName': communityName}),
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      return responseBody['isMember'];
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to check membership status')),
      );
      return false;
    }
  }

  void _logout(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/signin');
  }
}

class BroadcastPage extends StatelessWidget {
  final String communityName;

  const BroadcastPage({Key? key, required this.communityName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Broadcast - $communityName'),
        backgroundColor: Colors.red[700],
      ),
      body: Center(
        child: Text(
          'Welcome to $communityName Broadcast Page!',
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}

class CommunityDetailPage extends StatelessWidget {
  final String communityName;
  final String name;
  final String email;
  final bool isPrivateCommunity; // Added parameter

  const CommunityDetailPage({
    Key? key,
    required this.communityName,
    required this.name,
    required this.email,
    required this.isPrivateCommunity, // Added parameter
  }) : super(key: key);

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Community: $communityName',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Welcome, $name! You can join this community to participate in discussions and access community resources.',
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      joinCommunity(context, communityName, email, isPrivateCommunity);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Join $communityName'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void joinCommunity(BuildContext context, String communityName, String email, bool isPrivateCommunity) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserInfoPage(
          communityName: communityName,
          email: email,
          isPrivateCommunity: isPrivateCommunity, // Pass the isPrivateCommunity parameter
        ),
      ),
    );
  }

  void _logout(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/signin');
  }
}
