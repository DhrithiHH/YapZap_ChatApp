import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart';
import 'connect.dart';

class HomePageDemo extends StatefulWidget {
  final String userId; // Accepts userId as a parameter

  const HomePageDemo({Key? key, required this.userId}) : super(key: key);

  @override
  _HomePageDemoState createState() => _HomePageDemoState();
}

class _HomePageDemoState extends State<HomePageDemo> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _searchQuery = '';
  bool _isPasswordVisible = false; // State for toggling password visibility

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00A86B), Color(0xFF5AC18E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // AppBar with Search
            Container(
              padding:
                  const EdgeInsets.only(top: 40.0, left: 16.0, right: 16.0),
              color: Colors.transparent,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by user ID...',
                        hintStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.2),
                        prefixIcon:
                            const Icon(Icons.search, color: Colors.white),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Password Field Example
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
              child: TextField(
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                  hintStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
            ),

            // Contacts List
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: _firestore
                    .collection('users')
                    .doc(widget.userId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                          'Failed to load contacts. Please try again later.'),
                    );
                  }

                  if (!snapshot.hasData ||
                      snapshot.data == null ||
                      !snapshot.data!.exists) {
                    return const Center(
                      child: Text(
                          'User data not found. Please check your account.'),
                    );
                  }

                  final userDoc = snapshot.data!;
                  final data = userDoc.data() as Map<String, dynamic>? ?? {};
                  final contacts = List<String>.from(data['contacts'] ?? []);

                  // Filter contacts based on search query
                  final filteredContacts = contacts.where((contactId) {
                    return contactId
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase());
                  }).toList();

                  return filteredContacts.isEmpty
                      ? const Center(
                          child: Text('No contacts found.',
                              style: TextStyle(color: Colors.white)))
                      : ListView.builder(
                          itemCount: filteredContacts.length,
                          itemBuilder: (context, index) {
                            final contactId = filteredContacts[index];

                            return FutureBuilder<DocumentSnapshot>(
                              future: _firestore
                                  .collection('users')
                                  .doc(contactId)
                                  .get(),
                              builder: (context, contactSnapshot) {
                                if (contactSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const ListTile(
                                    title: Text('Loading...',
                                        style: TextStyle(color: Colors.white)),
                                  );
                                }

                                if (contactSnapshot.hasError ||
                                    !contactSnapshot.hasData ||
                                    !contactSnapshot.data!.exists) {
                                  return const ListTile(
                                    title: Text('Error loading contact',
                                        style: TextStyle(color: Colors.white)),
                                  );
                                }

                                final contactData = contactSnapshot.data!.data()
                                    as Map<String, dynamic>;
                                final username =
                                    contactData['username'] ?? 'Unknown User';
                                final profilePic =
                                    contactData['profilePic'] ?? '';

                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage: profilePic.isNotEmpty
                                        ? NetworkImage(profilePic)
                                        : null,
                                    child: profilePic.isEmpty
                                        ? const Icon(Icons.person,
                                            color: Colors.white)
                                        : null,
                                  ),
                                  title: Text(username,
                                      style:
                                          const TextStyle(color: Colors.white)),
                                  subtitle: Text('UserID: $contactId',
                                      style: const TextStyle(
                                          color: Colors.white70)),
                                  onTap: () {
                                    // Navigate to Chat Screen with userId and peerId
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => WebRTCChatApp(
                                          userId: widget.userId,
                                          peerId: contactId,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        );
                },
              ),
            ),

            // Add Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: FloatingActionButton(
                backgroundColor: const Color(0xFF007F5F),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ConnectUsersPage(),
                    ),
                  );
                },
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
