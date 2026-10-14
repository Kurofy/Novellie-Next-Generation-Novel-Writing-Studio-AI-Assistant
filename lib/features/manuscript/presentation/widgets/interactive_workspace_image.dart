import 'dart:io';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../core/theme/theme.dart';

enum WorkspaceImageFloat {
  floatLeft('Float Left'),
  center('Center'),
  floatRight('Float Right'),
  fullWidth('Full Width');

  final String label;
  const WorkspaceImageFloat(this.label);
}

enum WorkspaceImagePosition {
  top('Top (Before Text)'),
  bottom('Bottom (After Text)');

  final String label;
  const WorkspaceImagePosition(this.label);
}

class WorkspaceImageItem {
  final String id;
  final String path;
  double width;
  double height;
  WorkspaceImageFloat alignment;
  WorkspaceImagePosition position;
  String caption;

  WorkspaceImageItem({
    required this.id,
    required this.path,
    this.width = 300,
    this.height = 200,
    this.alignment = WorkspaceImageFloat.center,
    this.position = WorkspaceImagePosition.top,
    this.caption = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'path': path,
        'width': width,
        'height': height,
        'alignment': alignment.name,
        'position': position.name,
        'caption': caption,
      };

  factory WorkspaceImageItem.fromJson(Map<String, dynamic> json) =>
      WorkspaceImageItem(
        id: json['id'] as String? ?? '',
        path: json['path'] as String? ?? '',
        width: (json['width'] as num?)?.toDouble() ?? 300.0,
        height: (json['height'] as num?)?.toDouble() ?? 200.0,
        alignment: WorkspaceImageFloat.values.firstWhere(
          (e) => e.name == json['alignment'],
          orElse: () => WorkspaceImageFloat.center,
        ),
        position: WorkspaceImagePosition.values.firstWhere(
          (e) => e.name == json['position'],
          orElse: () => WorkspaceImagePosition.top,
        ),
        caption: json['caption'] as String? ?? '',
      );
}

class InteractiveWorkspaceImage extends StatefulWidget {
  final WorkspaceImageItem item;
  final VoidCallback onDelete;
  final ValueChanged<WorkspaceImageItem>? onChanged;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final VoidCallback? onTogglePosition;

  const InteractiveWorkspaceImage({
    super.key,
    required this.item,
    required this.onDelete,
    this.onChanged,
    this.onMoveUp,
    this.onMoveDown,
    this.onTogglePosition,
  });

  @override
  State<InteractiveWorkspaceImage> createState() =>
      _InteractiveWorkspaceImageState();
}

class _InteractiveWorkspaceImageState extends State<InteractiveWorkspaceImage> {
  bool _isSelected = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final item = widget.item;

    Alignment boxAlignment;
    switch (item.alignment) {
      case WorkspaceImageFloat.floatLeft:
        boxAlignment = Alignment.centerLeft;
        break;
      case WorkspaceImageFloat.center:
        boxAlignment = Alignment.center;
        break;
      case WorkspaceImageFloat.floatRight:
        boxAlignment = Alignment.centerRight;
        break;
      case WorkspaceImageFloat.fullWidth:
        boxAlignment = Alignment.center;
        break;
    }

    final displayWidth = item.alignment == WorkspaceImageFloat.fullWidth
        ? double.infinity
        : item.width;

    return Align(
      alignment: boxAlignment,
      child: GestureDetector(
        onTap: () {
          setState(() => _isSelected = !_isSelected);
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          width: displayWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Image Box with Transform Handles
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: _isSelected
                          ? Border.all(color: c.primary, width: 2)
                          : Border.all(color: c.outlineVariant),
                      boxShadow: _isSelected
                          ? [
                              BoxShadow(
                                color: c.primary.withValues(alpha: 0.25),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : [],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.file(
                      File(item.path),
                      width: displayWidth,
                      height: item.height,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: displayWidth,
                        height: item.height,
                        color: c.surfaceSecondary,
                        child: Center(
                          child: Icon(
                            Symbols.broken_image,
                            size: 40,
                            color: c.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 4 Corner Interactive Transform Handles (visible when selected)
                  if (_isSelected &&
                      item.alignment != WorkspaceImageFloat.fullWidth) ...[
                    // Bottom-Right Handle (Resize Width & Height)
                    Positioned(
                      right: -14,
                      bottom: -14,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanUpdate: (details) {
                          setState(() {
                            item.width =
                                (item.width + details.delta.dx).clamp(120.0, 700.0);
                            item.height =
                                (item.height + details.delta.dy).clamp(80.0, 600.0);
                          });
                          widget.onChanged?.call(item);
                        },
                        child: _buildHandle(c),
                      ),
                    ),
                    // Bottom-Left Handle
                    Positioned(
                      left: -14,
                      bottom: -14,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanUpdate: (details) {
                          setState(() {
                            item.width =
                                (item.width - details.delta.dx).clamp(120.0, 700.0);
                            item.height =
                                (item.height + details.delta.dy).clamp(80.0, 600.0);
                          });
                          widget.onChanged?.call(item);
                        },
                        child: _buildHandle(c),
                      ),
                    ),
                    // Top-Right Handle
                    Positioned(
                      right: -14,
                      top: -14,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanUpdate: (details) {
                          setState(() {
                            item.width =
                                (item.width + details.delta.dx).clamp(120.0, 700.0);
                            item.height =
                                (item.height - details.delta.dy).clamp(80.0, 600.0);
                          });
                          widget.onChanged?.call(item);
                        },
                        child: _buildHandle(c),
                      ),
                    ),
                    // Top-Left Handle
                    Positioned(
                      left: -14,
                      top: -14,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanUpdate: (details) {
                          setState(() {
                            item.width =
                                (item.width - details.delta.dx).clamp(120.0, 700.0);
                            item.height =
                                (item.height - details.delta.dy).clamp(80.0, 600.0);
                          });
                          widget.onChanged?.call(item);
                        },
                        child: _buildHandle(c),
                      ),
                    ),
                  ],
                ],
              ),

              // Interactive Toolbar (when selected)
              if (_isSelected) ...[
                const SizedBox(height: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    boxShadow: AppShadows.resolve(context, AppShadows.soft),
                    border: Border.all(color: c.outlineVariant),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Float Left
                      IconButton(
                        icon: Icon(
                          Symbols.format_align_left,
                          size: 18,
                          color: item.alignment == WorkspaceImageFloat.floatLeft
                              ? c.primary
                              : c.textSecondary,
                        ),
                        tooltip: 'Float Left',
                        onPressed: () {
                          setState(() {
                            item.alignment = WorkspaceImageFloat.floatLeft;
                          });
                          widget.onChanged?.call(item);
                        },
                      ),
                      // Center
                      IconButton(
                        icon: Icon(
                          Symbols.format_align_center,
                          size: 18,
                          color: item.alignment == WorkspaceImageFloat.center
                              ? c.primary
                              : c.textSecondary,
                        ),
                        tooltip: 'Center',
                        onPressed: () {
                          setState(() {
                            item.alignment = WorkspaceImageFloat.center;
                          });
                          widget.onChanged?.call(item);
                        },
                      ),
                      // Float Right
                      IconButton(
                        icon: Icon(
                          Symbols.format_align_right,
                          size: 18,
                          color: item.alignment == WorkspaceImageFloat.floatRight
                              ? c.primary
                              : c.textSecondary,
                        ),
                        tooltip: 'Float Right',
                        onPressed: () {
                          setState(() {
                            item.alignment = WorkspaceImageFloat.floatRight;
                          });
                          widget.onChanged?.call(item);
                        },
                      ),
                      // Full Width
                      IconButton(
                        icon: Icon(
                          Symbols.width_full,
                          size: 18,
                          color: item.alignment == WorkspaceImageFloat.fullWidth
                              ? c.primary
                              : c.textSecondary,
                        ),
                        tooltip: 'Full Width',
                        onPressed: () {
                          setState(() {
                            item.alignment = WorkspaceImageFloat.fullWidth;
                          });
                          widget.onChanged?.call(item);
                        },
                      ),
                      const SizedBox(width: 4),
                      // Position: Top or Bottom of Chapter
                      IconButton(
                        icon: Icon(
                          item.position == WorkspaceImagePosition.top
                              ? Symbols.vertical_align_bottom
                              : Symbols.vertical_align_top,
                          size: 18,
                          color: c.primary,
                        ),
                        tooltip: item.position == WorkspaceImagePosition.top
                            ? 'Move to Bottom of Chapter'
                            : 'Move to Top of Chapter',
                        onPressed: () {
                          setState(() {
                            item.position =
                                item.position == WorkspaceImagePosition.top
                                    ? WorkspaceImagePosition.bottom
                                    : WorkspaceImagePosition.top;
                          });
                          widget.onChanged?.call(item);
                          widget.onTogglePosition?.call();
                        },
                      ),
                      if (widget.onMoveUp != null)
                        IconButton(
                          icon: const Icon(Symbols.arrow_upward, size: 18),
                          tooltip: 'Move Up in Order',
                          onPressed: widget.onMoveUp,
                        ),
                      if (widget.onMoveDown != null)
                        IconButton(
                          icon: const Icon(Symbols.arrow_downward, size: 18),
                          tooltip: 'Move Down in Order',
                          onPressed: widget.onMoveDown,
                        ),
                      const SizedBox(width: 4),
                      // Edit Caption
                      IconButton(
                        icon: Icon(
                          Symbols.subtitles,
                          size: 18,
                          color: item.caption.isNotEmpty
                              ? c.primary
                              : c.textSecondary,
                        ),
                        tooltip: 'Edit Caption',
                        onPressed: () => _editCaption(context),
                      ),
                      const SizedBox(width: 4),
                      // Scale presets dropdown/menu
                      PopupMenuButton<double>(
                        icon: Icon(
                          Symbols.aspect_ratio,
                          size: 18,
                          color: c.textSecondary,
                        ),
                        tooltip: 'Scale Image',
                        onSelected: (scale) {
                          setState(() {
                            item.width = (300 * scale).clamp(120.0, 700.0);
                            item.height = (200 * scale).clamp(80.0, 600.0);
                          });
                          widget.onChanged?.call(item);
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 0.5, child: Text('50%')),
                          const PopupMenuItem(value: 0.75, child: Text('75%')),
                          const PopupMenuItem(value: 1.0, child: Text('100%')),
                          const PopupMenuItem(value: 1.25, child: Text('125%')),
                          const PopupMenuItem(value: 1.5, child: Text('150%')),
                        ],
                      ),
                      const SizedBox(width: 4),
                      // Delete
                      IconButton(
                        icon: Icon(Symbols.delete, size: 18, color: c.error),
                        tooltip: 'Remove Image',
                        onPressed: widget.onDelete,
                      ),
                    ],
                  ),
                ),
              ],
              if (item.caption.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  item.caption,
                  style: AppTypography.bodySm.copyWith(
                    color: c.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _editCaption(BuildContext context) {
    final controller = TextEditingController(text: widget.item.caption);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Image Caption'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Caption',
            hintText: 'e.g. Map of Eldoria, Scene Illustration',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              setState(() => widget.item.caption = controller.text.trim());
              widget.onChanged?.call(widget.item);
              Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle(AppColors c) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      color: Colors.transparent,
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: c.surface,
          shape: BoxShape.circle,
          border: Border.all(color: c.primary, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 4,
            ),
          ],
        ),
      ),
    );
  }
}
