import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Get all chats for current user
  Stream<QuerySnapshot> getChatsForCurrentUser() {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .snapshots();
  }

  // Get chat messages
  Stream<QuerySnapshot> getChatMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots();
  }

  // Get user data by ID
  Future<DocumentSnapshot> getUserById(String userId) {
    return _firestore.collection('users').doc(userId).get();
  }

  // Send message
  Future<void> sendMessage({
    required String chatId,
    required String message,
  }) async {
    if (message.trim().isEmpty) return;

    // Get current user data for profile image
    final currentUserDoc = await _firestore.collection('users').doc(currentUserId).get();
    final currentUserData = currentUserDoc.data();

    // Add message to chat
    await _firestore.collection('chats').doc(chatId).collection('messages').add({
      'text': message,
      'senderId': currentUserId,
      'senderProfileImage': currentUserData?['profileImage'],
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Update last message in chat document
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': message,
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
    });
  }

  // Create or get chat with user
  Future<String> createOrGetChat(String otherUserId) async {
    // Check if user exists
    final userDoc = await _firestore.collection('users').doc(otherUserId).get();
    if (!userDoc.exists) {
      throw Exception('User not found');
    }

    // Create chat ID from sorted user IDs
    List<String> participants = [currentUserId!, otherUserId];
    participants.sort();
    String chatId = participants.join('_');

    // Create chat document if it doesn't exist
    await _firestore.collection('chats').doc(chatId).set({
      'participants': participants,
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': '',
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return chatId;
  }
}