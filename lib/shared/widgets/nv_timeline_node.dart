import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../core/theme/theme.dart';

enum NvTimelineNodeState {
  current,
  complete,
  upcoming,
  planned,
}

class NvTimelineNode extends StatelessWidget {
  const NvTimelineNode({
    super.key,
    required this.state,
    required this.child,
    this.index,
    this.isFirst = false,
    this.isLast = false,
  });

  final NvTimelineNodeState state;
  final Widget child;
  final int? index;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    Color discBg;
    Color discFg;
    Widget discContent;

    switch (state) {
      case NvTimelineNodeState.current:
        discBg = c.primaryFill;
        discFg = c.onPrimary;
        discContent = index != null
            ? Text(
                '$index',
                style: AppTypography.labelMd.copyWith(color: discFg),
              )
            : Icon(Symbols.edit, size: 14, color: discFg);
        break;
      case NvTimelineNodeState.complete:
        discBg = c.primarySoft;
        discFg = c.primary;
        discContent = Icon(Symbols.check, size: 16, color: discFg);
        break;
      case NvTimelineNodeState.upcoming:
      case NvTimelineNodeState.planned:
        discBg = c.canvas;
        discFg = c.textSecondary;
        discContent = index != null
            ? Text(
                '$index',
                style: AppTypography.labelMd.copyWith(color: discFg),
              )
            : Icon(Symbols.circle, size: 8, color: discFg);
        break;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 40,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Uninterrupted hairline track
                Positioned(
                  top: isFirst ? 20 : 0,
                  bottom: isLast ? 20 : 0,
                  child: Container(
                    width: 1,
                    color: c.timelineTrack,
                  ),
                ),
                // Centered disc
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: discBg,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: discContent,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
