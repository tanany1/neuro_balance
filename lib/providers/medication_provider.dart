import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/medication.dart';

class MedicationProvider with ChangeNotifier {
  List<Medication> _medications = [];
  static const String _storageKey = 'medications';

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

  // Initialize the provider by loading medications from storage
  Future<void> initialize() async {
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

  // Save medications to persistent storage
  Future<void> saveMedications() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> medicationJsonList =
    _medications.map((med) => jsonEncode(med.toMap())).toList();
    await prefs.setStringList(_storageKey, medicationJsonList);
  }

  // Load medications from persistent storage
  Future<void> loadMedications() async {
    final prefs = await SharedPreferences.getInstance();
    final medicationJsonList = prefs.getStringList(_storageKey);

    if (medicationJsonList != null) {
      _medications = medicationJsonList
          .map((medJson) => Medication.fromMap(jsonDecode(medJson)))
          .toList();
      notifyListeners();
    }
  }
}