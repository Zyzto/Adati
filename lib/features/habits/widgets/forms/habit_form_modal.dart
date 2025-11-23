import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:drift/drift.dart' as drift;
import '../../../../../core/database/app_database.dart' as db;
import '../../../../../core/database/models/tracking_types.dart';
import '../../providers/habit_providers.dart';
import 'tag_form_modal.dart';
import '../components/icon_constants.dart';
import '../components/color_picker.dart';
import '../components/icon_picker.dart';
import '../../../../../core/utils/icon_utils.dart';

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
  int _selectedColor = IconConstants.availableColors.first.toARGB32();
  String? _selectedIcon;
  Set<int> _selectedTagIds = {}; // Changed to Set for multiple tags
  // Habit type and tracking type
  HabitType _habitType = HabitType.good;
  TrackingType _trackingType = TrackingType.completed;
  // Measurable tracking configuration
  final _unitController = TextEditingController();
  final _goalValueController = TextEditingController();
  GoalPeriod _goalPeriod = GoalPeriod.daily;
  // Occurrences tracking configuration
  final List<String> _occurrenceNames = [];
  final _occurrenceNameController = TextEditingController();
  // Reminders
  bool _reminderEnabled = false;
  String _reminderFrequency = 'daily'; // daily, weekly, monthly
  List<int> _reminderDays = []; // For weekly: 1-7 (Mon-Sun), For monthly: 1-31
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);
  // Icon search
  final _iconSearchController = TextEditingController();
  final _iconSearchFocusNode = FocusNode();
  bool _isIconSearchExpanded = false;
  String _iconSearchQuery = '';

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
    final repository = ref.read(habitRepositoryProvider);
    final habitAsync = ref.read(habitByIdProvider(widget.habitId!).future);
    final habit = await habitAsync;
    if (habit != null && mounted) {
      // Load tags for this habit
      final tags = await repository.getTagsForHabit(habit.id);

      setState(() {
        _nameController.text = habit.name;
        _descriptionController.text = habit.description ?? '';
        _selectedColor = habit.color;
        _selectedIcon = habit.icon;
        _selectedTagIds = tags.map((t) => t.id).toSet();
        _habitType = HabitType.fromValue(habit.habitType);
        _trackingType = TrackingType.fromValue(habit.trackingType);
        // Load measurable configuration
        _unitController.text = habit.unit ?? '';
        _goalValueController.text = habit.goalValue?.toString() ?? '';
        _goalPeriod = habit.goalPeriod != null
            ? GoalPeriod.fromValue(habit.goalPeriod!)
            : GoalPeriod.daily;
        // Load occurrences configuration
        if (habit.occurrenceNames != null &&
            habit.occurrenceNames!.isNotEmpty) {
          try {
            _occurrenceNames.clear();
            _occurrenceNames.addAll(
              List<String>.from(jsonDecode(habit.occurrenceNames!)),
            );
          } catch (e) {
            _occurrenceNames.clear();
          }
        }
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
    _unitController.dispose();
    _goalValueController.dispose();
    _occurrenceNameController.dispose();
    _iconSearchController.dispose();
    _iconSearchFocusNode.dispose();
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
        'time':
            '${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}',
      };
      reminderTimeJson = jsonEncode(reminderData);
    }

    // Build tracking configuration
    String? unit;
    double? goalValue;
    String? goalPeriod;
    String? occurrenceNamesJson;

    if (_trackingType == TrackingType.measurable) {
      unit = _unitController.text.trim().isEmpty
          ? null
          : _unitController.text.trim();
      goalValue = _goalValueController.text.trim().isEmpty
          ? null
          : double.tryParse(_goalValueController.text.trim());
      goalPeriod = _goalPeriod.value;
    } else if (_trackingType == TrackingType.occurrences) {
      occurrenceNamesJson = _occurrenceNames.isEmpty
          ? null
          : jsonEncode(_occurrenceNames);
    }

    final habitId = widget.habitId;
    final habit = db.HabitsCompanion(
      id: habitId == null ? const drift.Value.absent() : drift.Value(habitId),
      name: drift.Value(_nameController.text.trim()),
      description: _descriptionController.text.trim().isEmpty
          ? const drift.Value.absent()
          : drift.Value(_descriptionController.text.trim()),
      color: drift.Value(_selectedColor),
      icon: _selectedIcon == null
          ? const drift.Value.absent()
          : drift.Value(_selectedIcon!),
      habitType: drift.Value(_habitType.value),
      trackingType: drift.Value(_trackingType.value),
      unit: unit == null ? const drift.Value.absent() : drift.Value(unit),
      goalValue: goalValue == null
          ? const drift.Value.absent()
          : drift.Value(goalValue),
      goalPeriod: goalPeriod == null
          ? const drift.Value.absent()
          : drift.Value(goalPeriod),
      occurrenceNames: occurrenceNamesJson == null
          ? const drift.Value.absent()
          : drift.Value(occurrenceNamesJson),
      reminderEnabled: drift.Value(_reminderEnabled),
      reminderTime: reminderTimeJson == null
          ? const drift.Value.absent()
          : drift.Value(reminderTimeJson),
      createdAt: existingHabit?.createdAt == null
          ? drift.Value(now)
          : drift.Value(existingHabit!.createdAt),
      updatedAt: drift.Value(now),
    );

    final tagIds = _selectedTagIds.toList();
    if (widget.habitId == null) {
      await repository.createHabit(habit, tagIds: tagIds);
    } else {
      await repository.updateHabit(habit, tagIds: tagIds);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tagsAsync = ref.watch(tagsProvider);

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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.habitId == null
                            ? 'new_habit'.tr()
                            : 'edit_habit'.tr(),
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
                          _buildBasicInfoSection(),
                          _buildHabitTypeSection(),
                          _buildTrackingTypeSection(),
                          _buildTrackingConfigurationSection(),
                          _buildAppearanceSection(),
                          _buildTagsSection(tagsAsync),
                          _buildReminderSection(),
                          const SizedBox(height: 24),

                          // Save Button
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _saveHabit,
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                'save'.tr(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
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

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('basic_info'.tr()),
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'habit_name'.tr(),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.description),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildHabitTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('habit_type'.tr()),
        SegmentedButton<HabitType>(
          segments: [
            ButtonSegment<HabitType>(
              value: HabitType.good,
              label: Text('good_habit'.tr()),
              icon: const Icon(Icons.thumb_up),
            ),
            ButtonSegment<HabitType>(
              value: HabitType.bad,
              label: Text('bad_habit'.tr()),
              icon: const Icon(Icons.thumb_down),
            ),
          ],
          selected: {_habitType},
          onSelectionChanged: (Set<HabitType> newSelection) {
            setState(() {
              _habitType = newSelection.first;
            });
          },
          showSelectedIcon: false,
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTrackingTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('tracking_type'.tr()),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<TrackingType>(
            segments: [
              ButtonSegment<TrackingType>(
                value: TrackingType.completed,
                label: Text('completed'.tr()),
                icon: const Icon(Icons.check_circle),
              ),
              ButtonSegment<TrackingType>(
                value: TrackingType.measurable,
                label: Text('measurable'.tr()),
                icon: const Icon(Icons.trending_up),
              ),
              ButtonSegment<TrackingType>(
                value: TrackingType.occurrences,
                label: Text('occurrences'.tr()),
                icon: const Icon(Icons.list),
              ),
            ],
            selected: {_trackingType},
            onSelectionChanged: (Set<TrackingType> newSelection) {
              setState(() {
                _trackingType = newSelection.first;
              });
            },
            showSelectedIcon: false,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTrackingConfigurationSection() {
    if (_trackingType == TrackingType.measurable) {
      return _buildMeasurableConfiguration();
    } else if (_trackingType == TrackingType.occurrences) {
      return _buildOccurrencesConfiguration();
    }
    return const SizedBox.shrink();
  }

  Widget _buildMeasurableConfiguration() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('measurable_config'.tr()),
        TextFormField(
          controller: _unitController,
          decoration: InputDecoration(
            labelText: 'unit'.tr(),
            hintText: 'unit_example'.tr(),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.straighten),
          ),
          onChanged: (value) {
            setState(() {});
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _goalValueController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'goal_value'.tr(),
            hintText: 'goal_value_example'.tr(),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.flag),
          ),
          validator: (value) {
            if (value != null &&
                value.trim().isNotEmpty &&
                double.tryParse(value.trim()) == null) {
              return 'please_enter_valid_number'.tr();
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<GoalPeriod>(
          initialValue: _goalPeriod,
          decoration: InputDecoration(
            labelText: 'goal_period'.tr(),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.calendar_today),
          ),
          items: GoalPeriod.values.map((period) {
            return DropdownMenuItem<GoalPeriod>(
              value: period,
              child: Text(period.value.tr()),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _goalPeriod = value;
              });
            }
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildOccurrencesConfiguration() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('occurrences_config'.tr()),
        Text(
          'occurrence_names'.tr(),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _occurrenceNames.map((name) {
            return Chip(
              label: Text(name),
              onDeleted: () {
                setState(() {
                  _occurrenceNames.remove(name);
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _occurrenceNameController,
                decoration: InputDecoration(
                  labelText: 'add_occurrence'.tr(),
                  hintText: 'occurrence_example'.tr(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.add),
                ),
                onFieldSubmitted: (value) {
                  if (value.trim().isNotEmpty &&
                      !_occurrenceNames.contains(value.trim())) {
                    setState(() {
                      _occurrenceNames.add(value.trim());
                      _occurrenceNameController.clear();
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add_circle),
              onPressed: () {
                final value = _occurrenceNameController.text.trim();
                if (value.isNotEmpty && !_occurrenceNames.contains(value)) {
                  setState(() {
                    _occurrenceNames.add(value);
                    _occurrenceNameController.clear();
                  });
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  void _toggleIconSearch() {
    if (!mounted) return;
    
    if (_isIconSearchExpanded) {
      // Collapse: clear search and close
      _iconSearchController.clear();
      _iconSearchFocusNode.unfocus();
      setState(() {
        _isIconSearchExpanded = false;
        _iconSearchQuery = '';
      });
    } else {
      // Expand: open search field
      setState(() {
        _isIconSearchExpanded = true;
      });
      // Request focus after the widget is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _isIconSearchExpanded) {
          _iconSearchFocusNode.requestFocus();
        }
      });
    }
  }

  Widget _buildAppearanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('appearance'.tr()),
        Text(
          'color'.tr(),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 12),
        ColorPickerWidget(
          selectedColor: _selectedColor,
          onColorSelected: (color) {
            setState(() => _selectedColor = color);
          },
        ),
        const SizedBox(height: 20),
        // "Select icon" label with search button next to it
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                'select_icon'.tr(),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _toggleIconSearch,
              tooltip: 'search_icons'.tr(),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        // Expanded search field (appears below the label when expanded)
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: _isIconSearchExpanded
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextField(
                    controller: _iconSearchController,
                    focusNode: _iconSearchFocusNode,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _iconSearchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _iconSearchController.clear();
                                setState(() {
                                  _iconSearchQuery = '';
                                });
                              },
                            )
                          : null,
                      hintText: 'search_icons'.tr(),
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    textInputAction: TextInputAction.search,
                    onChanged: (value) {
                      setState(() {
                        _iconSearchQuery = value;
                      });
                    },
                  ),
                )
              : const SizedBox.shrink(),
        ),
        IconPickerWidget(
          selectedIcon: _selectedIcon,
          onIconSelected: (icon) {
            setState(() => _selectedIcon = icon);
          },
          searchQuery: _iconSearchQuery,
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTagsSection(AsyncValue<List<db.Tag>> tagsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('tags'.tr()),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'select_tags'.tr(),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () {
                TagFormModal.show(context).then((_) {
                  // Refresh tags after creating
                  if (mounted) {
                    ref.invalidate(tagsProvider);
                  }
                });
              },
              icon: const Icon(Icons.add, size: 18),
              label: Text('create_tag'.tr()),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildTagSelector(tagsAsync),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildReminderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      ],
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

  Widget _buildTagSelector(AsyncValue<List<db.Tag>> tagsAsync) {
    return tagsAsync.when(
      data: (tags) {
        if (tags.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!, width: 1),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'no_tags_available'.tr(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags.map((tag) {
            final tagId = tag.id;
            final isSelected = _selectedTagIds.contains(tagId);
            return FilterChip(
              label: Text(tag.name),
              selected: isSelected,
              showCheckmark: false,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedTagIds.add(tagId);
                  } else {
                    _selectedTagIds.remove(tagId);
                  }
                });
              },
              avatar: tag.icon != null
                  ? Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Color(tag.color).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        createIconDataFromString(tag.icon!),
                        size: 14,
                        color: Color(tag.color),
                      ),
                    )
                  : Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Color(tag.color).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
              selectedColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.15),
              checkmarkColor: Theme.of(context).colorScheme.primary,
              side: BorderSide(
                color: isSelected
                    ? Theme.of(context).colorScheme.secondary
                    : Theme.of(context).colorScheme.outlineVariant,
                width: isSelected ? 1.5 : 1,
              ),
              labelStyle: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? Theme.of(context).colorScheme.secondary
                    : Theme.of(context).colorScheme.onSurface,
              ),
            );
          }).toList(),
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.errorContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              size: 20,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'error_loading_tags'.tr(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ],
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
                showCheckmark: false,
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
                selectedColor: Theme.of(
                  context,
                ).colorScheme.secondary.withValues(alpha: 0.15),
                checkmarkColor: Theme.of(context).colorScheme.secondary,
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
        Text('select_days'.tr(), style: Theme.of(context).textTheme.titleSmall),
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
              showCheckmark: false,
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
              selectedColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.15),
              checkmarkColor: Theme.of(context).colorScheme.primary,
            );
          }),
        ),
      ],
    );
  }
}
