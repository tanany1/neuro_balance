import 'package:flutter/material.dart';

class Symptom {
  final int id;
  final String name;
  final IconData icon;
  final int severity; // 1-5 scale
  final String note; // Optional additional details
  final DateTime date;

  Symptom({
    required this.name,
    required this.icon,
    required this.severity,
    this.note = '',
    required this.date,
    int? id,
  }) : this.id = id ?? DateTime.now().millisecondsSinceEpoch;

  Symptom copyWith({
    int? id,
    String? name,
    IconData? icon,
    int? severity,
    String? note,
    DateTime? date,
  }) {
    return Symptom(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      severity: severity ?? this.severity,
      note: note ?? this.note,
      date: date ?? this.date,
    );
  }
}