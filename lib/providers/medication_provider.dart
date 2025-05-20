import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/medication.dart';

class MedicationProvider with ChangeNotifier {
  List<Medication> _medications = [];
  static const String _boxName = 'medications';
  late Box<Map> _medicationsBox;

  List<Medication> get medications {
    // Sort by date and time
    _medications.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    return _medications;
  }

  // Get medications scheduled for today
  List<Medication> get todaysMedications {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return _medications
        .where((med) =>
    med.scheduledTime.isAfter(startOfDay) &&
        med.scheduledTime.isBefore(endOfDay))
        .toList()
      ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
  }

  // Get upcoming medications (scheduled for future dates)
  List<Medication> get upcomingMedications {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final endOfTomorrow = DateTime(now.year, now.month, now.day + 1, 23, 59, 59);

    return _medications
        .where((med) =>
    med.scheduledTime.isAfter(tomorrow) &&
        med.scheduledTime.isBefore(endOfTomorrow))
        .toList()
      ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
  }

  // Initialize the provider by setting up Hive and loading medications
  Future<void> initialize() async {
    // Initialize Hive
    await Hive.initFlutter();

    // Open the medications box
    _medicationsBox = await Hive.openBox<Map>(_boxName);

    // Load medications from Hive
    await loadMedications();
  }

  // Add a new medication
  void addMedication(Medication medication) {
    _medications.add(medication);
    notifyListeners();
    saveMedications();
  }

  // Mark a medication as taken
  void markAsTaken(String id) {
    final index = _medications.indexWhere((med) => med.id == id);
    if (index != -1) {
      _medications[index] = _medications[index].copyWith(isTaken: true);
      notifyListeners();
      saveMedications();
    }
  }

  // Update an existing medication
  void updateMedication(Medication updatedMedication) {
    final index = _medications.indexWhere((med) => med.id == updatedMedication.id);
    if (index != -1) {
      _medications[index] = updatedMedication;
      notifyListeners();
      saveMedications();
    }
  }

  // Delete a medication
  void deleteMedication(String id) {
    _medications.removeWhere((med) => med.id == id);
    notifyListeners();
    saveMedications();
  }

  // Save medications to Hive
  Future<void> saveMedications() async {
    // Clear the existing data
    await _medicationsBox.clear();

    // Save all medications
    for (var med in _medications) {
      await _medicationsBox.put(med.id, med.toMap());
    }
  }

  // Load medications from Hive
  Future<void> loadMedications() async {
    _medications = _medicationsBox.values
        .map((medMap) => Medication.fromMap(Map<String, dynamic>.from(medMap)))
        .toList();
    notifyListeners();
  }

  // Close Hive boxes when the app is closed
  Future<void> dispose() async {
    await _medicationsBox.close();
    super.dispose();
  }
}