import 'package:flutter/material.dart';

enum HabitCheckboxStyle {
  square,
  rounded,
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

  switch (style) {
    case HabitCheckboxStyle.square:
      return Icon(
        isCompleted ? Icons.check_box : Icons.check_box_outline_blank,
        color: color,
        size: size,
      );

    case HabitCheckboxStyle.rounded:
      return Icon(
        isCompleted
            ? Icons.check_box_rounded
            : Icons.check_box_outline_blank_rounded,
        color: color,
        size: size,
      );

    case HabitCheckboxStyle.bordered:
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          border: Border.all(
            color: color,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(4),
          color: isCompleted ? color.withOpacity(0.1) : Colors.transparent,
        ),
        child: isCompleted
            ? Icon(
                Icons.check,
                color: color,
                size: iconSize,
              )
            : null,
      );

    case HabitCheckboxStyle.circle:
      return Icon(
        isCompleted ? Icons.check_circle : Icons.circle_outlined,
        color: color,
        size: size,
      );

    case HabitCheckboxStyle.radio:
      return Icon(
        isCompleted
            ? Icons.radio_button_checked
            : Icons.radio_button_unchecked,
        color: color,
        size: size,
      );

    case HabitCheckboxStyle.task:
      return Icon(
        isCompleted ? Icons.assignment_turned_in : Icons.assignment_outlined,
        color: color,
        size: size,
      );

    case HabitCheckboxStyle.verified:
      return Icon(
        isCompleted ? Icons.verified : Icons.verified_outlined,
        color: color,
        size: size,
      );

    case HabitCheckboxStyle.taskAlt:
      return Icon(
        isCompleted ? Icons.task_alt : Icons.task_outlined,
        color: color,
        size: size,
      );
  }
}

HabitCheckboxStyle habitCheckboxStyleFromString(String? value) {
  switch (value) {
    case 'square':
      return HabitCheckboxStyle.square;
    case 'rounded':
      return HabitCheckboxStyle.rounded;
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
    case HabitCheckboxStyle.rounded:
      return 'rounded';
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

