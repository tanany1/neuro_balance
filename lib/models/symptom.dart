import 'package:flutter/material.dart';

class Symptom {
  final int id;
  final String name;
  final IconData icon;
  final int severity; // 1-5 scale
  final String note; // Optional additional details
  final DateTime date;

  // New fields for the structured symptom data
  final String? experience;
  final String? location;
  final String? additionalInfo;

  Symptom({
    required this.name,
    required this.icon,
    required this.severity,
    this.note = '',
    required this.date,
    int? id,
    this.experience,
    this.location,
    this.additionalInfo,
  }) : this.id = id ?? DateTime.now().millisecondsSinceEpoch;

  Symptom copyWith({
    int? id,
    String? name,
    IconData? icon,
    int? severity,
    String? note,
    DateTime? date,
    String? experience,
    String? location,
    String? additionalInfo,
  }) {
    return Symptom(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      severity: severity ?? this.severity,
      note: note ?? this.note,
      date: date ?? this.date,
      experience: experience ?? this.experience,
      location: location ?? this.location,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }

  // Helper method to parse structured data from a note
  factory Symptom.fromNote(Symptom original) {
    // Default values
    String? experience;
    String? location;
    String? additionalInfo;

    // Try to extract structured data from the note
    if (original.note.isNotEmpty) {
      final lines = original.note.split('\n');

      for (final line in lines) {
        if (line.startsWith('Experience:')) {
          experience = line.replaceFirst('Experience:', '').trim();
        } else if (line.startsWith('Location:')) {
          location = line.replaceFirst('Location:', '').trim();
        } else if (line.startsWith('Additional Info:')) {
          additionalInfo = line.replaceFirst('Additional Info:', '').trim();
        }
      }
    }

    return Symptom(
      id: original.id,
      name: original.name,
      icon: original.icon,
      severity: original.severity,
      note: original.note,
      date: original.date,
      experience: experience,
      location: location,
      additionalInfo: additionalInfo,
    );
  }
}