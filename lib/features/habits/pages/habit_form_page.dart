import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:drift/drift.dart' as drift;
import '../../../../core/database/app_database.dart' as db;
import '../providers/habit_providers.dart';

class HabitFormPage extends ConsumerStatefulWidget {
  final int? habitId;

  const HabitFormPage({super.key, this.habitId});

  @override
  ConsumerState<HabitFormPage> createState() => _HabitFormPageState();
}

class _HabitFormPageState extends ConsumerState<HabitFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  int _selectedColor = Colors.deepPurple.toARGB32();
  Set<int> _selectedTagIds = {};

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
        _selectedTagIds = tags.map((t) => t.id).toSet();
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveHabit() async {
    if (!_formKey.currentState!.validate()) return;

    final repository = ref.read(habitRepositoryProvider);
    final now = DateTime.now();

    final existingHabit = widget.habitId != null 
        ? await repository.getHabitById(widget.habitId!)
        : null;
    
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
      icon: existingHabit?.icon == null
          ? const drift.Value.absent()
          : drift.Value(existingHabit!.icon),
      reminderEnabled: drift.Value(existingHabit?.reminderEnabled ?? false),
      reminderTime: existingHabit?.reminderTime == null
          ? const drift.Value.absent()
          : drift.Value(existingHabit!.reminderTime!),
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
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.habitId == null ? 'new_habit'.tr() : 'edit_habit'.tr()),
        actions: [
          TextButton(
            onPressed: _saveHabit,
            child: Text('save'.tr()),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'habit_name'.tr(),
                border: const OutlineInputBorder(),
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
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            Text(
              'color'.tr(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
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
            const SizedBox(height: 24),
            Text(
              'tags'.tr(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildTagSelector(),
          ],
        ),
      ),
    );
  }

  Widget _buildTagSelector() {
    final tagsAsync = ref.watch(tagsProvider);
    
    return tagsAsync.when(
      data: (tags) {
        if (tags.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'no_tags_available'.tr(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
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
                        IconData(
                          int.parse(tag.icon!),
                          fontFamily: 'MaterialIcons',
                        ),
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
              selectedColor: Theme.of(context)
                  .colorScheme.primary
                  .withValues(alpha: 0.15),
              checkmarkColor: Theme.of(context).colorScheme.primary,
            );
          }).toList(),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'error_loading_tags'.tr(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.red,
              ),
        ),
      ),
    );
  }
}

