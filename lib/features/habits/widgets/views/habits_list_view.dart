import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/habit_providers.dart';
import '../cards/habit_card.dart';
import '../../../../../core/database/app_database.dart' as db;

class HabitsListView extends ConsumerWidget {
  final List<db.Habit> habits;
  final String cardLayout;

  const HabitsListView({
    super.key,
    required this.habits,
    required this.cardLayout,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupBy = ref.watch(habitGroupByProvider);

    if (groupBy == 'type') {
      return _buildGroupedList(context);
    }

    if (cardLayout == 'grid') {
      return _buildGridView(context);
    }

    return _buildListView();
  }

  Widget _buildGroupedList(BuildContext context) {
    final goodHabits = habits.where((h) => h.habitType == 0).toList();
    final badHabits = habits.where((h) => h.habitType == 1).toList();

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        if (goodHabits.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'good_habits'.tr(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
            ),
          ),
          ...goodHabits.map((habit) => HabitCard(habit: habit)),
        ],
        if (badHabits.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'bad_habits'.tr(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
            ),
          ),
          ...badHabits.map((habit) => HabitCard(habit: habit)),
        ],
      ],
    );
  }

  Widget _buildGridView(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: habits.length,
      itemBuilder: (context, index) {
        return HabitGridCard(habit: habits[index]);
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: habits.length,
      itemBuilder: (context, index) {
        return HabitCard(habit: habits[index]);
      },
    );
  }
}

