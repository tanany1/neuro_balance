import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/symptom.dart';
import '../providers/symptom_provider.dart';

class SymptomDetailDialog extends StatefulWidget {
  final String symptomName;
  final IconData symptomIcon;

  const SymptomDetailDialog({
    Key? key,
    required this.symptomName,
    required this.symptomIcon,
  }) : super(key: key);

  @override
  State<SymptomDetailDialog> createState() => _SymptomDetailDialogState();
}

class _SymptomDetailDialogState extends State<SymptomDetailDialog> {
  int _selectedSeverity = 3;
  final TextEditingController _noteController = TextEditingController();

  final List<String> _severityLabels = [
    'Very Mild',
    'Mild',
    'Moderate',
    'Severe',
    'Very Severe',
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon and symptom name
              Row(
                children: [
                  Icon(
                    widget.symptomIcon,
                    size: 32,
                    color: const Color(0xFF4E68FA),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.symptomName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Add a close button
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Severity selector
              const Text(
                'Severity Level',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),

              // Severity slider
              Column(
                children: [
                  Slider(
                    value: _selectedSeverity.toDouble(),
                    min: 0,
                    max: 4,
                    divisions: 4,
                    activeColor: const Color(0xFF4E68FA),
                    onChanged: (value) {
                      setState(() {
                        _selectedSeverity = value.toInt();
                      });
                    },
                  ),
                  // Severity labels
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (int i = 0; i < _severityLabels.length; i++)
                          Text(
                            i == _selectedSeverity ? _severityLabels[i] : '',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                              i == _selectedSeverity
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color:
                              i == _selectedSeverity
                                  ? const Color(0xFF4E68FA)
                                  : Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Notes',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add any details about this symptom...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF4E68FA)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final symptomProvider = Provider.of<SymptomProvider>(
                      context,
                      listen: false,
                    );

                    // Create a new symptom with the entered details
                    final newSymptom = Symptom(
                      name: widget.symptomName,
                      icon: widget.symptomIcon,
                      severity: _selectedSeverity + 1, // Convert to 1-5 scale
                      note: _noteController.text,
                      date: DateTime.now(),
                      // No need to explicitly set id - it will be auto-generated in the constructor
                    );

                    // Add the symptom to the provider
                    symptomProvider.addSymptom(newSymptom);

                    // Show snackbar confirmation
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${widget.symptomName} recorded successfully'),
                        duration: const Duration(seconds: 2),
                        backgroundColor: const Color(0xFF4E68FA),
                      ),
                    );

                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4E68FA),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Add Symptom',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}