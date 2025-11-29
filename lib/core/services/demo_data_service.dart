import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart' as drift;
import 'package:easy_localization/easy_localization.dart';
import '../database/app_database.dart' as db;
import '../database/models/tracking_types.dart';
import '../utils/date_utils.dart' as app_date_utils;
import '../../features/habits/habit_repository.dart';
import 'log_helper.dart';

class DemoDataService {
  static String get _demoTagName => 'demo'.tr();
  static final Random _random = Random();

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

  /// Load demo data configuration from JSON
  static Future<Map<String, dynamic>> _loadDemoConfig() async {
    try {
      final jsonString = await rootBundle.loadString('assets/demo_data.json');
      final config = jsonDecode(jsonString) as Map<String, dynamic>;
      Log.info('Demo data config loaded successfully');
      return config;
    } catch (e, stackTrace) {
      Log.error(
        'Error loading demo data config',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Generate realistic completion pattern based on pattern type
  static bool _shouldComplete(
    String pattern,
    int dayIndex,
    int totalDays,
    double completionRate,
  ) {
    switch (pattern) {
      case 'streak_with_breaks':
        // Create streaks with occasional breaks
        final streakLength = 5 + _random.nextInt(10);
        final breakChance = 1.0 - completionRate;
        if (dayIndex % streakLength == 0 && _random.nextDouble() < breakChance) {
          return false;
        }
        return _random.nextDouble() < completionRate;

      case 'gradual_improvement':
        // Start lower, improve over time
        final progress = dayIndex / totalDays;
        final adjustedRate = completionRate * 0.6 + (completionRate * 0.4 * progress);
        return _random.nextDouble() < adjustedRate;

      case 'consistent':
        // High consistency with occasional misses
        return _random.nextDouble() < completionRate;

      case 'reduction_tracking':
        // For bad habits - track reduction (opposite logic)
        return _random.nextDouble() < completionRate;

      case 'varied_occurrences':
        // Varied pattern for occurrences
        return _random.nextDouble() < completionRate;

      case 'weekly_aggregation':
      case 'monthly_aggregation':
        // For period-based goals, we'll handle aggregation separately
        return _random.nextDouble() < completionRate;

      default:
        return _random.nextDouble() < completionRate;
    }
  }

  /// Generate realistic value for measurable habits
  static double _generateMeasurableValue(
    double goalValue,
    bool shouldComplete,
    String pattern,
    int dayIndex,
  ) {
    if (!shouldComplete) {
      // Below goal
      return goalValue * (0.3 + _random.nextDouble() * 0.4);
    }

    switch (pattern) {
      case 'gradual_improvement':
        // Gradually improve towards goal
        final progress = dayIndex / 100.0;
        final baseMultiplier = 0.7 + (progress * 0.3);
        return goalValue * (baseMultiplier + _random.nextDouble() * 0.2);

      case 'reduction_tracking':
        // For bad habits, track reduction (lower is better)
        return goalValue * (0.1 + _random.nextDouble() * 0.3);

      default:
        // Vary between 80-110% of goal
        return goalValue * (0.8 + _random.nextDouble() * 0.3);
    }
  }

  /// Generate occurrences list
  static List<String> _generateOccurrences(
    List<String> allOccurrences,
    String pattern,
  ) {
    if (pattern == 'varied_occurrences') {
      // Randomly select 1 to all occurrences
      final count = 1 + _random.nextInt(allOccurrences.length);
      final selected = <String>[];
      final shuffled = List<String>.from(allOccurrences)..shuffle(_random);
      for (int i = 0; i < count && i < shuffled.length; i++) {
        selected.add(shuffled[i]);
      }
      return selected;
    } else {
      // Select most occurrences
      final count = (allOccurrences.length * 0.7).round();
      return allOccurrences.take(count).toList();
    }
  }

  /// Load demo data into the app
  static Future<void> loadDemoData(HabitRepository repository) async {
    Log.info('loadDemoData() called');
    try {
      // Check if demo data already exists
      if (await hasDemoData(repository)) {
        Log.info('Demo data already exists, skipping creation');
        return;
      }

      // Load config from JSON
      final config = await _loadDemoConfig();
      final tagConfig = config['tag'] as Map<String, dynamic>;
      final habitsConfig = config['habits'] as List<dynamic>;

      // Create demo tag
      final demoTagId = await repository.createTag(
        db.TagsCompanion(
          name: drift.Value(_demoTagName),
          color: drift.Value(tagConfig['color'] as int),
          icon: drift.Value(tagConfig['icon'] as String),
        ),
      );

      final today = app_date_utils.DateUtils.getToday();

      // Create habits and entries from config
      for (final habitConfig in habitsConfig) {
        final habitData = habitConfig as Map<String, dynamic>;

        // Calculate creation date based on entries count
        // Each habit should be created when its first entry would have been
        // Spread habits out over time for more realism
        final entriesCount = habitData['entries'] as int;
        final daysAgo = entriesCount - 1; // First entry was (entries-1) days ago
        final creationDate = today.subtract(Duration(days: daysAgo));
        final createdAt = DateTime(
          creationDate.year,
          creationDate.month,
          creationDate.day,
        );

        // Parse habit type
        final habitTypeStr = habitData['habitType'] as String;
        final habitType = habitTypeStr == 'good' ? HabitType.good : HabitType.bad;

        // Parse tracking type
        final trackingTypeStr = habitData['trackingType'] as String;
        final trackingType = TrackingType.fromValue(trackingTypeStr);

        // Parse goal period if present
        GoalPeriod? goalPeriod;
        if (habitData.containsKey('goalPeriod')) {
          goalPeriod = GoalPeriod.fromValue(habitData['goalPeriod'] as String);
        }

        // Build habit companion
        final habitCompanion = db.HabitsCompanion(
          name: drift.Value(habitData['name'] as String),
          description: drift.Value(habitData['description'] as String),
          color: drift.Value(habitData['color'] as int),
          icon: drift.Value(habitData['icon'] as String),
          habitType: drift.Value(habitType.value),
          trackingType: drift.Value(trackingType.value),
          unit: habitData.containsKey('unit')
              ? drift.Value(habitData['unit'] as String)
              : const drift.Value.absent(),
          goalValue: habitData.containsKey('goalValue')
              ? drift.Value((habitData['goalValue'] as num).toDouble())
              : const drift.Value.absent(),
          goalPeriod: goalPeriod != null
              ? drift.Value(goalPeriod.value)
              : const drift.Value.absent(),
          occurrenceNames: habitData.containsKey('occurrenceNames')
              ? drift.Value(
                  (habitData['occurrenceNames'] as List<dynamic>)
                      .map((e) => e.toString())
                      .join(','),
                )
              : const drift.Value.absent(),
          reminderEnabled: habitData.containsKey('reminderEnabled')
              ? drift.Value(habitData['reminderEnabled'] as bool)
              : const drift.Value.absent(),
          reminderTime: habitData.containsKey('reminderTime')
              ? drift.Value(habitData['reminderTime'] as String)
              : const drift.Value.absent(),
          createdAt: drift.Value(createdAt),
          updatedAt: drift.Value(createdAt),
        );

        final habitId = await repository.createHabit(
          habitCompanion,
          tagIds: [demoTagId],
        );

        // Generate tracking entries
        final completionRate = (habitData['completionRate'] as num).toDouble();
        final pattern = habitData['pattern'] as String? ?? 'consistent';
        final goalValue = habitData.containsKey('goalValue')
            ? (habitData['goalValue'] as num).toDouble()
            : null;

        // Handle weekly/monthly aggregation differently
        if (trackingType == TrackingType.measurable &&
            goalPeriod != null &&
            (goalPeriod == GoalPeriod.weekly || goalPeriod == GoalPeriod.monthly)) {
          await _generatePeriodBasedEntries(
            repository,
            habitId,
            trackingType,
            today,
            createdAt,
            entriesCount,
            completionRate,
            goalValue!,
            goalPeriod,
            pattern,
          );
        } else {
          // Generate daily entries starting from creation date
          for (int i = 0; i < entriesCount; i++) {
            final date = createdAt.add(Duration(days: i));
            // Only create entries up to today
            if (date.isAfter(today)) break;
            
            final shouldComplete = _shouldComplete(
              pattern,
              i,
              entriesCount,
              completionRate,
            );

            if (trackingType == TrackingType.completed) {
              if (shouldComplete) {
                await repository.toggleCompletion(habitId, date, true);
              }
            } else if (trackingType == TrackingType.measurable) {
              final actualValue = _generateMeasurableValue(
                goalValue!,
                shouldComplete,
                pattern,
                i,
              );
              await repository.trackMeasurable(habitId, date, actualValue);
            } else if (trackingType == TrackingType.occurrences) {
              if (shouldComplete) {
                final occurrenceNames = (habitData['occurrenceNames'] as List<dynamic>)
                    .map((e) => e.toString())
                    .toList();
                final completedOccurrences = _generateOccurrences(
                  occurrenceNames,
                  pattern,
                );
                await repository.trackOccurrences(
                  habitId,
                  date,
                  completedOccurrences,
                );
              }
            }
          }
        }
      }

      Log.info('Demo data loaded successfully');
    } catch (e, stackTrace) {
      Log.error(
        'Error loading demo data',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Generate entries for weekly/monthly period-based goals
  static Future<void> _generatePeriodBasedEntries(
    HabitRepository repository,
    int habitId,
    TrackingType trackingType,
    DateTime today,
    DateTime createdAt,
    int totalDays,
    double completionRate,
    double goalValue,
    GoalPeriod goalPeriod,
    String pattern,
  ) async {
    if (goalPeriod == GoalPeriod.weekly) {
      // For weekly goals, distribute across the week starting from creation date
      final weeks = (totalDays / 7).ceil();
      for (int week = 0; week < weeks; week++) {
        final weekStart = createdAt.add(Duration(days: week * 7));
        final weekDays = <DateTime>[];
        for (int d = 0; d < 7; d++) {
          final date = weekStart.add(Duration(days: d));
          // Only create entries up to today
          if (date.isAfter(today)) break;
          weekDays.add(date);
        }
        if (weekDays.isEmpty) break;

        // Decide if week goal is met
        final weekShouldComplete = _random.nextDouble() < completionRate;
        final dailyTarget = goalValue / weekDays.length;
        if (weekShouldComplete) {
          // Distribute goal value across week days
          for (final date in weekDays) {
            final value = _generateMeasurableValue(
              dailyTarget,
              true,
              pattern,
              week * 7 + weekDays.indexOf(date),
            );
            await repository.trackMeasurable(habitId, date, value);
          }
        } else {
          // Some days with lower values
          final daysToTrack = (weekDays.length * 0.6).round();
          for (int i = 0; i < daysToTrack && i < weekDays.length; i++) {
            final value = _generateMeasurableValue(
              dailyTarget,
              false,
              pattern,
              week * 7 + i,
            );
            await repository.trackMeasurable(habitId, weekDays[i], value);
          }
        }
      }
    } else if (goalPeriod == GoalPeriod.monthly) {
      // For monthly goals, distribute across the month starting from creation date
      final months = (totalDays / 30).ceil();
      for (int month = 0; month < months; month++) {
        final monthStart = DateTime(
          createdAt.year,
          createdAt.month + month,
          1,
        );
        final monthEnd = DateTime(
          monthStart.year,
          monthStart.month + 1,
          0,
        );
        final monthDays = <DateTime>[];
        var currentDate = monthStart.isBefore(createdAt) ? createdAt : monthStart;
        while (currentDate.isBefore(monthEnd.add(const Duration(days: 1))) &&
            !currentDate.isAfter(today)) {
          monthDays.add(currentDate);
          currentDate = currentDate.add(const Duration(days: 1));
        }
        if (monthDays.isEmpty) break;

        // Decide if month goal is met
        final monthShouldComplete = _random.nextDouble() < completionRate;
        final dailyTarget = goalValue / monthDays.length;
        if (monthShouldComplete) {
          // Distribute goal value across month days
          for (final date in monthDays) {
            final value = _generateMeasurableValue(
              dailyTarget,
              true,
              pattern,
              month * 30 + monthDays.indexOf(date),
            );
            await repository.trackMeasurable(habitId, date, value);
          }
        } else {
          // Some days with lower values
          final daysToTrack = (monthDays.length * 0.5).round();
          for (int i = 0; i < daysToTrack && i < monthDays.length; i++) {
            final value = _generateMeasurableValue(
              dailyTarget,
              false,
              pattern,
              month * 30 + i,
            );
            await repository.trackMeasurable(habitId, monthDays[i], value);
          }
        }
      }
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

      Log.info('Demo data deleted successfully');
    } catch (e, stackTrace) {
      Log.error(
        'Error deleting demo data',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
