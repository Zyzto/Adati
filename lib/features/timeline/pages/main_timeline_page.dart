import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../widgets/calendar_grid.dart';
import '../widgets/timeline_stats.dart';
import '../../habits/widgets/habits_section.dart';
import '../../habits/widgets/quick_actions_widget.dart';

class MainTimelinePage extends ConsumerStatefulWidget {
  const MainTimelinePage({super.key});

  @override
  ConsumerState<MainTimelinePage> createState() => _MainTimelinePageState();
}

class _MainTimelinePageState extends ConsumerState<MainTimelinePage> {
  bool _showQuickActions = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('timeline'.tr()),
        actions: [
          IconButton(
            icon: Icon(_showQuickActions ? Icons.flash_off : Icons.flash_on),
            tooltip: _showQuickActions ? 'hide_quick_actions'.tr() : 'show_quick_actions'.tr(),
            onPressed: () {
              setState(() {
                _showQuickActions = !_showQuickActions;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TimelineStats(),
            const CalendarGrid(),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, -0.3),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOut,
                  )),
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              },
              child: _showQuickActions
                  ? const QuickActionsWidget(key: ValueKey('quick_actions'))
                  : const SizedBox.shrink(key: ValueKey('empty')),
            ),
            const HabitsSection(),
          ],
        ),
      ),
    );
  }
}

