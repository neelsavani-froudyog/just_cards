import 'package:flutter/material.dart';

/// Compact download control for CSV export toolbars (next to search).
class CsvExportDownloadChip extends StatelessWidget {
  const CsvExportDownloadChip({
    super.key,
    required this.busy,
    required this.onPressed,
    required this.foreground,
    this.label = 'Download',
    this.tooltip,
    this.minimal = false,
  });

  final bool busy;
  final VoidCallback? onPressed;
  final Color foreground;
  final String label;
  final String? tooltip;

  /// Light text+icon style without the filled chip (e.g. below a full-width search).
  final bool minimal;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null && !busy;

    if (minimal) {
      final link = InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (busy)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: foreground,
                  ),
                )
              else
                Icon(
                  Icons.download_rounded,
                  size: 20,
                  color: foreground.withValues(alpha: disabled ? 0.38 : 0.88),
                ),
              if (label.isNotEmpty) ...[
                const SizedBox(width: 6),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: foreground.withValues(alpha: disabled ? 0.38 : 0.82),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
      final t = tooltip;
      if (t != null && t.isNotEmpty) {
        return Tooltip(message: t, child: link);
      }
      return link;
    }

    final chip = Material(
      color: foreground.withValues(alpha: disabled ? 0.07 : 0.14),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (busy)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: foreground,
                    ),
                  )
                else
                  Icon(
                    Icons.download_rounded,
                    size: 22,
                    color: foreground.withValues(alpha: disabled ? 0.45 : 1),
                  ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: foreground.withValues(alpha: disabled ? 0.45 : 1),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final t = tooltip;
    if (t != null && t.isNotEmpty) {
      return Tooltip(message: t, child: chip);
    }
    return chip;
  }
}
