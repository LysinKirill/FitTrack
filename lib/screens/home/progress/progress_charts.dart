import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'package:fit_track/models/activity_entry.dart';
import 'package:fit_track/models/body_measurement.dart';
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
  String _selectedTimeRange = 'Неделя';
  final List<String> _timeRanges = ['Неделя', 'Месяц', '3 Месяца', 'Год'];

  // Data for charts
  List<WeightEntry> _weightEntries = [];
  List<BodyMeasurement> _bodyMeasurements = [];

  // Hover state for chart points
  int? _hoveredPointIndex;

  // Selected body measurement type for chart
  String _selectedMeasurementType = 'Талия';
  final List<String> _measurementTypes = [
    'Грудь',
    'Талия',
    'Бёдра',
    'Бедра',
    'Руки',
    'Плечи',
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

    // Determine start date based on selected time range
    switch (_selectedTimeRange) {
      case 'Неделя':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 'Месяц':
        startDate = DateTime(now.year, now.month - 1, now.day);
        break;
      case '3 Месяца':
        startDate = DateTime(now.year, now.month - 3, now.day);
        break;
      case 'Год':
        startDate = DateTime(now.year - 1, now.month, now.day);
        break;
      default:
        startDate = now.subtract(const Duration(days: 7));
    }

    // Load data for the selected time range
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
      print('Loaded ${_weightEntries.length} weight entries');
    } catch (e) {
      print('Error loading weight entries: $e');
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
      print('Loaded ${_bodyMeasurements.length} body measurements');
    } catch (e) {
      print('Error loading body measurements: $e');
      _bodyMeasurements = [];
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
            'Рост или вес не указаны',
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
      category = 'Недостаточный вес';
      color = Colors.blue;
    } else if (bmi < 25) {
      category = 'Нормальный';
      color = Colors.green;
    } else if (bmi < 30) {
      category = 'Избыточный вес';
      color = Colors.orange;
    } else {
      category = 'Ожирение';
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
        title: const Text('Прогресс'),
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
            return Center(child: Text('Ошибка: ${snapshot.error}'));
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
          _buildSectionTitle('Отслеживание веса и измерений'),

          // Current weight card
          Card(
            margin: const EdgeInsets.symmetric(vertical: 16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Текущий вес',
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
                        '${user.weight?.toStringAsFixed(1) ?? "Не указан"} кг',
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
                      label: const Text('Добавить запись веса'),
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
                    'История веса',
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
                    'Индекс массы тела (ИМТ)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildBMIIndicator(user),
                ],
              ),
            ),
          ),

          // Body measurements section
          const SizedBox(height: 24),
          _buildSectionTitle('Измерения тела'),

          // Current measurements card
          Card(
            margin: const EdgeInsets.symmetric(vertical: 16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Текущие измерения',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildCurrentMeasurements(),
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Добавить измерения'),
                      onPressed: () {
                        _showAddMeasurementsDialog(context, user);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Measurements history chart
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
                        'История измерений',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Dropdown for selecting measurement type
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
      return _buildEmptyDataCard('Нет записей веса за этот период');
    }

    // Sort entries by date
    final sortedEntries = List<WeightEntry>.from(_weightEntries)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Find min and max weight for chart scaling
    double minWeight;
    double maxWeight;

    if (sortedEntries.length == 1) {
      // If there's only one entry, set min and max to create a range around it
      minWeight = sortedEntries[0].weight * 0.95; // 5% below
      maxWeight = sortedEntries[0].weight * 1.05; // 5% above
    } else {
      minWeight = sortedEntries
          .map((e) => e.weight)
          .reduce((a, b) => a < b ? a : b);
      maxWeight = sortedEntries
          .map((e) => e.weight)
          .reduce((a, b) => a > b ? a : b);
    }

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

  // Removed hover-related methods as we're now always showing weight values

  void _showAddWeightDialog(BuildContext context, User user) {
    final weightController = TextEditingController(
      text: user.weight?.toString() ?? '',
    );
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Добавить запись веса'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: weightController,
                  decoration: const InputDecoration(
                    labelText: 'Вес (кг)',
                    hintText: 'Введите ваш вес в кг',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Заметка (необязательно)',
                    hintText: 'Добавьте заметку к этой записи',
                  ),
                  maxLines: 2,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отмена'),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Validate input
                  final weightText = weightController.text.trim();
                  if (weightText.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Пожалуйста, введите вес')),
                    );
                    return;
                  }

                  final weight = double.tryParse(weightText);
                  if (weight == null || weight <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Пожалуйста, введите корректный вес'),
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
                        content: Text('Запись веса успешно добавлена'),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Не удалось добавить запись веса'),
                      ),
                    );
                  }
                },
                child: const Text('Сохранить'),
              ),
            ],
          ),
    );
  }

  // Helper method to build current measurements display
  Widget _buildCurrentMeasurements() {
    // Get the most recent measurement if available
    final latestMeasurement =
        _bodyMeasurements.isNotEmpty
            ? _bodyMeasurements.reduce((a, b) => a.date.isAfter(b.date) ? a : b)
            : null;

    if (latestMeasurement == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Нет данных об измерениях',
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
          'Грудь',
          latestMeasurement.chest,
          'см',
          Icons.accessibility_new,
        ),
        _buildMeasurementItem(
          'Талия',
          latestMeasurement.waist,
          'см',
          Icons.straighten,
        ),
        _buildMeasurementItem(
          'Бёдра',
          latestMeasurement.hips,
          'см',
          Icons.accessibility_new,
        ),
        _buildMeasurementItem(
          'Бедра',
          latestMeasurement.thighs,
          'см',
          Icons.accessibility_new,
        ),
        _buildMeasurementItem(
          'Руки',
          latestMeasurement.arms,
          'см',
          Icons.fitness_center,
        ),
        _buildMeasurementItem(
          'Плечи',
          latestMeasurement.shoulders,
          'см',
          Icons.accessibility_new,
        ),
      ],
    );
  }

  // Helper method to build individual measurement item
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

  // Helper method to build measurements history chart
  Widget _buildMeasurementsHistoryChart() {
    if (_bodyMeasurements.isEmpty) {
      return _buildEmptyDataCard('Нет записей измерений за этот период');
    }

    // Filter measurements that have the selected measurement type
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
        'Нет записей для ${_selectedMeasurementType.toLowerCase()} за этот период',
      );
    }

    // Sort measurements by date
    filteredMeasurements.sort((a, b) => a.date.compareTo(b.date));

    // Get measurement values based on selected type
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

    // Find min and max values for chart scaling
    double minValue;
    double maxValue;

    if (values.length == 1) {
      // If there's only one entry, set min and max to create a range around it
      minValue = values[0] * 0.95; // 5% below
      maxValue = values[0] * 1.05; // 5% above
    } else {
      minValue = values.reduce((a, b) => a < b ? a : b);
      maxValue = values.reduce((a, b) => a > b ? a : b);
    }

    // Add some padding to min and max for better visualization
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

    // Get the most recent measurement if available to pre-fill values
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
            title: const Text('Добавить измерения тела'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: chestController,
                    decoration: const InputDecoration(
                      labelText: 'Грудь (см)',
                      hintText: 'Введите обхват груди в см',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: waistController,
                    decoration: const InputDecoration(
                      labelText: 'Талия (см)',
                      hintText: 'Введите обхват талии в см',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: hipsController,
                    decoration: const InputDecoration(
                      labelText: 'Бёдра (см)',
                      hintText: 'Введите обхват бёдер в см',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: thighsController,
                    decoration: const InputDecoration(
                      labelText: 'Бедра (см)',
                      hintText: 'Введите обхват бедра в см',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: armsController,
                    decoration: const InputDecoration(
                      labelText: 'Руки (см)',
                      hintText: 'Введите обхват руки в см',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: shouldersController,
                    decoration: const InputDecoration(
                      labelText: 'Плечи (см)',
                      hintText: 'Введите ширину плеч в см',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      labelText: 'Заметка (необязательно)',
                      hintText: 'Добавьте заметку к этой записи',
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отмена'),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Parse input values
                  final chest = double.tryParse(chestController.text.trim());
                  final waist = double.tryParse(waistController.text.trim());
                  final hips = double.tryParse(hipsController.text.trim());
                  final thighs = double.tryParse(thighsController.text.trim());
                  final arms = double.tryParse(armsController.text.trim());
                  final shoulders = double.tryParse(
                    shouldersController.text.trim(),
                  );

                  // Validate that at least one measurement is provided
                  if (chest == null &&
                      waist == null &&
                      hips == null &&
                      thighs == null &&
                      arms == null &&
                      shoulders == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Пожалуйста, введите хотя бы одно измерение',
                        ),
                      ),
                    );
                    return;
                  }

                  // Create body measurement entry
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

                  // Save to database
                  final id = await _dbHelper.insertBodyMeasurement(measurement);
                  if (id > 0) {
                    // Reload data
                    _loadData();

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Измерения успешно добавлены'),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Не удалось добавить измерения'),
                      ),
                    );
                  }
                },
                child: const Text('Сохранить'),
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

    // Handle single entry case
    if (weightEntries.length == 1) {
      final entry = weightEntries.first;
      final x = size.width / 2; // Center the single point
      final y = _calculateYPosition(entry.weight, size.height);

      // Draw the point
      canvas.drawCircle(Offset(x, y), 5, pointPaint);

      // Draw the weight value
      _drawWeightValue(canvas, entry.weight, x, y);

      return;
    }

    // Calculate x and y positions for multiple entries
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
      canvas.drawCircle(Offset(x, y), 5, pointPaint);

      // Draw weight value for each point
      _drawWeightValue(canvas, entry.weight, x, y);
    }

    // Draw the path
    canvas.drawPath(path, paint);

    // Draw min and max weight markers
    final labelPaint =
        Paint()
          ..color = Colors.grey[600]!
          ..style = PaintingStyle.fill;

    // Draw min weight marker at bottom
    canvas.drawCircle(Offset(0, size.height), 3, labelPaint);

    // Draw max weight marker at top
    canvas.drawCircle(Offset(0, 0), 3, labelPaint);
  }

  // Helper method to draw weight value
  void _drawWeightValue(Canvas canvas, double weight, double x, double y) {
    // Create a background for better readability
    final bgPaint =
        Paint()
          ..color = Colors.white.withOpacity(0.8)
          ..style = PaintingStyle.fill;

    final textValue = '${weight.toStringAsFixed(1)} кг';

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

    // Position the text above the point
    final textX = x - paragraph.width / 2;
    final textY = y - paragraph.height - 10;

    // Draw background with padding
    final padding = 4.0;
    final bgRect = Rect.fromLTWH(
      textX - padding,
      textY - padding,
      paragraph.width + padding * 2,
      paragraph.height + padding * 2,
    );

    final bgRRect = RRect.fromRectAndRadius(bgRect, const Radius.circular(4));

    canvas.drawRRect(bgRRect, bgPaint);

    // Draw text
    canvas.drawParagraph(paragraph, Offset(textX, textY));
  }

  double _calculateYPosition(double weight, double height) {
    // Invert y-axis (0 is at top in canvas)
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

// WeightValuePainter class removed as we're now always showing weight values directly

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

    // Handle single entry case
    if (measurements.length == 1) {
      final entry = measurements.first;
      final x = size.width / 2; // Center the single point
      final y = _calculateYPosition(_getMeasurementValue(entry), size.height);

      // Draw the point
      canvas.drawCircle(Offset(x, y), 5, pointPaint);

      // Draw the measurement value
      _drawMeasurementValue(canvas, _getMeasurementValue(entry), x, y);

      return;
    }

    // Calculate x and y positions for multiple entries
    final firstEntry = measurements.first;
    final firstX = 0.0;
    final firstY = _calculateYPosition(
      _getMeasurementValue(firstEntry),
      size.height,
    );

    path.moveTo(firstX, firstY);

    // Draw points and connect with lines
    for (int i = 0; i < measurements.length; i++) {
      final entry = measurements[i];
      final x = i * (size.width / (measurements.length - 1));
      final y = _calculateYPosition(_getMeasurementValue(entry), size.height);

      // Draw line to this point
      if (i > 0) {
        path.lineTo(x, y);
      }

      // Draw point
      canvas.drawCircle(Offset(x, y), 5, pointPaint);

      // Draw measurement value
      _drawMeasurementValue(canvas, _getMeasurementValue(entry), x, y);
    }

    // Draw the path
    canvas.drawPath(path, paint);
  }

  // Helper method to get measurement value based on type
  double _getMeasurementValue(BodyMeasurement measurement) {
    switch (measurementType) {
      case 'Грудь':
        return measurement.chest ?? 0;
      case 'Талия':
        return measurement.waist ?? 0;
      case 'Бёдра':
        return measurement.hips ?? 0;
      case 'Бедра':
        return measurement.thighs ?? 0;
      case 'Руки':
        return measurement.arms ?? 0;
      case 'Плечи':
        return measurement.shoulders ?? 0;
      default:
        return 0.0;
    }
  }

  // Helper method to draw measurement value
  void _drawMeasurementValue(Canvas canvas, double value, double x, double y) {
    // Create a background for better readability
    final bgPaint =
        Paint()
          ..color = Colors.white.withOpacity(0.8)
          ..style = PaintingStyle.fill;

    final textValue = '${value.toStringAsFixed(1)} см';

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

    // Position the text above the point
    final textX = x - paragraph.width / 2;
    final textY = y - paragraph.height - 10;

    // Draw background with padding
    final padding = 4.0;
    final bgRect = Rect.fromLTWH(
      textX - padding,
      textY - padding,
      paragraph.width + padding * 2,
      paragraph.height + padding * 2,
    );

    final bgRRect = RRect.fromRectAndRadius(bgRect, const Radius.circular(4));

    canvas.drawRRect(bgRRect, bgPaint);

    // Draw text
    canvas.drawParagraph(paragraph, Offset(textX, textY));
  }

  double _calculateYPosition(double value, double height) {
    // Invert y-axis (0 is at top in canvas)
    return height - ((value - minValue) / (maxValue - minValue) * height);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
