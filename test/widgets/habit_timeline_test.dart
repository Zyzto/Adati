import 'package:flutter_test/flutter_test.dart';
import 'package:adati/core/database/app_database.dart' as db;
import 'package:adati/features/habits/widgets/cards/habit_timeline.dart';
import 'package:adati/features/habits/habit_repository.dart';
import 'package:adati/features/habits/providers/habit_providers.dart';
import '../helpers/test_helpers.dart';
import '../helpers/database_helpers.dart';
import '../fixtures/habit_fixtures.dart';

void main() {
  setUpAll(() async {
    // Initialize test environment (localization + preferences)
    await setupTestEnvironment();
  });
  group('HabitTimeline Widget Tests', () {
    late db.AppDatabase testDatabase;
    late HabitRepository repository;

    setUp(() async {
      testDatabase = await createTestDatabase();
      repository = HabitRepository(testDatabase);
    });

    tearDown(() async {
      await testDatabase.close();
    });

    testWidgets('renders timeline without crashing', (WidgetTester tester) async {
      final habitCompanion = createTestHabitCompanion(name: 'Test Habit');
      final habitId = await repository.createHabit(habitCompanion);

      await pumpTestWidget(
        tester,
        HabitTimeline(
          habitId: habitId,
          compact: false,
          daysToShow: 30,
        ),
        overrides: [
          databaseProvider.overrideWithValue(testDatabase),
          habitRepositoryProvider.overrideWithValue(repository),
        ],
      );

      // Timeline should render
      expect(find.byType(HabitTimeline), findsOneWidget);
    });

    testWidgets('displays timeline squares for multiple days',
        (WidgetTester tester) async {
      final habitCompanion = createTestHabitCompanion(name: 'Test Habit');
      final habitId = await repository.createHabit(habitCompanion);

      await pumpTestWidget(
        tester,
        HabitTimeline(
          habitId: habitId,
          compact: true,
          daysToShow: 7,
        ),
        overrides: [
          databaseProvider.overrideWithValue(testDatabase),
          habitRepositoryProvider.overrideWithValue(repository),
        ],
      );

      // Should render timeline
      expect(find.byType(HabitTimeline), findsOneWidget);
    });
  });
}

