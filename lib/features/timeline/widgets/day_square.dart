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
  final int? completionColor;

  const DaySquare({
    super.key,
    required this.date,
    required this.completed,
    this.size,
    this.onTap,
    this.streakLength,
    this.highlightWeek = false,
    this.highlightMonth = false,
    this.completionColor,
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

  Color _getColor(WidgetRef ref) {
    if (!completed) {
      if (app_date_utils.DateUtils.isToday(date)) {
        return Colors.grey[300]!;
      }
      if (date.isAfter(app_date_utils.DateUtils.getToday())) {
        return Colors.grey[100]!;
      }
      return Colors.grey[200]!;
    }
    
    // Check if streak colors should be used for squares
    final useStreakColors = ref.watch(useStreakColorsForSquaresProvider);
    
    // If enabled and there's a streak, use streak colors based on color scheme
    if (useStreakColors && streakLength != null && streakLength! > 0) {
      final scheme = ref.watch(streakColorSchemeProvider);
      return _getStreakColorForLength(streakLength!, scheme);
    }
    
    // Default: use provided completion color or apply gradient based on streak length
    final baseColor = completionColor != null 
        ? Color(completionColor!)
        : Colors.green;
    
    // Apply gradient based on streak length (if not using streak colors)
    if (streakLength != null && streakLength! > 0) {
      // Darker color for longer streaks
      final intensity = (streakLength! / 30).clamp(0.0, 1.0); // Max at 30 days
      return Color.fromARGB(
        255,
        ((baseColor.r * 255.0 * (0.5 + intensity * 0.5)).clamp(0, 255)).round(),
        ((baseColor.g * 255.0 * (0.5 + intensity * 0.5)).clamp(0, 255)).round(),
        ((baseColor.b * 255.0 * (0.5 + intensity * 0.5)).clamp(0, 255)).round(),
      );
    }
    
    return baseColor;
  }

  Color? _getStreakBorderColor(WidgetRef ref) {
    if (streakLength == null || streakLength! == 0) {
      return null;
    }
    
    final scheme = ref.watch(streakColorSchemeProvider);
    return _getStreakColorForLength(streakLength!, scheme);
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


  Border? _getBorder(WidgetRef ref) {
    final showStreakBorders = ref.watch(showStreakBordersProvider);
    final streakBorderColor = _getStreakBorderColor(ref);
    final isToday = app_date_utils.DateUtils.isToday(date);
    
    // Priority: Today > Streak (only for completed days with active streaks)
    if (isToday) {
      return Border.all(color: Colors.blue, width: 1.5);
    } else if (showStreakBorders && streakBorderColor != null && completed && streakLength != null && streakLength! > 0) {
      // Show streak border only for completed days with active streaks
      return Border.all(
        color: streakBorderColor,
        width: streakLength! >= 7 ? 2 : 1.5,
      );
    }
    
    // Don't show week/month highlight borders - they were causing unwanted borders
    return null;
  }

  String _getTooltipMessage(WidgetRef ref) {
    final dateStr = app_date_utils.DateUtils.formatDate(date);
    final status = completed ? 'completed'.tr() : 'not_completed'.tr();
    final showStreakNumbers = ref.watch(showStreakNumbersProvider);
    final streakInfo = showStreakNumbers && streakLength != null && streakLength! > 0
        ? ' - ${'streak'.tr()}: $streakLength'
        : '';
    return '$dateStr - $status$streakInfo';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final squareSize = _getSize(ref);
    final showStreakNumbers = ref.watch(showStreakNumbersProvider);
    
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
                  _getTooltipMessage(ref),
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
        message: _getTooltipMessage(ref),
        waitDuration: const Duration(milliseconds: 500),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: squareSize,
              height: squareSize,
              decoration: BoxDecoration(
                color: _getColor(ref),
                borderRadius: BorderRadius.circular(2),
                border: _getBorder(ref),
              ),
            ),
            if (showStreakNumbers && streakLength != null && streakLength! > 0)
              Text(
                streakLength.toString(),
                style: TextStyle(
                  fontSize: squareSize * 0.4,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
          ],
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

