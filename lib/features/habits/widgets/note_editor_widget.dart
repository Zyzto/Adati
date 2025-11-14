import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/utils/date_utils.dart' as app_date_utils;
import '../providers/habit_providers.dart';

class NoteEditorWidget extends ConsumerStatefulWidget {
  final int habitId;
  final DateTime date;
  final String? initialNotes;

  const NoteEditorWidget({
    super.key,
    required this.habitId,
    required this.date,
    this.initialNotes,
  });

  @override
  ConsumerState<NoteEditorWidget> createState() => _NoteEditorWidgetState();
}

class _NoteEditorWidgetState extends ConsumerState<NoteEditorWidget> {
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.initialNotes ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveNotes() async {
    final repository = ref.read(habitRepositoryProvider);
    final dateOnly = app_date_utils.DateUtils.getDateOnly(widget.date);
    final notes = _notesController.text.trim();
    
    // Get current entry to preserve completion status
    final entry = await repository.getEntry(widget.habitId, dateOnly);
    final isCompleted = entry?.completed ?? false;
    
    // Update entry with notes
    await repository.toggleCompletion(
      widget.habitId,
      dateOnly,
      isCompleted,
      notes: notes.isEmpty ? null : notes,
    );
    
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'notes'.tr(),
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
            // Date display
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                app_date_utils.DateUtils.formatDate(widget.date),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ),
            const SizedBox(height: 16),
            // Notes text field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _notesController,
                maxLines: 8,
                minLines: 4,
                decoration: InputDecoration(
                  hintText: 'add_notes_about_habit'.tr(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                ),
                autofocus: widget.initialNotes == null || widget.initialNotes!.isEmpty,
              ),
            ),
            const SizedBox(height: 16),
            // Save button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveNotes,
                  child: Text('save'.tr()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

