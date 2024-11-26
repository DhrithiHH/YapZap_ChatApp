import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart';
import 'connect.dart';

class Home extends StatefulWidget {
  final String userId;

  const Home({Key? key, required this.userId}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF7F7F9), Color(0xFFFCFDFE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 20.0,
                    horizontal: 16.0,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF7F7F9), // Whitish Grey
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(12.0),
                      bottomRight: Radius.circular(12.0),
                    ),
                  ),
                  child: Text(
                    'Chats',
                    style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black, // Black text
                    ),
                  ),
                ),

                // Status Update Section
                Container(
                  margin: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 16.0,
                  ),
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB0FE), // Pink background
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Update Status',
                        style: TextStyle(
                          color: Colors.white, // White text
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        onPressed: () {
                          // Action for updating status
                        },
                      ),
                    ],
                  ),
                ),

                // Search Bar
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by user ID...',
                      hintStyle: const TextStyle(
                          color: Color(0xFFCACBCF)), // Grey placeholder
                      filled: true,
                      fillColor: Colors.white, // White background
                      prefixIcon: const Icon(Icons.search, color: Colors.black),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),

                // Chat List
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
                            'Failed to load contacts. Please try again later.',
                            style: TextStyle(color: Colors.black),
                          ),
                        );
                      }

                      if (!snapshot.hasData ||
                          snapshot.data == null ||
                          !snapshot.data!.exists) {
                        return const Center(
                          child: Text(
                            'User data not found. Please check your account.',
                            style: TextStyle(color: Colors.black),
                          ),
                        );
                      }

                      final userDoc = snapshot.data!;
                      final data =
                          userDoc.data() as Map<String, dynamic>? ?? {};
                      final contacts =
                          List<String>.from(data['contacts'] ?? []);

                      final filteredContacts = contacts.where((contactId) {
                        return contactId
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase());
                      }).toList();

                      return filteredContacts.isEmpty
                          ? const Center(
                              child: Text(
                                'No contacts found.',
                                style: TextStyle(
                                    color: Color(0xFFCACBCF)), // Grey text
                              ),
                            )
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
                                        title: Text(
                                          'Loading...',
                                          style: TextStyle(color: Colors.black),
                                        ),
                                      );
                                    }

                                    if (contactSnapshot.hasError ||
                                        !contactSnapshot.hasData ||
                                        !contactSnapshot.data!.exists) {
                                      return const ListTile(
                                        title: Text(
                                          'Error loading contact',
                                          style: TextStyle(color: Colors.black),
                                        ),
                                      );
                                    }

                                    final contactData = contactSnapshot.data!
                                        .data() as Map<String, dynamic>;
                                    final username = contactData['username'] ??
                                        'Unknown User';
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
                                          style: const TextStyle(
                                              color: Colors.black)),
                                      subtitle: Text(
                                        'UserID: $contactId',
                                        style: const TextStyle(
                                            color: Color(0xFFCACBCF)), // Grey
                                      ),
                                      onTap: () {
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
              ],
            ),
          ),

          // Floating Action Button
          Positioned(
            bottom: 16.0,
            right: 16.0,
            child: FloatingActionButton(
              backgroundColor: const Color(0xFF00A86B), // Green
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ConnectPage(userId: widget.userId),
                  ),
                );
              },
              child: const Icon(Icons.add, color: Colors.white), // White icon
            ),
          ),
        ],
      ),
    );
  }
}
