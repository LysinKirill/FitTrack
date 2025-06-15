import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fit_track/models/activity_entry.dart';
import 'package:fit_track/services/database/db_helper.dart';

class ActivityLogScreen extends StatefulWidget {
  final int userId;

  const ActivityLogScreen({super.key, required this.userId});

  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  DateTime _selectedDate = DateTime.now();
  List<ActivityEntry> _activityEntries = [];
  late int _userId;

  // Activity summary
  int _totalCaloriesBurned = 0;
  int _totalDuration = 0;

  @override
  void initState() {
    super.initState();
    _userId = widget.userId;
    _loadActivityEntries();
  }

  Future<void> _loadActivityEntries() async {
    print('Loading activities for date: ${_selectedDate.toString()}');
    final entries = await _dbHelper.getActivityEntriesByDate(
      _userId,
      _selectedDate,
    );
    print('Loaded ${entries.length} activities from database');

    setState(() {
      _activityEntries = entries;
      _calculateActivitySummary();
    });
  }

  void _calculateActivitySummary() {
    _totalCaloriesBurned = 0;
    _totalDuration = 0;

    for (var entry in _activityEntries) {
      _totalCaloriesBurned += entry.caloriesBurned;
      _totalDuration += entry.duration;
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
      _loadActivityEntries();
    }
  }

  Future<void> _addActivityEntry() async {
    final result = await showDialog<ActivityEntry>(
      context: context,
      builder: (context) => AddActivityDialog(selectedDate: _selectedDate),
    );

    if (result != null) {
      print('Adding activity: ${result.name}, type: ${result.activityType}');
      final id = await _dbHelper.insertActivityEntry(result, _userId);
      print('Activity added with ID: $id');
      await _loadActivityEntries();
    }
  }

  Future<void> _deleteActivityEntry(int id) async {
    await _dbHelper.deleteActivityEntry(id);
    _loadActivityEntries();
  }

  // Debug method to add a test activity entry
  Future<void> _addTestActivityEntry() async {
    // Use the selected date with current time
    final now = DateTime.now();
    final dateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      now.hour,
      now.minute,
      now.second,
    );

    final testActivity = ActivityEntry(
      name: 'Test Activity',
      activityType: 'Running',
      duration: 30,
      caloriesBurned: 250,
      dateTime: dateTime,
      notes: 'This is a test activity',
    );

    print(
      'Adding test activity: ${testActivity.name}, type: ${testActivity.activityType}',
    );
    final id = await _dbHelper.insertActivityEntry(testActivity, _userId);
    print('Test activity added with ID: $id');
    await _loadActivityEntries();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Test activity added')));
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

  @override
  Widget build(BuildContext context) {
    // Group activity entries by activity type
    Map<String, List<ActivityEntry>> groupedEntries = {};
    for (var type in ActivityEntry.activityTypes) {
      groupedEntries[type] =
          _activityEntries
              .where((entry) => entry.activityType == type)
              .toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Log'),
        actions: [
          // Debug button to add test activity
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: _addTestActivityEntry,
          ),
          // Debug button to clear all entries
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () async {
              final count = await _dbHelper.clearActivityEntries();
              print('Cleared $count activity entries');
              _loadActivityEntries();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Deleted $count activity entries')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Date display
          Padding(
            padding: const EdgeInsets.all(16.0),
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
                    _loadActivityEntries();
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
                    _loadActivityEntries();
                  },
                ),
              ],
            ),
          ),

          // Activity summary card
          Card(
            margin: const EdgeInsets.all(16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daily Summary',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryItem(
                        Icons.local_fire_department,
                        '$_totalCaloriesBurned',
                        'Calories burned',
                        Colors.orange,
                      ),
                      _buildSummaryItem(
                        Icons.timer,
                        _formatDuration(_totalDuration),
                        'Total duration',
                        Colors.blue,
                      ),
                      _buildSummaryItem(
                        Icons.fitness_center,
                        '${_activityEntries.length}',
                        'Activities',
                        Colors.green,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Activity entries list
          Expanded(
            child:
                _activityEntries.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.directions_run,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No activity entries for this day',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Add Activity'),
                            onPressed: _addActivityEntry,
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      itemCount: ActivityEntry.activityTypes.length,
                      itemBuilder: (context, index) {
                        final activityType = ActivityEntry.activityTypes[index];
                        final entries = groupedEntries[activityType] ?? [];

                        if (entries.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        return ExpansionTile(
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(activityType),
                              Text(
                                '${entries.fold<int>(0, (sum, entry) => sum + entry.caloriesBurned)} kcal',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          initiallyExpanded: true,
                          children: [
                            ...entries.map(
                              (entry) => _buildActivityEntryTile(entry),
                            ),
                            ListTile(
                              leading: const Icon(Icons.add_circle_outline),
                              title: const Text('Add Activity'),
                              onTap: () async {
                                final result = await showDialog<ActivityEntry>(
                                  context: context,
                                  builder:
                                      (context) => AddActivityDialog(
                                        initialActivityType: activityType,
                                        selectedDate: _selectedDate,
                                      ),
                                );

                                if (result != null) {
                                  await _dbHelper.insertActivityEntry(
                                    result,
                                    _userId,
                                  );
                                  _loadActivityEntries();
                                }
                              },
                            ),
                          ],
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addActivityEntry,
        child: const Icon(Icons.add),
      ),
    );
  }

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

  Widget _buildActivityEntryTile(ActivityEntry entry) {
    return ListTile(
      title: Text(entry.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Duration: ${_formatDuration(entry.duration)}'),
          if (entry.notes != null && entry.notes!.isNotEmpty)
            Text(
              entry.notes!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${entry.caloriesBurned} kcal',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _deleteActivityEntry(entry.id!),
          ),
        ],
      ),
    );
  }
}

class AddActivityDialog extends StatefulWidget {
  final String? initialActivityType;
  final DateTime selectedDate;

  const AddActivityDialog({
    super.key,
    this.initialActivityType,
    required this.selectedDate,
  });

  @override
  State<AddActivityDialog> createState() => _AddActivityDialogState();
}

class _AddActivityDialogState extends State<AddActivityDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _durationController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _notesController = TextEditingController();

  String _activityType = 'Running';

  @override
  void initState() {
    super.initState();
    if (widget.initialActivityType != null) {
      _activityType = widget.initialActivityType!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    _caloriesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Activity'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _activityType,
                decoration: const InputDecoration(labelText: 'Activity Type'),
                items:
                    ActivityEntry.activityTypes.map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _activityType = value!;
                  });
                },
              ),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Activity Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter activity name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(
                  labelText: 'Duration (minutes)',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter duration';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _caloriesController,
                decoration: const InputDecoration(labelText: 'Calories Burned'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter calories burned';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              // Use the selected date with current time
              final now = DateTime.now();
              final dateTime = DateTime(
                widget.selectedDate.year,
                widget.selectedDate.month,
                widget.selectedDate.day,
                now.hour,
                now.minute,
                now.second,
              );

              final activityEntry = ActivityEntry(
                name: _nameController.text,
                activityType: _activityType,
                duration: int.parse(_durationController.text),
                caloriesBurned: int.parse(_caloriesController.text),
                dateTime: dateTime,
                notes:
                    _notesController.text.isEmpty
                        ? null
                        : _notesController.text,
              );
              Navigator.of(context).pop(activityEntry);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
