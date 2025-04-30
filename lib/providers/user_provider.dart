import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';

class UserProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _userDataBox = Hive.box('user_data');

  User? _user;
  Map<String, dynamic>? _userData;
  bool _isLoading = false;
  String _errorMessage = '';

  User? get user => _user;

  Map<String, dynamic>? get userData => _userData;

  bool get isLoading => _isLoading;

  String get errorMessage => _errorMessage;

  // Use firstName and lastName from the user data to match profile_screen
  String get userName {
    String firstName = _userData?['firstName'] ?? '';
    String lastName = _userData?['lastName'] ?? '';

    // Fallback options if firstName/lastName don't exist
    if (firstName.isEmpty && lastName.isEmpty) {
      // Try to get from name field directly
      final name = _userData?['name'];
      if (name != null && name.toString().isNotEmpty) {
        return name.toString();
      }

      // Try display name from Firebase auth
      final displayName = _user?.displayName;
      if (displayName != null && displayName.isNotEmpty) {
        return displayName;
      }

      // Default fallback
      return 'User';
    }

    // Return the concatenated name
    return '$firstName $lastName'.trim();
  }

  UserProvider() {
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Get current user if already logged in
      _user = _auth.currentUser;
      if (_user != null) {
        await fetchUserData();
      }

      // Listen to auth state changes
      _auth.authStateChanges().listen((User? user) async {
        _user = user;
        if (user != null) {
          await fetchUserData();
        } else {
          _userData = null;
          notifyListeners();
        }
      });
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error initializing user: $_errorMessage');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUserData() async {
    if (_user == null) return;
    final String userId = _user!.uid;

    try {
      _isLoading = true;
      notifyListeners();

      // First try to get data from Firestore
      try {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(userId).get();

        if (userDoc.exists) {
          _userData = userDoc.data() as Map<String, dynamic>;
          debugPrint('User data fetched from Firestore: $_userData');
          // No need to check local storage if Firestore data exists
          return;
        }
      } catch (e) {
        debugPrint('Error fetching from Firestore: $e');
        // Continue to check local storage
      }

      // If Firestore data doesn't exist or there was an error, try local storage
      final localFirstName = _userDataBox.get('$userId-firstName');
      final localLastName = _userDataBox.get('$userId-lastName');
      final localEmail = _userDataBox.get('$userId-email');
      final localUserType = _userDataBox.get('$userId-userType');
      final localGender = _userDataBox.get('$userId-gender');
      final localUniqueId = _userDataBox.get('$userId-uniqueId');

      if (localFirstName != null || localLastName != null) {
        _userData = {
          'firstName': localFirstName ?? '',
          'lastName': localLastName ?? '',
          'email': localEmail ?? _user?.email ?? '',
          'userType': localUserType ?? '',
          'gender': localGender ?? '',
          'uniqueId': localUniqueId ?? '',
        };
        debugPrint('User data fetched from local storage: $_userData');
      }
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error fetching user data: $_errorMessage');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUserData(Map<String, dynamic> data) async {
    if (_user == null) return;
    final String userId = _user!.uid;

    try {
      _isLoading = true;
      notifyListeners();

      await _firestore.collection('users').doc(userId).update(data);

      // Also update local storage
      for (var entry in data.entries) {
        await _userDataBox.put('$userId-${entry.key}', entry.value);
      }

      await fetchUserData();
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error updating user data: $_errorMessage');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
