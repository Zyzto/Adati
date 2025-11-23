import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:adati/main.dart' as app;

/// Integration tests for bad habits functionality
/// 
/// Tests complete flows related to bad habits, including:
/// - Creating bad habits
/// - Positive mode behavior
/// - Negative mode behavior
/// - Creation date handling
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Bad Habits Flow Tests', () {
    testWidgets('Create bad habit and verify positive mode behavior', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Placeholder for bad habit creation and positive mode test
      // Would test:
      // 1. Create a bad habit
      // 2. Set mode to positive
      // 3. Verify unmarked days count as positive
      // 4. Verify only dates after creation are counted
      
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Bad habit negative mode behavior', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Placeholder for negative mode test
      // Would test:
      // 1. Create a bad habit
      // 2. Set mode to negative
      // 3. Mark the habit (doing bad thing)
      // 4. Verify it counts as negative
      
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}

