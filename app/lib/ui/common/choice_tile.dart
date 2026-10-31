import 'package:flutter/material.dart';

/// One selectable answer, with room for a line explaining it.
///
/// Hand-rolled rather than a `RadioListTile` so that a choice can carry its
/// own explanation without fighting the list tile's layout, and so the
/// selected state is a single obvious thing in the widget tree for tests to
/// assert on.
class ChoiceTile extends StatelessWidget {
  const ChoiceTile({
    required this.title,
    required this.selected,
    required this.onTap,
    this.detail,
    this.trailing,
    this.multiSelect = false,
    super.key,
  });

  final String title;
  final String? detail;
  final bool selected;
  final VoidCallback onTap;

  /// Shown after the title, for a badge such as camera support.
  final Widget? trailing;

  /// Draws a checkbox instead of a radio mark, for questions that take more
  /// than one answer.
  final bool multiSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedColor = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: selected
            ? selectedColor.withValues(alpha: 0.12)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _icon,
                  size: 22,
                  color: selected
                      ? selectedColor
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleSmall),
                      if (detail != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          detail!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData get _icon => multiSelect
      ? (selected ? Icons.check_box : Icons.check_box_outline_blank)
      : (selected ? Icons.radio_button_checked : Icons.radio_button_unchecked);
}

/// A titled block of questions, with optional explanatory text.
class QuestionSection extends StatelessWidget {
  const QuestionSection({
    required this.title,
    required this.children,
    this.body,
    super.key,
  });

  final String title;
  final String? body;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.headlineSmall),
        if (body != null) ...[
          const SizedBox(height: 8),
          Text(
            body!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }
}
