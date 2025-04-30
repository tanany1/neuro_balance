import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/symptom.dart';

class SymptomProvider extends ChangeNotifier {
  final List<Symptom> _symptoms = [];

  // Get all symptoms
  List<Symptom> get symptoms => _symptoms;

  // Get today's symptoms
  List<Symptom> get todaysSymptoms {
    final now = DateTime.now();
    return _symptoms
        .where(
          (s) =>
      s.date.year == now.year &&
          s.date.month == now.month &&
          s.date.day == now.day,
    )
        .toList();
  }

  // Get symptoms for specific date range
  List<Symptom> getSymptomsByDateRange(DateTime start, DateTime end) {
    return _symptoms
        .where(
          (s) =>
      s.date.isAfter(start.subtract(const Duration(days: 1))) &&
          s.date.isBefore(end.add(const Duration(days: 1))),
    )
        .toList();
  }

  // Get symptoms by time range (day, week, month, year)
  List<Symptom> getSymptomsByTimeRange(String timeRange) {
    final now = DateTime.now();
    late DateTime startDate;

    switch (timeRange) {
      case 'Day':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'Week':
      // Get start of the week (consider Sunday as first day)
        final daysToSubtract = now.weekday % 7;
        startDate = DateTime(now.year, now.month, now.day - daysToSubtract);
        break;
      case 'Month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'Year':
        startDate = DateTime(now.year, now.month, 1);
        break;
      default:
        startDate = DateTime(
          now.year,
          now.month,
          now.day - 7,
        ); // Default to week
    }

    return getSymptomsByDateRange(startDate, now);
  }

  // Add a new symptom
  void addSymptom(Symptom symptom) {
    _symptoms.add(symptom);
    notifyListeners();
  }

  // Update existing symptom
  void updateSymptom(Symptom oldSymptom, Symptom newSymptom) {
    final index = _symptoms.indexOf(oldSymptom);
    if (index != -1) {
      _symptoms[index] = newSymptom;
      notifyListeners();
    }
  }

  // Delete symptom
  void deleteSymptom(Symptom symptom) {
    _symptoms.remove(symptom);
    notifyListeners();
  }

  // Remove symptom by ID
  void removeSymptom(int id) {
    _symptoms.removeWhere((symptom) => symptom.id == id);
    notifyListeners();
  }

  // Get chart data for specific symptom
  List<Map<String, dynamic>> getChartDataForSymptom(
      String symptomName,
      String timeRange,
      ) {
    final relevantSymptoms =
    getSymptomsByTimeRange(
      timeRange,
    ).where((s) => s.name == symptomName).toList();

    if (relevantSymptoms.isEmpty) return [];

    // Sort by date
    relevantSymptoms.sort((a, b) => a.date.compareTo(b.date));

    // Convert to chart data format
    return relevantSymptoms.map((symptom) {
      return {'date': symptom.date, 'severity': symptom.severity};
    }).toList();
  }

  // Get all unique symptom names for the selected time range
  List<String> getUniqueSymptomNames(String timeRange) {
    final symptoms = getSymptomsByTimeRange(timeRange);
    final uniqueNames = <String>{};

    for (var symptom in symptoms) {
      uniqueNames.add(symptom.name);
    }

    return uniqueNames.toList();
  }

  // Get daily symptoms data for bar chart (maps symptom names to severity values)
  Map<String, double> getDailySymptomsData() {
    final result = <String, double>{};
    final todaySymptoms = todaysSymptoms;

    // Group symptoms by name and take highest severity for each
    for (var symptom in todaySymptoms) {
      if (!result.containsKey(symptom.name) || result[symptom.name]! < symptom.severity) {
        result[symptom.name] = symptom.severity.toDouble();
      }
    }

    return result;
  }

  // Get chart data for all symptoms
  Map<String, List<FlSpot>> getAllSymptomsChartData(String timeRange) {
    final uniqueSymptoms = getUniqueSymptomNames(timeRange);
    final result = <String, List<FlSpot>>{};

    // Handle different time scales
    final now = DateTime.now();
    late DateTime startDate;
    late int daysDifference;

    switch (timeRange) {
      case 'Day':
        startDate = DateTime(now.year, now.month, now.day);
        daysDifference = 1;
        break;
      case 'Week':
        startDate = DateTime(now.year, now.month, now.day - 6);
        daysDifference = 7;
        break;
      case 'Month':
        startDate = DateTime(now.year, now.month, 1);
        daysDifference = now.difference(startDate).inDays + 1;
        break;
      case 'Year':
        startDate = DateTime(now.year, 1, 1);
        daysDifference = now.difference(startDate).inDays + 1;
        break;
      default:
        startDate = DateTime(now.year, now.month, now.day - 6);
        daysDifference = 7;
    }

    // For each symptom, create a list of spots for the chart
    for (var symptomName in uniqueSymptoms) {
      final symptomData = <FlSpot>[];

      // Get relevant symptoms for this name
      final relevantSymptoms =
      getSymptomsByTimeRange(
        timeRange,
      ).where((s) => s.name == symptomName).toList();

      // For each day in the range, find the symptom or add 0
      for (var i = 0; i < daysDifference; i++) {
        final date = startDate.add(Duration(days: i));

        // Try to find a symptom for this date
        final symptomForDate =
        relevantSymptoms
            .where(
              (s) =>
          s.date.year == date.year &&
              s.date.month == date.month &&
              s.date.day == date.day,
        )
            .toList();

        if (symptomForDate.isNotEmpty) {
          // If multiple entries for same day, take the highest severity
          final highestSeverity = symptomForDate
              .map((s) => s.severity)
              .reduce((a, b) => a > b ? a : b);

          symptomData.add(FlSpot(i.toDouble(), highestSeverity.toDouble()));
        } else {
          // No symptom for this date, add 0 to maintain continuity
          symptomData.add(FlSpot(i.toDouble(), 0));
        }
      }

      result[symptomName] = symptomData;
    }

    return result;
  }

  // Demo data for initial testing
  void addDemoData() {
    final now = DateTime.now();

    // Add some demo symptoms for the past few days
    final symptoms = [
      Symptom(
        id: 1,
        name: 'Numbness or Tingling',
        icon: Icons.pin_end,
        severity: 3,
        note: 'Severe numbness in right leg',
        date: now.subtract(const Duration(days: 4)),
      ),
      Symptom(
        id: 2,
        name: 'Numbness or Tingling',
        icon: Icons.pin_end,
        severity: 5,
        note: 'Numbness in both hands',
        date: now.subtract(const Duration(days: 2)),
      ),
      Symptom(
        id: 3,
        name: 'Numbness or Tingling',
        icon: Icons.pin_end,
        severity: 4,
        note: 'Tingling in fingers',
        date: now,
      ),
      Symptom(
        id: 4,
        name: 'Vision Problems',
        icon: Icons.visibility,
        severity: 2,
        note: 'Slightly blurry vision',
        date: now.subtract(const Duration(days: 3)),
      ),
      Symptom(
        id: 5,
        name: 'Vision Problems',
        icon: Icons.visibility,
        severity: 4,
        note: 'Double vision',
        date: now.subtract(const Duration(days: 1)),
      ),
      Symptom(
        id: 6,
        name: 'Feeling Tired',
        icon: Icons.bedtime,
        severity: 3,
        note: 'Moderate fatigue all day',
        date: now.subtract(const Duration(days: 5)),
      ),
      Symptom(
        id: 7,
        name: 'Feeling Tired',
        icon: Icons.bedtime,
        severity: 2,
        note: 'Tired in the afternoon',
        date: now.subtract(const Duration(days: 1)),
      ),
      Symptom(
        id: 8,
        name: 'Muscle Weakness',
        icon: Icons.fitness_center,
        severity: 3,
        note: 'Moderate weakness while moving in both sides',
        date: now,
      ),
    ];

    for (var symptom in symptoms) {
      _symptoms.add(symptom);
    }

    notifyListeners();
  }
}