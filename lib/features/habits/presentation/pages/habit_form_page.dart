import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/habit_providers.dart';
import '../../domain/models/habit.dart';

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
  int? _selectedCategoryId;

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
      _nameController.text = habit.name;
      _descriptionController.text = habit.description ?? '';
      _selectedColor = habit.color;
      _selectedCategoryId = habit.categoryId;
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

    final habit = Habit(
      id: widget.habitId,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      color: _selectedColor,
      categoryId: _selectedCategoryId,
      createdAt: widget.habitId == null ? now : DateTime.now(),
      updatedAt: now,
    );

    if (widget.habitId == null) {
      await repository.createHabit(habit);
    } else {
      await repository.updateHabit(habit);
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
          ],
        ),
      ),
    );
  }
}

