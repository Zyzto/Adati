import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../habits/widgets/forms/tag_management.dart';

/// Tags management section
class TagsSectionContent extends ConsumerWidget {
  const TagsSectionContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TagManagementWidget(),
        ),
      ],
    );
  }
}

