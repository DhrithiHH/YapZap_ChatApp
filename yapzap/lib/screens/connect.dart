import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart';

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

  /// Method to search users in Firestore
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
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();

      List<Map<String, dynamic>> results = snapshot.docs
          .where((doc) => doc.id.toLowerCase().startsWith(query.toLowerCase()))
          .map((doc) => {
                'userId': doc.id,
                'username': doc['username'],
                'email': doc['email'],
                'profilePic': doc['profilePic'] ?? '',
              })
          .where((user) => user['userId'] != widget.userId)
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

  /// Method to add a contact to the user's `contacts` array in Firestore
  Future<void> _addContact(String userId) async {
    try {
      // Reference to the current user's document
      DocumentReference userDoc =
          FirebaseFirestore.instance.collection('users').doc(widget.userId);

      // Update the contacts array
      await userDoc.update({
        'contacts': FieldValue.arrayUnion([userId]),
      });

      print('Contact added successfully!');
    } catch (e) {
      print('Error adding contact: $e');
    }
  }

  /// Method to navigate to the chat screen and add the user to the contact list
 /// Method to navigate to the chat screen and add the user to the contact list
void _openChatScreen(String userId, String username) async {
  // Generate a unique sorted ID for the message document
  final sortedId = [widget.userId, userId]..sort(); // Sort the IDs
  final chatId = sortedId.join('_'); // Combine into a unique string

  try {
    // Add the selected user to the contacts list
    await _addContact(userId);

    // Fetch the email addresses of both users
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
    final peerDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

    final userEmail = userDoc.data()?['email'];
    final peerEmail = peerDoc.data()?['email'];

    // Reference to the `messages` document
    DocumentReference chatDoc = FirebaseFirestore.instance.collection('messages').doc(chatId);

    // Create the document if it doesn't exist, using emails as participants
    await chatDoc.set({
      'participants': [userEmail, peerEmail],  // Store emails instead of userIds
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)); // Use `merge: true` to avoid overwriting existing data

    print('Chat document created successfully!');
  } catch (e) {
    print('Error creating chat document: $e');
    return;
  }


  // Navigate to the chat screen
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => WebRTCChatApp(
        userId: widget.userId,
        peerId: userId,
        // chatId: chatId, // Pass the chatId to the chat screen
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        title: const Text(
          'Connect',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search input field
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: _searchUsers,
              decoration: InputDecoration(
                hintText: 'Search users by ID...',
                hintStyle: TextStyle(color: Colors.grey.shade600),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
              ),
            ),
          ),

          // Display search results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                    ? const Center(
                        child: Text(
                          'No users found',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final user = _searchResults[index];
                          final profilePic = user['profilePic'];
                          final username = user['username'] ?? 'Unknown';

                          return ListTile(
                            leading: CircleAvatar(
                              radius: 24,
                              backgroundImage: profilePic.isNotEmpty
                                  ? NetworkImage(profilePic)
                                  : null,
                              backgroundColor: Colors.green.shade200,
                              child: profilePic.isEmpty
                                  ? Text(
                                      username.isNotEmpty
                                          ? username[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                    )
                                  : null,
                            ),
                            title: Text(
                              username,
                              style: const TextStyle(fontSize: 14),
                            ),
                            subtitle: Text(
                              user['email'] ?? '',
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 12),
                            ),
                            onTap: () => _openChatScreen(
                                user['userId'], user['username']),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
