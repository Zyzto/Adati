import 'package:flutter/material.dart';
import '../../../../core/utils/date_utils.dart' as app_date_utils;

class DaySquare extends StatelessWidget {
  final DateTime date;
  final bool completed;
  final double size;
  final VoidCallback? onTap;

  const DaySquare({
    super.key,
    required this.date,
    required this.completed,
    this.size = 16,
    this.onTap,
  });

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
  Widget build(BuildContext context) {
    Widget square = Tooltip(
      message: app_date_utils.DateUtils.formatDate(date),
      child: Container(
        width: size,
        height: size,
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

