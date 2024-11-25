import 'package:flutter/material.dart';

// Model for Chat Data
class Chat {
  final String userName;
  final String lastMessage;
  final String time;
  final String avatarUrl;
  final bool isOnline;

  Chat({
    required this.userName,
    required this.lastMessage,
    required this.time,
    required this.avatarUrl,
    required this.isOnline,
  });
}

class ChatListPage extends StatelessWidget {
  const ChatListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Example data for chat list
    List<Chat> chatList = [
      Chat(
        userName: 'Liam',
        lastMessage: 'Hey! Let\'s meet up tomorrow.',
        time: '12:30 PM',
        avatarUrl: 'assets/images/avatar_1.png',
        isOnline: true,
      ),
      Chat(
        userName: 'Emma',
        lastMessage: 'Got your message!',
        time: '10:15 AM',
        avatarUrl: 'assets/images/avatar_2.png',
        isOnline: false,
      ),
      Chat(
        userName: 'Olivia',
        lastMessage: 'Are you free today?',
        time: '8:00 AM',
        avatarUrl: 'assets/images/avatar_3.png',
        isOnline: true,
      ),
      Chat(
        userName: 'Noah',
        lastMessage: 'What\'s up?',
        time: 'Yesterday',
        avatarUrl: 'assets/images/avatar_4.png',
        isOnline: false,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF7ED321), // Green from the theme
        title: const Text('Chats', style: TextStyle(fontFamily: 'ComicSans')),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Search functionality can be added here
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: chatList.length,
        itemBuilder: (context, index) {
          final chat = chatList[index];
          return ChatListItem(chat: chat);
        },
      ),
    );
  }
}

// Chat List Item Widget
class ChatListItem extends StatelessWidget {
  final Chat chat;

  const ChatListItem({Key? key, required this.chat}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
      child: InkWell(
        onTap: () {
          // Navigate to chat screen when tapping on the chat item
          Navigator.pushNamed(context, '/chat', arguments: chat);
        },
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 30,
              backgroundImage: AssetImage(chat.avatarUrl),
              backgroundColor: Colors.transparent,
            ),
            const SizedBox(width: 15),
            // Chat Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User name
                  Text(
                    chat.userName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  // Last message
                  Text(
                    chat.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            // Time
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  chat.time,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white60,
                  ),
                ),
                const SizedBox(height: 5),
                // Online/Offline status indicator
                CircleAvatar(
                  radius: 6,
                  backgroundColor: chat.isOnline
                      ? const Color(0xFF4CAF50) // Green for online
                      : const Color(0xFF757575), // Grey for offline
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
