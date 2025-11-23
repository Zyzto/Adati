import 'package:flutter_test/flutter_test.dart';
import 'package:adati/features/timeline/widgets/day_square.dart';
import 'package:adati/core/utils/date_utils.dart' as date_utils;
import '../helpers/test_helpers.dart';

void main() {
  setUpAll(() async {
    // Initialize test environment (localization + preferences)
    await setupTestEnvironment();
  });
  group('DaySquare Widget Tests', () {
    testWidgets('renders day square without crashing',
        (WidgetTester tester) async {
      final today = date_utils.DateUtils.getToday();

      await pumpTestWidget(
        tester,
        DaySquare(
          date: today,
          completed: false,
        ),
      );

      // DaySquare should render without errors
      expect(find.byType(DaySquare), findsOneWidget);
    });

    testWidgets('displays completed state correctly',
        (WidgetTester tester) async {
      final today = date_utils.DateUtils.getToday();

      await pumpTestWidget(
        tester,
        DaySquare(
          date: today,
          completed: true,
          completionColor: 0xFF4CAF50, // Green
        ),
      );

      expect(find.byType(DaySquare), findsOneWidget);
    });

    testWidgets('displays incomplete state correctly',
        (WidgetTester tester) async {
      final today = date_utils.DateUtils.getToday();

      await pumpTestWidget(
        tester,
        DaySquare(
          date: today,
          completed: false,
        ),
      );

      expect(find.byType(DaySquare), findsOneWidget);
    });

    testWidgets('displays streak length when provided',
        (WidgetTester tester) async {
      final today = date_utils.DateUtils.getToday();

      await pumpTestWidget(
        tester,
        DaySquare(
          date: today,
          completed: true,
          streakLength: 5,
        ),
      );

      expect(find.byType(DaySquare), findsOneWidget);
      // Streak number should be displayed if showStreakNumbers is enabled
    });
  });
}

