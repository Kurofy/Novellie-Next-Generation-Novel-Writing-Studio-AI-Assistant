import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../core/theme/theme.dart';
import 'import_index_entity_dialog.dart';

class EditorToolbar extends StatelessWidget {
  final QuillController controller;
  final String novelId;
  final ValueChanged<String> onInsertImage;
  final ValueChanged<IndexEntityItem> onInsertEntity;

  const EditorToolbar({
    super.key,
    required this.controller,
    required this.novelId,
    required this.onInsertImage,
    required this.onInsertEntity,
  });

  void _insertText(String text) {
    final selection = controller.selection;
    final offset = selection.baseOffset >= 0 ? selection.baseOffset : 0;
    controller.replaceText(offset, 0, text, null);
    controller.updateSelection(
      TextSelection.collapsed(offset: offset + text.length),
      ChangeSource.local,
    );
  }

  void _wrapSelection(String open, String close) {
    final selection = controller.selection;
    if (selection.isCollapsed || selection.baseOffset < 0) {
      _insertText('$open$close');
      return;
    }
    final start = selection.start;
    final end = selection.end;
    final len = end - start;
    final plainText = controller.document.toPlainText();
    final selectedText = plainText.substring(start, end);
    controller.replaceText(start, len, '$open$selectedText$close', null);
    controller.updateSelection(
      TextSelection(
        baseOffset: start + open.length,
        extentOffset: start + open.length + selectedText.length,
      ),
      ChangeSource.local,
    );
  }

  Future<void> _pickAndInsertImage(BuildContext context) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked != null) {
        onInsertImage(picked.path);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  void _showLinkDialog(BuildContext context) {
    final selection = controller.selection;
    String selectedText = '';
    if (!selection.isCollapsed && selection.baseOffset >= 0) {
      final plainText = controller.document.toPlainText();
      selectedText = plainText.substring(selection.start, selection.end);
    }

    final urlController = TextEditingController();
    final textController = TextEditingController(text: selectedText);

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Insert Hyperlink'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                labelText: 'Display Text',
                hintText: 'e.g. Reference Note or Chapter link',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: urlController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Link URL / Destination',
                hintText: 'https://...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final url = urlController.text.trim();
              final text = textController.text.trim();
              if (url.isNotEmpty) {
                Navigator.of(ctx).pop();
                if (selection.isCollapsed || text != selectedText) {
                  final displayText = text.isNotEmpty ? text : url;
                  final offset =
                      selection.baseOffset >= 0 ? selection.baseOffset : 0;
                  controller.replaceText(offset, 0, displayText, null);
                  controller.formatText(
                    offset,
                    displayText.length,
                    LinkAttribute(url),
                  );
                } else {
                  controller.formatSelection(LinkAttribute(url));
                }
              }
            },
            child: const Text('Insert Link'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleImportFromIndex(BuildContext context) async {
    FocusScope.of(context).unfocus();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (!context.mounted) return;
    final entity = await ImportIndexEntityDialog.show(context, novelId);
    if (entity != null) {
      onInsertEntity(entity);
    }
  }

  void _clearFormatting() {
    controller.formatSelection(Attribute.clone(Attribute.bold, null));
    controller.formatSelection(Attribute.clone(Attribute.italic, null));
    controller.formatSelection(Attribute.clone(Attribute.underline, null));
    controller.formatSelection(Attribute.clone(Attribute.strikeThrough, null));
    controller.formatSelection(Attribute.clone(Attribute.link, null));
  }

  Widget _buildIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    Color? color,
    double size = 18,
  }) {
    return IconButton(
      icon: Icon(icon, size: size, color: color),
      tooltip: tooltip,
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      splashRadius: 16,
      onPressed: onPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Container(
      height: 48,
      constraints: const BoxConstraints(maxHeight: 52),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(
          top: BorderSide(color: c.outlineVariant, width: 0.5),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: 2,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Undo / Redo
            _buildIconButton(
              icon: Symbols.undo,
              tooltip: 'Undo',
              size: 16,
              onPressed: () => controller.undo(),
            ),
            _buildIconButton(
              icon: Symbols.redo,
              tooltip: 'Redo',
              size: 16,
              onPressed: () => controller.redo(),
            ),
            const VerticalDivider(width: 12, indent: 8, endIndent: 8),

            // Bold, Italic, Underline, Clear Formatting
            _buildIconButton(
              icon: Symbols.format_bold,
              tooltip: 'Bold',
              size: 18,
              onPressed: () => controller.formatSelection(
                controller.getSelectionStyle().containsKey(Attribute.bold.key)
                    ? Attribute.clone(Attribute.bold, null)
                    : Attribute.bold,
              ),
            ),
            _buildIconButton(
              icon: Symbols.format_italic,
              tooltip: 'Italic',
              size: 18,
              onPressed: () => controller.formatSelection(
                controller.getSelectionStyle().containsKey(Attribute.italic.key)
                    ? Attribute.clone(Attribute.italic, null)
                    : Attribute.italic,
              ),
            ),
            _buildIconButton(
              icon: Symbols.format_underlined,
              tooltip: 'Underline',
              size: 18,
              onPressed: () => controller.formatSelection(
                controller
                        .getSelectionStyle()
                        .containsKey(Attribute.underline.key)
                    ? Attribute.clone(Attribute.underline, null)
                    : Attribute.underline,
              ),
            ),
            _buildIconButton(
              icon: Symbols.format_clear,
              tooltip: 'Clear Formatting',
              size: 16,
              onPressed: _clearFormatting,
            ),
            const VerticalDivider(width: 12, indent: 8, endIndent: 8),

            // Text Alignment (Left, Center, Right, Justified)
            _buildIconButton(
              icon: Symbols.format_align_left,
              tooltip: 'Align Left',
              size: 18,
              onPressed: () =>
                  controller.formatSelection(Attribute.leftAlignment),
            ),
            _buildIconButton(
              icon: Symbols.format_align_center,
              tooltip: 'Align Center',
              size: 18,
              onPressed: () =>
                  controller.formatSelection(Attribute.centerAlignment),
            ),
            _buildIconButton(
              icon: Symbols.format_align_right,
              tooltip: 'Align Right',
              size: 18,
              onPressed: () =>
                  controller.formatSelection(Attribute.rightAlignment),
            ),
            _buildIconButton(
              icon: Symbols.format_align_justify,
              tooltip: 'Justify Alignment',
              size: 18,
              onPressed: () =>
                  controller.formatSelection(Attribute.justifyAlignment),
            ),
            const VerticalDivider(width: 12, indent: 8, endIndent: 8),

            // Typography Insertions: Smart Quotes, Guillemets (« »), Em Dash (—)
            Tooltip(
              message: 'Insert Smart Quotes (“ ”)',
              child: TextButton(
                style: TextButton.styleFrom(
                  minimumSize: const Size(28, 28),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                ),
                onPressed: () => _wrapSelection('“', '”'),
                child: const Text(
                  '“ ”',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Tooltip(
              message: 'Insert Guillemets (« »)',
              child: TextButton(
                style: TextButton.styleFrom(
                  minimumSize: const Size(28, 28),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                ),
                onPressed: () => _wrapSelection('« ', ' »'),
                child: const Text(
                  '« »',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Tooltip(
              message: 'Insert Em Dash (—)',
              child: TextButton(
                style: TextButton.styleFrom(
                  minimumSize: const Size(28, 28),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                ),
                onPressed: () => _insertText('—'),
                child: const Text(
                  '—',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const VerticalDivider(width: 12, indent: 8, endIndent: 8),

            // Hyperlinks & Media
            _buildIconButton(
              icon: Symbols.link,
              tooltip: 'Insert Hyperlink',
              size: 18,
              onPressed: () => _showLinkDialog(context),
            ),
            _buildIconButton(
              icon: Symbols.add_photo_alternate,
              tooltip: 'Insert Image from Device',
              size: 18,
              onPressed: () => _pickAndInsertImage(context),
            ),
            const VerticalDivider(width: 12, indent: 8, endIndent: 8),

            // Import from Index (Character / Location / Faction)
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: c.primary,
                backgroundColor: c.primarySoft,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: const Size(32, 28),
              ),
              icon: const Icon(Symbols.bookmark_add, size: 15),
              label: const Text(
                'Import from Index',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
              onPressed: () => _handleImportFromIndex(context),
            ),
          ],
        ),
      ),
    );
  }
}
