import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/utils/date_utils.dart' as app_date_utils;
import '../../settings/providers/settings_providers.dart';

class DaySquare extends ConsumerWidget {
  final DateTime date;
  final bool completed;
  final double? size;
  final VoidCallback? onTap;
  final int? streakLength;
  final bool highlightWeek;
  final bool highlightMonth;

  const DaySquare({
    super.key,
    required this.date,
    required this.completed,
    this.size,
    this.onTap,
    this.streakLength,
    this.highlightWeek = false,
    this.highlightMonth = false,
  });

  double _getSize(WidgetRef ref) {
    if (size != null) return size!;
    
    final sizePreference = ref.watch(daySquareSizeProvider);
    switch (sizePreference) {
      case 'small':
        return 12;
      case 'large':
        return 20;
      case 'medium':
      default:
        return 16;
    }
  }

  Color _getColor() {
    if (!completed) {
      if (app_date_utils.DateUtils.isToday(date)) {
        return Colors.grey[300]!;
      }
      if (date.isAfter(app_date_utils.DateUtils.getToday())) {
        return Colors.grey[100]!;
      }
      return Colors.grey[200]!;
    }
    
    // Apply gradient based on streak length
    if (streakLength != null && streakLength! > 0) {
      // Darker green for longer streaks
      final intensity = (streakLength! / 30).clamp(0.0, 1.0); // Max at 30 days
      final baseGreen = Colors.green;
      return Color.fromRGBO(
        ((baseGreen.r * 255.0) * (0.5 + intensity * 0.5)).round().clamp(0, 255),
        ((baseGreen.g * 255.0) * (0.5 + intensity * 0.5)).round().clamp(0, 255),
        ((baseGreen.b * 255.0) * (0.5 + intensity * 0.5)).round().clamp(0, 255),
        1.0,
      );
    }
    
    return Colors.green;
  }

  Color? _getStreakBorderColor() {
    if (streakLength == null || streakLength! == 0) {
      return null;
    }
    
    // Border color based on streak length
    if (streakLength! >= 30) {
      return Colors.purple; // Longest streaks - purple
    } else if (streakLength! >= 14) {
      return Colors.orange; // Medium streaks - orange
    } else if (streakLength! >= 7) {
      return Colors.amber; // Short streaks - amber
    } else {
      return Colors.green; // Very short streaks - green
    }
  }

  String _getTooltipMessage() {
    final dateStr = app_date_utils.DateUtils.formatDate(date);
    final status = completed ? 'completed'.tr() : 'not_completed'.tr();
    final streakInfo = streakLength != null && streakLength! > 0
        ? ' - ${'streak'.tr()}: $streakLength'
        : '';
    return '$dateStr - $status$streakInfo';
  }

  Border? _getBorder() {
    final streakBorderColor = _getStreakBorderColor();
    final isToday = app_date_utils.DateUtils.isToday(date);
    
    // Priority: Today > Streak (only for completed days with active streaks)
    if (isToday) {
      return Border.all(color: Colors.blue, width: 1.5);
    } else if (streakBorderColor != null && completed && streakLength != null && streakLength! > 0) {
      // Show streak border only for completed days with active streaks
      return Border.all(
        color: streakBorderColor,
        width: streakLength! >= 7 ? 2 : 1.5,
      );
    }
    
    // Don't show week/month highlight borders - they were causing unwanted borders
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final squareSize = _getSize(ref);
    
    Widget square = GestureDetector(
      onLongPress: () {
        // Show detailed tooltip on long press
        final overlay = Overlay.of(context);
        final overlayEntry = OverlayEntry(
          builder: (context) => Positioned(
            left: MediaQuery.of(context).size.width / 2 - 100,
            top: MediaQuery.of(context).size.height / 2,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getTooltipMessage(),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ),
        );
        overlay.insert(overlayEntry);
        Future.delayed(const Duration(seconds: 2), () {
          overlayEntry.remove();
        });
      },
      child: Tooltip(
        message: _getTooltipMessage(),
        waitDuration: const Duration(milliseconds: 500),
        child: Container(
          width: squareSize,
          height: squareSize,
          decoration: BoxDecoration(
            color: _getColor(),
            borderRadius: BorderRadius.circular(2),
            border: _getBorder(),
          ),
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: square,
      );
    }

    return square;
  }
}

