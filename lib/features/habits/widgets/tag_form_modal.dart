import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:drift/drift.dart' as drift;
import '../../../../core/database/app_database.dart' as db;
import '../providers/habit_providers.dart';
import 'form_icon_constants.dart';
import 'color_picker_widget.dart';
import 'icon_picker_widget.dart';

class TagFormModal extends ConsumerStatefulWidget {
  final int? tagId;

  const TagFormModal({super.key, this.tagId});

  static Future<void> show(BuildContext context, {int? tagId}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TagFormModal(tagId: tagId),
    ).then((_) {});
  }

  @override
  ConsumerState<TagFormModal> createState() => _TagFormModalState();
}

class _TagFormModalState extends ConsumerState<TagFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  int _selectedColor = FormIconConstants.availableColors.first.toARGB32();
  String? _selectedIcon;

  @override
  void initState() {
    super.initState();
    if (widget.tagId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadTag();
      });
    }
  }

  Future<void> _loadTag() async {
    final repository = ref.read(habitRepositoryProvider);
    final tag = await repository.getTagById(widget.tagId!);
    if (tag != null && mounted) {
      setState(() {
        _nameController.text = tag.name;
        _selectedColor = tag.color;
        _selectedIcon = tag.icon;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveTag() async {
    if (!_formKey.currentState!.validate()) return;

    final repository = ref.read(habitRepositoryProvider);
    final now = DateTime.now();

    final tag = db.TagsCompanion(
      id: widget.tagId == null
          ? const drift.Value.absent()
          : drift.Value(widget.tagId!),
      name: drift.Value(_nameController.text.trim()),
      color: drift.Value(_selectedColor),
      icon: _selectedIcon == null
          ? const drift.Value.absent()
          : drift.Value(_selectedIcon!),
      createdAt: widget.tagId == null
          ? drift.Value(now)
          : const drift.Value.absent(),
    );

    if (widget.tagId == null) {
      await repository.createTag(tag);
    } else {
      await repository.updateTag(tag);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.tagId == null ? 'new_tag'.tr() : 'edit_tag'.tr(),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                // Form
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'tag_name'.tr(),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.label),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'please_enter_tag_name'.tr();
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Color
                          Text(
                            'color'.tr(),
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                                ),
                          ),
                          const SizedBox(height: 12),
                          ColorPickerWidget(
                            selectedColor: _selectedColor,
                            onColorSelected: (color) {
                              setState(() => _selectedColor = color);
                            },
                          ),
                          const SizedBox(height: 20),

                          // Icon
                          Text(
                            'select_icon'.tr(),
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                                ),
                          ),
                          const SizedBox(height: 12),
                          IconPickerWidget(
                            selectedIcon: _selectedIcon,
                            onIconSelected: (icon) {
                              setState(() => _selectedIcon = icon);
                            },
                          ),
                          const SizedBox(height: 24),

                          // Save Button
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _saveTag,
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                'save'.tr(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
