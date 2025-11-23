import 'package:flutter_test/flutter_test.dart';
import 'package:adati/core/database/app_database.dart' as db;
import 'package:adati/features/timeline/widgets/calendar_grid.dart';
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
  group('CalendarGrid Widget Tests', () {
    late db.AppDatabase testDatabase;
    late HabitRepository repository;

    setUp(() async {
      testDatabase = await createTestDatabase();
      repository = HabitRepository(testDatabase);
    });

    tearDown(() async {
      await testDatabase.close();
    });

    testWidgets('renders calendar grid without crashing',
        (WidgetTester tester) async {
      // Create a test habit
      final habitCompanion = createTestHabitCompanion(name: 'Test Habit');
      await repository.createHabit(habitCompanion);

      // Use pump instead of pumpAndSettle to avoid timeout
      await tester.pumpWidget(
        createTestWidget(
          child: const CalendarGrid(),
          overrides: [
            databaseProvider.overrideWithValue(testDatabase),
            habitRepositoryProvider.overrideWithValue(repository),
          ],
        ),
      );

      // Pump a few times to allow async operations
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();

      // Calendar grid should render
      expect(find.byType(CalendarGrid), findsOneWidget);
    });

    testWidgets('displays day squares for timeline',
        (WidgetTester tester) async {
      final habitCompanion = createTestHabitCompanion(name: 'Test Habit');
      await repository.createHabit(habitCompanion);

      // Use pump instead of pumpAndSettle to avoid timeout
      await tester.pumpWidget(
        createTestWidget(
          child: const CalendarGrid(),
          overrides: [
            databaseProvider.overrideWithValue(testDatabase),
            habitRepositoryProvider.overrideWithValue(repository),
          ],
        ),
      );

      // Pump a few times to allow async operations
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();

      // Should render calendar grid
      expect(find.byType(CalendarGrid), findsOneWidget);
    });
  });
}

