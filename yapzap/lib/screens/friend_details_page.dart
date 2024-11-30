import 'package:flutter/material.dart';

class FriendDetailsPage extends StatelessWidget {
  final String profilePic;
  final String contactName;
  final String userId;

  const FriendDetailsPage({
    Key? key,
    required this.profilePic,
    required this.contactName,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text("Friend Details"),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Picture and Details
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(profilePic),
                  ),
                  SizedBox(height: 10),
                  Text(
                    contactName,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "ID: $userId",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _actionButton(Icons.call, "Audio Call", Colors.green),
                _actionButton(Icons.videocam, "Video Call", Colors.blue),
                _actionButton(Icons.chat, "Chat", Colors.purple),
              ],
            ),
            SizedBox(height: 20),

            // Media, Links, Docs Section
            _sectionHeader(context, "Media, Links & Docs", Icons.arrow_forward,
                () {
              // Navigate to full media view
            }),
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: List.generate(10, (index) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.network(
                      "https://via.placeholder.com/100",
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  );
                }),
              ),
            ),
            Divider(),

            // Notification Toggle
            SwitchListTile(
              title: Text("Notifications"),
              value: true,
              onChanged: (bool value) {
                // Handle toggle
              },
            ),
            Divider(),

            // Starred Messages
            _sectionHeader(context, "Starred Messages", Icons.star, () {
              // Navigate to starred messages
            }),
            Divider(),

            // Create Group
            ListTile(
              title: Text("Create Group with $contactName"),
              trailing: Icon(Icons.group),
              onTap: () {
                // Handle create group
              },
            ),
            Divider(),

            // Add to Favorites
            SwitchListTile(
              title: Text("Add to Favorites"),
              value: false,
              onChanged: (bool value) {
                // Handle toggle
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, Color color) {
    return Column(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 14)),
      ],
    );
  }

  Widget _sectionHeader(
      BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
      trailing: Icon(icon),
      onTap: onTap,
    );
  }
}
