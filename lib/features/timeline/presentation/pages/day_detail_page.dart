import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/date_utils.dart' as app_date_utils;
import '../../../habits/presentation/providers/habit_providers.dart';
import '../../../tracking/presentation/providers/tracking_providers.dart';
import '../../../habits/domain/models/habit.dart';

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
              // Filter to only show completed habits
              final completedHabits = habits.where((habit) {
                return entries[habit.id!] == true;
              }).toList();

              final totalHabits = habits.length;
              final completedCount = completedHabits.length;

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
                                'Completed',
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
                                'Total Habits',
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
                                'Completion',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Completed habits list
                  Expanded(
                    child: completedHabits.isEmpty
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
                                  'No habits completed',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Complete habits to see them here',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: completedHabits.length,
                            itemBuilder: (context, index) {
                              final habit = completedHabits[index];
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
            error: (error, stack) => Center(child: Text('Error: $error')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

class _HabitEntryCard extends ConsumerStatefulWidget {
  final Habit habit;
  final DateTime date;

  const _HabitEntryCard({required this.habit, required this.date});

  @override
  ConsumerState<_HabitEntryCard> createState() => _HabitEntryCardState();
}

class _HabitEntryCardState extends ConsumerState<_HabitEntryCard> {
  String? _notes;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final repository = ref.read(habitRepositoryProvider);
    final entry = await repository.getEntry(widget.habit.id!, widget.date);
    if (mounted) {
      setState(() {
        _notes = entry?.notes;
      });
    }
  }

  Future<void> _showNotesDialog() async {
    final repository = ref.read(habitRepositoryProvider);
    final entry = await repository.getEntry(widget.habit.id!, widget.date);
    final currentNotes = entry?.notes ?? '';

    if (!mounted) return;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => _NotesDialog(initialNotes: currentNotes),
    );

    if (result != null && mounted) {
      await repository.toggleCompletion(
        widget.habit.id!,
        widget.date,
        true,
        notes: result.isEmpty ? null : result,
      );
      _loadNotes();
    }
  }

  @override
  Widget build(BuildContext context) {
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
        subtitle: _notes != null && _notes!.isNotEmpty
            ? Text(_notes!, maxLines: 2, overflow: TextOverflow.ellipsis)
            : const Text('Tap to add notes'),
        trailing: IconButton(
          icon: Icon(
            _notes != null && _notes!.isNotEmpty
                ? Icons.edit_note
                : Icons.note_add,
          ),
          onPressed: _showNotesDialog,
        ),
        onTap: _showNotesDialog,
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
      title: const Text('Notes'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          hintText: 'Add notes about this habit...',
          border: OutlineInputBorder(),
        ),
        maxLines: 5,
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
