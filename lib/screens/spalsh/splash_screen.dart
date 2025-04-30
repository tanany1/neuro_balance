import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _userDataBox = Hive.box('user_data');

  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 3));

    // Check if user is logged in
    bool isLoggedIn = _userDataBox.get('isLoggedIn') ?? false;

    if (isLoggedIn) {
      String? userId = _userDataBox.get('loggedInUserId');

      // Verify that the Firebase auth session is still valid
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null && userId != null) {
        // User is authenticated both locally and in Firebase
        bool isDoctor = _userDataBox.get('$userId-userType') == 'Doctor';

        if (isDoctor) {
          Navigator.pushReplacementNamed(context, '/chat');
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
        return;
      } else {
        // Firebase session expired but local data exists
        // Clear login state as it's no longer valid
        await _userDataBox.put('isLoggedIn', false);
        await _userDataBox.delete('loggedInUserId');
      }
    }

    // Default path if not logged in
    Navigator.pushReplacementNamed(context, '/welcome');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4B5FFC),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.medical_services_outlined,
                color: Color(0xFF4B5FFC),
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Neuro Balance',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}