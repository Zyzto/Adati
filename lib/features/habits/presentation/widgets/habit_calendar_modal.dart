import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../tracking/presentation/providers/tracking_providers.dart';
import '../../../../core/utils/date_utils.dart' as app_date_utils;
import '../providers/habit_providers.dart';

class HabitCalendarModal extends ConsumerStatefulWidget {
  final int habitId;

  const HabitCalendarModal({super.key, required this.habitId});

  @override
  ConsumerState<HabitCalendarModal> createState() => _HabitCalendarModalState();
}

class _HabitCalendarModalState extends ConsumerState<HabitCalendarModal> {
  DateTime _selectedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(trackingEntriesProvider(widget.habitId));

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header with month navigation
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {
                        setState(() {
                          _selectedMonth = DateTime(
                            _selectedMonth.year,
                            _selectedMonth.month - 1,
                          );
                        });
                      },
                    ),
                    Text(
                      DateFormat('MMMM yyyy').format(_selectedMonth),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {
                        setState(() {
                          _selectedMonth = DateTime(
                            _selectedMonth.year,
                            _selectedMonth.month + 1,
                          );
                        });
                      },
                    ),
                  ],
                ),
              ),
              // Calendar
              Expanded(
                child: entriesAsync.when(
                  data: (entries) {
                    final entriesMap = {
                      for (var entry in entries)
                        app_date_utils.DateUtils.getDateOnly(entry.date): entry.completed
                    };
                    return _buildCalendar(entriesMap);
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(child: Text('${'error'.tr()}: $error')),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCalendar(Map<DateTime, bool> entriesMap) {
    final firstDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final lastDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    final firstDayWeekday = firstDayOfMonth.weekday;
    
    // Calculate days to show
    final daysInMonth = lastDayOfMonth.day;
    final days = <DateTime?>[];
    
    // Add empty cells for days before the first day of the month
    for (int i = 1; i < firstDayWeekday; i++) {
      days.add(null);
    }
    
    // Add all days of the month
    for (int day = 1; day <= daysInMonth; day++) {
      days.add(DateTime(_selectedMonth.year, _selectedMonth.month, day));
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Weekday headers
          Row(
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map((day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          // Calendar grid
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: days.length,
              itemBuilder: (context, index) {
                final day = days[index];
                if (day == null) {
                  return const SizedBox.shrink();
                }

                final isCompleted = entriesMap[app_date_utils.DateUtils.getDateOnly(day)] ?? false;
                final isToday = app_date_utils.DateUtils.isToday(day);

                return GestureDetector(
                  onTap: () => _toggleDay(day),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? Colors.green
                          : (isToday
                              ? Colors.blue.withValues(alpha: 0.2)
                              : Colors.grey[200]),
                      shape: BoxShape.circle,
                      border: isToday
                          ? Border.all(color: Colors.blue, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${day.day}',
                            style: TextStyle(
                              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                              color: isCompleted
                                  ? Colors.white
                                  : (isToday ? Colors.blue : Colors.black87),
                            ),
                          ),
                          if (isCompleted)
                            const Icon(
                              Icons.check,
                              size: 12,
                              color: Colors.white,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleDay(DateTime day) async {
    final repository = ref.read(habitRepositoryProvider);
    final dateOnly = app_date_utils.DateUtils.getDateOnly(day);
    
    // Get current status
    final entry = await repository.getEntry(widget.habitId, dateOnly);
    final isCompleted = entry?.completed ?? false;
    
    // Toggle completion
    await repository.toggleCompletion(
      widget.habitId,
      dateOnly,
      !isCompleted,
    );
  }
}

