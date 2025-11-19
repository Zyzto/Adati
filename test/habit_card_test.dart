import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:adati/features/habits/widgets/cards/habit_card.dart' as habit_card;
import 'package:adati/core/database/app_database.dart' as db;

void main() {
  group('HabitCard', () {
    testWidgets('renders basic habit info without crashing',
        (WidgetTester tester) async {
      // Minimal fake habit record
      final fakeHabit = db.Habit(
        id: 1,
        name: 'Test Habit',
        description: 'A simple test habit',
        color: Colors.blue.hashCode,
        icon: null,
        habitType: 0,
        trackingType: 'completed',
        unit: null,
        goalValue: null,
        goalPeriod: null,
        occurrenceNames: null,
        reminderEnabled: false,
        reminderTime: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('en')],
          path: 'assets/translations',
          fallbackLocale: const Locale('en'),
          child: const ProviderScope(
            child: MaterialApp(
              home: Scaffold(),
            ),
          ),
        ),
      );

      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('en')],
          path: 'assets/translations',
          fallbackLocale: const Locale('en'),
          child: ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: habit_card.HabitCard(habit: fakeHabit),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Test Habit'), findsOneWidget);
    });
  });
}


