import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/database/app_database.dart' as db;
import '../../../../core/database/models/tracking_types.dart';
import '../providers/tracking_providers.dart';
import '../../../../core/utils/date_utils.dart' as app_date_utils;
import '../providers/habit_providers.dart';
import '../widgets/habit_timeline.dart';
import '../pages/habit_detail_page.dart';
import 'checkbox_style.dart';
import '../../settings/providers/settings_providers.dart';
import '../../../../core/widgets/skeleton_loader.dart';

class HabitCard extends ConsumerWidget {
  final db.Habit habit;

  const HabitCard({super.key, required this.habit});

  Future<void> _toggleTodayCompletion(
    BuildContext context,
    WidgetRef ref,
  ) async {
    HapticFeedback.mediumImpact();
    final repository = ref.read(habitRepositoryProvider);
    final today = app_date_utils.DateUtils.getToday();
    final trackingType = TrackingType.fromValue(habit.trackingType);

    // Get current status
    final entry = await repository.getEntry(habit.id, today);
    final isCompleted = entry?.completed ?? false;

    // Handle different tracking types
    if (trackingType == TrackingType.completed) {
      // Simple toggle for completed tracking
      await repository.toggleCompletion(habit.id, today, !isCompleted);
    } else if (trackingType == TrackingType.measurable) {
      // For measurable, open input dialog
      if (context.mounted) {
        _showMeasurableInputDialog(context, ref, entry);
      }
    } else if (trackingType == TrackingType.occurrences) {
      // For occurrences, open selection dialog
      if (context.mounted) {
        _showOccurrencesInputDialog(context, ref, entry);
      }
    }
  }

  void _showMeasurableInputDialog(
    BuildContext context,
    WidgetRef ref,
    db.TrackingEntry? entry,
  ) {
    final repository = ref.read(habitRepositoryProvider);
    final today = app_date_utils.DateUtils.getToday();
    final currentValue = entry?.value ?? 0.0;
    final unit = habit.unit ?? '';
    final goalValue = habit.goalValue;

    final controller = TextEditingController(
      text: currentValue > 0 ? currentValue.toString() : '',
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(habit.name),
          content: _buildMeasurableDialogContent(
            context,
            controller,
            currentValue,
            unit,
            goalValue,
            setDialogState,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('cancel'.tr()),
            ),
            TextButton(
              onPressed: () async {
                final value = double.tryParse(controller.text.trim()) ?? 0.0;
                await repository.trackMeasurable(habit.id, today, value);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: Text('save'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurableDialogContent(
    BuildContext context,
    TextEditingController controller,
    double currentValue,
    String unit,
    double? goalValue,
    StateSetter setDialogState,
  ) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (goalValue != null && goalValue > 0) ...[
            _buildQuickActionsRow(
              context,
              controller,
              goalValue,
              setDialogState,
            ),
            const SizedBox(height: 16),
          ],
          _buildValueInputRow(
            context,
            controller,
            unit,
            goalValue,
            setDialogState,
          ),
          if (goalValue != null) ...[
            const SizedBox(height: 16),
            _buildProgressIndicator(
              context,
              controller,
              currentValue,
              goalValue,
              unit,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActionsRow(
    BuildContext context,
    TextEditingController controller,
    double goalValue,
    StateSetter setDialogState,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'quick_actions'.tr(),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: _buildQuickActionButton(
                context,
                '25%',
                goalValue * 0.25,
                controller,
                setDialogState,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildQuickActionButton(
                context,
                '50%',
                goalValue * 0.5,
                controller,
                setDialogState,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildQuickActionButton(
                context,
                '75%',
                goalValue * 0.75,
                controller,
                setDialogState,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildQuickActionButton(
                context,
                '100%',
                goalValue,
                controller,
                setDialogState,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildValueInputRow(
    BuildContext context,
    TextEditingController controller,
    String unit,
    double? goalValue,
    StateSetter setDialogState,
  ) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.remove),
          onPressed: () {
            final current = double.tryParse(controller.text.trim()) ?? 0.0;
            final step = 1.0;
            final newValue = (current - step).clamp(0.0, double.infinity);
            controller.text = newValue.toStringAsFixed(
              newValue % 1 == 0 ? 0 : 1,
            );
            setDialogState(() {});
          },
        ),
        Expanded(
          child: TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              labelText: 'value'.tr(),
              suffixText: unit.isNotEmpty ? unit : null,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => setDialogState(() {}),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () {
            final current = double.tryParse(controller.text.trim()) ?? 0.0;
            final step = 1.0;
            final newValue = current + step;
            controller.text = newValue.toStringAsFixed(
              newValue % 1 == 0 ? 0 : 1,
            );
            setDialogState(() {});
          },
        ),
      ],
    );
  }

  Widget _buildProgressIndicator(
    BuildContext context,
    TextEditingController controller,
    double currentValue,
    double goalValue,
    String unit,
  ) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        final inputValue = double.tryParse(value.text.trim()) ?? currentValue;
        final percentage = (inputValue / goalValue * 100).clamp(
          0.0,
          double.infinity,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'progress'.tr(),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: percentage > 100 ? 1.0 : percentage / 100,
              backgroundColor: Colors.grey[300],
            ),
            const SizedBox(height: 4),
            Text(
              '${inputValue.toStringAsFixed(1)} / ${goalValue.toStringAsFixed(1)} $unit (${percentage.toStringAsFixed(0)}%)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context,
    String label,
    double value,
    TextEditingController controller,
    StateSetter setDialogState,
  ) {
    return OutlinedButton(
      onPressed: () {
        controller.text = value.toStringAsFixed(value % 1 == 0 ? 0 : 1);
        setDialogState(() {});
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(60, 36),
      ),
      child: Text(label),
    );
  }

  void _showOccurrencesInputDialog(
    BuildContext context,
    WidgetRef ref,
    db.TrackingEntry? entry,
  ) {
    final repository = ref.read(habitRepositoryProvider);
    final today = app_date_utils.DateUtils.getToday();

    List<String> occurrenceNames = [];
    if (habit.occurrenceNames != null && habit.occurrenceNames!.isNotEmpty) {
      try {
        occurrenceNames = List<String>.from(jsonDecode(habit.occurrenceNames!));
      } catch (e) {
        occurrenceNames = [];
      }
    }

    if (occurrenceNames.isEmpty) {
      _showNoOccurrencesDialog(context);
      return;
    }

    List<String> selectedOccurrences = [];
    if (entry?.occurrenceData != null && entry!.occurrenceData!.isNotEmpty) {
      try {
        selectedOccurrences = List<String>.from(
          jsonDecode(entry.occurrenceData!),
        );
      } catch (e) {
        selectedOccurrences = [];
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(habit.name),
          content: _buildOccurrencesDialogContent(
            context,
            occurrenceNames,
            selectedOccurrences,
            setDialogState,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('cancel'.tr()),
            ),
            TextButton(
              onPressed: () async {
                await repository.trackOccurrences(
                  habit.id,
                  today,
                  selectedOccurrences,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: Text('save'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  void _showNoOccurrencesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('no_occurrences'.tr()),
        content: Text('please_define_occurrences'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ok'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildOccurrencesDialogContent(
    BuildContext context,
    List<String> occurrenceNames,
    List<String> selectedOccurrences,
    StateSetter setDialogState,
  ) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'select_occurrences'.tr(),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 12),
          ...occurrenceNames.map((name) {
            final isSelected = selectedOccurrences.contains(name);
            return CheckboxListTile(
              title: Text(name),
              value: isSelected,
              onChanged: (value) {
                setDialogState(() {
                  if (value == true) {
                    selectedOccurrences.add(name);
                  } else {
                    selectedOccurrences.remove(name);
                  }
                });
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTrackingDisplay(
    BuildContext context,
    WidgetRef ref,
    db.TrackingEntry? entry,
  ) {
    final trackingType = TrackingType.fromValue(habit.trackingType);

    if (trackingType == TrackingType.completed) {
      // Completed tracking - show checkmark
      final isCompleted = entry?.completed ?? false;
      final checkboxStyleString = ref.watch(habitCheckboxStyleProvider);
      final checkboxStyle = habitCheckboxStyleFromString(checkboxStyleString);

      final isGoodHabit = habit.habitType == HabitType.good.value;
      final habitCardCompletionColor = isGoodHabit
          ? ref.watch(habitCardCompletionColorProvider)
          : ref.watch(habitCardBadHabitCompletionColorProvider);
      return IgnorePointer(
        child: buildCheckboxWidget(
          checkboxStyle,
          isCompleted,
          36,
          null, // onTap is handled by parent InkWell
          completionColor: Color(habitCardCompletionColor),
        ),
      );
    } else if (trackingType == TrackingType.measurable) {
      // Measurable tracking - show progress percentage
      final value = entry?.value ?? 0.0;
      final goalValue = habit.goalValue;
      final unit = habit.unit ?? '';

      if (goalValue != null && goalValue > 0) {
        final percentage = (value / goalValue * 100).clamp(
          0.0,
          double.infinity,
        );
        return IgnorePointer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 36,
                height: 36,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: percentage > 100 ? 1.0 : percentage / 100,
                      backgroundColor: Colors.grey[300],
                      strokeWidth: 3,
                    ),
                    Text(
                      '${percentage.toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              if (value > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${value.toStringAsFixed(1)} $unit',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        );
      } else {
        // No goal set, just show value
        return IgnorePointer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                value > 0 ? Icons.check_circle : Icons.circle_outlined,
                color: value > 0 ? Colors.green : Colors.grey,
                size: 36,
              ),
              if (value > 0)
                Text(
                  '${value.toStringAsFixed(1)} $unit',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        );
      }
    } else if (trackingType == TrackingType.occurrences) {
      // Occurrences tracking - show count/names
      List<String> completedOccurrences = [];
      if (entry?.occurrenceData != null && entry!.occurrenceData!.isNotEmpty) {
        try {
          completedOccurrences = List<String>.from(
            jsonDecode(entry.occurrenceData!),
          );
        } catch (e) {
          completedOccurrences = [];
        }
      }

      List<String> allOccurrences = [];
      if (habit.occurrenceNames != null && habit.occurrenceNames!.isNotEmpty) {
        try {
          allOccurrences = List<String>.from(
            jsonDecode(habit.occurrenceNames!),
          );
        } catch (e) {
          allOccurrences = [];
        }
      }

      return IgnorePointer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              completedOccurrences.isNotEmpty
                  ? Icons.check_circle
                  : Icons.circle_outlined,
              color: completedOccurrences.isNotEmpty
                  ? Colors.green
                  : Colors.grey,
              size: 36,
            ),
            const SizedBox(height: 4),
            Text(
              '${completedOccurrences.length}/${allOccurrences.length}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (completedOccurrences.isNotEmpty &&
                completedOccurrences.length <= 3)
              ...completedOccurrences.map(
                (name) => Text(
                  name,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      );
    }

    // Fallback
    return const SizedBox.shrink();
  }

  Widget _buildCardContent(BuildContext context, WidgetRef ref) {
    final sessionOptions = ref.watch(sessionViewOptionsProvider);
    final globalShowDescriptions = ref.watch(showDescriptionsProvider);
    final showDescriptions =
        sessionOptions.showDescriptions ?? globalShowDescriptions;
    final showStreakOnCard = ref.watch(showStreakOnCardProvider);
    final iconSize = ref.watch(iconSizeProvider);
    final globalCompactCards = ref.watch(compactCardsProvider);
    final compactCards = sessionOptions.compactCards ?? globalCompactCards;
    final streakAsync = ref.watch(streakProvider(habit.id));
    final tagsAsync = ref.watch(habitTagsProvider(habit.id));

    // Calculate icon size
    double iconSizeValue;
    switch (iconSize) {
      case 'small':
        iconSizeValue = 32;
        break;
      case 'large':
        iconSizeValue = 48;
        break;
      case 'medium':
      default:
        iconSizeValue = 40;
        break;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon - Title row
        Row(
          children: [
            // Icon
            Container(
              width: iconSizeValue,
              height: iconSizeValue,
              decoration: BoxDecoration(
                color: Color(habit.color),
                borderRadius: BorderRadius.circular(8),
              ),
              child: habit.icon != null
                  ? Icon(
                      IconData(
                        int.parse(habit.icon!),
                        fontFamily: 'MaterialIcons',
                      ),
                      color: Colors.white,
                      size: iconSizeValue * 0.6,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            // Title and Streak
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    habit.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (showStreakOnCard)
                    streakAsync.maybeWhen(
                      data: (streak) {
                        if (streak != null && streak.combinedStreak > 0) {
                          return Text(
                            '${'streak'.tr()}: ${streak.combinedStreak}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      orElse: () => const SizedBox.shrink(),
                    ),
                ],
              ),
            ),
          ],
        ),
        // Description
        if (showDescriptions &&
            habit.description != null &&
            habit.description!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            habit.description!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            maxLines: compactCards ? 1 : 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        // Tags
        if (sessionOptions.showTags ?? true)
          tagsAsync.when(
            data: (tags) {
              if (tags.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: tags.take(3).map((tag) {
                    return Chip(
                      label: Text(
                        tag.name,
                        style: TextStyle(fontSize: compactCards ? 10 : 12),
                      ),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        // Timeline visualization (disabled clicks)
        SizedBox(height: compactCards ? 8 : 16),
        HabitTimeline(
          habitId: habit.id,
          compact: compactCards || ref.watch(timelineCompactModeProvider),
          daysToShow: ref.watch(habitCardTimelineDaysProvider),
        ),
      ],
    );
  }

  Color _getStreakColor(WidgetRef ref, int streakLength) {
    final scheme = ref.watch(streakColorSchemeProvider);
    return _getStreakColorForLength(streakLength, scheme);
  }

  Color _getStreakColorForLength(int length, String scheme) {
    Color baseColor;
    
    // Determine base color based on streak length
    if (length >= 30) {
      baseColor = Colors.purple; // Longest streaks
    } else if (length >= 14) {
      baseColor = Colors.orange; // Medium streaks
    } else if (length >= 7) {
      baseColor = Colors.amber; // Short streaks
    } else {
      baseColor = Colors.green; // Very short streaks
    }
    
    // Apply color scheme transformation
    switch (scheme) {
      case 'vibrant':
        // More saturated, brighter colors
        return Color.fromARGB(
          255,
          ((baseColor.r * 255.0 * 1.2).clamp(0, 255)).round(),
          ((baseColor.g * 255.0 * 1.2).clamp(0, 255)).round(),
          ((baseColor.b * 255.0 * 1.2).clamp(0, 255)).round(),
        );
      case 'subtle':
        // Muted, desaturated colors
        final gray = ((baseColor.r * 255.0 * 0.299 + baseColor.g * 255.0 * 0.587 + baseColor.b * 255.0 * 0.114)).round();
        return Color.fromARGB(
          255,
          ((gray + baseColor.r * 255.0) / 2).clamp(0, 255).round(),
          ((gray + baseColor.g * 255.0) / 2).clamp(0, 255).round(),
          ((gray + baseColor.b * 255.0) / 2).clamp(0, 255).round(),
        );
      case 'monochrome':
        // Grayscale
        final gray = ((baseColor.r * 255.0 * 0.299 + baseColor.g * 255.0 * 0.587 + baseColor.b * 255.0 * 0.114)).round();
        return Color.fromARGB(255, gray, gray, gray);
      case 'default':
      default:
        return baseColor;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayEntryAsync = ref.watch(todayEntryProvider(habit.id));
    final streakAsync = ref.watch(streakProvider(habit.id));
    final entriesAsync = ref.watch(trackingEntriesProvider(habit.id));
    final isGoodHabit = habit.habitType == HabitType.good.value;
    final showStreakBorders = ref.watch(showStreakBordersProvider);
    final cardSpacing = ref.watch(cardSpacingProvider);

    final habitCardCompletionColor = isGoodHabit
        ? ref.watch(habitCardCompletionColorProvider)
        : ref.watch(habitCardBadHabitCompletionColorProvider);

    return Card(
      margin: EdgeInsets.only(bottom: cardSpacing),
      shape: streakAsync.maybeWhen(
        data: (streak) {
          // Show border with completion color when today is completed, or with streak color if streak borders are enabled
          return entriesAsync.maybeWhen(
            data: (entries) {
              final today = app_date_utils.DateUtils.getToday();
              final todayEntry = entries
                  .where(
                    (e) => app_date_utils.DateUtils.isSameDay(e.date, today),
                  )
                  .firstOrNull;

              final isTodayCompleted = todayEntry?.completed ?? false;

              // For good habits: today must be completed for streak to be active
              // For bad habits: today must NOT be completed (not doing bad habit) for streak to be active
              // If there's no entry for today, we can't assume it's part of the streak
              bool todayIsPartOfStreak = false;
              if (todayEntry != null) {
                todayIsPartOfStreak = isGoodHabit
                    ? todayEntry.completed
                    : !todayEntry.completed;
              }

              // Border logic: show border when checked/completed (same for good and bad habits)
              // - Good habits: border when completed (they did the good thing)
              // - Bad habits: border when completed (they did the bad thing - checked)
              final shouldShowCompletionBorder = isTodayCompleted;

              // Priority: Completion color border (if applicable) > Streak border (if enabled and streak active)
              if (shouldShowCompletionBorder) {
                // Show border with completion color
                return RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Color(habitCardCompletionColor),
                    width: 2,
                  ),
                );
              } else if (showStreakBorders &&
                  streak != null &&
                  streak.combinedStreak > 0 &&
                  todayIsPartOfStreak) {
                // Show streak color border if streak borders are enabled and streak is active
                final streakColor = _getStreakColor(ref, streak.combinedStreak);
                return RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: streakColor, width: 2),
                );
              }
              return RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              );
            },
            orElse: () =>
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          );
        },
        orElse: () {
          // When streak data is not available, check if today is completed
          return entriesAsync.maybeWhen(
            data: (entries) {
              final today = app_date_utils.DateUtils.getToday();
              final todayEntry = entries
                  .where(
                    (e) => app_date_utils.DateUtils.isSameDay(e.date, today),
                  )
                  .firstOrNull;
              final isTodayCompleted = todayEntry?.completed ?? false;

              // Border logic: show border when checked/completed (same for good and bad habits)
              // - Good habits: border when completed (they did the good thing)
              // - Bad habits: border when completed (they did the bad thing - checked)
              final shouldShowCompletionBorder = isTodayCompleted;

              if (shouldShowCompletionBorder) {
                return RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Color(habitCardCompletionColor),
                    width: 2,
                  ),
                );
              }
              return RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              );
            },
            orElse: () =>
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          );
        },
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: InkWell(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (context) => HabitDetailPage(habitId: habit.id),
                  );
                },
                hoverColor: Colors.transparent,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildCardContent(context, ref),
                ),
              ),
            ),
            // Tracking display button - fills entire height
            todayEntryAsync.when(
              data: (isCompleted) {
                // Get entry from tracking entries stream
                final entriesAsync = ref.watch(
                  trackingEntriesProvider(habit.id),
                );

                return entriesAsync.when(
                  data: (entries) {
                    final today = app_date_utils.DateUtils.getToday();
                    final entry = entries
                        .where(
                          (e) =>
                              app_date_utils.DateUtils.isSameDay(e.date, today),
                        )
                        .firstOrNull;

                    return Material(
                      color: Colors.transparent,
                      child: Semantics(
                        label: 'track_habit'.tr(),
                        button: true,
                        child: InkWell(
                          onTap: () => _toggleTodayCompletion(context, ref),
                          hoverColor: Colors.transparent,
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          child: Container(
                            width: 96,
                            constraints: const BoxConstraints(minHeight: 44),
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(8),
                            child: _buildTrackingDisplay(context, ref, entry),
                          ),
                        ),
                      ),
                    );
                  },
                  loading: () => Container(
                    width: 96,
                    alignment: Alignment.center,
                    child: SkeletonLoader(
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  error: (_, _) => Material(
                    color: Colors.transparent,
                    child: Semantics(
                      label: 'track_habit'.tr(),
                      button: true,
                      child: InkWell(
                        onTap: () => _toggleTodayCompletion(context, ref),
                        hoverColor: Colors.transparent,
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        child: Container(
                          width: 96,
                          constraints: const BoxConstraints(minHeight: 44),
                          alignment: Alignment.center,
                          child: _buildTrackingDisplay(context, ref, null),
                        ),
                      ),
                    ),
                  ),
                );
              },
              loading: () => Container(
                width: 96,
                alignment: Alignment.center,
                child: SkeletonLoader(
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              error: (_, _) => Material(
                color: Colors.transparent,
                child: Semantics(
                  label: 'track_habit'.tr(),
                  button: true,
                  child: InkWell(
                    onTap: () => _toggleTodayCompletion(context, ref),
                    child: Container(
                      width: 96,
                      constraints: const BoxConstraints(minHeight: 44),
                      alignment: Alignment.center,
                      child: _buildTrackingDisplay(context, ref, null),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
