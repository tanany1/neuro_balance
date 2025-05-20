import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:neuro_balance/providers/user_provider.dart';
import 'package:neuro_balance/screens/home/doctor_home_screen.dart';
import 'package:neuro_balance/screens/profile/profile_screen.dart';
import 'package:neuro_balance/screens/tips/awareness_screen.dart';
import 'package:provider/provider.dart';
import 'package:neuro_balance/providers/medication_provider.dart';
import 'package:neuro_balance/providers/symptom_provider.dart';
import 'package:neuro_balance/screens/auth/login/login_screen.dart';
import 'package:neuro_balance/screens/auth/register/register_screen.dart';
import 'package:neuro_balance/screens/chat/chat_screen.dart';
import 'package:neuro_balance/screens/home/home_screen.dart';
import 'package:neuro_balance/screens/medication/medication_screen.dart';
import 'package:neuro_balance/screens/spalsh/splash_screen.dart';
import 'package:neuro_balance/screens/symptoms/symptoms_screen.dart';
import 'package:neuro_balance/screens/welcome/welcome_screen.dart';

import 'firebase_options.dart';
import 'models/medication.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('user_data');
  // Initialize Hive
  await Hive.initFlutter();

  // Register the Medication adapter
  Hive.registerAdapter(MedicationAdapter());

  // Create and initialize the MedicationProvider
  final medicationProvider = MedicationProvider();
  await medicationProvider.initialize();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
          ChangeNotifierProvider(create: (_) => UserProvider()),
          ChangeNotifierProvider(create: (_) => MedicationProvider()),
          ChangeNotifierProvider(create: (_) => SymptomProvider()),
          // Add other providers
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final userDataBox = Hive.box('user_data');
    bool isLoggedIn = userDataBox.get('isLoggedIn', defaultValue: false);
    String? userId = userDataBox.get('loggedInUserId');
    String? userType;

    if (isLoggedIn && userId != null) {
      userType = userDataBox.get('$userId-userType');
    }

    String initialRoute = '/welcome';
    if (isLoggedIn) {
      initialRoute = userType == 'Doctor' ? '/doctor_home' : '/home';
    }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Neuro Balance',
      theme: ThemeData(
        primaryColor: const Color(0xFF4E68FA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4E68FA),
          primary: const Color(0xFF4E68FA),
        ),
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF4E68FA),
          foregroundColor: Colors.white,
        ),
      ),
      routes: {
        '/splash': (context) => SplashScreen(),
        '/welcome': (context) => WelcomeScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/home': (context) => HomeScreen(),
        '/chat': (context) => ChatScreen(),
        '/symptoms': (context) => const SymptomTrackerScreen(),
        '/medications': (context) => const MedicationsScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/doctor_home': (context) => const DoctorHomeScreen(),
        '/awareness': (context) => AwarenessScreen(),
      },
      initialRoute: '/splash',
    );
  }
}
class RouteGuard {
  static Future<bool> canAccessDoctorHome(BuildContext context) async {
    final userDataBox = Hive.box('user_data');
    bool isLoggedIn = userDataBox.get('isLoggedIn', defaultValue: false);
    String? userId = userDataBox.get('loggedInUserId');

    if (!isLoggedIn || userId == null) {
      Navigator.of(context).pushReplacementNamed('/login');
      return false;
    }

    String? userType = userDataBox.get('$userId-userType');
    if (userType != 'Doctor') {
      Navigator.of(context).pushReplacementNamed('/home');
      return false;
    }

    return true;
  }

  static Future<bool> canAccessPatientHome(BuildContext context) async {
    final userDataBox = Hive.box('user_data');
    bool isLoggedIn = userDataBox.get('isLoggedIn', defaultValue: false);
    String? userId = userDataBox.get('loggedInUserId');

    if (!isLoggedIn || userId == null) {
      Navigator.of(context).pushReplacementNamed('/login');
      return false;
    }

    String? userType = userDataBox.get('$userId-userType');
    if (userType == 'Doctor') {
      Navigator.of(context).pushReplacementNamed('/doctor_home');
      return false;
    }

    return true;
  }
}