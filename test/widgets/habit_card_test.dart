import 'package:flutter_test/flutter_test.dart';
import 'package:adati/features/habits/widgets/cards/habit_card.dart';
import '../helpers/test_helpers.dart';
import '../helpers/localization_helpers.dart';
import '../fixtures/habit_fixtures.dart';

void main() {
  setUpAll(() async {
    // Initialize test environment (localization + preferences)
    await setupTestEnvironment();
  });

  group('HabitCard Widget Tests', () {
    testWidgets('renders basic habit info without crashing',
        (WidgetTester tester) async {
      final fakeHabit = createTestHabit(
        name: 'Test Habit',
        description: 'A simple test habit',
      );

      await pumpTestWidget(
        tester,
        HabitCard(habit: fakeHabit),
      );

      expect(find.text('Test Habit'), findsOneWidget);
    });

    testWidgets('displays habit description when present',
        (WidgetTester tester) async {
      final fakeHabit = createTestHabit(
        name: 'Test Habit',
        description: 'This is a test description',
      );

      await pumpTestWidget(
        tester,
        HabitCard(habit: fakeHabit),
      );

      expect(find.text('This is a test description'), findsOneWidget);
    });

    testWidgets('displays good habit correctly', (WidgetTester tester) async {
      final goodHabit = createTestGoodHabit(name: 'Exercise');

      await pumpTestWidget(
        tester,
        HabitCard(habit: goodHabit),
      );

      expect(find.text('Exercise'), findsOneWidget);
    });

    testWidgets('displays bad habit correctly', (WidgetTester tester) async {
      final badHabit = createTestBadHabit(name: 'No Smoking');

      await pumpTestWidget(
        tester,
        HabitCard(habit: badHabit),
      );

      expect(find.text('No Smoking'), findsOneWidget);
    });

    testWidgets('displays measurable habit correctly',
        (WidgetTester tester) async {
      final measurableHabit = createTestMeasurableHabit(
        name: 'Exercise',
        unit: 'minutes',
        goalValue: 30.0,
      );

      await pumpTestWidget(
        tester,
        HabitCard(habit: measurableHabit),
      );

      expect(find.text('Exercise'), findsOneWidget);
    });

    testWidgets('displays occurrences habit correctly',
        (WidgetTester tester) async {
      final occurrencesHabit = createTestOccurrencesHabit(
        name: 'Meditation',
        occurrenceNames: ['Morning', 'Evening'],
      );

      await pumpTestWidget(
        tester,
        HabitCard(habit: occurrencesHabit),
      );

      expect(find.text('Meditation'), findsOneWidget);
    });
  });
}

