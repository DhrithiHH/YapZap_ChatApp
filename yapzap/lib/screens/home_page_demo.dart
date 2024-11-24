import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';
import 'connect.dart';

class HomePageDemo extends StatefulWidget {
  @override
  _HomePageDemoState createState() => _HomePageDemoState();
}

class _HomePageDemoState extends State<HomePageDemo> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _searchQuery = '';
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = user.uid;
      });
    }
  }

  void _navigateToConnectUsersPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConnectUsersPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeGreen = const Color(0xFF00A86B); // Green theme color

    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeGreen,
        elevation: 0,
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search by user ID...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          style: const TextStyle(color: Colors.white),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              // Add navigation to settings if needed
            },
          ),
        ],
      ),
      body: _currentUserId == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<DocumentSnapshot>(
              stream: _firestore.collection('users').doc(_currentUserId).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Failed to load contacts. Please try again.'),
                  );
                }

                final userDoc = snapshot.data;

                if (userDoc == null || !userDoc.exists) {
                  return const Center(
                    child: Text('User data not found. Please check your account.'),
                  );
                }

                // Safely cast the document data to a Map
                final data = userDoc.data() as Map<String, dynamic>;
                final contacts = List<String>.from(data['contacts'] ?? []);

                // Filter contacts based on search query
                final filteredContacts = contacts.where((contactId) {
                  return contactId.toLowerCase().contains(_searchQuery.toLowerCase());
                }).toList();

                return Column(
                  children: [
                    Expanded(
                      child: filteredContacts.isEmpty
                          ? const Center(
                              child: Text('No contacts found.'),
                            )
                          : ListView.builder(
                              itemCount: filteredContacts.length,
                              itemBuilder: (context, index) {
                                final contactId = filteredContacts[index];

                                return FutureBuilder<DocumentSnapshot>(
                                  future: _firestore.collection('users').doc(contactId).get(),
                                  builder: (context, contactSnapshot) {
                                    if (contactSnapshot.connectionState == ConnectionState.waiting) {
                                      return const ListTile(
                                        title: Text('Loading...'),
                                      );
                                    }

                                    if (contactSnapshot.hasError ||
                                        !contactSnapshot.hasData ||
                                        !contactSnapshot.data!.exists) {
                                      return const ListTile(
                                        title: Text('Error loading contact'),
                                      );
                                    }

                                    final contactData = contactSnapshot.data!;
                                    final contactMap = contactData.data() as Map<String, dynamic>;
                                    final username = contactMap['username'] ?? 'Unknown User';
                                    final profilePic = contactMap['profilePic'] ?? '';

                                    return ListTile(
                                      leading: CircleAvatar(
                                        backgroundImage: profilePic.isNotEmpty
                                            ? NetworkImage(profilePic)
                                            : null,
                                        child: profilePic.isEmpty
                                            ? const Icon(Icons.person, color: Colors.white)
                                            : null,
                                      ),
                                      title: Text(username),
                                      subtitle: Text('UserID: $contactId'),
                                      tileColor: Colors.white,
                                      onTap: () {
                                        // Navigate to Chat Screen with userId and peerId
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => WebRTCChatApp(
                                              userId: _currentUserId!,
                                              peerId: contactId,
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: FloatingActionButton(
                        backgroundColor: themeGreen,
                        onPressed: _navigateToConnectUsersPage,
                        child: const Icon(Icons.add, color: Colors.white),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
