import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/database/app_database.dart' as db;
import '../providers/habit_providers.dart';
import 'tag_form_modal.dart';

class TagManagementWidget extends ConsumerWidget {
  const TagManagementWidget({super.key});

  Future<void> _deleteTag(
    BuildContext context,
    WidgetRef ref,
    db.Tag tag,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('delete_tag'.tr()),
        content: Text(
          'delete_tag_confirmation'.tr(namedArgs: {'name': tag.name}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('delete'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final repository = ref.read(habitRepositoryProvider);
      await repository.deleteTag(tag.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('tag_deleted'.tr()),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(tagsProvider);

    return tagsAsync.when(
      data: (tags) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'manage_tags'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton.icon(
                  onPressed: () {
                    TagFormModal.show(context).then((_) {
                      if (context.mounted) {
                        ref.invalidate(tagsProvider);
                      }
                    });
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: Text('create_tag'.tr()),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (tags.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.label_outline,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'no_tags_available'.tr(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'create_first_tag'.tr(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[500],
                            ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tags.length,
                itemBuilder: (context, index) {
                  final tag = tags[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(tag.color).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: tag.icon != null
                            ? Icon(
                                IconData(
                                  int.parse(tag.icon!),
                                  fontFamily: 'MaterialIcons',
                                ),
                                color: Color(tag.color),
                                size: 24,
                              )
                            : Icon(
                                Icons.label,
                                color: Color(tag.color),
                                size: 24,
                              ),
                      ),
                      title: Text(tag.name),
                      subtitle: Text(
                        'tag_color'.tr(),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            tooltip: 'edit_tag'.tr(),
                            onPressed: () {
                              TagFormModal.show(context, tagId: tag.id).then((_) {
                                if (context.mounted) {
                                  ref.invalidate(tagsProvider);
                                }
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20),
                            tooltip: 'delete_tag'.tr(),
                            color: Colors.red,
                            onPressed: () => _deleteTag(context, ref, tag),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'error_loading_tags'.tr(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.red,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

