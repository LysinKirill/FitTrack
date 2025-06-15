import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'package:fit_track/models/body_measurement.dart';
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

  String _selectedTimeRange = 'Week';
  final List<String> _timeRanges = ['Week', 'Month', '3 Months', 'Year'];

  List<WeightEntry> _weightEntries = [];
  List<BodyMeasurement> _bodyMeasurements = [];

  String _selectedMeasurementType = 'Waist';
  final List<String> _measurementTypes = [
    'Chest',
    'Waist',
    'Hips',
    'Thighs',
    'Arms',
    'Shoulders',
  ];

  @override
  void initState() {
    super.initState();
    _userFuture = _userRepository.getUser(widget.userId);
    _loadData();
  }

  Future<void> _loadData() async {
    final DateTime now = DateTime.now();
    DateTime startDate;

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

    await _loadWeightEntries(startDate, now);
    await _loadBodyMeasurements(startDate, now);

    setState(() {});
  }

  Future<void> _loadWeightEntries(DateTime startDate, DateTime endDate) async {
    try {
      _weightEntries = await _dbHelper.getWeightEntriesForDateRange(
        widget.userId,
        startDate,
        endDate,
      );
    } catch (e) {
      _weightEntries = [];
    }
  }

  Future<void> _loadBodyMeasurements(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      _bodyMeasurements = await _dbHelper.getBodyMeasurementsForDateRange(
        widget.userId,
        startDate,
        endDate,
      );
    } catch (e) {
      _bodyMeasurements = [];
    }
  }

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

  Widget _buildBMIIndicator(User user) {
    if (user.height == null || user.weight == null || user.height == 0) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Height or weight not specified',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final heightInMeters = user.height! / 100;
    final bmi = user.weight! / (heightInMeters * heightInMeters);

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
        title: const Text('Progress'),
        actions: [
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
          _buildSectionTitle('Weight and Measurements Tracking'),

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
                        '${user.weight?.toStringAsFixed(1) ?? "Not specified"} kg',
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

          const SizedBox(height: 24),
          _buildSectionTitle('Body Measurements'),

          Card(
            margin: const EdgeInsets.symmetric(vertical: 16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Measurements',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildCurrentMeasurements(),
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add Measurements'),
                      onPressed: () {
                        _showAddMeasurementsDialog(context, user);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Measurement History',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      DropdownButton<String>(
                        value: _selectedMeasurementType,
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedMeasurementType = newValue;
                            });
                          }
                        },
                        items:
                            _measurementTypes.map<DropdownMenuItem<String>>((
                              String value,
                            ) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildMeasurementsHistoryChart(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightHistoryChart() {
    if (_weightEntries.isEmpty) {
      return _buildEmptyDataCard('No weight entries for this period');
    }

    final sortedEntries = List<WeightEntry>.from(_weightEntries)
      ..sort((a, b) => a.date.compareTo(b.date));

    double minWeight;
    double maxWeight;

    if (sortedEntries.length == 1) {
      minWeight = sortedEntries[0].weight * 0.95;
      maxWeight = sortedEntries[0].weight * 1.05;
    } else {
      minWeight = sortedEntries
          .map((e) => e.weight)
          .reduce((a, b) => a < b ? a : b);
      maxWeight = sortedEntries
          .map((e) => e.weight)
          .reduce((a, b) => a > b ? a : b);
    }

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
                hoveredPointIndex: null,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('d MMM').format(sortedEntries.first.date),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                DateFormat('d MMM').format(sortedEntries.last.date),
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
                    hintText: 'Add a note to this entry',
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
                  final weightText = weightController.text.trim();
                  if (weightText.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter weight')),
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

                  final weightEntry = WeightEntry(
                    weight: weight,
                    date: DateTime.now(),
                    note:
                        noteController.text.trim().isEmpty
                            ? null
                            : noteController.text.trim(),
                    userId: widget.userId,
                  );

                  final id = await _dbHelper.insertWeightEntry(weightEntry);
                  if (id > 0) {
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

                    setState(() {
                      _userFuture = _userRepository.getUser(widget.userId);
                    });
                    _loadData();

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Weight entry successfully added'),
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

  Widget _buildCurrentMeasurements() {
    final latestMeasurement =
        _bodyMeasurements.isNotEmpty
            ? _bodyMeasurements.reduce((a, b) => a.date.isAfter(b.date) ? a : b)
            : null;

    if (latestMeasurement == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No measurement data',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 16.0,
      runSpacing: 16.0,
      alignment: WrapAlignment.center,
      children: [
        _buildMeasurementItem(
          'Chest',
          latestMeasurement.chest,
          'см',
          Icons.accessibility_new,
        ),
        _buildMeasurementItem(
          'Waist',
          latestMeasurement.waist,
          'см',
          Icons.straighten,
        ),
        _buildMeasurementItem(
          'Hips',
          latestMeasurement.hips,
          'см',
          Icons.accessibility_new,
        ),
        _buildMeasurementItem(
          'Thighs',
          latestMeasurement.thighs,
          'см',
          Icons.accessibility_new,
        ),
        _buildMeasurementItem(
          'Arms',
          latestMeasurement.arms,
          'см',
          Icons.fitness_center,
        ),
        _buildMeasurementItem(
          'Shoulders',
          latestMeasurement.shoulders,
          'см',
          Icons.accessibility_new,
        ),
      ],
    );
  }

  Widget _buildMeasurementItem(
    String label,
    double? value,
    String unit,
    IconData icon,
  ) {
    return Container(
      width: 100,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Theme.of(context).primaryColor),
          ),
          const SizedBox(height: 8),
          Text(
            value != null ? '${value.toStringAsFixed(1)} $unit' : '—',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildMeasurementsHistoryChart() {
    if (_bodyMeasurements.isEmpty) {
      return _buildEmptyDataCard('No measurement entries for this period');
    }

    final filteredMeasurements =
        _bodyMeasurements.where((m) {
          switch (_selectedMeasurementType) {
            case 'Грудь':
              return m.chest != null;
            case 'Талия':
              return m.waist != null;
            case 'Бёдра':
              return m.hips != null;
            case 'Бедра':
              return m.thighs != null;
            case 'Руки':
              return m.arms != null;
            case 'Плечи':
              return m.shoulders != null;
            default:
              return false;
          }
        }).toList();

    if (filteredMeasurements.isEmpty) {
      return _buildEmptyDataCard(
        'No entries for ${_selectedMeasurementType.toLowerCase()} for this period',
      );
    }

    filteredMeasurements.sort((a, b) => a.date.compareTo(b.date));

    List<double> values =
        filteredMeasurements.map((m) {
          switch (_selectedMeasurementType) {
            case 'Грудь':
              return m.chest ?? 0;
            case 'Талия':
              return m.waist ?? 0;
            case 'Бёдра':
              return m.hips ?? 0;
            case 'Бедра':
              return m.thighs ?? 0;
            case 'Руки':
              return m.arms ?? 0;
            case 'Плечи':
              return m.shoulders ?? 0;
            default:
              return 0.0;
          }
        }).toList();

    double minValue;
    double maxValue;

    if (values.length == 1) {
      minValue = values[0] * 0.95;
      maxValue = values[0] * 1.05;
    } else {
      minValue = values.reduce((a, b) => a < b ? a : b);
      maxValue = values.reduce((a, b) => a > b ? a : b);
    }

    final chartMinValue = (minValue - 1.0).clamp(0.0, double.infinity);
    final chartMaxValue = maxValue + 1.0;

    return SizedBox(
      height: 250,
      child: Column(
        children: [
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: MeasurementChartPainter(
                measurements: filteredMeasurements,
                measurementType: _selectedMeasurementType,
                minValue: chartMinValue,
                maxValue: chartMaxValue,
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
                DateFormat('d MMM').format(filteredMeasurements.first.date),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                DateFormat('d MMM').format(filteredMeasurements.last.date),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddMeasurementsDialog(BuildContext context, User user) {
    final chestController = TextEditingController();
    final waistController = TextEditingController();
    final hipsController = TextEditingController();
    final thighsController = TextEditingController();
    final armsController = TextEditingController();
    final shouldersController = TextEditingController();
    final noteController = TextEditingController();

    final latestMeasurement =
        _bodyMeasurements.isNotEmpty
            ? _bodyMeasurements.reduce((a, b) => a.date.isAfter(b.date) ? a : b)
            : null;

    if (latestMeasurement != null) {
      chestController.text = latestMeasurement.chest?.toString() ?? '';
      waistController.text = latestMeasurement.waist?.toString() ?? '';
      hipsController.text = latestMeasurement.hips?.toString() ?? '';
      thighsController.text = latestMeasurement.thighs?.toString() ?? '';
      armsController.text = latestMeasurement.arms?.toString() ?? '';
      shouldersController.text = latestMeasurement.shoulders?.toString() ?? '';
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Body Measurements'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: chestController,
                    decoration: const InputDecoration(
                      labelText: 'Chest (cm)',
                      hintText: 'Enter chest circumference in cm',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: waistController,
                    decoration: const InputDecoration(
                      labelText: 'Waist (cm)',
                      hintText: 'Enter waist circumference in cm',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: hipsController,
                    decoration: const InputDecoration(
                      labelText: 'Hips (cm)',
                      hintText: 'Enter hips circumference in cm',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: thighsController,
                    decoration: const InputDecoration(
                      labelText: 'Thighs (cm)',
                      hintText: 'Enter thigh circumference in cm',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: armsController,
                    decoration: const InputDecoration(
                      labelText: 'Arms (cm)',
                      hintText: 'Enter arm circumference in cm',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: shouldersController,
                    decoration: const InputDecoration(
                      labelText: 'Shoulders (cm)',
                      hintText: 'Enter shoulder width in cm',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      labelText: 'Note (optional)',
                      hintText: 'Add a note to this entry',
                    ),
                    maxLines: 2,
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
                onPressed: () async {
                  final chest = double.tryParse(chestController.text.trim());
                  final waist = double.tryParse(waistController.text.trim());
                  final hips = double.tryParse(hipsController.text.trim());
                  final thighs = double.tryParse(thighsController.text.trim());
                  final arms = double.tryParse(armsController.text.trim());
                  final shoulders = double.tryParse(
                    shouldersController.text.trim(),
                  );

                  if (chest == null &&
                      waist == null &&
                      hips == null &&
                      thighs == null &&
                      arms == null &&
                      shoulders == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter at least one measurement'),
                      ),
                    );
                    return;
                  }

                  final measurement = BodyMeasurement(
                    userId: widget.userId,
                    date: DateTime.now(),
                    chest: chest,
                    waist: waist,
                    hips: hips,
                    thighs: thighs,
                    arms: arms,
                    shoulders: shoulders,
                    note:
                        noteController.text.trim().isEmpty
                            ? null
                            : noteController.text.trim(),
                  );

                  final id = await _dbHelper.insertBodyMeasurement(measurement);
                  if (id > 0) {
                    _loadData();

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Measurements successfully added'),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to add measurements'),
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
  final int? hoveredPointIndex;

  WeightChartPainter({
    required this.weightEntries,
    required this.minWeight,
    required this.maxWeight,
    required this.lineColor,
    required this.pointColor,
    this.hoveredPointIndex,
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

    if (weightEntries.length == 1) {
      final entry = weightEntries.first;
      final x = size.width / 2;
      final y = _calculateYPosition(entry.weight, size.height);

      canvas.drawCircle(Offset(x, y), 5, pointPaint);
      _drawWeightValue(canvas, entry.weight, x, y);

      return;
    }

    final firstEntry = weightEntries.first;
    final firstX = 0.0;
    final firstY = _calculateYPosition(firstEntry.weight, size.height);

    path.moveTo(firstX, firstY);

    for (int i = 0; i < weightEntries.length; i++) {
      final entry = weightEntries[i];
      final x = i * (size.width / (weightEntries.length - 1));
      final y = _calculateYPosition(entry.weight, size.height);

      if (i > 0) {
        path.lineTo(x, y);
      }

      canvas.drawCircle(Offset(x, y), 5, pointPaint);

      _drawWeightValue(canvas, entry.weight, x, y);
    }

    canvas.drawPath(path, paint);

    final labelPaint =
        Paint()
          ..color = Colors.grey[600]!
          ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(0, size.height), 3, labelPaint);
    canvas.drawCircle(Offset(0, 0), 3, labelPaint);
  }

  void _drawWeightValue(Canvas canvas, double weight, double x, double y) {
    final bgPaint =
        Paint()
          ..color = Colors.white.withOpacity(0.8)
          ..style = PaintingStyle.fill;

    final textValue = '${weight.toStringAsFixed(1)} kg';

    final paragraphBuilder =
        ui.ParagraphBuilder(
            ui.ParagraphStyle(
              textAlign: ui.TextAlign.center,
              fontSize: 14,
              fontWeight: ui.FontWeight.bold,
            ),
          )
          ..pushStyle(ui.TextStyle(color: Colors.black))
          ..addText(textValue);

    final paragraph =
        paragraphBuilder.build()..layout(ui.ParagraphConstraints(width: 70));
    final textX = x - paragraph.width / 2;
    final textY = y - paragraph.height - 10;
    final padding = 4.0;
    final bgRect = Rect.fromLTWH(
      textX - padding,
      textY - padding,
      paragraph.width + padding * 2,
      paragraph.height + padding * 2,
    );

    final bgRRect = RRect.fromRectAndRadius(bgRect, const Radius.circular(4));

    canvas.drawRRect(bgRRect, bgPaint);
    canvas.drawParagraph(paragraph, Offset(textX, textY));
  }

  double _calculateYPosition(double weight, double height) {
    return height - ((weight - minWeight) / (maxWeight - minWeight) * height);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is WeightChartPainter) {
      return oldDelegate.hoveredPointIndex != hoveredPointIndex;
    }
    return true;
  }
}

class MeasurementChartPainter extends CustomPainter {
  final List<BodyMeasurement> measurements;
  final String measurementType;
  final double minValue;
  final double maxValue;
  final Color lineColor;
  final Color pointColor;

  MeasurementChartPainter({
    required this.measurements,
    required this.measurementType,
    required this.minValue,
    required this.maxValue,
    required this.lineColor,
    required this.pointColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (measurements.isEmpty) return;

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
    if (measurements.length == 1) {
      final entry = measurements.first;
      final x = size.width / 2;
      final y = _calculateYPosition(_getMeasurementValue(entry), size.height);
      canvas.drawCircle(Offset(x, y), 5, pointPaint);
      _drawMeasurementValue(canvas, _getMeasurementValue(entry), x, y);

      return;
    }

    final firstEntry = measurements.first;
    final firstX = 0.0;
    final firstY = _calculateYPosition(
      _getMeasurementValue(firstEntry),
      size.height,
    );

    path.moveTo(firstX, firstY);
    for (int i = 0; i < measurements.length; i++) {
      final entry = measurements[i];
      final x = i * (size.width / (measurements.length - 1));
      final y = _calculateYPosition(_getMeasurementValue(entry), size.height);

      if (i > 0) {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 5, pointPaint);

      _drawMeasurementValue(canvas, _getMeasurementValue(entry), x, y);
    }

    canvas.drawPath(path, paint);
  }

  double _getMeasurementValue(BodyMeasurement measurement) {
    switch (measurementType) {
      case 'Chest':
        return measurement.chest ?? 0;
      case 'Waist':
        return measurement.waist ?? 0;
      case 'Hips':
        return measurement.hips ?? 0;
      case 'Thighs':
        return measurement.thighs ?? 0;
      case 'Arms':
        return measurement.arms ?? 0;
      case 'Shoulders':
        return measurement.shoulders ?? 0;
      default:
        return 0.0;
    }
  }

  void _drawMeasurementValue(Canvas canvas, double value, double x, double y) {
    final bgPaint =
        Paint()
          ..color = Colors.white.withOpacity(0.8)
          ..style = PaintingStyle.fill;

    final textValue = '${value.toStringAsFixed(1)} cm';

    final paragraphBuilder =
        ui.ParagraphBuilder(
            ui.ParagraphStyle(
              textAlign: ui.TextAlign.center,
              fontSize: 14,
              fontWeight: ui.FontWeight.bold,
            ),
          )
          ..pushStyle(ui.TextStyle(color: Colors.black))
          ..addText(textValue);

    final paragraph =
        paragraphBuilder.build()..layout(ui.ParagraphConstraints(width: 70));

    final textX = x - paragraph.width / 2;
    final textY = y - paragraph.height - 10;

    final padding = 4.0;
    final bgRect = Rect.fromLTWH(
      textX - padding,
      textY - padding,
      paragraph.width + padding * 2,
      paragraph.height + padding * 2,
    );

    final bgRRect = RRect.fromRectAndRadius(bgRect, const Radius.circular(4));

    canvas.drawRRect(bgRRect, bgPaint);
    canvas.drawParagraph(paragraph, Offset(textX, textY));
  }

  double _calculateYPosition(double value, double height) {
    return height - ((value - minValue) / (maxValue - minValue) * height);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
