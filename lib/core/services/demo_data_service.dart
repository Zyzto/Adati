import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import 'package:easy_localization/easy_localization.dart';
import '../database/app_database.dart' as db;
import '../database/models/tracking_types.dart';
import '../utils/date_utils.dart' as app_date_utils;
import '../../features/habits/habit_repository.dart';
import 'logging_service.dart';

class DemoDataService {
  static String get _demoTagName => 'demo'.tr();

  /// Check if a habit is demo data
  static Future<bool> isDemoData(int habitId, HabitRepository repository) async {
    final tags = await repository.getTagsForHabit(habitId);
    return tags.any((tag) => tag.name == _demoTagName);
  }

  /// Check if any demo data exists
  static Future<bool> hasDemoData(HabitRepository repository) async {
    try {
      final tags = await repository.getAllTags();
      final demoTag = tags.firstWhere(
        (tag) => tag.name == _demoTagName,
        orElse: () => throw StateError('No demo tag found'),
      );
      final habits = await repository.getHabitsByTag(demoTag.id);
      return habits.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Load demo data into the app
  static Future<void> loadDemoData(HabitRepository repository) async {
    try {
      // Check if demo data already exists
      if (await hasDemoData(repository)) {
        LoggingService.info('Demo data already exists, skipping creation');
        return;
      }

      // Create demo tag
      final demoTagId = await repository.createTag(
        db.TagsCompanion(
          name: drift.Value(_demoTagName),
          color: drift.Value(Colors.deepPurple.toARGB32()),
          icon: drift.Value(Icons.rocket_launch.codePoint.toString()),
        ),
      );

      final now = DateTime.now();
      final today = app_date_utils.DateUtils.getToday();

      // Demo habits
      final demoHabits = [
        {
          'name': 'Exercise',
          'description': 'Daily workout routine',
          'color': Colors.blue[700]!,
          'icon': Icons.fitness_center,
          'habitType': HabitType.good,
          'trackingType': TrackingType.completed,
          'entries': 45, // Last 45 days
          'completionRate': 0.75, // 75% completion
        },
        {
          'name': 'Read Books',
          'description': 'Read for at least 30 minutes',
          'color': Colors.green[700]!,
          'icon': Icons.book,
          'habitType': HabitType.good,
          'trackingType': TrackingType.measurable,
          'unit': 'pages',
          'goalValue': 10.0,
          'goalPeriod': GoalPeriod.daily,
          'entries': 50,
          'completionRate': 0.80,
        },
        {
          'name': 'Meditation',
          'description': 'Daily mindfulness practice',
          'color': Colors.purple[700]!,
          'icon': Icons.self_improvement,
          'habitType': HabitType.good,
          'trackingType': TrackingType.measurable,
          'unit': 'minutes',
          'goalValue': 15.0,
          'goalPeriod': GoalPeriod.daily,
          'entries': 40,
          'completionRate': 0.70,
        },
        {
          'name': 'Smoking',
          'description': 'Avoid smoking cigarettes',
          'color': Colors.red[700]!,
          'icon': Icons.smoking_rooms,
          'habitType': HabitType.bad,
          'trackingType': TrackingType.completed,
          'entries': 60,
          'completionRate': 0.85, // 85% success (not smoking)
        },
        {
          'name': 'Junk Food',
          'description': 'Avoid unhealthy snacks',
          'color': Colors.orange[700]!,
          'icon': Icons.fastfood,
          'habitType': HabitType.bad,
          'trackingType': TrackingType.occurrences,
          'occurrenceNames': ['breakfast'.tr(), 'lunch'.tr(), 'dinner'.tr(), 'snack'.tr()],
          'entries': 55,
          'completionRate': 0.65,
        },
        {
          'name': 'Water Intake',
          'description': 'Drink enough water daily',
          'color': Colors.cyan[700]!,
          'icon': Icons.water_drop,
          'habitType': HabitType.good,
          'trackingType': TrackingType.measurable,
          'unit': 'glasses',
          'goalValue': 8.0,
          'goalPeriod': GoalPeriod.daily,
          'entries': 50,
          'completionRate': 0.90,
        },
      ];

      // Create habits and entries
      for (final habitData in demoHabits) {
        final habitCompanion = db.HabitsCompanion(
          name: drift.Value(habitData['name'] as String),
          description: drift.Value(habitData['description'] as String),
          color: drift.Value((habitData['color'] as Color).toARGB32()),
          icon: drift.Value((habitData['icon'] as IconData).codePoint.toString()),
          habitType: drift.Value((habitData['habitType'] as HabitType).value),
          trackingType: drift.Value((habitData['trackingType'] as TrackingType).value),
          unit: habitData['unit'] != null
              ? drift.Value(habitData['unit'] as String)
              : const drift.Value.absent(),
          goalValue: habitData['goalValue'] != null
              ? drift.Value(habitData['goalValue'] as double)
              : const drift.Value.absent(),
          goalPeriod: habitData['goalPeriod'] != null
              ? drift.Value((habitData['goalPeriod'] as GoalPeriod).value)
              : const drift.Value.absent(),
          occurrenceNames: habitData['occurrenceNames'] != null
              ? drift.Value(
                  (habitData['occurrenceNames'] as List<String>).join(','),
                )
              : const drift.Value.absent(),
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
        );

        final habitId = await repository.createHabit(
          habitCompanion,
          tagIds: [demoTagId],
        );

        // Create tracking entries
        final entries = habitData['entries'] as int;
        final completionRate = habitData['completionRate'] as double;
        final trackingType = habitData['trackingType'] as TrackingType;

        for (int i = 0; i < entries; i++) {
          final date = today.subtract(Duration(days: entries - i - 1));
          final shouldComplete = (i / entries) < completionRate;

          if (trackingType == TrackingType.completed) {
            if (shouldComplete) {
              await repository.toggleCompletion(habitId, date, true);
            }
          } else if (trackingType == TrackingType.measurable) {
            final goalValue = habitData['goalValue'] as double;
            final actualValue = shouldComplete
                ? goalValue * (0.8 + (i % 3) * 0.1) // Vary between 80-100%
                : goalValue * 0.5; // Below goal
            await repository.trackMeasurable(
              habitId,
              date,
              actualValue,
            );
          } else if (trackingType == TrackingType.occurrences) {
            if (shouldComplete) {
              final occurrenceNames = habitData['occurrenceNames'] as List<String>;
              final count = (occurrenceNames.length * 0.7).round();
              final completedOccurrences = <String>[];
              for (int j = 0; j < count; j++) {
                completedOccurrences.add(
                  occurrenceNames[j % occurrenceNames.length],
                );
              }
              await repository.trackOccurrences(
                habitId,
                date,
                completedOccurrences,
              );
            }
          }
        }
      }

      LoggingService.info('Demo data loaded successfully');
    } catch (e, stackTrace) {
      LoggingService.error('Error loading demo data', e, stackTrace);
      rethrow;
    }
  }

  /// Delete all demo data
  static Future<void> deleteDemoData(HabitRepository repository) async {
    try {
      // Get demo tag
      final tags = await repository.getAllTags();
      final demoTag = tags.firstWhere(
        (tag) => tag.name == _demoTagName,
        orElse: () => throw StateError('No demo tag found'),
      );

      // Get all habits with demo tag
      final habits = await repository.getHabitsByTag(demoTag.id);

      // Delete all demo habits (this will cascade delete entries and streaks)
      for (final habit in habits) {
        await repository.deleteHabit(habit.id);
      }

      // Delete demo tag
      await repository.deleteTag(demoTag.id);

      LoggingService.info('Demo data deleted successfully');
    } catch (e, stackTrace) {
      LoggingService.error('Error deleting demo data', e, stackTrace);
      rethrow;
    }
  }
}

