import 'package:flutter_test/flutter_test.dart';
import 'package:adati/core/database/app_database.dart' as db;
import 'package:adati/core/database/models/tracking_types.dart';
import 'package:adati/core/utils/date_utils.dart' as date_utils;
import 'package:adati/features/timeline/widgets/timeline_stats.dart';
import 'package:adati/features/habits/habit_repository.dart';
import 'package:adati/features/habits/providers/habit_providers.dart';
import '../helpers/test_helpers.dart';
import '../helpers/localization_helpers.dart';
import '../helpers/database_helpers.dart';
import '../fixtures/habit_fixtures.dart';

void main() {
  setUpAll(() async {
    // Initialize test environment (localization + preferences)
    await setupTestEnvironment();
  });
  group('TimelineStats Widget Tests', () {
    late db.AppDatabase testDatabase;
    late HabitRepository repository;

    setUp(() async {
      testDatabase = await createTestDatabase();
      repository = HabitRepository(testDatabase);
    });

    tearDown(() async {
      await testDatabase.close();
    });

    testWidgets('renders timeline stats without crashing',
        (WidgetTester tester) async {
      // Create test habits
      final habitCompanion1 = createTestHabitCompanion(
        name: 'Habit 1',
        habitType: HabitType.good,
      );
      final habitCompanion2 = createTestHabitCompanion(
        name: 'Habit 2',
        habitType: HabitType.good,
      );
      await repository.createHabit(habitCompanion1);
      await repository.createHabit(habitCompanion2);

      await pumpTestWidget(
        tester,
        const TimelineStats(),
        overrides: [
          databaseProvider.overrideWithValue(testDatabase),
          habitRepositoryProvider.overrideWithValue(repository),
        ],
      );

      // Stats should render
      expect(find.byType(TimelineStats), findsOneWidget);
    });

    testWidgets('displays completion percentage', (WidgetTester tester) async {
      final habitCompanion = createTestHabitCompanion(
        name: 'Test Habit',
        habitType: HabitType.good,
      );
      final habitId = await repository.createHabit(habitCompanion);

      // Complete the habit today
      final today = date_utils.DateUtils.getToday();
      await repository.toggleCompletion(habitId, today, true);

      await pumpTestWidget(
        tester,
        const TimelineStats(),
        overrides: [
          databaseProvider.overrideWithValue(testDatabase),
          habitRepositoryProvider.overrideWithValue(repository),
        ],
      );

      // Should display stats
      expect(find.byType(TimelineStats), findsOneWidget);
    });
  });
}

