import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notifier to track the currently selected tab index in the bottom navigation
/// 0 = Timeline, 1 = Habits
class SelectedTabIndexNotifier {
  int _index = 0;
  final Ref _ref;

  SelectedTabIndexNotifier(this._ref);

  int get index => _index;

  void setIndex(int index) {
    if (_index != index) {
      _index = index;
      // Invalidate the notifier provider to trigger a rebuild
      _ref.invalidate(selectedTabIndexNotifierProvider);
    }
  }
}

final selectedTabIndexNotifierProvider =
    Provider<SelectedTabIndexNotifier>((ref) {
  return SelectedTabIndexNotifier(ref);
});

final selectedTabIndexProvider = Provider<int>((ref) {
  return ref.watch(selectedTabIndexNotifierProvider).index;
});

