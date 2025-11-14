import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/database/app_database.dart' as db;
import '../../../../core/services/preferences_service.dart';

class GoalSettingWidget extends ConsumerStatefulWidget {
  final db.Habit habit;

  const GoalSettingWidget({super.key, required this.habit});

  @override
  ConsumerState<GoalSettingWidget> createState() => _GoalSettingWidgetState();
}

class _GoalSettingWidgetState extends ConsumerState<GoalSettingWidget> {
  late TextEditingController _weeklyGoalController;
  late TextEditingController _monthlyGoalController;
  int? _weeklyGoal;
  int? _monthlyGoal;

  @override
  void initState() {
    super.initState();
    // Load existing goals from preferences
    _weeklyGoal = PreferencesService.getHabitWeeklyGoal(widget.habit.id);
    _monthlyGoal = PreferencesService.getHabitMonthlyGoal(widget.habit.id);
    _weeklyGoalController = TextEditingController(
      text: _weeklyGoal?.toString() ?? '',
    );
    _monthlyGoalController = TextEditingController(
      text: _monthlyGoal?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _weeklyGoalController.dispose();
    _monthlyGoalController.dispose();
    super.dispose();
  }


  Future<void> _saveGoals() async {
    final weekly = _weeklyGoalController.text.isEmpty
        ? null
        : int.tryParse(_weeklyGoalController.text);
    final monthly = _monthlyGoalController.text.isEmpty
        ? null
        : int.tryParse(_monthlyGoalController.text);
    
    if (weekly != null && (weekly < 0 || weekly > 7)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('weekly_goal_invalid'.tr())),
      );
      return;
    }
    
    if (monthly != null && (monthly < 0 || monthly > 31)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('monthly_goal_invalid'.tr())),
      );
      return;
    }
    
    setState(() {
      _weeklyGoal = weekly;
      _monthlyGoal = monthly;
    });
    
    await PreferencesService.setHabitWeeklyGoal(widget.habit.id, weekly);
    await PreferencesService.setHabitMonthlyGoal(widget.habit.id, monthly);
    
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('goals_saved'.tr())),
      );
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'set_goals'.tr(),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                widget.habit.name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _weeklyGoalController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'weekly_goal'.tr(),
                  hintText: 'days_per_week'.tr(),
                  helperText: 'set_weekly_target'.tr(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.calendar_view_week),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _monthlyGoalController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'monthly_goal'.tr(),
                  hintText: 'days_per_month'.tr(),
                  helperText: 'set_monthly_target'.tr(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.calendar_month),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveGoals,
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

