import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:io';
import '../widgets/calendar_grid.dart';
import '../widgets/timeline_stats.dart';
import '../../habits/widgets/views/habits_section.dart';
import '../../habits/providers/habit_providers.dart';
import '../../habits/widgets/forms/habit_form_modal.dart';
import '../../settings/providers/settings_framework_providers.dart';
import '../../settings/settings_definitions.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/services/demo_data_service.dart';
import '../../../core/services/preferences_service.dart';
import 'package:flutter_logging_service/flutter_logging_service.dart';
import '../../../core/services/reminder_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/database/app_database.dart' as db;
import '../../../core/database/daos/habit_dao.dart';
import '../../../core/database/daos/tag_dao.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class MainTimelinePage extends ConsumerStatefulWidget {
  const MainTimelinePage({super.key});

  @override
  ConsumerState<MainTimelinePage> createState() => _MainTimelinePageState();
}

class _MainTimelinePageState extends ConsumerState<MainTimelinePage> {
  bool _showPerformanceIndicator = false;

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitsProvider);
    final hasDemoDataAsync = ref.watch(hasDemoDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('timeline'.tr()),
        actions: [
          // Delete demo data button (only visible when demo data exists)
          hasDemoDataAsync.when(
            data: (hasDemo) {
              if (hasDemo) {
                return IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'delete_demo_data'.tr(),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('delete_demo_data'.tr()),
                        content: Text('delete_demo_data_confirmation'.tr()),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text('cancel'.tr()),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text('delete'.tr()),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      final repository = ref.read(habitRepositoryProvider);
                      await DemoDataService.deleteDemoData(repository);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('demo_data_deleted'.tr())),
                        );
                      }
                    }
                  },
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          // Debug buttons (only in debug mode)
          if (kDebugMode)
            PopupMenuButton<String>(
              icon: const Icon(Icons.bug_report),
              tooltip: 'Debug Tools',
              onSelected: (value) async {
                final database = ref.read(databaseProvider);

                switch (value) {
                  case 'log_prefs':
                    await _logAllPreferences();
                    break;
                  case 'log_habits':
                    await _logAllHabits(database);
                    break;
                  case 'log_tags':
                    await _logAllTags(database);
                    break;
                  case 'log_entries':
                    await _logAllEntries(database);
                    break;
                  case 'log_streaks':
                    await _logAllStreaks(database);
                    break;
                  case 'db_path':
                    _showDatabasePath(context, database);
                    break;
                  case 'refresh':
                    // Invalidate all relevant stream providers
                    ref.invalidate(habitsProvider);
                    ref.invalidate(tagsProvider);
                    ref.invalidate(filteredSortedHabitsProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Providers refreshed')),
                      );
                    }
                    break;
                  case 'performance':
                    setState(() {
                      _showPerformanceIndicator = !_showPerformanceIndicator;
                    });
                    break;
                  case 'test_reminder':
                    await _testReminderSystem(context, ref);
                    break;
                  case 'test_notification_30s':
                    await _testNotificationIn30Seconds(context, ref);
                    break;
                  case 'reschedule_reminders':
                    await _rescheduleAllReminders(context, ref);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'log_prefs',
                  child: Row(
                    children: [
                      Icon(Icons.settings, size: 20),
                      SizedBox(width: 12),
                      Text('Log All Preferences'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'log_habits',
                  child: Row(
                    children: [
                      Icon(Icons.list, size: 20),
                      SizedBox(width: 12),
                      Text('Log All Habits'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'log_tags',
                  child: Row(
                    children: [
                      Icon(Icons.label, size: 20),
                      SizedBox(width: 12),
                      Text('Log All Tags'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'log_entries',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 20),
                      SizedBox(width: 12),
                      Text('Log All Entries'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'log_streaks',
                  child: Row(
                    children: [
                      Icon(Icons.local_fire_department, size: 20),
                      SizedBox(width: 12),
                      Text('Log All Streaks'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'db_path',
                  child: Row(
                    children: [
                      Icon(Icons.storage, size: 20),
                      SizedBox(width: 12),
                      Text('Database Path'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'refresh',
                  child: Row(
                    children: [
                      Icon(Icons.refresh, size: 20),
                      SizedBox(width: 12),
                      Text('Force Refresh'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'performance',
                  child: Row(
                    children: [
                      Icon(Icons.speed, size: 20),
                      SizedBox(width: 12),
                      Text('Performance Indicator'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'test_reminder',
                  child: Row(
                    children: [
                      Icon(Icons.notifications_active, size: 20),
                      SizedBox(width: 12),
                      Text('Test Reminder (Immediate)'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'test_notification_30s',
                  child: Row(
                    children: [
                      Icon(Icons.timer, size: 20),
                      SizedBox(width: 12),
                      Text('Test Notification (30s)'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'reschedule_reminders',
                  child: Row(
                    children: [
                      Icon(Icons.schedule, size: 20),
                      SizedBox(width: 12),
                      Text('Reschedule All Reminders'),
                    ],
                  ),
                ),
              ],
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: habitsAsync.when(
        data: (habits) {
          if (habits.isEmpty) {
            // Show unified empty state
            final theme = Theme.of(context);
            return EmptyStateWidget(
              icon: Icons.timeline,
              title: 'no_habits_title'.tr(),
              message: 'no_habits_message'.tr(),
              actions: [
                FilledButton.icon(
                  onPressed: () => HabitFormModal.show(context),
                  icon: const Icon(Icons.add, size: 24),
                  label: Text(
                    'create_habit'.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                ),
              ],
            );
          }

          // Show normal layout when habits exist
          final settings = ref.watch(adatiSettingsProvider);
          final showStatisticsCard = ref.watch(settings.provider(showStatisticsCardSettingDef));
          final showMainTimeline = ref.watch(settings.provider(showMainTimelineSettingDef));
          
          return Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showStatisticsCard) const TimelineStats(),
                    if (showMainTimeline) const CalendarGrid(),
                    const HabitsSection(),
                  ],
                ),
              ),
              // Performance indicator overlay
              if (_showPerformanceIndicator)
                Positioned(
                  top: 8,
                  right: 8,
                  child: _PerformanceIndicator(),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('${'error'.tr()}: $error')),
      ),
    );
  }

  // Debug helper methods
  Future<void> _logAllPreferences() async {
    final prefs = PreferencesService.prefs;
    final allKeys = prefs.getKeys();
    Log.info('=== All Preferences (Raw SharedPreferences) ===');
    for (final key in allKeys) {
      final value = prefs.get(key);
      Log.info('$key: $value');
    }
    Log.info('Total preferences: ${allKeys.length}');
    
    // Also log current provider values for key settings
    Log.info('=== Current Provider Values ===');
    final settings = ref.read(adatiSettingsProvider);
    final themeModeStr = ref.read(settings.provider(themeModeSettingDef));
    Log.info('Theme Mode: $themeModeStr');
    Log.info('Theme Color: 0x${ref.read(settings.provider(themeColorSettingDef)).toRadixString(16).toUpperCase()}');
    Log.info('Card Elevation: ${ref.read(settings.provider(cardElevationSettingDef))}');
    Log.info('Card Border Radius: ${ref.read(settings.provider(cardBorderRadiusSettingDef))}');
    Log.info('Card Spacing: ${ref.read(settings.provider(cardSpacingSettingDef))}');
    Log.info('Font Size Scale: ${ref.read(settings.provider(fontSizeScaleSettingDef))}');
    Log.info('Icon Size: ${ref.read(settings.provider(iconSizeSettingDef))}');
    Log.info('Timeline Days: ${ref.read(settings.provider(timelineDaysSettingDef))}');
    Log.info('Modal Timeline Days: ${ref.read(settings.provider(modalTimelineDaysSettingDef))}');
    Log.info('Habit Card Timeline Days: ${ref.read(settings.provider(habitCardTimelineDaysSettingDef))}');
    Log.info('Timeline Spacing: ${ref.read(settings.provider(timelineSpacingSettingDef))}');
    Log.info('Timeline Compact Mode: ${ref.read(settings.provider(timelineCompactModeSettingDef))}');
    Log.info('Main Timeline Fill Lines: ${ref.read(settings.provider(mainTimelineFillLinesSettingDef))}');
    Log.info('Main Timeline Lines: ${ref.read(settings.provider(mainTimelineLinesSettingDef))}');
    Log.info('Habit Card Timeline Fill Lines: ${ref.read(settings.provider(habitCardTimelineFillLinesSettingDef))}');
    Log.info('Habit Card Timeline Lines: ${ref.read(settings.provider(habitCardTimelineLinesSettingDef))}');
    Log.info('Show Statistics Card: ${ref.read(settings.provider(showStatisticsCardSettingDef))}');
    Log.info('Show Main Timeline: ${ref.read(settings.provider(showMainTimelineSettingDef))}');
    Log.info('Habits Layout Mode: ${ref.read(settings.provider(habitsLayoutModeSettingDef))}');
    Log.info('Habit Sort Order: ${ref.read(settings.provider(habitSortOrderSettingDef))}');
    Log.info('Bad Habit Logic Mode: ${ref.read(settings.provider(badHabitLogicModeSettingDef))}');
    Log.info('--- Grid Settings ---');
    Log.info('Grid Show Icon: ${ref.read(settings.provider(gridShowIconSettingDef))}');
    Log.info('Grid Show Completion: ${ref.read(settings.provider(gridShowCompletionSettingDef))}');
    Log.info('Grid Show Timeline: ${ref.read(settings.provider(gridShowTimelineSettingDef))}');
    Log.info('Grid Completion Button Placement: ${ref.read(settings.provider(gridCompletionButtonPlacementSettingDef))}');
    Log.info('Grid Timeline Box Size: ${ref.read(settings.provider(gridTimelineBoxSizeSettingDef))}');
    Log.info('Grid Timeline Fit Mode: ${ref.read(settings.provider(gridTimelineFitModeSettingDef))}');
    Log.info('--- Display Settings ---');
    Log.info('Show Descriptions: ${ref.read(settings.provider(showDescriptionsSettingDef))}');
    Log.info('Show Streak On Card: ${ref.read(settings.provider(showStreakOnCardSettingDef))}');
    Log.info('Show Streak Borders: ${ref.read(settings.provider(showStreakBordersSettingDef))}');
    Log.info('Compact Cards: ${ref.read(settings.provider(compactCardsSettingDef))}');
    Log.info('Day Square Size: ${ref.read(settings.provider(daySquareSizeSettingDef))}');
    Log.info('Use Streak Colors for Squares: ${ref.read(settings.provider(useStreakColorsForSquaresSettingDef))}');
  }

  Future<void> _logAllHabits(db.AppDatabase database) async {
    final habitDao = HabitDao(database);
    final habits = await habitDao.getAllHabits();
    Log.info('=== All Habits ===');
    if (habits.isEmpty) {
      Log.info('No habits found');
      return;
    }
    for (final habit in habits) {
      Log.info(
        'Habit ${habit.id}: ${habit.name}',
      );
      Log.info('  Type: ${habit.habitType}');
      Log.info('  Color: 0x${habit.color.toRadixString(16).toUpperCase()}');
      Log.info('  Icon: ${habit.icon}');
      Log.info('  Description: ${habit.description ?? "N/A"}');
      Log.info('  Created: ${habit.createdAt}');
      Log.info('  Updated: ${habit.updatedAt}');
    }
    Log.info('Total habits: ${habits.length}');
  }

  Future<void> _logAllTags(db.AppDatabase database) async {
    final tagDao = TagDao(database);
    final tags = await tagDao.getAllTags();
    Log.info('=== All Tags ===');
    if (tags.isEmpty) {
      Log.info('No tags found');
      return;
    }
    for (final tag in tags) {
      Log.info('Tag ${tag.id}: ${tag.name}');
      Log.info('  Color: 0x${tag.color.toRadixString(16).toUpperCase()}');
      Log.info('  Icon: ${tag.icon ?? "N/A"}');
    }
    Log.info('Total tags: ${tags.length}');
  }

  Future<void> _logAllEntries(db.AppDatabase database) async {
    final entries = await database.select(database.trackingEntries).get();
    Log.info('=== All Tracking Entries ===');
    if (entries.isEmpty) {
      Log.info('No tracking entries found');
      return;
    }
    // Group by habit for better readability
    final entriesByHabit = <int, List<db.TrackingEntry>>{};
    for (final entry in entries) {
      entriesByHabit.putIfAbsent(entry.habitId, () => []).add(entry);
    }
    Log.info('Entries grouped by habit:');
    for (final habitId in entriesByHabit.keys) {
      final habitEntries = entriesByHabit[habitId]!;
      Log.info('  Habit $habitId: ${habitEntries.length} entries');
      for (final entry in habitEntries.take(5)) {
        Log.info(
          '    ${entry.date}: ${entry.completed ? "✓" : "✗"} ${entry.notes?.isNotEmpty == true ? "(${entry.notes})" : ""}',
        );
      }
      if (habitEntries.length > 5) {
        Log.info('    ... and ${habitEntries.length - 5} more');
      }
    }
    Log.info('Total entries: ${entries.length}');
  }

  Future<void> _logAllStreaks(db.AppDatabase database) async {
    final streaks = await database.select(database.streaks).get();
    Log.info('=== All Streaks ===');
    if (streaks.isEmpty) {
      Log.info('No streaks found');
      return;
    }
    for (final streak in streaks) {
      Log.info('Streak for Habit ${streak.habitId}:');
      Log.info('  Combined Current: ${streak.combinedStreak}');
      Log.info('  Combined Longest: ${streak.combinedLongestStreak}');
      Log.info('  Good Current: ${streak.goodStreak}');
      Log.info('  Good Longest: ${streak.goodLongestStreak}');
      Log.info('  Bad Current: ${streak.badStreak}');
      Log.info('  Bad Longest: ${streak.badLongestStreak}');
      Log.info('  Last Updated: ${streak.lastUpdated}');
    }
    Log.info('Total streaks: ${streaks.length}');
  }

  Future<void> _showDatabasePath(BuildContext context, db.AppDatabase database) async {
    try {
      // Get database path from documents directory
      final dbFolder = await getApplicationDocumentsDirectory();
      final path = p.join(dbFolder.path, 'adati.db');
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Database Path'),
            content: SelectableText(path),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _testReminderSystem(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      // Check if notifications are available
      final isAvailable = NotificationService.isAvailable();
      Log.info('NotificationService available: $isAvailable');

      // Show immediate test notification (better for testing)
      await NotificationService.showNotification(
        id: 999999, // Use a high ID that won't conflict
        title: 'Test Reminder',
        body: 'This is a test reminder from the debug menu',
        payload: 'test',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAvailable
                  ? 'Test notification shown'
                  : 'Test notification shown (notifications may not be available on this platform)',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }

      Log.info('Test notification shown');
    } catch (e, stackTrace) {
      Log.error(
        'Failed to schedule test reminder',
        error: e,
        stackTrace: stackTrace,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scheduling test reminder: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _testNotificationIn30Seconds(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      // Check if notifications are available
      final isAvailable = NotificationService.isAvailable();
      if (!isAvailable) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notifications not available on this platform'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Calculate time 30 seconds from now
      final scheduledTime = DateTime.now().add(const Duration(seconds: 30));
      
      Log.info('Scheduling test notification for ${scheduledTime.toString()}');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Test notification scheduled for 30 seconds (${scheduledTime.hour}:${scheduledTime.minute.toString().padLeft(2, '0')}:${scheduledTime.second.toString().padLeft(2, '0')})',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // Use a timer to show the notification after 30 seconds
      // This works on all platforms including Android
      Future.delayed(const Duration(seconds: 30), () async {
        try {
          await NotificationService.showNotification(
            id: 999998, // Use a different high ID
            title: 'Test Notification (30s)',
            body: 'This is a test notification scheduled 30 seconds ago from the debug menu',
            payload: 'test_30s',
          );
          Log.info('Test notification (30s) shown successfully');
        } catch (e, stackTrace) {
          Log.error(
            'Failed to show test notification (30s)',
            error: e,
            stackTrace: stackTrace,
          );
        }
      });
    } catch (e, stackTrace) {
      Log.error(
        'Failed to schedule test notification (30s)',
        error: e,
        stackTrace: stackTrace,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scheduling test notification: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rescheduleAllReminders(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      final repository = ref.read(habitRepositoryProvider);
      ReminderService.init(repository);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rescheduling all reminders...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      await ReminderService.rescheduleAllReminders();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All reminders rescheduled successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      Log.info('All reminders rescheduled from debug menu');
    } catch (e, stackTrace) {
      Log.error(
        'Failed to reschedule reminders',
        error: e,
        stackTrace: stackTrace,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rescheduling reminders: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Performance indicator widget that shows FPS and memory usage
class _PerformanceIndicator extends StatefulWidget {
  const _PerformanceIndicator();

  @override
  State<_PerformanceIndicator> createState() => _PerformanceIndicatorState();
}

class _PerformanceIndicatorState extends State<_PerformanceIndicator>
    with SingleTickerProviderStateMixin {
  int _frameCount = 0;
  DateTime _lastTime = DateTime.now();
  double _fps = 0.0;
  String _memoryInfo = '';

  @override
  void initState() {
    super.initState();
    _updateMemoryInfo();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startFpsCounter();
    });
  }

  void _startFpsCounter() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _frameCount++;
      final now = DateTime.now();
      final elapsed = now.difference(_lastTime).inMilliseconds;
      if (elapsed >= 1000) {
        setState(() {
          _fps = (_frameCount * 1000) / elapsed;
          _frameCount = 0;
          _lastTime = now;
        });
        _updateMemoryInfo();
      }
      _startFpsCounter();
    });
  }

  void _updateMemoryInfo() {
    // Get memory info if available
    if (Platform.isAndroid || Platform.isIOS) {
      // Memory info would require platform channels
      _memoryInfo = 'N/A';
    } else {
      _memoryInfo = 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FPS: ${_fps.toStringAsFixed(1)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
          if (_memoryInfo.isNotEmpty)
            Text(
              'Memory: $_memoryInfo',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
        ],
      ),
    );
  }
}
