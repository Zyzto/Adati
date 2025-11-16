import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:io';
import '../widgets/calendar_grid.dart';
import '../widgets/timeline_stats.dart';
import '../../habits/widgets/habits_section.dart';
import '../../habits/providers/habit_providers.dart';
import '../../habits/widgets/habit_form_modal.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/services/demo_data_service.dart';
import '../../../core/services/preferences_service.dart';
import '../../../core/services/log_helper.dart';
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
                    ref.invalidate(habitsProvider);
                    ref.invalidate(tagsProvider);
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
          return Stack(
            children: [
              const SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [TimelineStats(), CalendarGrid(), HabitsSection()],
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
    Log.info('=== All Preferences ===');
    for (final key in allKeys) {
      final value = prefs.get(key);
      Log.info('$key: $value');
    }
    Log.info('Total preferences: ${allKeys.length}');
  }

  Future<void> _logAllHabits(db.AppDatabase database) async {
    final habitDao = HabitDao(database);
    final habits = await habitDao.getAllHabits();
    Log.info('=== All Habits ===');
    for (final habit in habits) {
      Log.info(
        'Habit ${habit.id}: ${habit.name} (type: ${habit.habitType}, color: ${habit.color}, icon: ${habit.icon})',
      );
    }
    Log.info('Total habits: ${habits.length}');
  }

  Future<void> _logAllTags(db.AppDatabase database) async {
    final tagDao = TagDao(database);
    final tags = await tagDao.getAllTags();
    Log.info('=== All Tags ===');
    for (final tag in tags) {
      Log.info('Tag ${tag.id}: ${tag.name} (color: ${tag.color})');
    }
    Log.info('Total tags: ${tags.length}');
  }

  Future<void> _logAllEntries(db.AppDatabase database) async {
    final entries = await database.select(database.trackingEntries).get();
    Log.info('=== All Tracking Entries ===');
    for (final entry in entries) {
      Log.info(
        'Entry: habitId=${entry.habitId}, date=${entry.date}, completed=${entry.completed}, notes=${entry.notes}',
      );
    }
    Log.info('Total entries: ${entries.length}');
  }

  Future<void> _logAllStreaks(db.AppDatabase database) async {
    final streaks = await database.select(database.streaks).get();
    Log.info('=== All Streaks ===');
    for (final streak in streaks) {
      Log.info(
        'Streak: habitId=${streak.habitId}, combined=${streak.combinedStreak}, good=${streak.goodStreak}, bad=${streak.badStreak}, current=${streak.currentStreak}, longest=${streak.longestStreak}',
      );
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
