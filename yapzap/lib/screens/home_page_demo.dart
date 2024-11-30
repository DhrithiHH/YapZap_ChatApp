import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:yapzap/screens/chatpage.dart';
import 'connect.dart';

class HomePageDemo extends StatefulWidget {
  final String userId; // Accepts userId as a parameter

  const HomePageDemo({Key? key, required this.userId}) : super(key: key);
  
  // get socket => null;
  

  @override
  _HomePageDemoState createState() => _HomePageDemoState();
}

class _HomePageDemoState extends State<HomePageDemo> with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _searchQuery = '';
  late IO.Socket socket;
  // get socket1 => socket;

  @override
  void initState() {
    super.initState();

    // Observe app lifecycle for managing socket connection
    WidgetsBinding.instance.addObserver(this);

    // Connect to the socket server
    _connectSocket();
  }

  @override
  void dispose() {
    // Cleanup socket connection
    _disconnectSocket();

    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Manage socket connection based on app lifecycle
    if (state == AppLifecycleState.resumed) {
      // Reconnect socket when app is active
      if (!socket.connected) {
        _connectSocket();
      }
    } else if (state == AppLifecycleState.detached) {
      // Disconnect socket when app is terminated
      _disconnectSocket();
    }
  }

  void _connectSocket() {
    // Initialize and connect the socket
    socket = IO.io(
      'http://server-ouzf.onrender.com', // Replace with your server URL
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setQuery({'userId': widget.userId}) // Send userId to the server
          .build(),
    );

    // Listen for connection
    socket.on('connect', (_) {
      print('Connected to socket: ${socket.id}');
    });

    // Handle disconnection
    socket.on('disconnect', (_) {
      print('Disconnected from socket');
    });

    // Listen for custom events (e.g., message, notification)
    socket.on('new-message', (data) {
      print('New message received: $data');
    });

    socket.on('user-joined', (data) {
      print('User joined: $data');
    });

    // Handle any errors
    socket.on('error', (error) {
      print('Socket error: $error');
    });
  }

  void _disconnectSocket() {
    // Disconnect socket
    if (socket.connected) {
      socket.disconnect();
    }
  }

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
            // Search Bar
            Container(
              padding: const EdgeInsets.only(top: 40.0, left: 16.0, right: 16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by user ID...',
                  hintStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.2),
                  prefixIcon: const Icon(Icons.search, color: Colors.white),
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

            // Contacts List
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: _firestore.collection('users').doc(widget.userId).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('Failed to load contacts. Please try again later.'),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data == null || !snapshot.data!.exists) {
                    return const Center(
                      child: Text('User data not found. Please check your account.'),
                    );
                  }

                  final userDoc = snapshot.data!;
                  final data = userDoc.data() as Map<String, dynamic>? ?? {};
                  final contacts = List<String>.from(data['contacts'] ?? []);

                  // Filter contacts based on search query
                  final filteredContacts = contacts.where((contactId) {
                    return contactId.toLowerCase().contains(_searchQuery.toLowerCase());
                  }).toList();

                  return filteredContacts.isEmpty
                      ? const Center(
                          child: Text(
                            'No contacts found.',
                            style: TextStyle(color: Colors.white),
                          ),
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
                                    title: Text(
                                      'Loading...',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  );
                                }

                                if (contactSnapshot.hasError ||
                                    !contactSnapshot.hasData ||
                                    !contactSnapshot.data!.exists) {
                                  return const ListTile(
                                    title: Text(
                                      'Error loading contact',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  );
                                }

                                final contactData = contactSnapshot.data!.data() as Map<String, dynamic>;
                                final username = contactData['username'] ?? 'Unknown User';
                                final profilePic = contactData['profilePic'] ?? '';

                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage: profilePic.isNotEmpty ? NetworkImage(profilePic) : null,
                                    child: profilePic.isEmpty
                                        ? const Icon(Icons.person, color: Colors.white)
                                        : null,
                                  ),
                                  title: Text(username, style: const TextStyle(color: Colors.white)),
                                  subtitle: Text(
                                    'UserID: $contactId',
                                    style: const TextStyle(color: Colors.white70),
                                  ),
                                  onTap: () {
                                    // Navigate to Chat Screen
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChatScreen(
                                          userId: widget.userId,
                                          peerId: contactId,
                                          socket: socket,
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

            // Floating Action Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: FloatingActionButton(
                backgroundColor: const Color(0xFF00A86B),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ConnectPage(userId: widget.userId,socket:socket),
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
