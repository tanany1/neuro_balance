import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'dart:developer' as developer;

import '../../models/medication.dart';
import '../../providers/medication_provider.dart';
import '../../services/notification_services.dart';

class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({Key? key}) : super(key: key);

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  bool _showAllMedications = true;
  final NotificationService _notificationService = NotificationService();
  DateTime _selectedDate = DateTime.now();
  int _notificationIdCounter = 0;

  final List<Map<String, dynamic>> _availableMedications = [
    {
      'name': 'Copaxone',
      'generic name' : 'Copaxone',
      'dosage': 20.0,
      'dosageUnit': 'mg/ml',
      'instructions': 'Rotate injection sites',
      'frequency': 'once daily',
    },
    {
      'name': 'Avonex',
      'generic name' : 'Avonex',
      'dosage': 30.0,
      'dosageUnit': 'mg/ml',
      'instructions': 'Take at bedtime to reduce flu-like symptoms',
      'frequency': 'once a week',
    },
    {
      'name': 'Rebif',
      'generic name' : 'Rebif',
      'dosage': 44.0,
      'dosageUnit': 'mg/ml',
      'instructions': 'Rotate injection sites',
      'frequency': 'three times a week',
    },
    {
      'name': 'Betaseron',
      'generic name' : 'Betaseron',
      'dosage': 250.0,
      'dosageUnit': 'mg/ml',
      'instructions': 'Rotate injection sites; allow solution to reach room temp before injecting',
      'frequency': 'once every two days',
    },
    {
      'name': 'Extavia',
      'generic name' : 'Extavia',
      'dosage': 250.0,
      'dosageUnit': 'mg/ml',
      'instructions': 'Rotate injection sites; allow solution to reach room temp before injecting',
      'frequency': 'once every two days',
    },
    {
      'generic name': 'Dimethylfumarate',
      'name' : 'Tecfidera/Marovarex',
      'dosage': 240.0,
      'dosageUnit': 'mg',
      'instructions': 'Take with food to reduce stomach upset and flushing',
      'frequency': 'twice daily',
    },
    {
      'generic name': 'Teriflunomide',
      'name' : 'Aubagio/Triflutect',
      'dosage': 14.0,
      'dosageUnit': 'mg',
      'instructions': 'Take at the same time daily, with or without food',
      'frequency': 'once daily',
    },
    {
      'generic name': ' Fingolimod',
      'name' : 'Gilenya/sphingomod',
      'dosage': 0.5,
      'dosageUnit': 'mg',
      'instructions': 'First dose must be monitored in clinic (heart rate)',
      'frequency': 'once daily',
    },
    {
      'generic name': 'Siponimod',
      'name' : 'Mayzent',
      'dosage': 2.0,
      'dosageUnit': 'mg',
      'instructions': 'First dose may need monitoring',
      'frequency': 'once daily',
    },
  ];

  @override
  void initState() {
    super.initState();
    _notificationService.initNotification().then((_) {
      developer.log('NotificationService initialized successfully');
    }).catchError((error) {
      developer.log('Error initializing NotificationService: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    final medicationProvider = Provider.of<MedicationProvider>(context);
    final allMedications = medicationProvider.medications;
    final selectedDateMedications = medicationProvider.medications.where((med) {
      final medicationDate = med.scheduledTime;
      return medicationDate.year == _selectedDate.year &&
          medicationDate.month == _selectedDate.month &&
          medicationDate.day == _selectedDate.day;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF4E68FA),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: const Text(
                'Medications',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildCalendarWidget(),
            ),
            Expanded(
              child: _showAllMedications
                  ? ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: allMedications.length,
                itemBuilder: (context, index) {
                  return _buildSwipeableMedicationCard(
                      context, allMedications[index], medicationProvider);
                },
              )
                  : selectedDateMedications.isEmpty
                  ? Center(
                child: Text(
                  'No medications added for ${DateFormat('MMMM d').format(_selectedDate)}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: selectedDateMedications.length,
                itemBuilder: (context, index) {
                  return _buildSwipeableMedicationCard(context,
                      selectedDateMedications[index], medicationProvider);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddMedicationDialog(context, medicationProvider);
        },
        backgroundColor: const Color(0xFF4E68FA),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCalendarWidget() {
    final now = DateTime.now();

    // Generate 7 days from today
    final List<DateTime> days = List.generate(7, (index) {
      return DateTime(now.year, now.month, now.day + index);
    });

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: days.map((day) {
          final isSelected = day.year == _selectedDate.year &&
              day.month == _selectedDate.month &&
              day.day == _selectedDate.day;

          final dayName = DateFormat('EEE').format(day).substring(0, 3);
          final dayNumber = day.day.toString();
          final monthName = DateFormat('MMM').format(day);

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = day;
                _showAllMedications = false;
              });
            },
            child: Container(
              width: 40,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF4E68FA) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    dayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dayNumber,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    monthName,
                    style: TextStyle(
                      fontSize: 10,
                      color: isSelected ? Colors.white : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSwipeableMedicationCard(BuildContext context, Medication medication, MedicationProvider provider) {
    return Dismissible(
      key: Key(medication.id),
      direction: DismissDirection.horizontal,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) {
        return _confirmDelete(context, medication);
      },
      onDismissed: (direction) {
        provider.deleteMedication(medication.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${medication.name} deleted'),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                provider.addMedication(medication);
                _scheduleNotification(medication);
              },
            ),
          ),
        );
      },
      child: _buildMedicationCard(context, medication, provider),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, Medication medication) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medication'),
        content: Text('Are you sure you want to delete ${medication.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Widget _buildMedicationCard(BuildContext context, Medication medication, MedicationProvider provider) {
    final timeString = DateFormat('h:mm a').format(medication.scheduledTime);
    final now = DateTime.now();

    // Date comparison to determine if it's today, tomorrow, etc.
    final isToday = medication.scheduledTime.year == now.year &&
        medication.scheduledTime.month == now.month &&
        medication.scheduledTime.day == now.day;

    final isTomorrow = medication.scheduledTime.year == now.year &&
        medication.scheduledTime.month == now.month &&
        medication.scheduledTime.day == now.day + 1;

    String statusText;
    Color statusColor;
    Color statusBgColor;

    if (medication.isTaken) {
      statusText = 'Taken';
      statusColor = Colors.white;
      statusBgColor = Colors.green;
    } else if (isToday && medication.scheduledTime.isBefore(now)) {
      statusText = 'Due';
      statusColor = Colors.black;
      statusBgColor = Colors.orange;
    } else if (isTomorrow) {
      statusText = 'Tomorrow';
      statusColor = Colors.black;
      statusBgColor = Colors.grey.shade300;
    } else {
      statusText = DateFormat('E, MMM d').format(medication.scheduledTime);
      statusColor = Colors.black;
      statusBgColor = Colors.grey.shade300;
    }

    // Calculate remaining time
    String remainingTimeText = '';
    if (isToday && !medication.isTaken) {
      final difference = medication.scheduledTime.difference(now);
      if (difference.isNegative) {
        final hours = difference.inHours.abs();
        final minutes = difference.inMinutes.abs() % 60;
        remainingTimeText = 'Overdue by ${hours > 0 ? '$hours hours' : ''} ${minutes > 0 ? '$minutes minutes' : ''}';
      } else {
        final hours = difference.inHours;
        final minutes = difference.inMinutes % 60;
        remainingTimeText = 'Due in ${hours > 0 ? '$hours hours' : ''} ${minutes > 0 ? '$minutes minutes' : ''}';
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  medication.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${medication.dosage} ${medication.dosageUnit}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'Generic Name: ',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
                Text(
                  medication.genericName,
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  timeString,
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Instructions: ${medication.instructions}',
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
            if (remainingTimeText.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                remainingTimeText,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 8),
            if (!medication.isTaken && (isToday || isTomorrow))
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    provider.markAsTaken(medication.id);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4E68FA),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text('Mark as taken'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAddMedicationDialog(BuildContext context, MedicationProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Medication'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _availableMedications.length,
            itemBuilder: (context, index) {
              final med = _availableMedications[index];
              return ListTile(
                title: Text(med['name']),
                subtitle: Text('${med['dosage']} ${med['dosageUnit']} - ${med['frequency']}'),
                onTap: () {
                  Navigator.pop(context);
                  _showTimePickerDialog(context, provider, med);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showTimePickerDialog(BuildContext context, MedicationProvider provider, Map<String, dynamic> selectedMed) {
    TimeOfDay lastTakenTime = TimeOfDay.now();
    DateTime lastTakenDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Schedule ${selectedMed['name']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select the time for this medication:'),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Date'),
                subtitle: Text(DateFormat('yyyy-MM-dd').format(lastTakenDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: lastTakenDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      lastTakenDate = pickedDate;
                    });
                  }
                },
              ),
              ListTile(
                title: const Text('Time'),
                subtitle: Text(lastTakenTime.format(context)),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: lastTakenTime,
                  );
                  if (pickedTime != null) {
                    setState(() {
                      lastTakenTime = pickedTime;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Combine date and time
                final scheduledDateTime = DateTime(
                  lastTakenDate.year,
                  lastTakenDate.month,
                  lastTakenDate.day,
                  lastTakenTime.hour,
                  lastTakenTime.minute,
                );

                // Calculate schedule based on frequency
                final frequency = selectedMed['frequency'].toString().toLowerCase();
                List<DateTime> scheduledTimes = [];
                developer.log('Scheduling for ${selectedMed['name']} with frequency: $frequency');

                if (frequency == 'three times a week') {
                  // Schedule on Mon, Wed, Fri starting from the selected date
                  final startDate = scheduledDateTime;
                  final daysOfWeek = [1, 3, 5]; // Monday, Wednesday, Friday
                  for (int i = 0; i < 7; i++) {
                    final nextDay = startDate.add(Duration(days: i));
                    if (daysOfWeek.contains(nextDay.weekday)) {
                      final nextDoseTime = DateTime(
                        nextDay.year,
                        nextDay.month,
                        nextDay.day,
                        lastTakenTime.hour,
                        lastTakenTime.minute,
                      );
                      if (nextDoseTime.isAfter(DateTime.now())) {
                        scheduledTimes.add(nextDoseTime);
                        developer.log('Added three times a week dose: ${DateFormat('yyyy-MM-dd HH:mm').format(nextDoseTime)}');
                      } else {
                        developer.log('Skipped past dose: ${DateFormat('yyyy-MM-dd HH:mm').format(nextDoseTime)}');
                      }
                    }
                  }
                } else {
                  // Define intervals (in hours)
                  int intervalHours;
                  int dosesPerCycle;
                  int cycleDays;

                  switch (frequency) {
                    case 'once daily':
                      intervalHours = 24;
                      dosesPerCycle = 1;
                      cycleDays = 1;
                      break;
                    case 'twice daily':
                      intervalHours = 12;
                      dosesPerCycle = 2;
                      cycleDays = 1;
                      break;
                    case 'once every two days':
                      intervalHours = 48;
                      dosesPerCycle = 1;
                      cycleDays = 2;
                      break;
                    case 'once a week':
                      intervalHours = 168;
                      dosesPerCycle = 1;
                      cycleDays = 7;
                      break;
                    default:
                      intervalHours = 24;
                      dosesPerCycle = 1;
                      cycleDays = 1;
                  }

                  // Schedule doses for the next 7 days
                  DateTime nextDoseTime = scheduledDateTime;
                  for (int i = 0; i < dosesPerCycle * 7; i++) {
                    nextDoseTime = nextDoseTime.add(Duration(hours: intervalHours));
                    developer.log('Calculated next dose time: ${DateFormat('yyyy-MM-dd HH:mm').format(nextDoseTime)}');
                    if (nextDoseTime.isAfter(DateTime.now())) {
                      scheduledTimes.add(nextDoseTime);
                      developer.log('Added to scheduledTimes: ${DateFormat('yyyy-MM-dd HH:mm').format(nextDoseTime)}');
                    } else {
                      developer.log('Skipped past dose time: ${DateFormat('yyyy-MM-dd HH:mm').format(nextDoseTime)}');
                    }
                  }
                }

                // Log scheduled times
                developer.log('Total scheduled times: ${scheduledTimes.length}');
                for (var time in scheduledTimes) {
                  developer.log('Scheduled time: ${DateFormat('yyyy-MM-dd HH:mm').format(time)}');
                }

                // Fallback test dose
                if (scheduledTimes.isEmpty) {
                  developer.log('No future doses scheduled, adding test dose in 1 minute');
                  scheduledTimes.add(DateTime.now().add(Duration(minutes: 1)));
                }

                // Create and add medications
                for (var scheduledTime in scheduledTimes) {
                  final medication = Medication(
                    id: const Uuid().v4(),
                    name: selectedMed['name'],
                    genericName: selectedMed['generic name'],
                    dosage: selectedMed['dosage'],
                    dosageUnit: selectedMed['dosageUnit'],
                    instructions: selectedMed['instructions'],
                    scheduledTime: scheduledTime,
                    isTaken: scheduledTime.isBefore(DateTime.now()),
                  );

                  provider.addMedication(medication);
                  _scheduleNotification(medication);
                }
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _scheduleNotification(Medication medication) {
    final notificationId = _notificationIdCounter++;
    developer.log(
        'Scheduling notification ID: $notificationId for ${medication.name} at ${DateFormat('yyyy-MM-dd HH:mm').format(medication.scheduledTime)}');
    _notificationService.scheduleNotification(
      id: notificationId,
      title: 'Medication Reminder',
      body: 'Time to take ${medication.name} (${medication.dosage} ${medication.dosageUnit})',
      scheduledTime: medication.scheduledTime,
    ).then((_) {
      developer.log('Notification ID: $notificationId scheduled successfully');
    }).catchError((error) {
      developer.log('Error scheduling notification ID: $notificationId: $error');
    });
  }
}