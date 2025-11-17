import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/services/preferences_service.dart';
import '../../../core/services/demo_data_service.dart';
import '../../../core/services/import_service.dart';
import '../../habits/providers/habit_providers.dart';
import '../../settings/providers/settings_providers.dart';
import '../widgets/onboarding_slide.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final FocusNode _focusNode = FocusNode();

  // Get slides list
  List<Map<String, dynamic>> get slides => [
        {
          'icon': Icons.timeline,
          'title': 'onboarding_welcome_title'.tr(),
          'description': 'onboarding_welcome_description'.tr(),
        },
        {
          'icon': Icons.calendar_view_week,
          'title': 'onboarding_timeline_title'.tr(),
          'description': 'onboarding_timeline_description'.tr(),
        },
        {
          'icon': Icons.track_changes,
          'title': 'onboarding_tracking_title'.tr(),
          'description': 'onboarding_tracking_description'.tr(),
        },
      ];

  @override
  void initState() {
    super.initState();
    // Request focus to enable keyboard navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _goToNextPage() {
    if (_currentPage < slides.length) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToPreviousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToPage(int page) {
    if (page >= 0 && page <= slides.length) {
      _pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final keyLabel = event.logicalKey.keyLabel;
      switch (keyLabel) {
        case 'Arrow Right':
        case 'Arrow Down':
          _goToNextPage();
          return true;
        case 'Arrow Left':
        case 'Arrow Up':
          _goToPreviousPage();
          return true;
        case 'Escape':
          _goToPage(slides.length);
          return true;
        case 'Enter':
        case ' ':
          if (_currentPage == slides.length) {
            // On final page, trigger first button (Try Demo Data)
            _handleTryDemoData();
          } else {
            _goToNextPage();
          }
          return true;
      }
    }
    return false;
  }

  void _completeOnboarding() async {
    await PreferencesService.setFirstLaunch(false);
    if (mounted) {
      context.go('/timeline');
    }
  }

  Future<void> _handleTryDemoData() async {
    final repository = ref.read(habitRepositoryProvider);
    await DemoDataService.loadDemoData(repository);
    _completeOnboarding();
  }

  Future<void> _handleImportData() async {
    final result = await ImportService.pickImportFile(importType: 'all');
    if (result != null && mounted) {
      final repository = ref.read(habitRepositoryProvider);
      await ImportService.importAllData(repository, result, null);
    }
    _completeOnboarding();
  }

  void _handleStartNew() {
    _completeOnboarding();
  }

  void _showLanguageDialog(BuildContext context) {
    final currentLanguage = PreferencesService.getLanguage() ?? 'en';
    final navigator = Navigator.of(context);
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('select_language'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                Icons.language,
                color: theme.colorScheme.primary,
              ),
              title: Text('english'.tr()),
              trailing: currentLanguage == 'en'
                  ? Icon(Icons.check, color: theme.colorScheme.primary)
                  : null,
              onTap: () async {
                await PreferencesService.setLanguage('en');
                if (dialogContext.mounted) {
                  await dialogContext.setLocale(const Locale('en'));
                  navigator.pop();
                }
              },
            ),
            ListTile(
              leading: Icon(
                Icons.language,
                color: theme.colorScheme.primary,
              ),
              title: Text('arabic'.tr()),
              trailing: currentLanguage == 'ar'
                  ? Icon(Icons.check, color: theme.colorScheme.primary)
                  : null,
              onTap: () async {
                await PreferencesService.setLanguage('ar');
                if (dialogContext.mounted) {
                  await dialogContext.setLocale(const Locale('ar'));
                  navigator.pop();
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(),
            child: Text('cancel'.tr()),
          ),
        ],
      ),
    );
  }

  void _toggleTheme(WidgetRef ref) {
    final notifier = ref.read(themeModeNotifierProvider);
    final currentTheme = ref.read(themeModeProvider);

    // Toggle between light and dark (skip system for simplicity in onboarding)
    final newTheme = currentTheme == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;

    notifier.setThemeMode(newTheme);
    ref.invalidate(themeModeNotifierProvider);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final slidesList = slides;

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Top bar with language, theme toggle, and skip button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Language and Theme controls (visible on all pages)
                    // In RTL, this will be on the right side
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Language selector
                        IconButton(
                          icon: const Icon(Icons.language),
                          tooltip: 'select_language'.tr(),
                          onPressed: () => _showLanguageDialog(context),
                          style: IconButton.styleFrom(
                            foregroundColor: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        // Theme toggle
                        IconButton(
                          icon: ref.watch(themeModeProvider) == ThemeMode.dark
                              ? const Icon(Icons.light_mode)
                              : const Icon(Icons.dark_mode),
                          tooltip: ref.watch(themeModeProvider) == ThemeMode.dark
                              ? 'light'.tr()
                              : 'dark'.tr(),
                          onPressed: () => _toggleTheme(ref),
                          style: IconButton.styleFrom(
                            foregroundColor: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    // Skip button (hide on last page)
                    // In RTL, this will be on the left side
                    if (_currentPage < slidesList.length)
                      TextButton(
                        onPressed: () {
                          _goToPage(slidesList.length);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.onSurfaceVariant,
                        ),
                        child: Text('skip'.tr()),
                      )
                    else
                      const SizedBox.shrink(),
                  ],
                ),
              ),
              // PageView
              Expanded(
                child: MouseRegion(
                  onEnter: (_) {
                    // Ensure focus for keyboard when mouse enters
                    _focusNode.requestFocus();
                  },
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const PageScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemCount: slidesList.length + 1,
                    itemBuilder: (context, index) {
                      if (index < slidesList.length) {
                        final slide = slidesList[index];
                        return OnboardingSlide(
                          icon: slide['icon'] as IconData,
                          title: slide['title'] as String,
                          description: slide['description'] as String,
                        );
                      } else {
                        // Final slide with action buttons
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.rocket_launch,
                                size: 120,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(height: 48),
                              Text(
                                'onboarding_get_started_title'.tr(),
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'onboarding_get_started_description'.tr(),
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 48),
                              // Action buttons - Start New is the primary call to action
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: _handleStartNew,
                                  icon: const Icon(Icons.add, size: 24),
                                  label: Text(
                                    'start_new'.tr(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 20,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                    backgroundColor: theme.colorScheme.primary,
                                    foregroundColor: theme.colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.tonalIcon(
                                  onPressed: _handleImportData,
                                  icon: const Icon(Icons.upload_file, size: 22),
                                  label: Text(
                                    'import_data'.tr(),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 28,
                                      vertical: 18,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _handleTryDemoData,
                                  icon: const Icon(Icons.play_arrow, size: 20),
                                  label: Text('try_demo_data'.tr()),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    side: BorderSide(
                                      color: theme.colorScheme.outline,
                                    ),
                                    foregroundColor: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),
              // Page indicator
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    slidesList.length + 1,
                    (index) => GestureDetector(
                      onTap: () => _goToPage(index),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outlineVariant,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
