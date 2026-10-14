import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../core/theme/theme.dart';

enum NvSaveState {
  saved,
  saving,
  failed,
}

class NvSaveStatus extends StatelessWidget {
  const NvSaveStatus({
    super.key,
    required this.state,
    this.customText,
  });

  final NvSaveState state;
  final String? customText;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    IconData icon;
    String text;
    Color color;
    double fill = 0.0;

    switch (state) {
      case NvSaveState.saved:
        icon = Symbols.check_circle;
        text = customText ?? 'Saved just now';
        color = c.success;
        fill = 1.0;
        break;
      case NvSaveState.saving:
        icon = Symbols.sync;
        text = customText ?? 'Saving…';
        color = c.textSecondary;
        break;
      case NvSaveState.failed:
        icon = Symbols.error;
        text = customText ?? 'Not saved — retrying';
        color = c.warning;
        break;
    }

    return Semantics(
      liveRegion: true,
      label: text,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: color,
            fill: fill,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            text,
            style: AppTypography.labelSm.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
