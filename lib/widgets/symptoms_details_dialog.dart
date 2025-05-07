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
  int _currentStep = 0;
  final TextEditingController _additionalInfoController = TextEditingController();

  // Selected options for each step
  String? _selectedExperience;
  String? _selectedLocation;
  String? _selectedSpecific;

  // Maps symptom names to their questionnaire options
  final Map<String, Map<String, dynamic>> _symptomQuestionnaires = {
    'Numbness or Tingling': {
      'experiences': ['Numbness', 'Electric shock feelings', 'Pins and needles', 'Burning sensation'],
      'locations': ['Left Toes/Feet', 'Left Hands/Fingers', 'Right Toes/Feet', 'Right Hands/Fingers', 'Legs'],
    },
    'Muscle Weakness': {
      'experiences': ['General Weakness', 'Weakness while moving', 'Weakness in one area'],
      'locations': {
        'General Weakness': ['Temperature Sensitivity', 'Specific Time of Day', 'All Day'],
        'Weakness while moving': ['Both Sides', 'Left Side', 'Right Side'],
        'Weakness in one area': ['Left Arm', 'Left Hand', 'Left Leg', 'Right Arm', 'Right Hand', 'Right Leg', 'Torso/Neck'],
      },
    },
    'Vision Problems': {
      'experiences': ['Blurred vision', 'Temporary blindness', 'Light sensitivity', 'Flashes of light', 'Uncontrolled eye movement', 'Blind spots'],
      'locations': {
        'Blurred vision': ['Peripheral vision', 'Center vision'],
        'Temporary blindness': ['Peripheral vision', 'Center vision'],
        'Light sensitivity': ['Entire vision field', 'Bright areas', 'Dimly lit areas'],
        'Flashes of light': ['Upper vision field', 'Lower vision field', 'Peripheral vision field', 'Center vision field'],
        'Uncontrolled eye movement': ['Rapid horizontal movement', 'Rapid vertical movement', 'Circular movement'],
        'Blind spots': ['Peripheral vision loss', 'Central vision loss', 'Scattered blind spots'],
      },
    },
    'Difficulty Walking': {
      'experiences': ['Clumsy Movements', 'Balance Issues', 'Foot Drop', 'Need Support to Walk'],
      'locations': {
        'Clumsy Movements': ['Legs feel clumsy or out of sync', 'Legs feel heavy or sluggish', 'Arms move awkwardly',
          'Toes feel unresponsive', 'Feet miss steps', 'Feet slap the ground'],
        'Balance Issues': ['Trouble staying steady', 'Trouble with uneven ground', 'Trouble with inclines', 'Trouble with turns',
          'Trouble starting movement', 'Trouble with sudden stops', 'Trouble in narrow spaces', 'Side-to-side swaying while walking'],
        'Foot Drop': ['Dragging while walking', 'Trips frequently', 'Difficulty lifting feet', 'Feet land unevenly while walking'],
        'Need Support to Walk': ['Need cane or walker', 'Need physical assistance', 'Cannot walk long distances', 'Requires frequent breaks to rest'],
      },
    },
    'Feeling Tired': {
      'experiences': ['General Fatigue', 'Physical Exhaustion', 'Mental Fatigue', 'Daytime Sleepiness', 'Post-Activity Tiredness', 'Morning Fatigue'],
      'locations': {
        'General Fatigue': ['Whole body'],
        'Mental Fatigue': ['Head', 'Problem Solving', 'Sustained Focus'],
        'Physical Exhaustion': ['Legs', 'Arms', 'Back'],
        'Daytime Sleepiness': ['Eyes', 'Whole Body'],
        'Post-Activity Tiredness': ['Whole Body', 'Legs'],
        'Morning Fatigue': ['Whole Body', 'Back', 'Legs'],
      },
    },
    'Muscle Stiffness': {
      'experiences': ['General Stiffness', 'Painful Stiffness', 'Morning Stiffness', 'Post-Activity Stiffness', 'Uncontrollable Muscle Spasms'],
      'locations': {
        'General Stiffness': ['Legs', 'Arms', 'Neck', 'Back', 'Shoulders'],
        'Painful Stiffness': ['Legs', 'Arms', 'Back'],
        'Morning Stiffness': ['Legs', 'Back', 'Neck'],
        'Post-Activity Stiffness': ['Legs', 'Arms', 'Hands'],
        'Uncontrollable Muscle Spasms': ['Legs', 'Arms', 'Back', 'Neck', 'Shoulders'],
      },
    },
    'Thinking Problems': {
      'experiences': ['Memory issues', 'Difficulty focusing', 'Slow thinking', 'Trouble solving problems', 'Difficulty understanding'],
      'locations': {
        'Memory issues': ['Short-term memory', 'Long-term memory', 'Semantic memory'],
        'Difficulty focusing': ['Sustained attention', 'Divided attention'],
        'Slow thinking': ['Processing speed', 'Mental effort'],
        'Trouble solving problems': ['Logical reasoning', 'Abstract reasoning'],
        'Difficulty understanding':  ['Verbal communication', 'Written communication'],
      },
    },
    'Pain': {
      'experiences': ['Localized Pain', 'Chronic Pain', 'Neuropathic Pain', 'Muscle Pain', 'Trigger-related Pain'],
      'locations': {
        'Localized Pain': ['Face', 'Back', 'Legs'],
        'Chronic Pain': ['Whole Body', 'Back', 'Legs'],
        'Neuropathic Pain': ['Arms', 'Hands', 'Feet', 'Legs', 'Face'],
        'Muscle Pain': ['Shoulders', 'Neck', 'Arms', 'Legs'],
        'Trigger-related Pain': ['Head', 'Arms', 'Back', 'Legs', 'Feet'],
      },
    },
    'Bladder or Bowel Problems': {
      'experiences': ['Urinary Issues', 'Time-Related', 'Incontinence', 'Retention Issues', 'Bowel Function Issues', 'Diet-Related', 'Abdominal Issues'],
      'locations': {
        'Urinary Issues': ['Bladder', 'Abdomen', 'Activity-Related'],
        'Time-Related': ['Bladder'],
        'Bowel Function Issues': ['Bowels', 'Time-Related'],
        'Incontinence': ['Bladder', 'Abdomen'],
        'Retention Issues': ['Bladder', 'Abdomen'],
        'Diet-Related': ['Diet'],
        'Abdominal Issues': ['Abdomen'],
      },
    },
    'Mood Changes': {
      'experiences': ['Depressive Symptoms', 'Anxiety Symptoms', 'Emotional Instability', 'Motivational Issues'],
      'locations': {
        'Depressive Symptoms': ['Emotional', 'Cognitive', 'Physical'],
        'Anxiety Symptoms': ['Emotional', 'Time-Related', 'Physical', 'Cognitive'],
        'Emotional Instability': ['Emotional', 'Social', 'Cognitive'],
        'Motivational Issues': ['Cognitive', 'Emotional', 'Time-Related'],
      },
    },
  };

  // Get severity options - same for all symptoms
  final List<String> _severityOptions = ['Very Mild', 'Mild', 'Moderate', 'Severe', 'Very Severe'];
  String _selectedSeverity = 'Moderate'; // Default to moderate

  @override
  void dispose() {
    _additionalInfoController.dispose();
    super.dispose();
  }

  // Get the appropriate options based on the current step and previous selections
  List<String> _getCurrentOptions() {
    switch (_currentStep) {
      case 0: // Step 1: Experience
        return _symptomQuestionnaires[widget.symptomName]?['experiences'] ?? [];
      case 1: // Step 2: Location
        final locations = _symptomQuestionnaires[widget.symptomName]?['locations'];
        if (locations is Map<String, dynamic> && _selectedExperience != null) {
          return locations[_selectedExperience] ?? [];
        } else if (locations is List<String>) {
          return locations;
        }
        return [];
      case 2: // Step 3: Severity
        return _severityOptions;
      default:
        return [];
    }
  }

  // Get the question title for the current step
  String _getCurrentStepTitle() {
    switch (_currentStep) {
      case 0:
        return "1) Describe the experience:";
      case 1:
        return "2) Where is it happening:";
      case 2:
        return "3) How severe is it?";
      case 3:
        return "4) Additional information:";
      default:
        return "";
    }
  }

  void _handleOptionSelected(String value) {
    setState(() {
      switch (_currentStep) {
        case 0:
          _selectedExperience = value;
          break;
        case 1:
          _selectedLocation = value;
          break;
        case 2:
          _selectedSeverity = value;
          break;
      }
    });
  }

  void _goToNextStep() {
    if (_currentStep < 3) {
      setState(() {
        _currentStep++;
      });
    } else {
      _saveSymptom();
    }
  }

  void _goToPreviousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  void _saveSymptom() {
    final symptomProvider = Provider.of<SymptomProvider>(context, listen: false);

    // Convert severity string to numeric value (1-5)
    final int severityValue = _severityOptions.indexOf(_selectedSeverity) + 1;

    // Construct note from selections
    final note = 'Experience: $_selectedExperience\n'
        'Location: $_selectedLocation\n'
        'Additional Info: ${_additionalInfoController.text}';

    // Create a new symptom with the entered details
    final newSymptom = Symptom(
      name: widget.symptomName,
      icon: widget.symptomIcon,
      severity: severityValue,
      note: note,
      date: DateTime.now(),
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

              // Progress indicator
              LinearProgressIndicator(
                value: (_currentStep + 1) / 4, // 4 total steps
                backgroundColor: Colors.grey[200],
                color: const Color(0xFF4E68FA),
              ),

              const SizedBox(height: 16),

              // Step title
              Text(
                _getCurrentStepTitle(),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),

              const SizedBox(height: 16),

              // Content based on current step
              if (_currentStep < 3) // Steps 0-2: Dropdown selections
                _buildDropdownStep()
              else // Step 3: Additional information text field
                TextField(
                  controller: _additionalInfoController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Add any additional details about this symptom...',
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

              // Navigation buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button (except on first step)
                  if (_currentStep > 0)
                    OutlinedButton(
                      onPressed: _goToPreviousStep,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: Color(0xFF4E68FA)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      child: const Text('Back'),
                    )
                  else
                    const SizedBox(), // Empty widget to maintain layout

                  // Next/Finish button
                  ElevatedButton(
                    onPressed: _currentStep == 0 && _selectedExperience == null ||
                        _currentStep == 1 && _selectedLocation == null
                        ? null // Disable if no selection made
                        : _goToNextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4E68FA),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: Text(
                      _currentStep < 3 ? 'Next' : 'Save',
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownStep() {
    final options = _getCurrentOptions();
    final String? currentValue = _currentStep == 0
        ? _selectedExperience
        : _currentStep == 1
        ? _selectedLocation
        : _selectedSeverity;

    // Show a message if there are no options
    if (options.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Text('No options available for this selection. Please go back and try a different option.'),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentValue,
          hint: const Text('Select an option'),
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF4E68FA)),
          elevation: 2,
          itemHeight: 60,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 16,
          ),
          onChanged: (String? value) {
            if (value != null) {
              _handleOptionSelected(value);
            }
          },
          items: options.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(value),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}