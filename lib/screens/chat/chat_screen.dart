import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _messageController = TextEditingController();

  String? _selectedChatUserUniqueId;
  String? _selectedChatUserName;
  String? _currentUserUniqueId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _getCurrentUserUniqueId();
  }

  Future<void> _getCurrentUserUniqueId() async {
    if (_auth.currentUser != null) {
      try {
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _currentUserUniqueId = userData['uniqueId'];
          });
        }
      } catch (e) {
        debugPrint('Error getting current user uniqueId: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Center(child: const Text('Messages')),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_selectedChatUserUniqueId == null
          ? _buildChatList()
          : _buildChatDetail()),
      floatingActionButton: _selectedChatUserUniqueId == null
          ? FloatingActionButton(
        onPressed: _showAddChatDialog,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      )
          : null,
    );
  }

  Widget _buildChatList() {
    String? currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null || _currentUserUniqueId == null) {
      return const Center(child: Text('You need to be logged in'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('chats')
          .where('participantUniqueIds', arrayContains: _currentUserUniqueId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('No conversations yet'),
          );
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var chatData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            String chatId = snapshot.data!.docs[index].id;
            List<dynamic> participantUniqueIds = chatData['participantUniqueIds'];

            // Safety check
            if (participantUniqueIds.isEmpty) {
              return const ListTile(title: Text('Invalid chat data'));
            }

            String otherUserUniqueId = participantUniqueIds.firstWhere(
                  (id) => id != _currentUserUniqueId,
              orElse: () => 'unknown',
            );

            if (otherUserUniqueId == 'unknown') {
              return const ListTile(title: Text('User not found'));
            }

            return FutureBuilder<QuerySnapshot>(
              future: _firestore
                  .collection('users')
                  .where('uniqueId', isEqualTo: otherUserUniqueId)
                  .limit(1)
                  .get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData || userSnapshot.data!.docs.isEmpty) {
                  return const ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Color(0xFFBCC2CB),
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text('Loading...'),
                  );
                }

                var userData = userSnapshot.data!.docs[0].data() as Map<String, dynamic>;
                String userName = '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim();
                if (userName.isEmpty) userName = 'Unknown User';

                return StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('chats')
                      .doc(chatId)
                      .collection('messages')
                      .orderBy('timestamp', descending: true)
                      .limit(1)
                      .snapshots(),
                  builder: (context, messageSnapshot) {
                    String lastMessage = '';
                    if (messageSnapshot.hasData && messageSnapshot.data!.docs.isNotEmpty) {
                      var lastMessageData = messageSnapshot.data!.docs[0].data() as Map<String, dynamic>;
                      lastMessage = lastMessageData['text'] ?? '';
                    }

                    return Dismissible(
                      key: Key(chatId),
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20.0),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                        ),
                      ),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (direction) {
                        return showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text("Confirm"),
                              content: const Text("Are you sure you want to delete this chat?"),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop(true);
                                    _deleteChat(chatId);
                                  },
                                  child: const Text("Delete"),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFBCC2CB),
                          backgroundImage: userData['profileImage'] != null
                              ? NetworkImage(userData['profileImage'])
                              : null,
                          child: userData['profileImage'] == null
                              ? const Icon(Icons.person, color: Colors.white)
                              : null,
                        ),
                        title: Text(userName),
                        subtitle: Text(
                          lastMessage.isNotEmpty ? lastMessage : 'No messages yet',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          setState(() {
                            _selectedChatUserUniqueId = otherUserUniqueId;
                            _selectedChatUserName = userName;
                          });
                        },
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _deleteChat(String chatId) async {
    try {
      // First delete all messages in the chat
      final messages = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .get();

      final batch = _firestore.batch();
      for (var message in messages.docs) {
        batch.delete(message.reference);
      }

      // Then delete the chat document
      batch.delete(_firestore.collection('chats').doc(chatId));

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting chat: ${e.toString()}')),
      );
    }
  }

  Widget _buildChatDetail() {
    if (_currentUserUniqueId == null || _selectedChatUserUniqueId == null) {
      return const Center(child: Text('Chat unavailable'));
    }

    // Create a unique chat ID from the two user unique IDs
    List<String> uniqueIds = [_currentUserUniqueId!, _selectedChatUserUniqueId!];
    uniqueIds.sort(); // Sort to ensure consistent chat ID regardless of who initiates
    String chatId = uniqueIds.join('_');

    return Column(
      children: [
        AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              setState(() {
                _selectedChatUserUniqueId = null;
                _selectedChatUserName = null;
              });
            },
          ),
          title: Text(_selectedChatUserName ?? 'Chat'),
          actions: [
            IconButton(
              icon: const Icon(Icons.info),
              onPressed: () {
              },
            ),
          ],
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('chats')
                .doc(chatId)
                .collection('messages')
                .orderBy('timestamp')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text('No messages yet. Send a message to start the conversation.'),
                );
              }

              List<QueryDocumentSnapshot> messages = snapshot.data!.docs;

              return ListView.builder(
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  var message = messages[index].data() as Map<String, dynamic>;
                  bool isSentByMe = message['senderUniqueId'] == _currentUserUniqueId;

                  // Safely handle timestamp
                  DateTime timestamp;
                  try {
                    timestamp = (message['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
                  } catch (e) {
                    timestamp = DateTime.now();
                  }
                  String formattedTime = DateFormat('h:mm a').format(timestamp);

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: Row(
                      mainAxisAlignment: isSentByMe
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isSentByMe)
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: const Color(0xFFBCC2CB),
                              backgroundImage: message['senderProfileImage'] != null
                                  ? NetworkImage(message['senderProfileImage'])
                                  : null,
                              child: message['senderProfileImage'] == null
                                  ? const Icon(Icons.person, size: 16, color: Colors.white)
                                  : null,
                            ),
                          ),

                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSentByMe ? Colors.blue : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message['text'] ?? '',
                                  style: TextStyle(
                                    color: isSentByMe ? Colors.white : Colors.black,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  formattedTime,
                                  style: TextStyle(
                                    color: isSentByMe
                                        ? Colors.white.withOpacity(0.7)
                                        : Colors.black54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 3,
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Write your message here',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: Colors.blue),
                onPressed: () => _sendMessage(chatId),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showAddChatDialog() {
    final TextEditingController uniqueIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Start a new conversation'),
          content: TextField(
            controller: uniqueIdController,
            decoration: const InputDecoration(
              labelText: 'Enter unique ID',
              hintText: 'Enter the unique ID of the user you want to chat with',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _startNewChat(uniqueIdController.text.trim());
              },
              child: const Text('Start Chat'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _startNewChat(String uniqueId) async {
    if (uniqueId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid unique ID')),
      );
      return;
    }
    if (uniqueId == _currentUserUniqueId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot chat with yourself')),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final userQuery = await _firestore
          .collection('users')
          .where('uniqueId', isEqualTo: uniqueId)
          .limit(1)
          .get();
      if (userQuery.docs.isNotEmpty) {
        final userData = userQuery.docs.first.data();
        final firstName = userData['firstName'] ?? '';
        final lastName = userData['lastName'] ?? '';
        final userName = '$firstName $lastName'.trim();
        List<String> participantUniqueIds = [_currentUserUniqueId!, uniqueId];
        participantUniqueIds.sort();
        String chatId = participantUniqueIds.join('_');

        await _firestore.collection('chats').doc(chatId).set({
          'participantUniqueIds': participantUniqueIds,
          'createdAt': FieldValue.serverTimestamp(),
          'lastMessage': '',
          'lastMessageTimestamp': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        setState(() {
          _selectedChatUserUniqueId = uniqueId;
          _selectedChatUserName = userName.isEmpty ? 'User' : userName;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chat with $userName started')),
        );
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User with this unique ID not found')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _sendMessage(String chatId) async {
    String message = _messageController.text.trim();
    if (message.isEmpty) return;
    _messageController.clear();
    if (_currentUserUniqueId == null) return;
    try {
      final currentUserQuery = await _firestore
          .collection('users')
          .where('uniqueId', isEqualTo: _currentUserUniqueId)
          .limit(1)
          .get();

      final currentUserData = currentUserQuery.docs.isNotEmpty
          ? currentUserQuery.docs.first.data()
          : null;
      await _firestore.collection('chats').doc(chatId).collection('messages').add({
        'text': message,
        'senderUniqueId': _currentUserUniqueId,
        'senderProfileImage': currentUserData?['profileImage'],
        'timestamp': FieldValue.serverTimestamp(),
      });
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': message,
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: ${e.toString()}')),
      );
    }
  }
}