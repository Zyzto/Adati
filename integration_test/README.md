# Integration Tests

This directory contains integration tests that test complete app flows and user journeys.

## What are Integration Tests?

Integration tests verify that multiple parts of your app work together correctly. Unlike unit tests (which test individual components in isolation) or widget tests (which test single widgets), integration tests:

- Run on real devices or emulators
- Test complete user flows
- Verify that all components work together
- Are slower but provide higher confidence

## Running Integration Tests

### Prerequisites

1. Have a device or emulator connected:
   ```bash
   flutter devices
   ```

2. Build the app in debug mode (integration tests require a built app)

### Run All Integration Tests

```bash
flutter test integration_test/
```

### Run Specific Integration Test

```bash
flutter test integration_test/app_flow_test.dart
```

### Run on Specific Device

```bash
flutter test -d <device-id> integration_test/app_flow_test.dart
```

## Test Files

- **app_flow_test.dart**: Tests complete app flows like habit creation, completion, etc.
- **bad_habits_flow_test.dart**: Tests end-to-end bad habits functionality

## Writing Integration Tests

### Basic Structure

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:adati/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Your test name', (tester) async {
    // Start the app
    app.main();
    await tester.pumpAndSettle();

    // Interact with the app
    await tester.tap(find.text('Button'));
    await tester.pumpAndSettle();

    // Verify results
    expect(find.text('Expected Result'), findsOneWidget);
  });
}
```

### Best Practices

1. **Use `pumpAndSettle()`**: Wait for all animations and async operations to complete
2. **Be Patient**: Integration tests are slower - use appropriate timeouts
3. **Clean State**: Each test should start with a clean app state
4. **Realistic Flows**: Test actual user journeys, not just technical scenarios

## Troubleshooting

### Tests Timeout

- Increase timeout: `testWidgets('...', (tester) async { ... }, timeout: Timeout(Duration(minutes: 5)));`
- Check device performance
- Reduce test complexity

### App Doesn't Start

- Ensure `main()` function is accessible
- Check for initialization errors
- Verify all dependencies are available

### Tests Fail Intermittently

- Add more `pumpAndSettle()` calls
- Increase wait times between actions
- Check for race conditions

## Resources

- [Flutter Integration Testing Guide](https://docs.flutter.dev/testing/integration-tests)
- [Integration Test Package](https://pub.dev/packages/integration_test)

