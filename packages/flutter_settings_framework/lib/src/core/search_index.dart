/// Flutter Settings Framework
/// Multi-language search index for settings.
///
/// The search index enables searching settings across all supported languages,
/// not just the currently displayed language.
library;

import 'package:flutter/widgets.dart';
import 'setting_definition.dart';
import 'settings_registry.dart';

/// Localization provider interface.
///
/// Implement this to provide translations for search indexing.
/// The framework provides an [EasyLocalizationAdapter] for easy_localization.
abstract class LocalizationProvider {
  /// Get all supported locales.
  List<Locale> get supportedLocales;

  /// Translate a key to a specific locale.
  String translate(String key, {required Locale locale});

  /// Check if the provider is ready to use.
  bool get isReady;
}

/// Search result containing a setting and its match score.
class SearchResult {
  /// The matched setting definition.
  final SettingDefinition setting;

  /// Match score (higher = better match).
  final double score;

  /// The matched term (for highlighting).
  final String matchedTerm;

  /// The locale where the match was found.
  final String? matchedLocale;

  const SearchResult({
    required this.setting,
    required this.score,
    required this.matchedTerm,
    this.matchedLocale,
  });

  @override
  String toString() =>
      'SearchResult(${setting.key}, score: $score, match: "$matchedTerm")';
}

/// Multi-language search index for settings.
///
/// The [SearchIndex] indexes settings by:
/// 1. The setting key
/// 2. Search terms defined in [SettingDefinition.searchTerms] (all languages)
/// 3. Translated titles/subtitles from the localization provider (all locales)
///
/// This allows users to search in any language, regardless of the current UI language.
///
/// Example:
/// ```dart
/// final index = SearchIndex(
///   registry: registry,
///   localizationProvider: EasyLocalizationAdapter(),
/// );
/// await index.build();
///
/// final results = index.search('dark'); // Finds 'theme' setting
/// final results2 = index.search('داكن'); // Also finds 'theme' setting (Arabic)
/// ```
class SearchIndex {
  /// The settings registry.
  final SettingsRegistry registry;

  /// The localization provider.
  final LocalizationProvider? localizationProvider;

  /// Index: lowercase term -> set of setting keys.
  final Map<String, Set<String>> _termToKeys = {};

  /// Reverse index: setting key -> set of indexed terms.
  final Map<String, Set<String>> _keyToTerms = {};

  /// Whether the index has been built.
  bool _built = false;

  /// Create a new search index.
  SearchIndex({
    required this.registry,
    this.localizationProvider,
  });

  /// Whether the index has been built.
  bool get isBuilt => _built;

  /// Build the search index.
  ///
  /// This should be called after all settings are registered
  /// and the localization provider is ready.
  Future<void> build() async {
    _termToKeys.clear();
    _keyToTerms.clear();

    for (final setting in registry.settings) {
      _indexSetting(setting);
    }

    _built = true;
  }

  void _indexSetting(SettingDefinition setting) {
    // Index by key
    _addToIndex(setting.key.toLowerCase(), setting.key);

    // Index by key parts (split by underscore)
    for (final part in setting.key.split('_')) {
      if (part.length >= 2) {
        _addToIndex(part.toLowerCase(), setting.key);
      }
    }

    // Index by search terms in all languages
    for (final entry in setting.searchTerms.entries) {
      for (final term in entry.value) {
        _addToIndex(term.toLowerCase(), setting.key);
      }
    }

    // Index by translated titles if localization is available
    if (localizationProvider?.isReady == true) {
      for (final locale in localizationProvider!.supportedLocales) {
        // Index title
        final title = localizationProvider!.translate(
          setting.titleKey,
          locale: locale,
        );
        _indexText(title, setting.key);

        // Index subtitle if available
        if (setting.subtitleKey != null) {
          final subtitle = localizationProvider!.translate(
            setting.subtitleKey!,
            locale: locale,
          );
          _indexText(subtitle, setting.key);
        }
      }
    }
  }

  void _indexText(String text, String settingKey) {
    // Index the full text
    _addToIndex(text.toLowerCase(), settingKey);

    // Index individual words
    final words = text.split(RegExp(r'\s+'));
    for (final word in words) {
      if (word.length >= 2) {
        _addToIndex(word.toLowerCase(), settingKey);
      }
    }
  }

  void _addToIndex(String term, String settingKey) {
    _termToKeys.putIfAbsent(term, () => {}).add(settingKey);
    _keyToTerms.putIfAbsent(settingKey, () => {}).add(term);
  }

  /// Rebuild the index.
  ///
  /// Call this after adding new settings or when the localization changes.
  Future<void> rebuild() async {
    _built = false;
    await build();
  }

  /// Search for settings matching the query.
  ///
  /// Returns a list of [SearchResult] sorted by relevance (highest first).
  ///
  /// The search is case-insensitive and supports:
  /// - Exact matches (highest score)
  /// - Prefix matches
  /// - Contains matches
  /// - Multi-word queries (all words must match)
  List<SearchResult> search(String query) {
    if (!_built) {
      throw StateError('SearchIndex not built. Call build() first.');
    }

    if (query.isEmpty) {
      return [];
    }

    final normalizedQuery = query.toLowerCase().trim();
    final queryWords = normalizedQuery.split(RegExp(r'\s+'));

    // Track scores for each setting
    final scores = <String, _ScoreAccumulator>{};

    for (final word in queryWords) {
      _searchWord(word, scores);
    }

    // Filter to settings that matched all query words (for multi-word queries)
    if (queryWords.length > 1) {
      scores.removeWhere((key, acc) => acc.wordMatches < queryWords.length);
    }

    // Convert to results
    final results = <SearchResult>[];
    for (final entry in scores.entries) {
      final setting = registry.get(entry.key);
      if (setting != null && setting.visible) {
        results.add(SearchResult(
          setting: setting,
          score: entry.value.totalScore,
          matchedTerm: entry.value.bestMatch,
          matchedLocale: entry.value.bestMatchLocale,
        ));
      }
    }

    // Sort by score (descending)
    results.sort((a, b) => b.score.compareTo(a.score));

    return results;
  }

  void _searchWord(String word, Map<String, _ScoreAccumulator> scores) {
    // Exact matches
    final exactMatches = _termToKeys[word];
    if (exactMatches != null) {
      for (final key in exactMatches) {
        scores.putIfAbsent(key, () => _ScoreAccumulator());
        scores[key]!.addMatch(word, 10.0);
      }
    }

    // Prefix and contains matches
    for (final entry in _termToKeys.entries) {
      final term = entry.key;
      
      // Skip exact matches (already handled)
      if (term == word) continue;

      double score = 0;
      if (term.startsWith(word)) {
        // Prefix match - score based on length ratio
        score = 8.0 * (word.length / term.length);
      } else if (term.contains(word)) {
        // Contains match - lower score
        score = 4.0 * (word.length / term.length);
      } else if (word.length >= 3 && _fuzzyMatch(word, term)) {
        // Fuzzy match for longer queries
        score = 2.0;
      }

      if (score > 0) {
        for (final key in entry.value) {
          scores.putIfAbsent(key, () => _ScoreAccumulator());
          scores[key]!.addMatch(term, score);
        }
      }
    }
  }

  /// Simple fuzzy matching using Levenshtein distance threshold.
  bool _fuzzyMatch(String query, String term) {
    if ((query.length - term.length).abs() > 3) return false;
    
    // Simple character overlap check
    int matches = 0;
    for (final char in query.split('')) {
      if (term.contains(char)) matches++;
    }
    return matches / query.length >= 0.7;
  }

  /// Get all indexed terms for a setting.
  Set<String> getTermsForSetting(String settingKey) {
    return _keyToTerms[settingKey] ?? {};
  }

  /// Get statistics about the index.
  Map<String, int> get stats => {
        'totalTerms': _termToKeys.length,
        'totalSettings': _keyToTerms.length,
        'avgTermsPerSetting': _keyToTerms.isEmpty
            ? 0
            : (_termToKeys.values.fold<int>(
                    0, (sum, set) => sum + set.length) /
                _keyToTerms.length)
            .round(),
      };

  /// Clear the index.
  void clear() {
    _termToKeys.clear();
    _keyToTerms.clear();
    _built = false;
  }
}

class _ScoreAccumulator {
  double totalScore = 0;
  int wordMatches = 0;
  String bestMatch = '';
  String? bestMatchLocale;
  double _bestScore = 0;

  void addMatch(String term, double score) {
    totalScore += score;
    wordMatches++;
    if (score > _bestScore) {
      _bestScore = score;
      bestMatch = term;
    }
  }
}

/// Adapter for easy_localization package.
///
/// Use this if your app uses easy_localization for i18n.
///
/// Example:
/// ```dart
/// // Ensure easy_localization is initialized first
/// await EasyLocalization.ensureInitialized();
///
/// final adapter = EasyLocalizationAdapter(supportedLocales);
/// final index = SearchIndex(
///   registry: registry,
///   localizationProvider: adapter,
/// );
/// ```
class EasyLocalizationAdapter implements LocalizationProvider {
  final List<Locale> _supportedLocales;

  /// Create an adapter with the supported locales.
  EasyLocalizationAdapter(this._supportedLocales);

  @override
  List<Locale> get supportedLocales => _supportedLocales;

  @override
  String translate(String key, {required Locale locale}) {
    // Default implementation returns the key
    // Apps should override this or use the actual easy_localization call
    return key;
  }

  @override
  bool get isReady => true;
}

/// Simple localization provider using a map of translations.
///
/// Useful for testing or simple apps without a full i18n setup.
class MapLocalizationProvider implements LocalizationProvider {
  /// Translations: locale code -> key -> translation.
  final Map<String, Map<String, String>> translations;

  const MapLocalizationProvider(this.translations);

  @override
  List<Locale> get supportedLocales =>
      translations.keys.map((code) => Locale(code)).toList();

  @override
  String translate(String key, {required Locale locale}) {
    return translations[locale.languageCode]?[key] ?? key;
  }

  @override
  bool get isReady => translations.isNotEmpty;
}

