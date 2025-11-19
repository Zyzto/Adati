import 'dart:io' show Platform, Process;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Static dialog methods for About section
class AboutDialogs {
  /// Launch URL with fallback for Linux
  static Future<void> launchUrlWithFallback(BuildContext context, String urlString) async {
    // Try url_launcher first, with Linux fallback using xdg-open
    try {
      final uri = Uri.parse(urlString);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return; // Success, exit early
    } on PlatformException {
      // If url_launcher fails on Linux, try xdg-open directly
      if (Platform.isLinux) {
        try {
          await Process.run('xdg-open', [urlString]);
          return; // Success with xdg-open
        } catch (e) {
          // xdg-open also failed, fall through to error handling
        }
      }
    } catch (e) {
      // Other errors, fall through to error handling
    }

    // If all methods failed, show error message with copy option
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'could_not_open_link'.tr(namedArgs: {'url': urlString}),
          ),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'copy'.tr(),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: urlString));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('url_copied_to_clipboard'.tr()),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ),
      );
    }
  }

  /// Show dialog with list of open source libraries used
  static void showLibrariesDialog(BuildContext context) {
    final packages = [
      {
        'name': 'flutter_riverpod',
        'version': '^3.0.1',
        'description': 'State management',
      },
      {
        'name': 'go_router',
        'version': '^17.0.0',
        'description': 'Navigation & routing',
      },
      {
        'name': 'easy_localization',
        'version': '^3.0.7',
        'description': 'Localization & i18n',
      },
      {'name': 'drift', 'version': '^2.18.0', 'description': 'Database ORM'},
      {
        'name': 'shared_preferences',
        'version': '^2.3.3',
        'description': 'Local storage',
      },
      {
        'name': 'file_picker',
        'version': '^10.3.6',
        'description': 'File handling',
      },
      {
        'name': 'url_launcher',
        'version': '^6.3.1',
        'description': 'URL launching',
      },
      {
        'name': 'flutter_local_notifications',
        'version': '^19.5.0',
        'description': 'Notifications',
      },
      {
        'name': 'animations',
        'version': '^2.1.0',
        'description': 'UI animations',
      },
      {
        'name': 'skeletonizer',
        'version': '^2.1.0+1',
        'description': 'Loading skeletons',
      },
      {
        'name': 'package_info_plus',
        'version': '^9.0.0',
        'description': 'App information',
      },
      {
        'name': 'intl',
        'version': '^0.20.2',
        'description': 'Internationalization',
      },
      {
        'name': 'timezone',
        'version': '^0.10.1',
        'description': 'Timezone support',
      },
      {'name': 'easy_logger', 'version': '^0.0.2', 'description': 'Logging'},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('packages_used'.tr()),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: packages.length,
            itemBuilder: (context, index) {
              final package = packages[index];
              return ListTile(
                dense: true,
                title: Text(
                  package['name'] as String,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${package['version']} - ${package['description']}',
                ),
                onTap: () =>
                    launchUrlWithFallback(context, 'https://pub.dev/packages/${package['name']}'),
                trailing: const Icon(Icons.open_in_new, size: 16),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ok'.tr()),
          ),
        ],
      ),
    );
  }

  /// Show license information dialog
  static void showLicenseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('license'.tr()),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'license_title'.tr(),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'license_description_full'.tr(),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'you_are_free_to'.tr(),
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('• ${'license_share'.tr()}'),
              Text('• ${'license_adapt'.tr()}'),
              const SizedBox(height: 16),
              Text(
                'under_following_terms'.tr(),
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('• ${'license_attribution'.tr()}'),
              Text('• ${'license_noncommercial'.tr()}'),
              Text('• ${'license_sharealike'.tr()}'),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => launchUrlWithFallback(
                  context,
                  'https://creativecommons.org/licenses/by-nc-sa/4.0/',
                ),
                child: Text('view_license'.tr()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ok'.tr()),
          ),
        ],
      ),
    );
  }

  /// Show usage rights and terms dialog
  static void showUsageRightsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('usage_rights'.tr()),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'terms_and_conditions'.tr(),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'usage_agreement'.tr(),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Text(
                '1. ${'usage_license_section'.tr()}',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('usage_license_text'.tr()),
              const SizedBox(height: 16),
              Text(
                '2. ${'usage_usage_section'.tr()}',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('• ${'usage_personal'.tr()}'),
              Text('• ${'usage_modify'.tr()}'),
              Text('• ${'usage_attribution'.tr()}'),
              const SizedBox(height: 16),
              Text(
                '3. ${'usage_limitations_section'.tr()}',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('• ${'usage_no_commercial'.tr()}'),
              Text('• ${'usage_no_warranty'.tr()}'),
              Text('• ${'usage_at_own_risk'.tr()}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ok'.tr()),
          ),
        ],
      ),
    );
  }

  /// Show privacy policy dialog
  static void showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('privacy_policy'.tr()),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'privacy_policy'.tr(),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'privacy_data_storage'.tr(),
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('privacy_data_storage_text'.tr()),
              const SizedBox(height: 16),
              Text(
                'privacy_data_collection'.tr(),
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('privacy_data_collection_text'.tr()),
              const SizedBox(height: 16),
              Text(
                'privacy_permissions'.tr(),
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('• ${'privacy_notifications'.tr()}'),
              Text('• ${'privacy_file_access'.tr()}'),
              Text('• ${'privacy_network'.tr()}'),
              const SizedBox(height: 16),
              Text(
                'privacy_your_rights'.tr(),
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('privacy_your_rights_text'.tr()),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ok'.tr()),
          ),
        ],
      ),
    );
  }
}

