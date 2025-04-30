class Medication {
  final String id;
  final String name;
  final String genericName;
  final double dosage;
  final String dosageUnit;
  final String instructions;
  final DateTime scheduledTime;
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