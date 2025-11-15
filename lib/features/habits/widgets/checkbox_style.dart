import 'package:flutter/material.dart';

enum HabitCheckboxStyle {
  square,
  bordered,
  circle,
  radio,
  task,
  verified,
  taskAlt,
}

Widget buildCheckboxWidget(
  HabitCheckboxStyle style,
  bool isCompleted,
  double size,
  VoidCallback? onTap,
) {
  final color = isCompleted ? Colors.green : Colors.grey;
  final iconSize = size * 0.9;

  Widget checkboxWidget;

  switch (style) {
    case HabitCheckboxStyle.square:
      checkboxWidget = Icon(
        isCompleted ? Icons.check_box : Icons.check_box_outline_blank,
        color: color,
        size: size,
      );
      break;

    case HabitCheckboxStyle.bordered:
      checkboxWidget = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(4),
          color: isCompleted
              ? color.withValues(alpha: 0.1)
              : Colors.transparent,
        ),
        child: isCompleted
            ? Icon(Icons.check, color: color, size: iconSize)
            : null,
      );
      break;

    case HabitCheckboxStyle.circle:
      checkboxWidget = Icon(
        isCompleted ? Icons.check_circle : Icons.circle_outlined,
        color: color,
        size: size,
      );
      break;

    case HabitCheckboxStyle.radio:
      checkboxWidget = Icon(
        isCompleted ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: color,
        size: size,
      );
      break;

    case HabitCheckboxStyle.task:
      checkboxWidget = Icon(
        isCompleted ? Icons.assignment_turned_in : Icons.assignment_outlined,
        color: color,
        size: size,
      );
      break;

    case HabitCheckboxStyle.verified:
      checkboxWidget = Icon(
        isCompleted ? Icons.verified : Icons.verified_outlined,
        color: color,
        size: size,
      );
      break;

    case HabitCheckboxStyle.taskAlt:
      checkboxWidget = Icon(
        isCompleted ? Icons.task_alt : Icons.task_outlined,
        color: color,
        size: size,
      );
      break;
  }

  // Return checkbox widget without hover effect
  // Hover effect will be handled by the parent InkWell in habit_card.dart
  return checkboxWidget;
}

HabitCheckboxStyle habitCheckboxStyleFromString(String? value) {
  switch (value) {
    case 'square':
      return HabitCheckboxStyle.square;
    case 'bordered':
      return HabitCheckboxStyle.bordered;
    case 'circle':
      return HabitCheckboxStyle.circle;
    case 'radio':
      return HabitCheckboxStyle.radio;
    case 'task':
      return HabitCheckboxStyle.task;
    case 'verified':
      return HabitCheckboxStyle.verified;
    case 'taskAlt':
      return HabitCheckboxStyle.taskAlt;
    default:
      return HabitCheckboxStyle.square;
  }
}

String habitCheckboxStyleToString(HabitCheckboxStyle style) {
  switch (style) {
    case HabitCheckboxStyle.square:
      return 'square';
    case HabitCheckboxStyle.bordered:
      return 'bordered';
    case HabitCheckboxStyle.circle:
      return 'circle';
    case HabitCheckboxStyle.radio:
      return 'radio';
    case HabitCheckboxStyle.task:
      return 'task';
    case HabitCheckboxStyle.verified:
      return 'verified';
    case HabitCheckboxStyle.taskAlt:
      return 'taskAlt';
  }
}
