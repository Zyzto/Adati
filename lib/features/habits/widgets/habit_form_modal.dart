import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:drift/drift.dart' as drift;
import '../../../../core/database/app_database.dart' as db;
import '../providers/habit_providers.dart';

class HabitFormModal extends ConsumerStatefulWidget {
  final int? habitId;

  const HabitFormModal({super.key, this.habitId});

  static void show(BuildContext context, {int? habitId}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => HabitFormModal(habitId: habitId),
    );
  }

  @override
  ConsumerState<HabitFormModal> createState() => _HabitFormModalState();
}

class _HabitFormModalState extends ConsumerState<HabitFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  int _selectedColor = Colors.deepPurple.toARGB32();
  String? _selectedIcon;
  int? _selectedCategoryId;
  bool _reminderEnabled = false;
  String _reminderFrequency = 'daily'; // daily, weekly, monthly
  List<int> _reminderDays = []; // For weekly: 1-7 (Mon-Sun), For monthly: 1-31
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);

  // Common Material Icons for habits
  static final List<IconData> _commonIcons = [
    Icons.fitness_center,
    Icons.local_dining,
    Icons.book,
    Icons.water_drop,
    Icons.bedtime,
    Icons.self_improvement,
    Icons.work,
    Icons.school,
    Icons.sports_soccer,
    Icons.music_note,
    Icons.movie,
    Icons.games,
    Icons.nature,
    Icons.pets,
    Icons.directions_walk,
    Icons.directions_run,
    Icons.bike_scooter,
    Icons.self_improvement,
    Icons.spa,
    Icons.health_and_safety,
    Icons.volunteer_activism,
    Icons.family_restroom,
    Icons.celebration,
    Icons.star,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.habitId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadHabit();
      });
    }
  }

  Future<void> _loadHabit() async {
    final habitAsync = ref.read(habitByIdProvider(widget.habitId!).future);
    final habit = await habitAsync;
    if (habit != null && mounted) {
      setState(() {
        _nameController.text = habit.name;
        _descriptionController.text = habit.description ?? '';
        _selectedColor = habit.color;
        _selectedIcon = habit.icon;
        _selectedCategoryId = habit.categoryId;
        _reminderEnabled = habit.reminderEnabled;
        
        // Parse reminder data
        if (habit.reminderTime != null && habit.reminderTime!.isNotEmpty) {
          try {
            final reminderData = jsonDecode(habit.reminderTime!);
            _reminderFrequency = reminderData['frequency'] ?? 'daily';
            _reminderDays = List<int>.from(reminderData['days'] ?? []);
            final timeStr = reminderData['time'] ?? '09:00';
            final parts = timeStr.split(':');
            _reminderTime = TimeOfDay(
              hour: int.parse(parts[0]),
              minute: int.parse(parts[1]),
            );
          } catch (e) {
            // Fallback to simple time format
            final parts = habit.reminderTime!.split(':');
            if (parts.length == 2) {
              _reminderTime = TimeOfDay(
                hour: int.parse(parts[0]),
                minute: int.parse(parts[1]),
              );
            }
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked != null && mounted) {
      setState(() {
        _reminderTime = picked;
      });
    }
  }

  Future<void> _saveHabit() async {
    if (!_formKey.currentState!.validate()) return;

    final repository = ref.read(habitRepositoryProvider);
    final now = DateTime.now();

    final existingHabit = widget.habitId != null 
        ? await repository.getHabitById(widget.habitId!)
        : null;
    
    // Build reminder data
    String? reminderTimeJson;
    if (_reminderEnabled) {
      final reminderData = {
        'frequency': _reminderFrequency,
        'days': _reminderDays,
        'time': '${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}',
      };
      reminderTimeJson = jsonEncode(reminderData);
    }
    
    final habitId = widget.habitId;
    final habit = db.HabitsCompanion(
      id: habitId == null 
          ? const drift.Value.absent() 
          : drift.Value(habitId),
      name: drift.Value(_nameController.text.trim()),
      description: _descriptionController.text.trim().isEmpty
          ? const drift.Value.absent()
          : drift.Value(_descriptionController.text.trim()),
      color: drift.Value(_selectedColor),
      icon: _selectedIcon == null
          ? const drift.Value.absent()
          : drift.Value(_selectedIcon!),
      categoryId: _selectedCategoryId == null
          ? const drift.Value.absent()
          : drift.Value(_selectedCategoryId),
      reminderEnabled: drift.Value(_reminderEnabled),
      reminderTime: reminderTimeJson == null
          ? const drift.Value.absent()
          : drift.Value(reminderTimeJson),
      createdAt: existingHabit?.createdAt == null
          ? drift.Value(now)
          : drift.Value(existingHabit!.createdAt),
      updatedAt: drift.Value(now),
    );

    if (widget.habitId == null) {
      await repository.createHabit(habit);
    } else {
      await repository.updateHabit(habit);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.habitId == null ? 'new_habit'.tr() : 'edit_habit'.tr(),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                // Form
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Basic Info Section
                          _buildSectionHeader('basic_info'.tr()),
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'habit_name'.tr(),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.label),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'please_enter_habit_name'.tr();
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _descriptionController,
                            decoration: InputDecoration(
                              labelText: 'habit_description'.tr(),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.description),
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 24),
                          
                          // Appearance Section
                          _buildSectionHeader('appearance'.tr()),
                          Text(
                            'color'.tr(),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Colors.deepPurple,
                              Colors.blue,
                              Colors.green,
                              Colors.orange,
                              Colors.red,
                              Colors.pink,
                              Colors.teal,
                              Colors.indigo,
                            ].map((color) {
                              return GestureDetector(
                                onTap: () => setState(() => _selectedColor = color.toARGB32()),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _selectedColor == color.toARGB32()
                                          ? Colors.black
                                          : Colors.transparent,
                                      width: 3,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'select_icon'.tr(),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          _buildIconPicker(),
                          const SizedBox(height: 24),
                          
                          // Organization Section
                          _buildSectionHeader('organization'.tr()),
                          Text(
                            'select_categories'.tr(),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          _buildCategoryTags(categoriesAsync),
                          const SizedBox(height: 24),
                          
                          // Reminders Section
                          _buildSectionHeader('reminders'.tr()),
                          SwitchListTile(
                            title: Text('enable_reminder'.tr()),
                            subtitle: Text('receive_reminder_notifications'.tr()),
                            value: _reminderEnabled,
                            onChanged: (value) {
                              setState(() {
                                _reminderEnabled = value;
                                if (!value) {
                                  _reminderDays.clear();
                                }
                              });
                            },
                          ),
                          if (_reminderEnabled) ...[
                            const SizedBox(height: 8),
                            _buildReminderFrequencySelector(),
                            const SizedBox(height: 16),
                            _buildReminderDaySelector(),
                            const SizedBox(height: 16),
                            ListTile(
                              leading: const Icon(Icons.access_time),
                              title: Text('reminder_time'.tr()),
                              subtitle: Text(
                                _reminderTime.format(context),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: _selectTime,
                            ),
                          ],
                          const SizedBox(height: 24),
                          
                          // Save Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _saveHabit,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text('save'.tr()),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  Widget _buildIconPicker() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        scrollDirection: Axis.horizontal,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1,
        ),
        itemCount: _commonIcons.length + 1, // +1 for "no icon" option
        itemBuilder: (context, index) {
          if (index == 0) {
            // "No icon" option
            final isSelected = _selectedIcon == null;
            return GestureDetector(
              onTap: () => setState(() => _selectedIcon = null),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.block, size: 24),
                    const SizedBox(height: 4),
                    Text(
                      'no_icon'.tr(),
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected ? Theme.of(context).primaryColor : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          
          final icon = _commonIcons[index - 1];
          final iconCode = icon.codePoint.toString();
          final isSelected = _selectedIcon == iconCode;
          
          return GestureDetector(
            onTap: () => setState(() => _selectedIcon = iconCode),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected 
                    ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey[700],
                size: 28,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryTags(AsyncValue<List<db.Category>> categoriesAsync) {
    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'no_categories'.tr(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          );
        }
        
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories.map((category) {
            final isSelected = _selectedCategoryId == category.id;
            return FilterChip(
              label: Text(category.name),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategoryId = selected ? category.id : null;
                });
              },
              avatar: category.icon != null
                  ? Icon(
                      IconData(
                        int.parse(category.icon!),
                        fontFamily: 'MaterialIcons',
                      ),
                      size: 18,
                    )
                  : null,
              selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
              checkmarkColor: Theme.of(context).primaryColor,
            );
          }).toList(),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'error_loading_categories'.tr(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.red,
              ),
        ),
      ),
    );
  }

  Widget _buildReminderFrequencySelector() {
    return SegmentedButton<String>(
      segments: [
        ButtonSegment(
          value: 'daily',
          label: Text('daily'.tr()),
          icon: const Icon(Icons.today, size: 18),
        ),
        ButtonSegment(
          value: 'weekly',
          label: Text('weekly'.tr()),
          icon: const Icon(Icons.calendar_view_week, size: 18),
        ),
        ButtonSegment(
          value: 'monthly',
          label: Text('monthly'.tr()),
          icon: const Icon(Icons.calendar_month, size: 18),
        ),
      ],
      selected: {_reminderFrequency},
      onSelectionChanged: (Set<String> newSelection) {
        setState(() {
          _reminderFrequency = newSelection.first;
          _reminderDays.clear();
        });
      },
    );
  }

  Widget _buildReminderDaySelector() {
    if (_reminderFrequency == 'daily') {
      return const SizedBox.shrink();
    }
    
    if (_reminderFrequency == 'weekly') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'select_days'.tr(),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(7, (index) {
              final dayIndex = index + 1; // 1 = Monday, 7 = Sunday
              final dayNames = [
                'monday'.tr(),
                'tuesday'.tr(),
                'wednesday'.tr(),
                'thursday'.tr(),
                'friday'.tr(),
                'saturday'.tr(),
                'sunday'.tr(),
              ];
              final isSelected = _reminderDays.contains(dayIndex);
              
              return FilterChip(
                label: Text(dayNames[index]),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _reminderDays.add(dayIndex);
                    } else {
                      _reminderDays.remove(dayIndex);
                    }
                    _reminderDays.sort();
                  });
                },
              );
            }),
          ),
        ],
      );
    }
    
    // Monthly
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'select_days'.tr(),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(31, (index) {
            final day = index + 1;
            final isSelected = _reminderDays.contains(day);
            
            return FilterChip(
              label: Text('$day'),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _reminderDays.add(day);
                  } else {
                    _reminderDays.remove(day);
                  }
                  _reminderDays.sort();
                });
              },
            );
          }),
        ),
      ],
    );
  }
}

