import 'package:flutter/material.dart';
import '../models/symptom.dart';

class SymptomCard extends StatelessWidget {
  final Symptom symptom;

  const SymptomCard({Key? key, required this.symptom}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Convert severity (1-5) to a text label
    final severityLabels = [
      'Very Mild',
      'Mild',
      'Moderate',
      'Severe',
      'Very Severe',
    ];
    final severityLabel = severityLabels[symptom.severity - 1];

    // Color based on severity
    final Color severityColor = _getSeverityColor(symptom.severity);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Symptom icon with circular background
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF4E68FA).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                symptom.icon is IconData ? symptom.icon : Icons.healing,
                color: const Color(0xFF4E68FA),
                size: 20,
              ),
            ),

            const SizedBox(width: 12),

            // Symptom details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Symptom name
                  Text(
                    symptom.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Severity text
                  Text(
                    severityLabel,
                    style: TextStyle(
                      color: severityColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Notes
                  Text(
                    symptom.note,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSeverityColor(int severity) {
    switch (severity) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.lime;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.deepOrange;
      case 5:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
