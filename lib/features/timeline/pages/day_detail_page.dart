import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/utils/date_utils.dart' as app_date_utils;
import '../../../../core/database/app_database.dart' as db;
import '../../../../core/database/models/tracking_types.dart';
import '../../habits/providers/habit_providers.dart';
import '../../habits/providers/tracking_providers.dart';

class DayDetailPage extends ConsumerWidget {
  final DateTime date;

  const DayDetailPage({super.key, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateOnly = app_date_utils.DateUtils.getDateOnly(date);
    final habitsAsync = ref.watch(habitsProvider);
    final dayEntriesAsync = ref.watch(dayEntriesProvider(dateOnly));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          app_date_utils.DateUtils.formatDate(
            dateOnly,
            format: 'EEEE, MMMM d, yyyy',
          ),
        ),
      ),
      body: habitsAsync.when(
        data: (habits) {
          return dayEntriesAsync.when(
            data: (entries) {
              // Show all habits that have entries (completed, measurable, or occurrences)
              final habitsWithEntries = habits.where((habit) {
                return entries[habit.id] == true;
              }).toList();

              final totalHabits = habits.length;
              final completedCount = habitsWithEntries.length;

              return Column(
                children: [
                  // Statistics card
                  Card(
                    margin: const EdgeInsets.all(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Text(
                                '$completedCount',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'completed'.tr(),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                '$totalHabits',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'total_habits'.tr(),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                totalHabits > 0
                                    ? '${((completedCount / totalHabits) * 100).toInt()}%'
                                    : '0%',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'completion'.tr(),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Habits with entries list
                  Expanded(
                    child: habitsWithEntries.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'no_habits_completed'.tr(),
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'complete_habits_to_see'.tr(),
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: habitsWithEntries.length,
                            itemBuilder: (context, index) {
                              final habit = habitsWithEntries[index];
                              return _HabitEntryCard(
                                habit: habit,
                                date: dateOnly,
                              );
                            },
                          ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) =>
                Center(child: Text('${'error'.tr()}: $error')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('${'error'.tr()}: $error')),
      ),
    );
  }
}

class _HabitEntryCard extends ConsumerStatefulWidget {
  final db.Habit habit;
  final DateTime date;

  const _HabitEntryCard({required this.habit, required this.date});

  @override
  ConsumerState<_HabitEntryCard> createState() => _HabitEntryCardState();
}

class _HabitEntryCardState extends ConsumerState<_HabitEntryCard> {
  // Use provider to watch entry changes reactively
  db.TrackingEntry? _getEntry() {
    final entriesAsync = ref.watch(trackingEntriesProvider(widget.habit.id));
    return entriesAsync.maybeWhen(
      data: (entries) {
        final dateOnly = app_date_utils.DateUtils.getDateOnly(widget.date);
        return entries.where((e) =>
          app_date_utils.DateUtils.isSameDay(e.date, dateOnly)
        ).firstOrNull;
      },
      orElse: () => null,
    );
  }

  Future<void> _showEditDialog() async {
    final trackingType = TrackingType.fromValue(widget.habit.trackingType);

    if (trackingType == TrackingType.completed) {
      // Show notes dialog for completed tracking
      await _showNotesDialog();
    } else if (trackingType == TrackingType.measurable) {
      // Show measurable input dialog
      await _showMeasurableDialog();
    } else if (trackingType == TrackingType.occurrences) {
      // Show occurrences selection dialog
      await _showOccurrencesDialog();
    }
  }

  Future<void> _showNotesDialog() async {
    final repository = ref.read(habitRepositoryProvider);
    final entry = _getEntry();
    final currentNotes = entry?.notes ?? '';

    if (!mounted) return;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => _NotesDialog(initialNotes: currentNotes),
    );

    if (result != null && mounted) {
      final entry = _getEntry();
      await repository.toggleCompletion(
        widget.habit.id,
        widget.date,
        entry?.completed ?? false,
        notes: result.isEmpty ? null : result,
      );
      // No need to call _loadEntry() - provider will update automatically
    }
  }

  Future<void> _showMeasurableDialog() async {
    final repository = ref.read(habitRepositoryProvider);
    final entry = _getEntry();
    final currentValue = entry?.value ?? 0.0;
    final unit = widget.habit.unit ?? '';
    final goalValue = widget.habit.goalValue;

    final controller = TextEditingController(
      text: currentValue > 0 ? currentValue.toString() : '',
    );

    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(widget.habit.name),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick action buttons (25%, 50%, 75%, 100%)
                if (goalValue != null && goalValue > 0) ...[
                  Text(
                    'quick_actions'.tr(),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildQuickActionButton(
                        context,
                        '25%',
                        goalValue * 0.25,
                        controller,
                        setDialogState,
                      ),
                      _buildQuickActionButton(
                        context,
                        '50%',
                        goalValue * 0.5,
                        controller,
                        setDialogState,
                      ),
                      _buildQuickActionButton(
                        context,
                        '75%',
                        goalValue * 0.75,
                        controller,
                        setDialogState,
                      ),
                      _buildQuickActionButton(
                        context,
                        '100%',
                        goalValue,
                        controller,
                        setDialogState,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                // Value input field with +/- buttons
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () {
                        final current = double.tryParse(controller.text.trim()) ?? 0.0;
                        final step = goalValue != null && goalValue > 0
                            ? goalValue / 20
                            : 1.0;
                        final newValue = (current - step).clamp(0.0, double.infinity);
                        controller.text = newValue.toStringAsFixed(newValue % 1 == 0 ? 0 : 1);
                        setDialogState(() {});
                      },
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: controller,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          labelText: 'value'.tr(),
                          suffixText: unit.isNotEmpty ? unit : null,
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (_) => setDialogState(() {}),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        final current = double.tryParse(controller.text.trim()) ?? 0.0;
                        final step = goalValue != null && goalValue > 0
                            ? goalValue / 20
                            : 1.0;
                        final newValue = current + step;
                        controller.text = newValue.toStringAsFixed(newValue % 1 == 0 ? 0 : 1);
                        setDialogState(() {});
                      },
                    ),
                  ],
                ),
                if (goalValue != null) ...[
                  const SizedBox(height: 16),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller,
                    builder: (context, value, child) {
                      final inputValue = double.tryParse(value.text.trim()) ?? currentValue;
                      final percentage = (inputValue / goalValue * 100).clamp(0.0, double.infinity);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'progress'.tr(),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: percentage > 100 ? 1.0 : percentage / 100,
                            backgroundColor: Colors.grey[300],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${inputValue.toStringAsFixed(1)} / ${goalValue.toStringAsFixed(1)} $unit (${percentage.toStringAsFixed(0)}%)',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('cancel'.tr()),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('save'.tr()),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      final value = double.tryParse(controller.text.trim()) ?? 0.0;
      final entry = _getEntry();
      await repository.trackMeasurable(
        widget.habit.id,
        widget.date,
        value,
        notes: entry?.notes,
      );
      // No need to call _loadEntry() - provider will update automatically
    }
  }

  Widget _buildQuickActionButton(
    BuildContext context,
    String label,
    double value,
    TextEditingController controller,
    StateSetter setDialogState,
  ) {
    return OutlinedButton(
      onPressed: () {
        controller.text = value.toStringAsFixed(value % 1 == 0 ? 0 : 1);
        setDialogState(() {});
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(60, 36),
      ),
      child: Text(label),
    );
  }

  Future<void> _showOccurrencesDialog() async {
    final repository = ref.read(habitRepositoryProvider);
    
    List<String> occurrenceNames = [];
    if (widget.habit.occurrenceNames != null && widget.habit.occurrenceNames!.isNotEmpty) {
      try {
        occurrenceNames = List<String>.from(jsonDecode(widget.habit.occurrenceNames!));
      } catch (e) {
        occurrenceNames = [];
      }
    }

    if (occurrenceNames.isEmpty) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('no_occurrences'.tr()),
          content: Text('please_define_occurrences'.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('ok'.tr()),
            ),
          ],
        ),
      );
      return;
    }

    final entry = _getEntry();
    List<String> selectedOccurrences = [];
    if (entry?.occurrenceData != null && entry!.occurrenceData!.isNotEmpty) {
      try {
        selectedOccurrences = List<String>.from(jsonDecode(entry.occurrenceData!));
      } catch (e) {
        selectedOccurrences = [];
      }
    }

    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(widget.habit.name),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'select_occurrences'.tr(),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 12),
                ...occurrenceNames.map((name) {
                  final isSelected = selectedOccurrences.contains(name);
                  return CheckboxListTile(
                    title: Text(name),
                    value: isSelected,
                    onChanged: (value) {
                      setDialogState(() {
                        if (value == true) {
                          selectedOccurrences.add(name);
                        } else {
                          selectedOccurrences.remove(name);
                        }
                      });
                    },
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('cancel'.tr()),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('save'.tr()),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      final entry = _getEntry();
      await repository.trackOccurrences(
        widget.habit.id,
        widget.date,
        selectedOccurrences,
        notes: entry?.notes,
      );
      // No need to call _loadEntry() - provider will update automatically
    }
  }

  Widget _buildTrackingInfo() {
    final trackingType = TrackingType.fromValue(widget.habit.trackingType);
    final currentEntry = _getEntry();
    
    if (trackingType == TrackingType.measurable) {
      final value = currentEntry?.value ?? 0.0;
      final unit = widget.habit.unit ?? '';
      final goalValue = widget.habit.goalValue;
      
      if (goalValue != null && goalValue > 0) {
        final percentage = (value / goalValue * 100).clamp(0.0, double.infinity);
        return Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: percentage > 100 ? 1.0 : percentage / 100,
                backgroundColor: Colors.grey[300],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${percentage.toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      } else if (value > 0) {
        return Text('${value.toStringAsFixed(1)} $unit');
      }
    } else if (trackingType == TrackingType.occurrences) {
      List<String> completedOccurrences = [];
      if (currentEntry?.occurrenceData != null && currentEntry!.occurrenceData!.isNotEmpty) {
        try {
          completedOccurrences = List<String>.from(jsonDecode(currentEntry.occurrenceData!));
        } catch (e) {
          completedOccurrences = [];
        }
      }

      List<String> allOccurrences = [];
      if (widget.habit.occurrenceNames != null && widget.habit.occurrenceNames!.isNotEmpty) {
        try {
          allOccurrences = List<String>.from(jsonDecode(widget.habit.occurrenceNames!));
        } catch (e) {
          allOccurrences = [];
        }
      }

      if (completedOccurrences.isNotEmpty) {
        return Text(
          '${completedOccurrences.length}/${allOccurrences.length}: ${completedOccurrences.join(', ')}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        );
      }
    }

    // Default: show notes or placeholder
    final notes = currentEntry?.notes;
    return notes != null && notes.isNotEmpty
        ? Text(notes, maxLines: 2, overflow: TextOverflow.ellipsis)
        : Text('tap_to_add_notes'.tr());
  }

  @override
  Widget build(BuildContext context) {
    final trackingType = TrackingType.fromValue(widget.habit.trackingType);
    final currentEntry = _getEntry();
    final notes = currentEntry?.notes;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Color(widget.habit.color),
            borderRadius: BorderRadius.circular(8),
          ),
          child: widget.habit.icon != null
              ? Icon(
                  IconData(
                    int.parse(widget.habit.icon!),
                    fontFamily: 'MaterialIcons',
                  ),
                  color: Colors.white,
                )
              : null,
        ),
        title: Text(
          widget.habit.name,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: _buildTrackingInfo(),
        trailing: IconButton(
          icon: Icon(
            trackingType == TrackingType.completed
                ? (notes != null && notes.isNotEmpty
                    ? Icons.edit_note
                    : Icons.note_add)
                : Icons.edit,
          ),
          onPressed: _showEditDialog,
        ),
        onTap: _showEditDialog,
      ),
    );
  }
}

class _NotesDialog extends StatefulWidget {
  final String initialNotes;

  const _NotesDialog({required this.initialNotes});

  @override
  State<_NotesDialog> createState() => _NotesDialogState();
}

class _NotesDialogState extends State<_NotesDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNotes);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('notes'.tr()),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: 'add_notes_about_habit'.tr(),
          border: const OutlineInputBorder(),
        ),
        maxLines: 5,
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('cancel'.tr()),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text('save'.tr()),
        ),
      ],
    );
  }
}
