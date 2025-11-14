import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/date_utils.dart' as app_date_utils;
import '../../settings/providers/settings_providers.dart';

class DaySquare extends ConsumerWidget {
  final DateTime date;
  final bool completed;
  final double? size;
  final VoidCallback? onTap;

  const DaySquare({
    super.key,
    required this.date,
    required this.completed,
    this.size,
    this.onTap,
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
    if (completed) {
      return Colors.green;
    }
    if (app_date_utils.DateUtils.isToday(date)) {
      return Colors.grey[300]!;
    }
    if (date.isAfter(app_date_utils.DateUtils.getToday())) {
      return Colors.grey[100]!;
    }
    return Colors.grey[200]!;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final squareSize = _getSize(ref);
    
    Widget square = Tooltip(
      message: app_date_utils.DateUtils.formatDate(date),
      child: Container(
        width: squareSize,
        height: squareSize,
        decoration: BoxDecoration(
          color: _getColor(),
          borderRadius: BorderRadius.circular(2),
          border: app_date_utils.DateUtils.isToday(date)
              ? Border.all(color: Colors.blue, width: 1.5)
              : null,
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

