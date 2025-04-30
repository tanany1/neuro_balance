import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

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

  @override
  void initState() {
    super.initState();
    _notificationService.initNotification();
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

  Widget _buildFilterButton(String text, bool isActive) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showAllMedications = text == 'All';
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? Colors.black : Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
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
      statusText = DateFormat('E, MMM d').format(medication.scheduledTime); // Day of week and date
      statusColor = Colors.black;
      statusBgColor = Colors.grey.shade300;
    }

    // Calculate remaining time
    String remainingTimeText = '';
    if (isToday && !medication.isTaken) {
      final difference = medication.scheduledTime.difference(now);
      if (difference.isNegative) {
        // Overdue
        final hours = difference.inHours.abs();
        final minutes = difference.inMinutes.abs() % 60;
        remainingTimeText = 'Overdue by ${hours > 0 ? '$hours hours' : ''} ${minutes > 0 ? '$minutes minutes' : ''}';
      } else {
        // Upcoming
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
    final nameController = TextEditingController();
    final genericNameController = TextEditingController();
    final dosageController = TextEditingController();
    final instructionsController = TextEditingController();
    String dosageUnit = 'mg';
    DateTime selectedDate = _selectedDate; // Use the currently selected date
    TimeOfDay selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add New Medication'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Medication Name',
                    ),
                  ),
                  TextField(
                    controller: genericNameController,
                    decoration: const InputDecoration(
                      labelText: 'Generic Name',
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: dosageController,
                          decoration: const InputDecoration(
                            labelText: 'Dosage',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: dosageUnit,
                        items: ['mg', 'mcg', 'ml', 'g', 'tablet(s)']
                            .map((unit) => DropdownMenuItem(
                          value: unit,
                          child: Text(unit),
                        ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              dosageUnit = value;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  TextField(
                    controller: instructionsController,
                    decoration: const InputDecoration(
                      labelText: 'Instructions (e.g., Take with food)',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Schedule:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ListTile(
                    title: const Text('Date'),
                    subtitle: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (pickedDate != null && pickedDate != selectedDate) {
                        setState(() {
                          selectedDate = pickedDate;
                        });
                      }
                    },
                  ),
                  ListTile(
                    title: const Text('Time'),
                    subtitle: Text(selectedTime.format(context)),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (pickedTime != null && pickedTime != selectedTime) {
                        setState(() {
                          selectedTime = pickedTime;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty &&
                      dosageController.text.isNotEmpty) {
                    // Combine date and time
                    final scheduledDateTime = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      selectedTime.hour,
                      selectedTime.minute,
                    );

                    // Create medication object
                    final newMedication = Medication(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameController.text,
                      genericName: genericNameController.text.isNotEmpty
                          ? genericNameController.text
                          : nameController.text,
                      dosage: double.tryParse(dosageController.text) ?? 0,
                      dosageUnit: dosageUnit,
                      instructions: instructionsController.text.isNotEmpty
                          ? instructionsController.text
                          : 'Take as directed',
                      scheduledTime: scheduledDateTime,
                      isTaken: false,
                    );

                    // Add medication and schedule notification
                    provider.addMedication(newMedication);
                    _scheduleNotification(newMedication);

                    Navigator.pop(context);
                  }
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _scheduleNotification(Medication medication) {
    // Schedule notification for the medication
    _notificationService.scheduleNotification(
      id: medication.id.hashCode,
      title: 'Medication Reminder',
      body: 'Time to take ${medication.name} (${medication.dosage} ${medication.dosageUnit})',
      scheduledTime: medication.scheduledTime,
    );
  }
}