import 'package:hive/hive.dart';

part 'medication.g.dart';

@HiveType(typeId: 0)
class Medication {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String genericName;

  @HiveField(3)
  final double dosage;

  @HiveField(4)
  final String dosageUnit;

  @HiveField(5)
  final String instructions;

  @HiveField(6)
  final DateTime scheduledTime;

  @HiveField(7)
  bool isTaken;

  Medication({
    required this.id,
    required this.name,
    required this.genericName,
    required this.dosage,
    required this.dosageUnit,
    required this.instructions,
    required this.scheduledTime,
    this.isTaken = false,
  });

  // Create a copy of the medication with updated properties
  Medication copyWith({
    String? id,
    String? name,
    String? genericName,
    double? dosage,
    String? dosageUnit,
    String? instructions,
    DateTime? scheduledTime,
    bool? isTaken,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      genericName: genericName ?? this.genericName,
      dosage: dosage ?? this.dosage,
      dosageUnit: dosageUnit ?? this.dosageUnit,
      instructions: instructions ?? this.instructions,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      isTaken: isTaken ?? this.isTaken,
    );
  }

  // Convert medication to a map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'genericName': genericName,
      'dosage': dosage,
      'dosageUnit': dosageUnit,
      'instructions': instructions,
      'scheduledTime': scheduledTime.millisecondsSinceEpoch,
      'isTaken': isTaken,
    };
  }

  // Create a medication from a map
  factory Medication.fromMap(Map<String, dynamic> map) {
    return Medication(
      id: map['id'],
      name: map['name'],
      genericName: map['genericName'],
      dosage: map['dosage'],
      dosageUnit: map['dosageUnit'],
      instructions: map['instructions'],
      scheduledTime: DateTime.fromMillisecondsSinceEpoch(map['scheduledTime']),
      isTaken: map['isTaken'],
    );
  }
}