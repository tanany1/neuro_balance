import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/symptom_provider.dart';
import '../../widgets/symptom_card.dart';
import '../../widgets/symptoms_details_dialog.dart';

class SymptomTrackerScreen extends StatefulWidget {
  const SymptomTrackerScreen({Key? key}) : super(key: key);

  @override
  State<SymptomTrackerScreen> createState() => _SymptomTrackerScreenState();
}

class _SymptomTrackerScreenState extends State<SymptomTrackerScreen> {
  bool _showSymptomGrid = false;
  String? _selectedSymptomName;
  IconData? _selectedSymptomIcon;

  @override
  Widget build(BuildContext context) {
    final symptomProvider = Provider.of<SymptomProvider>(context);

    // Get symptoms data for the current day
    final symptomsData = symptomProvider.getDailySymptomsData();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _showSymptomGrid
            ? _buildSymptomGrid()
            : Column(
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
              child: const Center(
                child: Text(
                  'Symptom Tracker',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Main content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Symptom Overview',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Today',
                                style: TextStyle(
                                  color: Color(0xFF4E68FA),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 200,
                            child: symptomsData.isEmpty
                                ? const Center(child: Text('No symptoms recorded today'))
                                : _buildSymptomBarChart(symptomsData),
                          ),

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Today's Symptoms header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Today\'s Symptoms',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _showSymptomGrid = true;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4E68FA),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.add,
                              size: 20,
                              color: Colors.white,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Add Symptoms',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Symptom cards with dismissible wrapper
                  if (symptomProvider.todaysSymptoms.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.event_note,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No symptoms recorded today',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap "+ Add Symptoms" to record how you\'re feeling',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...symptomProvider.todaysSymptoms.map((symptom) =>
                        _buildDismissibleSymptomCard(symptom, symptomProvider)
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build dismissible wrapper around symptom card
  Widget _buildDismissibleSymptomCard(symptom, SymptomProvider provider) {
    return Dismissible(
      key: Key(symptom.id.toString()),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        color: Colors.red,
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) {
        return _showDeleteConfirmationDialog(symptom);
      },
      onDismissed: (direction) {
        provider.removeSymptom(symptom.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${symptom.name} removed'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: SymptomCard(symptom: symptom),
    );
  }

  // Delete confirmation dialog
  Future<bool> _showDeleteConfirmationDialog(symptom) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Delete Symptom'),
          content: Text('Are you sure you want to delete ${symptom.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  // Build bar chart for symptoms
  Widget _buildSymptomBarChart(Map<String, double> symptomsData) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 5,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.grey.shade800,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final symptomName = symptomsData.keys.elementAt(groupIndex);
              return BarTooltipItem(
                '$symptomName\n${rod.toY.toStringAsFixed(1)}',
                const TextStyle(color: Colors.white),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final symptomName = symptomsData.keys.elementAt(value.toInt());
                // Truncate long symptom names
                final displayName = symptomName.length > 8
                    ? '${symptomName.substring(0, 6)}...'
                    : symptomName;

                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    displayName,
                    style: const TextStyle(fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                );
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value % 1 == 0 && value >= 0 && value <= 5) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(
                      value.toInt().toString(),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const SizedBox();
              },
              reservedSize: 30,
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        barGroups: _getBarGroups(symptomsData),
      ),
    );
  }

  // Generate bar groups from symptom data
  List<BarChartGroupData> _getBarGroups(Map<String, double> symptomsData) {
    // Define colors for each symptom
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.orange,
      Colors.green,
      Colors.purple,
      Colors.teal,
    ];

    final List<BarChartGroupData> bars = [];
    int colorIndex = 0;

    symptomsData.forEach((symptomName, intensity) {
      final barGroup = BarChartGroupData(
        x: colorIndex,
        barRods: [
          BarChartRodData(
            toY: intensity,
            color: colors[colorIndex % colors.length],
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );

      bars.add(barGroup);
      colorIndex++;
    });

    return bars;
  }

  Widget _buildSymptomGrid() {
    return Column(
      children: [
        // Header
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
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _showSymptomGrid = false;
                    // Clear any selected symptom when going back without selection
                    _selectedSymptomName = null;
                    _selectedSymptomIcon = null;
                  });
                },
              ),
              const Text(
                'Add Symptoms',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // Grid of symptom options
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _buildSymptomOption('Numbness or Tingling', Icons.pin_end),
                _buildSymptomOption('Muscle Weakness', Icons.fitness_center),
                _buildSymptomOption('Vision Problems', Icons.visibility),
                _buildSymptomOption('Muscle Stiffness', Icons.accessible),
                _buildSymptomOption('Feeling Tired', Icons.bedtime),
                _buildSymptomOption('Difficulty Walking', Icons.directions_walk),
                _buildSymptomOption('Pain', Icons.flash_on),
                _buildSymptomOption('Thinking Problems', Icons.psychology),
                _buildSymptomOption('Bladder or Bowel Problems', Icons.wc),
                _buildSymptomOption('Mood Changes', Icons.mood),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSymptomOption(String name, IconData icon) {
    return GestureDetector(
      onTap: () {
        // When a symptom is selected, save it and immediately show the dialog
        setState(() {
          _selectedSymptomName = name;
          _selectedSymptomIcon = icon;
          _showSymptomGrid = false;
        });

        // Show dialog directly after updating state
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showSymptomDetailsDialog(name, icon);
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 42,
              color: const Color(0xFF4E68FA),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Method to show the dialog
  void _showSymptomDetailsDialog(String symptomName, IconData icon) {
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext dialogContext) {
          return SymptomDetailDialog(
            symptomName: symptomName,
            symptomIcon: icon,
          );
        },
      ).catchError((error) {
        // Log the error and handle it gracefully
        print('Failed to show dialog: $error');
      });
    }
  }
}