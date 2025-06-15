import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/user.dart';
import '../../models/water_entry.dart';
import '../../services/database/db_helper.dart';
import '../../services/database/user_repository.dart';
import '../../widgets/setting_bottom_sheet.dart';

class DashboardScreen extends StatefulWidget {
  final int userId;

  const DashboardScreen({super.key, required this.userId});

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  late Future<User> _userFuture;
  final UserRepository _userRepository = UserRepository(
    DatabaseHelper.instance,
  );
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  DateTime _selectedDate = DateTime.now();

  int _caloriesConsumed = 0;
  int _caloriesBurned = 0;
  int _waterConsumed = 0;
  int _activityMinutes = 0;
  double _proteinConsumed = 0;
  double _fatsConsumed = 0;
  double _carbsConsumed = 0;

  @override
  void initState() {
    super.initState();
    _userFuture = _userRepository.getUser(widget.userId);
    _loadDailyData();
  }

  void refreshData() {
    setState(() {
      _userFuture = _userRepository.getUser(widget.userId);
    });
    _loadDailyData();
  }

  void updateCaloriesConsumed(int calories) {
    setState(() {
      _caloriesConsumed = calories;
    });
  }

  Future<void> _loadDailyData() async {
    final calories = await _dbHelper.getTotalCaloriesForDate(
      widget.userId,
      _selectedDate,
    );

    final mealEntries = await _dbHelper.getMealEntriesByDate(
      widget.userId,
      _selectedDate,
    );

    final activityEntries = await _dbHelper.getActivityEntriesByDate(
      widget.userId,
      _selectedDate,
    );

    double protein = 0;
    double fats = 0;
    double carbs = 0;

    for (var meal in mealEntries) {
      protein += meal.proteins;
      fats += meal.fats;
      carbs += meal.carbs;
    }

    int burned = 0;
    int duration = 0;

    for (var activity in activityEntries) {
      burned += activity.caloriesBurned;
      duration += activity.duration;
    }

    final waterAmount = await _dbHelper.getTotalWaterForDate(
      widget.userId,
      _selectedDate,
    );

    if (mounted) {
      setState(() {
        _caloriesConsumed = calories;
        _caloriesBurned = burned;
        _waterConsumed = waterAmount;
        _activityMinutes = duration;
        _proteinConsumed = protein;
        _fatsConsumed = fats;
        _carbsConsumed = carbs;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadDailyData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User>(
      future: _userFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        final user = snapshot.data!;
        final remainingCalories =
            user.dailyCalorieGoal - _caloriesConsumed + _caloriesBurned;
        final waterProgress = (_waterConsumed / user.dailyWaterGoal) * 100;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Home'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  _loadDailyData();
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Data updated')));
                },
              ),
              IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () => _selectDate(context),
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => _showSettings(context, user),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _loadDailyData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date display
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios),
                            onPressed: () {
                              setState(() {
                                _selectedDate = _selectedDate.subtract(
                                  const Duration(days: 1),
                                );
                              });
                              _loadDailyData();
                            },
                          ),
                          Text(
                            DateFormat('EEEE, d MMMM').format(_selectedDate),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward_ios),
                            onPressed: () {
                              setState(() {
                                _selectedDate = _selectedDate.add(
                                  const Duration(days: 1),
                                );
                              });
                              _loadDailyData();
                            },
                          ),
                        ],
                      ),
                    ),

                    // Welcome message and summary
                    Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, ${user.name}!',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              DateFormat(
                                        'EEEE, d MMMM',
                                      ).format(_selectedDate) ==
                                      DateFormat(
                                        'EEEE, d MMMM',
                                      ).format(DateTime.now())
                                  ? 'Here is your progress for today'
                                  : 'Here is your progress for ${DateFormat('d MMMM').format(_selectedDate)}',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildCircularProgress(
                                  value:
                                      _caloriesConsumed / user.dailyCalorieGoal,
                                  label: 'Calories',
                                  color: Colors.orange,
                                  centerText:
                                      '${(_caloriesConsumed / user.dailyCalorieGoal * 100).toStringAsFixed(0)}%',
                                ),
                                const SizedBox(width: 0),
                                _buildCircularProgress(
                                  value: _waterConsumed / user.dailyWaterGoal,
                                  label: 'Water',
                                  color: Colors.blue,
                                  centerText:
                                      '${(_waterConsumed / user.dailyWaterGoal * 100).toStringAsFixed(0)}%',
                                ),
                                const SizedBox(width: 0),
                                _buildCircularProgress(
                                  value:
                                      _activityMinutes /
                                      60, // Assuming 60 minutes is the goal
                                  label: 'Activity',
                                  color: Colors.green,
                                  centerText: '${_activityMinutes}m',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Calories',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Icon(
                                  Icons.local_fire_department,
                                  color: Colors.orange,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            remainingCalories < 0
                                ? Container(
                                  width: double.infinity,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'YOU HAVE EXCEEDED YOUR CALORIE LIMIT',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red,
                                        ),
                                      ),
                                      Text(
                                        'BY ${remainingCalories.abs()} KCAL',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red,
                                        ),
                                      ),
                                      const Text(
                                        'STOP EATING',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                : Row(
                                  children: [
                                    Text(
                                      '$remainingCalories',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      ' kcal remaining',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  flex: _caloriesConsumed,
                                  child: Container(
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(10),
                                        bottomLeft: Radius.circular(10),
                                        topRight: Radius.circular(
                                          _caloriesBurned == 0 ? 10 : 0,
                                        ),
                                        bottomRight: Radius.circular(
                                          _caloriesBurned == 0 ? 10 : 0,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: _caloriesBurned,
                                  child: Container(
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(
                                          _caloriesConsumed == 0 ? 10 : 0,
                                        ),
                                        bottomLeft: Radius.circular(
                                          _caloriesConsumed == 0 ? 10 : 0,
                                        ),
                                        topRight: Radius.circular(10),
                                        bottomRight: Radius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex:
                                      remainingCalories > 0
                                          ? remainingCalories
                                          : 1,
                                  child: Container(
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.only(
                                        topRight: Radius.circular(10),
                                        bottomRight: Radius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Consumed: $_caloriesConsumed',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Burned: $_caloriesBurned',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Water',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Icon(Icons.water_drop, color: Colors.blue),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  (_waterConsumed / 1000).toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  ' / ${(user.dailyWaterGoal / 1000).toStringAsFixed(1)} L',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: _waterConsumed / user.dailyWaterGoal,
                                minHeight: 10,
                                backgroundColor: Colors.blue.withOpacity(0.1),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.blue,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${waterProgress.toStringAsFixed(0)}% of daily goal',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Activity and Nutrition Summary
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 16.0,
                        top: 16.0,
                        bottom: 8.0,
                      ),
                      child: Text(
                        'Today\'s Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),

                    // Activity summary
                    Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.directions_run, color: Colors.green),
                                const SizedBox(width: 8),
                                const Text(
                                  'Activity',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildSummaryItem(
                                  Icons.local_fire_department,
                                  '$_caloriesBurned',
                                  'kcal burned',
                                  Colors.orange,
                                ),
                                _buildSummaryItem(
                                  Icons.timer,
                                  _formatDuration(_activityMinutes),
                                  'activity time',
                                  Colors.blue,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Nutrition summary
                    Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.restaurant, color: Colors.red),
                                const SizedBox(width: 8),
                                const Text(
                                  'Nutrition',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildSummaryItem(
                                  Icons.food_bank,
                                  '$_caloriesConsumed',
                                  'kcal consumed',
                                  Colors.red,
                                ),
                                _buildSummaryItem(
                                  null,
                                  '${_proteinConsumed.toStringAsFixed(1)}g',
                                  'protein',
                                  Colors.blue,
                                  textLabel: 'P',
                                ),
                                _buildSummaryItem(
                                  null,
                                  '${_fatsConsumed.toStringAsFixed(1)}g',
                                  'fats',
                                  Colors.yellow.shade800,
                                  textLabel: 'F',
                                ),
                                _buildSummaryItem(
                                  null,
                                  '${_carbsConsumed.toStringAsFixed(1)}g',
                                  'carbs',
                                  Colors.green,
                                  textLabel: 'C',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Quick actions
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 16.0,
                        top: 16.0,
                        bottom: 8.0,
                      ),
                      child: Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),

                    Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildActionButton(
                              context,
                              Icons.restaurant,
                              'Add Food',
                              Colors.red,
                              () => Navigator.pushNamed(context, '/food_diary'),
                            ),
                            _buildActionButton(
                              context,
                              Icons.directions_run,
                              'Log Activity',
                              Colors.green,
                              () =>
                                  Navigator.pushNamed(context, '/activity_log'),
                            ),
                            _buildActionButton(
                              context,
                              Icons.water_drop,
                              'Add Water',
                              Colors.blue,
                              () => _showAddWaterDialog(context),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryItem(
    IconData? icon,
    String value,
    String label,
    Color color, {
    String? textLabel,
  }) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child:
                icon != null
                    ? Icon(icon, color: color, size: 24)
                    : Text(
                      textLabel ?? '',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildCircularProgress({
    required double value,
    required String label,
    required Color color,
    required String centerText,
  }) {
    final clampedValue = value.clamp(0.0, 1.0);

    return Column(
      children: [
        SizedBox(
          width: 150,
          height: 150,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: clampedValue,
                  backgroundColor: color.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeWidth: 12,
                ),
              ),
              Container(
                width: 90,
                height: 90,
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    centerText,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 1),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onPressed,
  ) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    if (hours > 0) {
      return '${hours}h ${remainingMinutes}m';
    } else {
      return '${remainingMinutes}m';
    }
  }

  Future<void> _showSettings(BuildContext context, User user) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SettingsBottomSheet(user: user),
        );
      },
    );

    if (result == true) {
      setState(() {
        _userFuture = _userRepository.getUser(widget.userId);
      });
      _loadDailyData();
    }
  }

  Future<void> _showAddWaterDialog(BuildContext context) async {
    int amount = 50;
    bool isSubmitting = false;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Water'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Select water amount:'),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () {
                            if (amount > 25) {
                              setDialogState(() {
                                amount -= 25;
                              });
                            }
                          },
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.blue),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$amount ml',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            if (amount < 500) {
                              setDialogState(() {
                                amount += 25;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        InkWell(
                          onTap: () {
                            setDialogState(() {
                              amount = 50;
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '50 ml',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            setDialogState(() {
                              amount = 100;
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '100 ml',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            setDialogState(() {
                              amount = 200;
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '200 ml',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                ),
                TextButton(
                  child: Text(isSubmitting ? 'Adding...' : 'Add'),
                  onPressed:
                      isSubmitting
                          ? null
                          : () async {
                            setDialogState(() {
                              isSubmitting = true;
                            });

                            try {
                              final waterEntry = WaterEntry(
                                amount: amount,
                                dateTime: DateTime.now(),
                                userId: widget.userId,
                              );

                              final updatedWaterAmount = await _dbHelper
                                  .getTotalWaterForDate(
                                    widget.userId,
                                    _selectedDate,
                                  );

                              if (mounted) {
                                setState(() {
                                  _waterConsumed = updatedWaterAmount;
                                });
                              }

                              if (dialogContext.mounted) {
                                Navigator.of(dialogContext).pop();

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Added $amount ml of water'),
                                    backgroundColor: Colors.blue,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (dialogContext.mounted) {
                                setDialogState(() {
                                  isSubmitting = false;
                                });

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error adding water'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
