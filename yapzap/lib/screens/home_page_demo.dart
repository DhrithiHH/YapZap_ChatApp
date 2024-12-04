import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
// import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:yapzap/screens/CallScreen.dart';
import 'package:yapzap/screens/chatpage.dart';
import 'connect.dart';

class HomePageDemo extends StatefulWidget {
  final String userId; // Accepts userId as a parameter

  const HomePageDemo({Key? key, required this.userId}) : super(key: key);

  @override
  _HomePageDemoState createState() => _HomePageDemoState();
}

class _HomePageDemoState extends State<HomePageDemo>
    with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _searchQuery = '';
  late IO.Socket socket;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _connectSocket();
  }

  @override
  void dispose() {
    _disconnectSocket();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!socket.connected) {
        _connectSocket();
      }
    } else if (state == AppLifecycleState.detached) {
      _disconnectSocket();
    }
  }

  void _connectSocket() {
    socket = IO.io(
      'http://server-ouzf.onrender.com', // Replace with your server URL
      IO.OptionBuilder().setTransports(['websocket']).setQuery(
          {'userId': widget.userId}).build(),
    );

    socket.on('connect', (_) => print('Connected to socket: ${socket.id}'));
    socket.on('disconnect', (_) => print('Disconnected from socket'));
    socket.on('call', _handleIncomingCall);
  }

  void _disconnectSocket() {
    if (socket.connected) {
      socket.disconnect();
    }
  }

  void _initiateCall(String peerId, String callType) {
    final callData = {
      'from': widget.userId,
      'type': callType,
      'to': peerId,
    };

    // Notify peer about the call
    socket.emit('call', callData);

    // Navigate to call screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CallScreen(callData: callData, socket: socket),
      ),
    );
  }

  void _handleIncomingCall(data) {
    // Incoming call logic
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CallScreen(callData: data, socket: socket, isIncoming: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0XFF5D8F), Color.fromARGB(0, 199, 87, 130)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // Search Bar
            Container(
              padding:
                  const EdgeInsets.only(top: 40.0, left: 16.0, right: 16.0),
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
                stream: _firestore
                    .collection('users')
                    .doc(widget.userId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError ||
                      !snapshot.hasData ||
                      snapshot.data == null ||
                      !snapshot.data!.exists) {
                    return const Center(
                        child: Text('Failed to load contacts.'));
                  }

                  final userDoc = snapshot.data!;
                  final data = userDoc.data() as Map<String, dynamic>? ?? {};
                  final contacts = List<String>.from(data['contacts'] ?? []);

                  final filteredContacts = contacts.where((contactId) {
                    return contactId
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase());
                  }).toList();

                  return filteredContacts.isEmpty
                      ? const Center(child: Text('No contacts found.'))
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
                                      title: Text('Loading...'));
                                }

                                if (contactSnapshot.hasError ||
                                    !contactSnapshot.hasData ||
                                    !contactSnapshot.data!.exists) {
                                  return const ListTile(
                                      title: Text('Error loading contact'));
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
                                  title: Text(username),
                                  subtitle: Text('UserID: $contactId'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.call,
                                            color: Colors.green),
                                        onPressed: () =>
                                            _initiateCall(contactId, 'audio'),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.videocam,
                                            color: Colors.blue),
                                        onPressed: () =>
                                            _initiateCall(contactId, 'video'),
                                      ),
                                    ],
                                  ),
                                  onTap: () {
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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: FloatingActionButton(
                backgroundColor: const Color(0xFF00A86B),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ConnectPage(userId: widget.userId, socket: socket),
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
