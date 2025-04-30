import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _userDataBox = Hive.box('user_data');
  final _auth = FirebaseAuth.instance;

  bool _isLoading = true;
  bool _showPassword = false;

  // User data
  String _uniqueId = '';
  String _firstName = '';
  String _lastName = '';
  String _email = '';
  final String _password = '********';
  String _userType = '';
  String _gender = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        final userId = currentUser.uid;

        // Try to load from Firestore first
        try {
          final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

          if (userDoc.exists) {
            final userData = userDoc.data()!;

            setState(() {
              _uniqueId = userData['uniqueId'] ?? '';
              _firstName = userData['firstName'] ?? '';
              _lastName = userData['lastName'] ?? '';
              _email = userData['email'] ?? '';
              _userType = userData['userType'] ?? '';
              _gender = userData['gender'] ?? '';
            });

            // Update local storage with latest data
            _updateLocalStorage(userId, userData);
          } else {
            // If not in Firestore, try to load from local storage
            _loadFromLocalStorage(userId);
          }
        } catch (e) {
          // If Firestore fails, fall back to local storage
          _loadFromLocalStorage(userId);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _loadFromLocalStorage(String userId) {
    setState(() {
      _uniqueId = _userDataBox.get('$userId-uniqueId') ?? '';
      _firstName = _userDataBox.get('$userId-firstName') ?? '';
      _lastName = _userDataBox.get('$userId-lastName') ?? '';
      _email = _userDataBox.get('$userId-email') ?? '';
      _userType = _userDataBox.get('$userId-userType') ?? '';
      _gender = _userDataBox.get('$userId-gender') ?? '';
    });
  }

  void _updateLocalStorage(String userId, Map<String, dynamic> userData) async {
    await _userDataBox.put('$userId-uniqueId', userData['uniqueId'] ?? '');
    await _userDataBox.put('$userId-firstName', userData['firstName'] ?? '');
    await _userDataBox.put('$userId-lastName', userData['lastName'] ?? '');
    await _userDataBox.put('$userId-email', userData['email'] ?? '');
    await _userDataBox.put('$userId-userType', userData['userType'] ?? '');
    await _userDataBox.put('$userId-gender', userData['gender'] ?? '');
  }

  Future<void> _logout() async {
    try {
      await _auth.signOut();

      // Clear login state
      await _userDataBox.put('isLoggedIn', false);
      await _userDataBox.delete('loggedInUserId');

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logged out successfully')),
      );

      // Navigate to welcome screen
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/welcome',
            (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: ${e.toString()}')),
      );
    }
  }

  Future<void> _deleteAccount() async {
    try {
      // Show loading indicator
      setState(() {
        _isLoading = true;
      });

      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        final userId = currentUser.uid;

        // 1. Delete user data from Firestore
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .delete();

          // Delete any other collections related to this user
          // For example, if you have patient records, appointments, etc.
          // await FirebaseFirestore.instance.collection('appointments').where('userId', isEqualTo: userId).get()
          //   .then((snapshot) {
          //     for (DocumentSnapshot ds in snapshot.docs) {
          //       ds.reference.delete();
          //     }
          //   });
        } catch (e) {
          print('Error deleting from Firestore: ${e.toString()}');
          // Continue with account deletion even if Firestore delete fails
        }

        // 2. Delete user from Firebase Authentication
        await currentUser.delete();

        // 3. Clear local storage data related to this user
        final allKeys = _userDataBox.keys.toList();
        for (final key in allKeys) {
          if (key is String && key.startsWith('$userId-')) {
            await _userDataBox.delete(key);
          }
        }

        // Clear login state
        await _userDataBox.put('isLoggedIn', false);
        await _userDataBox.delete('loggedInUserId');

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account deleted successfully')),
        );

        // Navigate to welcome screen
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/welcome',
              (route) => false,
        );
      }
    } catch (e) {
      // Hide loading indicator
      setState(() {
        _isLoading = false;
      });

      String errorMessage = 'Error deleting account: ${e.toString()}';

      // Handle specific Firebase Auth errors
      if (e is FirebaseAuthException) {
        if (e.code == 'requires-recent-login') {
          errorMessage = 'Please log out and log in again before deleting your account.';
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently lost.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _logout();
              _deleteAccount();
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _logout();
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Center(child: const Text('My Profile')),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              _showLogoutDialog();
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body:
      _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(color: Color(0xFF4B5FFC)),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: _getAvatarContent(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$_firstName $_lastName',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _userType,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Profile Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4B5FFC),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildProfileField(
                    label: 'User ID',
                    value: _uniqueId,
                    icon: Icons.badge,
                  ),
                  _buildProfileField(
                    label: 'Full Name',
                    value: '$_firstName $_lastName',
                    icon: Icons.person,
                  ),
                  _buildProfileField(
                    label: 'Email',
                    value: _email,
                    icon: Icons.email,
                  ),
                  _buildPasswordField(),
                  _buildProfileField(
                    label: 'Gender',
                    value: _gender,
                    icon:
                    _gender == 'Male'
                        ? Icons.male
                        : _gender == 'Female'
                        ? Icons.female
                        : Icons.person,
                  ),
                  _buildProfileField(
                    label: 'User Type',
                    value: _userType,
                    icon:
                    _userType == 'Doctor'
                        ? Icons.medical_services
                        : Icons.personal_injury,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _showDeleteAccountDialog,
                      icon: const Icon(Icons.delete_forever),
                      label: const Text(
                        'Delete Account',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getAvatarContent() {
    if (_firstName.isNotEmpty && _lastName.isNotEmpty) {
      return Text(
        '${_firstName[0]}${_lastName.isNotEmpty ? _lastName[0] : ''}',
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Color(0xFF4B5FFC),
        ),
      );
    } else {
      return const Icon(Icons.person, size: 40, color: Color(0xFF4B5FFC));
    }
  }

  Widget _buildProfileField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF4B5FFC), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.lock, color: Color(0xFF4B5FFC), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Password',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _showPassword
                        ? 'Your actual password is not accessible'
                        : _password,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                _showPassword ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFF4B5FFC),
              ),
              onPressed: () {
                setState(() {
                  _showPassword = !_showPassword;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}