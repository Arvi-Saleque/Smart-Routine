import 'package:flutter/material.dart';

class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

IconData categoryIconFromName(String iconName) {
  return switch (iconName) {
    'menu_book' => Icons.menu_book_outlined,
    'code' => Icons.code,
    'work' => Icons.work_outline,
    'school' => Icons.school_outlined,
    'fitness_center' => Icons.fitness_center,
    'self_improvement' => Icons.self_improvement,
    'psychology' => Icons.psychology_outlined,
    'coffee' => Icons.coffee_outlined,
    'event_note' => Icons.event_note_outlined,
    'home' => Icons.home_outlined,
    _ => Icons.category_outlined,
  };
}
