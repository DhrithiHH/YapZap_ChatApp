import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:yapzap/screens/anonymous/anonymous_chat_lobby_page.dart';
import 'package:yapzap/screens/chatpage.dart';
import 'package:yapzap/screens/connect.dart';
import 'package:yapzap/screens/user_profile_page.dart'; // Make sure the ConnectPage is available

class Home extends StatefulWidget {
  final String userId;

  const Home({Key? key, required this.userId}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _searchQuery = '';
  late IO.Socket socket;

  // Page Controller for smooth sliding
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _connectSocket();
  }

  void _connectSocket() {
    socket = IO.io(
      'http://server-ouzf.onrender.com',
      IO.OptionBuilder().setTransports(['websocket']).setQuery({'userId': widget.userId}).build(),
    );

    socket.on('connect', (_) => print('Connected to socket: ${socket.id}'));
    socket.on('disconnect', (_) => print('Disconnected from socket'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // backgroundColor: const Color(0xFFFFB0FE),
        elevation: 0,
        // title: const Text(
        //   'Chats',
        //   style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        // ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black),
            onPressed: () {
              // Navigate to settings screen
            },
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: [
          _buildChatScreen(),
          _buildAnonymousScreen(), // Chat screen content
          UserProfilePage(userId: widget.userId ), // Anonymous screen content
          // _buildProfileScreen(), // Profile screen content
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Anonymous',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ConnectPage(userId: widget.userId, socket: socket),
                  ),
                );
              },
              child: const Icon(Icons.add),
              backgroundColor: const Color(0xFF00A86B),
            )
          : null, // Only show FAB on the Chat screen
    );
  }

  Widget _buildChatScreen() {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            // Show a dialog to update the status
          },
          child: Container(
            margin: const EdgeInsets.all(16.0),
            padding: const EdgeInsets.all(16.0),
            height: 100.0, // Set explicit height for a taller container
            decoration: BoxDecoration(
              color: const Color(0xFFFFB0FE),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center, // Center content vertically
              children: const [
                Text(
                  'Update Status',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.0),
                ),
                Icon(Icons.edit, color: Colors.white, size: 24.0),
              ],
            ),
          ),
        ),
        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by user ID...',
              filled: true,
              fillColor: Colors.grey[200],
              prefixIcon: const Icon(Icons.search, color: Colors.black),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) => setState(() {
              _searchQuery = value;
            }),
          ),
        ),

        // Chat List
        Expanded(
          child: StreamBuilder<DocumentSnapshot>( 
            stream: _firestore.collection('users').doc(widget.userId).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return const Center(
                  child: Text('Failed to load contacts. Try again.'),
                );
              }

              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Center(
                  child: Text('User data not found.'),
                );
              }

              final userDoc = snapshot.data!;
              final contacts = List<String>.from(userDoc['contacts'] ?? []);
              final filteredContacts = contacts.where((contactId) {
                return contactId.toLowerCase().contains(_searchQuery.toLowerCase());
              }).toList();

              if (filteredContacts.isEmpty) {
                return const Center(
                  child: Text('No contacts found.'),
                );
              }

              return ListView.builder(
                itemCount: filteredContacts.length,
                itemBuilder: (context, index) {
                  final contactId = filteredContacts[index];
                  return ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    title: Text(contactId),
                    onTap: () {
                      // Navigate to chat screen
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
          ),
        ),
      ],
    );
  }

  Widget _buildAnonymousScreen() {
    // Navigate to the Anonymous Chat Lobby Page
    return AnonymousChatLobbyPage();
  }

  // Widget _buildProfileScreen() {
  //   return const UserProfilePage(userId: widget.userId );
  // }

  @override
  void dispose() {
    socket.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }
}
