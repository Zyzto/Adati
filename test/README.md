# Test Documentation

This directory contains all tests for the Adati habit tracking app. The test structure follows Flutter's testing best practices.

## Test Structure

```
test/
├── helpers/          # Test utilities and helpers
│   ├── database_helpers.dart    # In-memory database setup
│   ├── test_helpers.dart        # Widget test setup utilities
│   ├── widget_helpers.dart      # Widget interaction helpers
│   └── provider_helpers.dart    # Riverpod provider test utilities
├── fixtures/         # Test data fixtures
│   ├── habit_fixtures.dart      # Habit test data factories
│   └── entry_fixtures.dart      # Tracking entry test data factories
├── services/         # Service/Repository unit tests
│   ├── habit_repository_test.dart
│   ├── bad_habits_creation_date_test.dart
│   ├── preferences_service_test.dart
│   ├── export_service_test.dart
│   ├── import_service_test.dart
│   ├── habit_providers_test.dart
│   ├── tracking_providers_test.dart
│   └── settings_providers_test.dart
└── widgets/          # Widget tests
    ├── habit_card_test.dart
    ├── day_square_test.dart
    ├── habit_timeline_test.dart
    ├── calendar_grid_test.dart
    └── timeline_stats_test.dart
```

## Test Categories

### Unit Tests (Service/Repository Tests)

Located in `test/services/`, these tests verify individual services and repositories in isolation:

- **HabitRepository Tests**: CRUD operations, tracking entries, streak calculations
- **PreferencesService Tests**: Settings persistence and retrieval
- **Export/Import Service Tests**: Data export/import functionality
- **Provider Tests**: Riverpod state management providers

**Characteristics:**
- Test single classes/functions in isolation
- Use in-memory database for data isolation
- Fast execution
- No UI rendering

**Example:**
```dart
test('createHabit creates a new habit', () async {
  final habitCompanion = createTestHabitCompanion(name: 'Exercise');
  final habitId = await repository.createHabit(habitCompanion);
  expect(habitId, greaterThan(0));
});
```

### Widget Tests

Located in `test/widgets/`, these tests verify individual widgets:

- **HabitCard Tests**: Widget rendering, different habit types
- **DaySquare Tests**: Completion states, streak display
- **Timeline Tests**: Timeline rendering, date handling
- **CalendarGrid Tests**: Calendar display
- **TimelineStats Tests**: Statistics display

**Characteristics:**
- Test single widgets in isolation
- Use `testWidgets()` function
- Render widgets in test environment
- Test UI interactions and rendering

**Example:**
```dart
testWidgets('renders habit card correctly', (tester) async {
  final habit = createTestHabit(name: 'Exercise');
  await pumpTestWidget(tester, HabitCard(habit: habit));
  expect(find.text('Exercise'), findsOneWidget);
});
```

### Integration Tests

Located in `integration_test/`, these tests verify complete app flows:

- **App Flow Tests**: Complete user journeys
- **Bad Habits Flow Tests**: End-to-end bad habits functionality

**Characteristics:**
- Test complete app or large parts
- Run on real devices/emulators
- Slower execution
- Test real user interactions

**Example:**
```dart
testWidgets('Complete habit creation flow', (tester) async {
  app.main();
  await tester.pumpAndSettle();
  // Test complete user flow
});
```

## Running Tests

### Run All Tests
```bash
flutter test
```

### Run Specific Test Category
```bash
# Run only unit/service tests
flutter test test/services/

# Run only widget tests
flutter test test/widgets/

# Run specific test file
flutter test test/services/habit_repository_test.dart
```

### Run Integration Tests
```bash
# Run on connected device/emulator
flutter test integration_test/app_flow_test.dart

# Run with specific device
flutter test -d <device-id> integration_test/app_flow_test.dart
```

### Run Tests with Coverage
```bash
flutter test --coverage
```

## Test Helpers

### Database Helpers

Create in-memory databases for isolated testing:

```dart
final testDatabase = await createTestDatabase();
final repository = HabitRepository(testDatabase);
```

### Widget Test Helpers

Set up widgets with proper providers and localization:

```dart
await pumpTestWidget(
  tester,
  HabitCard(habit: habit),
  overrides: [/* provider overrides */],
);
```

### Test Fixtures

Create test data easily:

```dart
final habit = createTestHabit(name: 'Exercise');
final badHabit = createTestBadHabit(name: 'No Smoking');
final entry = createCompletedEntry(habitId: 1);
```

## Best Practices

1. **Isolation**: Each test should be independent and not rely on other tests
2. **Setup/Teardown**: Always clean up resources in `tearDown()`
3. **Naming**: Use descriptive test names that explain what is being tested
4. **Grouping**: Use `group()` to organize related tests
5. **Fixtures**: Use test fixtures for reusable test data
6. **Mocking**: Mock external dependencies when testing in isolation

## Test Coverage Goals

- **Unit Tests**: 80%+ coverage for services and repositories
- **Widget Tests**: All major widgets should have tests
- **Integration Tests**: All critical user flows should be covered

## Troubleshooting

### Tests Fail with Database Errors
- Ensure `tearDown()` properly closes the database
- Check that each test uses a fresh database instance

### Widget Tests Fail to Render
- Verify all required providers are included in `overrides`
- Check that localization is properly set up

### Integration Tests Don't Run
- Ensure a device/emulator is connected
- Verify `integration_test` package is in `pubspec.yaml`

## Additional Resources

- [Flutter Testing Documentation](https://docs.flutter.dev/testing/overview)
- [Widget Testing Guide](https://docs.flutter.dev/cookbook/testing/widget)
- [Integration Testing Guide](https://docs.flutter.dev/testing/integration-tests)

