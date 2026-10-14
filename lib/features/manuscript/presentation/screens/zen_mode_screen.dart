import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/utils/word_counter.dart';
import '../../../settings/application/settings_providers.dart';
import '../../application/manuscript_providers.dart';

class ZenModeScreen extends ConsumerStatefulWidget {
  final String novelId;
  final String chapterId;

  const ZenModeScreen({
    super.key,
    required this.novelId,
    required this.chapterId,
  });

  @override
  ConsumerState<ZenModeScreen> createState() => _ZenModeScreenState();
}

class _ZenModeScreenState extends ConsumerState<ZenModeScreen> {
  QuillController? _controller;
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;
  int _wordCount = 0;
  bool _isDirty = false;
  bool _showControls = true;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    _loadChapter();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _hideControlsTimer?.cancel();
    _saveToDatabase();
    _controller?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChapter() async {
    final content = await ref
        .read(manuscriptRepositoryProvider)
        .getChapterContent(widget.chapterId);

    Document doc;
    try {
      final decoded = jsonDecode(content.deltaJson);
      if (decoded is List) {
        doc = Document.fromJson(decoded);
      } else if (decoded is Map<String, dynamic>) {
        final list = decoded['delta'] as List<dynamic>? ?? [];
        doc = Document.fromJson(list);
      } else {
        doc = Document()..insert(0, '\n');
      }
    } catch (_) {
      doc = Document()..insert(0, '\n');
    }

    _controller = QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );

    _wordCount = countWords(_controller!.document.toPlainText());
    _controller!.document.changes.listen((_) => _onContentChanged());

    if (mounted) {
      setState(() {});
    }
  }

  void _onContentChanged() {
    if (_controller == null) return;
    final plainText = _controller!.document.toPlainText();
    setState(() {
      _wordCount = countWords(plainText);
      _isDirty = true;
      _showControls = false;
    });

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 800), _saveToDatabase);

    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showControls = true);
    });
  }

  Future<void> _saveToDatabase() async {
    if (_controller == null || !_isDirty) return;

    final deltaJson = jsonEncode(_controller!.document.toDelta().toJson());
    final plainText = _controller!.document.toPlainText();
    final stats = countWordsAndCharacters(plainText);

    try {
      await ref.read(manuscriptActionsControllerProvider).saveChapterContent(
            widget.chapterId,
            deltaJson: deltaJson,
            plainText: plainText,
            wordCount: stats.words,
            charCount: stats.characters,
          );
      _isDirty = false;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final editorFontSize = ref.watch(editorFontSizeProvider);
    final editorFontFamily = ref.watch(editorFontFamilyProvider);

    if (_controller == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: c.canvas,
      body: SafeArea(
        child: Stack(
          children: [
            // Zen Distraction-Free Editor
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.x3,
                  vertical: AppSpacing.x2,
                ),
                child: QuillEditor.basic(
                  controller: _controller!,
                  scrollController: _scrollController,
                  config: QuillEditorConfig(
                    placeholder: 'Write without distraction...',
                    autoFocus: true,
                    expands: false,
                    padding: EdgeInsets.zero,
                    customStyles: AppEditorTypography.buildQuillStyles(
                      context,
                      fontSize: editorFontSize,
                      fontFamily: editorFontFamily,
                      textColor: c.textPrimary,
                    ),
                  ),
                ),
              ),
            ),

            // Top overlay bar (auto-fades during active typing)
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Symbols.close),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Exit Zen Mode',
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: c.surfaceSecondary,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        '$_wordCount words',
                        style: AppTypography.bodySm,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
