import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Finds a widget by type and returns it
T findWidgetByType<T extends Widget>(WidgetTester tester) {
  return tester.widget<T>(find.byType(T));
}

/// Finds all widgets of a specific type
List<T> findWidgetsByType<T extends Widget>(WidgetTester tester) {
  final finder = find.byType(T);
  return tester.widgetList<T>(finder).toList();
}

/// Verifies that a widget exists and is visible
void expectWidgetVisible(WidgetTester tester, Finder finder) {
  expect(finder, findsOneWidget);
  expect(tester.widget(finder), isNotNull);
}

/// Verifies that a widget does not exist
void expectWidgetNotVisible(WidgetTester tester, Finder finder) {
  expect(finder, findsNothing);
}

/// Taps a widget and waits for animations
Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Enters text into a text field
Future<void> enterText(WidgetTester tester, Finder finder, String text) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
  await tester.enterText(finder, text);
  await tester.pumpAndSettle();
}

/// Scrolls to make a widget visible
Future<void> scrollToWidget(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    500.0,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

