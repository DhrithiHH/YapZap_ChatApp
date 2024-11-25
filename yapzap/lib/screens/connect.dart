import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart'; // Update with the correct import path

class ConnectPage extends StatefulWidget {
  final String userId;

  const ConnectPage({Key? key, required this.userId}) : super(key: key);

  @override
  _ConnectPageState createState() => _ConnectPageState();
}

class _ConnectPageState extends State<ConnectPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;

  void _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Query users whose name starts with the query text
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: query + '\uf8ff')
          .get();

      List<Map<String, dynamic>> results = snapshot.docs
          .map((doc) => {
                'id': doc.id,
                'name': doc['name'],
                'email': doc['email'],
              })
          .where((user) => user['id'] != widget.userId)
          .toList();

      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      print('Error searching users: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _openChatScreen(String userId, String userName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WebRTCChatApp(
          userId: widget.userId,
          peerId: userId,
          // otherUserName: userName, // Pass this if your ChatScreen requires it
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Connect'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: _searchUsers,
              decoration: const InputDecoration(
                hintText: 'Search users by name...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          _isLoading
              ? const CircularProgressIndicator()
              : Expanded(
                  child: _searchResults.isEmpty
                      ? const Center(child: Text('No users found'))
                      : ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final user = _searchResults[index];
                            return ListTile(
                              title: Text(user['name']),
                              subtitle: Text(user['email']),
                              onTap: () =>
                                  _openChatScreen(user['id'], user['name']),
                            );
                          },
                        ),
                ),
        ],
      ),
    );
  }
}
