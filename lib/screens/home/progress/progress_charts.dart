import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fit_track/models/activity_entry.dart';
import 'package:fit_track/models/meal_entry.dart';
import 'package:fit_track/models/user.dart';
import 'package:fit_track/models/weight_entry.dart';
import 'package:fit_track/services/database/db_helper.dart';
import 'package:fit_track/services/database/user_repository.dart';

class ProgressChartsScreen extends StatefulWidget {
  final int userId;
  const ProgressChartsScreen({super.key, required this.userId});

  @override
  State<ProgressChartsScreen> createState() => _ProgressChartsScreenState();
}

class _ProgressChartsScreenState extends State<ProgressChartsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final UserRepository _userRepository = UserRepository(
    DatabaseHelper.instance,
  );

  late Future<User> _userFuture;

  // Time range selection
  String _selectedTimeRange = 'Week';
  final List<String> _timeRanges = ['Week', 'Month', '3 Months', 'Year'];

  // Data for weight chart
  List<WeightEntry> _weightEntries = [];

  @override
  void initState() {
    super.initState();
    _userFuture = _userRepository.getUser(widget.userId);
    _loadData();
  }

  Future<void> _loadData() async {
    final DateTime now = DateTime.now();
    DateTime startDate;

    // Determine start date based on selected time range
    switch (_selectedTimeRange) {
      case 'Week':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 'Month':
        startDate = DateTime(now.year, now.month - 1, now.day);
        break;
      case '3 Months':
        startDate = DateTime(now.year, now.month - 3, now.day);
        break;
      case 'Year':
        startDate = DateTime(now.year - 1, now.month, now.day);
        break;
      default:
        startDate = now.subtract(const Duration(days: 7));
    }

    // Load weight entries for the selected time range
    await _loadWeightEntries(startDate, now);

    setState(() {});
  }

  Future<void> _loadWeightEntries(DateTime startDate, DateTime endDate) async {
    try {
      _weightEntries = await _dbHelper.getWeightEntriesForDateRange(
        widget.userId,
        startDate,
        endDate,
      );
      print('Loaded ${_weightEntries.length} weight entries');
    } catch (e) {
      print('Error loading weight entries: $e');
      _weightEntries = [];
    }
  }

  // Helper method to build section titles
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  // Helper method to build empty data cards
  Widget _buildEmptyDataCard(String message) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.bar_chart, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build summary items
  Widget _buildSummaryItem(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 30),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  // Helper method to build BMI indicator
  Widget _buildBMIIndicator(User user) {
    if (user.height == null || user.weight == null || user.height == 0) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Height or weight not set',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    // Calculate BMI: weight (kg) / (height (m))^2
    final heightInMeters = user.height! / 100; // Convert cm to m
    final bmi = user.weight! / (heightInMeters * heightInMeters);

    // Determine BMI category and color
    String category;
    Color color;

    if (bmi < 18.5) {
      category = 'Underweight';
      color = Colors.blue;
    } else if (bmi < 25) {
      category = 'Normal';
      color = Colors.green;
    } else if (bmi < 30) {
      category = 'Overweight';
      color = Colors.orange;
    } else {
      category = 'Obese';
      color = Colors.red;
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              bmi.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(width: 8),
            Text(category, style: TextStyle(fontSize: 18, color: color)),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 24,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              colors: [Colors.blue, Colors.green, Colors.orange, Colors.red],
            ),
          ),
          child: Stack(
            children: [
              // BMI marker
              Positioned(
                left: (bmi / 40 * MediaQuery.of(context).size.width * 0.8)
                    .clamp(0, MediaQuery.of(context).size.width * 0.8 - 16),
                child: Container(
                  width: 16,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('18.5', style: TextStyle(fontSize: 12)),
            Text('25', style: TextStyle(fontSize: 12)),
            Text('30', style: TextStyle(fontSize: 12)),
            Text('40', style: TextStyle(fontSize: 12)),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weight Tracking'),
        actions: [
          // Time range selector
          PopupMenuButton<String>(
            icon: const Icon(Icons.calendar_today),
            onSelected: (String value) {
              setState(() {
                _selectedTimeRange = value;
              });
              _loadData();
            },
            itemBuilder: (BuildContext context) {
              return _timeRanges.map((String range) {
                return PopupMenuItem<String>(value: range, child: Text(range));
              }).toList();
            },
          ),
        ],
      ),
      body: FutureBuilder<User>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final user = snapshot.data!;
          return _buildWeightContent(user);
        },
      ),
    );
  }

  Widget _buildWeightContent(User user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Weight Tracking'),

          // Current weight card
          Card(
            margin: const EdgeInsets.symmetric(vertical: 16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Weight',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.monitor_weight,
                        size: 48,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '${user.weight?.toStringAsFixed(1) ?? "Not set"} kg',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add Weight Entry'),
                      onPressed: () {
                        _showAddWeightDialog(context, user);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Weight history chart
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Weight History',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildWeightHistoryChart(),
                ],
              ),
            ),
          ),

          // BMI card
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Body Mass Index (BMI)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildBMIIndicator(user),
                ],
              ),
            ),
          ),

          // Body measurements would be added here in a real app
          const SizedBox(height: 24),
          _buildSectionTitle('Body Measurements'),
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                'Body measurement tracking coming soon!',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightHistoryChart() {
    if (_weightEntries.isEmpty) {
      return _buildEmptyDataCard('No weight entries available for this period');
    }

    // Sort entries by date
    final sortedEntries = List<WeightEntry>.from(_weightEntries)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Find min and max weight for chart scaling
    final minWeight = sortedEntries
        .map((e) => e.weight)
        .reduce((a, b) => a < b ? a : b);
    final maxWeight = sortedEntries
        .map((e) => e.weight)
        .reduce((a, b) => a > b ? a : b);

    // Add some padding to min and max for better visualization
    final chartMinWeight = (minWeight - 1.0).clamp(0.0, double.infinity);
    final chartMaxWeight = maxWeight + 1.0;

    return SizedBox(
      height: 250,
      child: Column(
        children: [
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: WeightChartPainter(
                weightEntries: sortedEntries,
                minWeight: chartMinWeight,
                maxWeight: chartMaxWeight,
                lineColor: Theme.of(context).primaryColor,
                pointColor: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMM d').format(sortedEntries.first.date),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                DateFormat('MMM d').format(sortedEntries.last.date),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddWeightDialog(BuildContext context, User user) {
    final weightController = TextEditingController(
      text: user.weight?.toString() ?? '',
    );
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Weight Entry'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: weightController,
                  decoration: const InputDecoration(
                    labelText: 'Weight (kg)',
                    hintText: 'Enter your weight in kg',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                    hintText: 'Add a note about this entry',
                  ),
                  maxLines: 2,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Validate input
                  final weightText = weightController.text.trim();
                  if (weightText.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a weight')),
                    );
                    return;
                  }

                  final weight = double.tryParse(weightText);
                  if (weight == null || weight <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid weight'),
                      ),
                    );
                    return;
                  }

                  // Create weight entry
                  final weightEntry = WeightEntry(
                    weight: weight,
                    date: DateTime.now(),
                    note:
                        noteController.text.trim().isEmpty
                            ? null
                            : noteController.text.trim(),
                    userId: widget.userId,
                  );

                  // Save to database
                  final id = await _dbHelper.insertWeightEntry(weightEntry);
                  if (id > 0) {
                    // Update user's current weight
                    final updatedUser = User(
                      id: user.id,
                      name: user.name,
                      email: user.email,
                      password: user.password,
                      createdAt: user.createdAt,
                      birthDate: user.birthDate,
                      height: user.height,
                      weight: weight,
                      gender: user.gender,
                      dailyCalorieGoal: user.dailyCalorieGoal,
                      dailyWaterGoal: user.dailyWaterGoal,
                    );
                    await _userRepository.updateUser(updatedUser);

                    // Reload data
                    setState(() {
                      _userFuture = _userRepository.getUser(widget.userId);
                    });
                    _loadData();

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Weight entry added successfully'),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to add weight entry'),
                      ),
                    );
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }
}

class WeightChartPainter extends CustomPainter {
  final List<WeightEntry> weightEntries;
  final double minWeight;
  final double maxWeight;
  final Color lineColor;
  final Color pointColor;

  WeightChartPainter({
    required this.weightEntries,
    required this.minWeight,
    required this.maxWeight,
    required this.lineColor,
    required this.pointColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (weightEntries.isEmpty) return;

    final paint =
        Paint()
          ..color = lineColor
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

    final pointPaint =
        Paint()
          ..color = pointColor
          ..strokeWidth = 2
          ..style = PaintingStyle.fill;

    final path = Path();

    // Calculate x and y positions
    final firstEntry = weightEntries.first;
    final firstX = 0.0;
    final firstY = _calculateYPosition(firstEntry.weight, size.height);

    path.moveTo(firstX, firstY);

    // Draw points and connect with lines
    for (int i = 0; i < weightEntries.length; i++) {
      final entry = weightEntries[i];
      final x = i * (size.width / (weightEntries.length - 1));
      final y = _calculateYPosition(entry.weight, size.height);

      // Draw line to this point
      if (i > 0) {
        path.lineTo(x, y);
      }

      // Draw point
      canvas.drawCircle(Offset(x, y), 4, pointPaint);
    }

    // Draw the path
    canvas.drawPath(path, paint);

    // Skip drawing text labels for now to avoid TextDirection issues
    // We'll draw simple markers instead

    final labelPaint =
        Paint()
          ..color = Colors.grey[600]!
          ..style = PaintingStyle.fill;

    // Draw min weight marker at bottom
    canvas.drawCircle(Offset(0, size.height), 3, labelPaint);

    // Draw max weight marker at top
    canvas.drawCircle(Offset(0, 0), 3, labelPaint);
  }

  double _calculateYPosition(double weight, double height) {
    // Invert y-axis (0 is at top in canvas)
    return height - ((weight - minWeight) / (maxWeight - minWeight) * height);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
