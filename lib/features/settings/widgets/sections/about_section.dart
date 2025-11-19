import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// About section (app info, links, legal)
class AboutSectionContent extends ConsumerWidget {
  final Function(BuildContext) showLibrariesDialog;
  final Function(BuildContext) showLicenseDialog;
  final Function(BuildContext) showUsageRightsDialog;
  final Function(BuildContext) showPrivacyPolicyDialog;
  final Function(BuildContext, String) launchUrl;

  const AboutSectionContent({
    super.key,
    required this.showLibrariesDialog,
    required this.showLicenseDialog,
    required this.showUsageRightsDialog,
    required this.showPrivacyPolicyDialog,
    required this.launchUrl,
  });

  Future<PackageInfo?> _getPackageInfo() async {
    try {
      return await PackageInfo.fromPlatform();
    } catch (e) {
      // Fallback for Linux when /proc/self/exe is not available
      // Return null and use fallback values in the UI
      return null;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<PackageInfo?>(
      future: _getPackageInfo(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListTile(
            leading: const CircularProgressIndicator(),
            title: Text('loading'.tr()),
          );
        }

        // Use fallback values if PackageInfo fails (e.g., on Linux)
        final packageInfo = snapshot.data;
        final appName = packageInfo?.appName ?? 'Adati';
        final version = packageInfo?.version ?? '0.1.0';
        final buildNumber = packageInfo?.buildNumber ?? '1';
        final packageName = packageInfo?.packageName ?? 'adati';

        return Column(
          children: [
            ListTile(
              leading: const Icon(Icons.apps),
              title: Text('app_name'.tr()),
              subtitle: Text(appName),
            ),
            ListTile(
              leading: const Icon(Icons.tag),
              title: Text('version'.tr()),
              subtitle: Text('$version ($buildNumber)'),
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: Text('description'.tr()),
              subtitle: Text('app_description'.tr()),
            ),
            ListTile(
              leading: const Icon(Icons.code),
              title: Text('package_name'.tr()),
              subtitle: Text(packageName),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: Text('developer'.tr()),
              subtitle: const Text('Shenepoy'),
            ),
            ListTile(
              leading: const Icon(Icons.code_off),
              title: Text('open_source_libraries'.tr()),
              subtitle: Text('open_source_libraries_description'.tr()),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showLibrariesDialog(context),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.gavel),
              title: Text('license'.tr()),
              subtitle: Text('license_description'.tr()),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showLicenseDialog(context),
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: Text('usage_rights'.tr()),
              subtitle: Text('usage_rights_description'.tr()),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showUsageRightsDialog(context),
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: Text('privacy_policy'.tr()),
              subtitle: Text('privacy_policy_description'.tr()),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showPrivacyPolicyDialog(context),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.link),
              title: Text('github'.tr()),
              subtitle: Text('view_source_code_on_github'.tr()),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => launchUrl(context, 'https://github.com/Zyzto/Adati'),
            ),
            ListTile(
              leading: const Icon(Icons.bug_report),
              title: Text('report_issue'.tr()),
              subtitle: Text('report_issue_description'.tr()),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => launchUrl(context, 'https://github.com/Zyzto/Adati/issues/new'),
            ),
            ListTile(
              leading: const Icon(Icons.lightbulb_outline),
              title: Text('suggest_feature'.tr()),
              subtitle: Text('suggest_feature_description'.tr()),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => launchUrl(
                context,
                'https://github.com/Zyzto/Adati/issues/new?template=feature_request.md',
              ),
            ),
          ],
        );
      },
    );
  }
}

