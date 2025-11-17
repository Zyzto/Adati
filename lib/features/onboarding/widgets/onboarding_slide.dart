import 'package:flutter/material.dart';

class OnboardingSlide extends StatelessWidget {
  final IconData? icon;
  final String? imagePath;
  final String title;
  final String description;
  final Color? iconColor;

  const OnboardingSlide({
    super.key,
    this.icon,
    this.imagePath,
    required this.title,
    required this.description,
    this.iconColor,
  }) : assert(icon != null || imagePath != null, 'Either icon or imagePath must be provided');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColorValue = iconColor ?? theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (imagePath != null)
            Image.asset(
              imagePath!,
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            )
          else if (icon != null)
            Icon(
              icon,
              size: 200,
              color: iconColorValue,
            ),
          const SizedBox(height: 48),
          Text(
            title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

