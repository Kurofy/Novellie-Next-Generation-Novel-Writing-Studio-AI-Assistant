import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../app/router/routes.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/utils/uuid_generator.dart';
import '../../../../shared/utils/word_counter.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../ai/application/ai_providers.dart';
import '../../../ai/presentation/screens/consistency_checker_dialog.dart';
import '../../../ai/presentation/utils/ai_markdown_to_quill.dart';
import '../../../ai/presentation/widgets/ai_chat_panel.dart';
import '../../../characters/presentation/screens/character_detail_screen.dart';
import '../../../settings/application/settings_providers.dart';
import '../../../tools/presentation/screens/writer_notes_screen.dart';
import '../../../world/presentation/screens/world_entry_detail_screen.dart';
import '../../application/manuscript_providers.dart';
import '../../domain/models/manuscript_models.dart';
import '../widgets/editor_find_replace_bar.dart';
import '../widgets/editor_toolbar.dart';
import '../widgets/import_index_entity_dialog.dart';
import '../widgets/interactive_workspace_image.dart';

class ChapterEditorScreen extends ConsumerStatefulWidget {
  final String novelId;
  final String chapterId;

  const ChapterEditorScreen({
    super.key,
    required this.novelId,
    required this.chapterId,
  });

  @override
  ConsumerState<ChapterEditorScreen> createState() =>
      _ChapterEditorScreenState();
}

class _ChapterEditorScreenState extends ConsumerState<ChapterEditorScreen>
    with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  QuillController? _controller;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  late TextEditingController _titleController;

  Timer? _debounceTimer;
  Timer? _maxWaitTimer;
  Timer? _wordCountDebounceTimer;
  bool _isDirty = false;
  NvSaveState _saveStatus = NvSaveState.saved;
  WordCountResult _wordStats = WordCountResult.zero;
  bool _isInitialized = false;

  // Workspace Navigations & Feature Flags
  bool _isReadingMode = false;
  bool _showFindReplace = false;
  double _zoomScale = 1.0;

  // Auto-Correction Toggles
  bool _smartQuotes = true;
  bool _guillemets = true;
  bool _hyphens = true;
  bool _ellipsis = true;
  bool _isAutoCorrecting = false;

  // Interactive Rich Content State
  final List<WorkspaceImageItem> _workspaceImages = [];
  final List<IndexEntityItem> _referencedEntities = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _titleController = TextEditingController();
    _loadChapter();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _flushPendingSave();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _flushPendingSave();
    _debounceTimer?.cancel();
    _maxWaitTimer?.cancel();
    _wordCountDebounceTimer?.cancel();
    _controller?.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _loadChapter() async {
    final chapter = await ref
        .read(manuscriptRepositoryProvider)
        .getChapter(widget.chapterId);
    if (chapter != null) {
      _titleController.text = chapter.title;
    }

    final content = await ref
        .read(manuscriptRepositoryProvider)
        .getChapterContent(widget.chapterId);

    Document doc;
    final List<WorkspaceImageItem> loadedImages = [];
    final List<IndexEntityItem> loadedEntities = [];
    try {
      final decoded = jsonDecode(content.deltaJson);
      if (decoded is Map<String, dynamic>) {
        final deltaList = decoded['delta'] as List<dynamic>? ?? [];
        doc = Document.fromJson(deltaList);
        if (decoded['images'] is List) {
          for (final item in decoded['images'] as List) {
            if (item is Map) {
              loadedImages.add(
                WorkspaceImageItem.fromJson(Map<String, dynamic>.from(item)),
              );
            }
          }
        }
        if (decoded['entities'] is List) {
          for (final item in decoded['entities'] as List) {
            if (item is Map) {
              loadedEntities.add(
                IndexEntityItem.fromJson(Map<String, dynamic>.from(item)),
              );
            }
          }
        }
      } else if (decoded is List) {
        doc = Document.fromJson(decoded);
      } else {
        doc = Document()..insert(0, '\n');
      }
    } catch (_) {
      doc = Document()..insert(0, '\n');
    }

    if (loadedImages.isEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString('chapter_images_${widget.chapterId}');
        if (raw != null && raw.isNotEmpty) {
          final list = jsonDecode(raw) as List<dynamic>;
          for (final item in list) {
            if (item is Map) {
              loadedImages.add(
                WorkspaceImageItem.fromJson(Map<String, dynamic>.from(item)),
              );
            }
          }
        }
      } catch (_) {}
    }

    if (loadedEntities.isEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString('chapter_entities_${widget.chapterId}');
        if (raw != null && raw.isNotEmpty) {
          final list = jsonDecode(raw) as List<dynamic>;
          for (final item in list) {
            if (item is Map) {
              loadedEntities.add(
                IndexEntityItem.fromJson(Map<String, dynamic>.from(item)),
              );
            }
          }
        }
      } catch (_) {}
    }

    _workspaceImages
      ..clear()
      ..addAll(loadedImages);

    _referencedEntities
      ..clear()
      ..addAll(loadedEntities);

    _controller = QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );

    _updateWordCount();
    _controller!.document.changes.listen(_onContentChanged);

    if (mounted) {
      setState(() => _isInitialized = true);
    }
  }

  void _onContentChanged([DocChange? docChange]) {
    // Debounce word count calculation to avoid heavy regex + setState during rapid typing or holding backspace
    _scheduleWordCountUpdate();

    // Auto-correction only triggers on text insertion, never during deletion / backspace
    final hasInsert = docChange == null ||
        docChange.change.operations.any((op) => op.isInsert);
    if (hasInsert) {
      _checkAndApplyAutoCorrection();
    }

    if (!_isDirty) {
      _isDirty = true;
      if (mounted) {
        setState(() {
          _saveStatus = NvSaveState.saving;
        });
      }
    }

    // Reset 800ms debounce (emergency recovery file is saved alongside debounced DB write)
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 800), _saveToDatabase);

    // Max 5s continuous wait
    _maxWaitTimer ??= Timer(const Duration(seconds: 5), () {
      _maxWaitTimer = null;
      _saveToDatabase();
    });
  }

  void _scheduleWordCountUpdate() {
    _wordCountDebounceTimer?.cancel();
    _wordCountDebounceTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) {
        _updateWordCount();
      }
    });
  }

  void _checkAndApplyAutoCorrection() {
    if (_isAutoCorrecting || _controller == null) return;
    final selection = _controller!.selection;
    if (!selection.isCollapsed || selection.baseOffset <= 0) return;

    final offset = selection.baseOffset;
    final plainText = _controller!.document.toPlainText();
    if (offset > plainText.length) return;

    _isAutoCorrecting = true;
    try {
      // 1. Ellipsis: Replace ... with …
      if (_ellipsis && offset >= 3) {
        final sub = plainText.substring(offset - 3, offset);
        if (sub == '...') {
          _controller!.replaceText(offset - 3, 3, '…', null);
          _controller!.updateSelection(
            TextSelection.collapsed(offset: offset - 2),
            ChangeSource.local,
          );
          return;
        }
      }

      // 2. Hyphens & Guillemets: Replace -- with —, << with «, >> with »
      if (offset >= 2) {
        final sub = plainText.substring(offset - 2, offset);
        if (_hyphens && sub == '--') {
          _controller!.replaceText(offset - 2, 2, '—', null);
          _controller!.updateSelection(
            TextSelection.collapsed(offset: offset - 1),
            ChangeSource.local,
          );
          return;
        }
        if (_guillemets && sub == '<<') {
          _controller!.replaceText(offset - 2, 2, '«', null);
          _controller!.updateSelection(
            TextSelection.collapsed(offset: offset - 1),
            ChangeSource.local,
          );
          return;
        }
        if (_guillemets && sub == '>>') {
          _controller!.replaceText(offset - 2, 2, '»', null);
          _controller!.updateSelection(
            TextSelection.collapsed(offset: offset - 1),
            ChangeSource.local,
          );
          return;
        }
      }

      // 3. Smart Quotes: Replace straight " with “ or ”
      if (_smartQuotes && offset >= 1) {
        final char = plainText[offset - 1];
        if (char == '"') {
          final prevChar = offset >= 2 ? plainText[offset - 2] : '';
          final isOpening =
              prevChar.isEmpty || RegExp(r'\s|[(\[{]').hasMatch(prevChar);
          final replacement = isOpening ? '“' : '”';
          _controller!.replaceText(offset - 1, 1, replacement, null);
          _controller!.updateSelection(
            TextSelection.collapsed(offset: offset),
            ChangeSource.local,
          );
          return;
        }
      }
    } finally {
      _isAutoCorrecting = false;
    }
  }

  void _runAutoCorrectionOnEntireChapter() {
    if (_controller == null) return;
    String text = _controller!.document.toPlainText();
    if (_ellipsis) {
      text = text.replaceAll('...', '…');
    }
    if (_hyphens) {
      text = text.replaceAll('--', '—');
    }
    if (_guillemets) {
      text = text.replaceAll('<<', '«').replaceAll('>>', '»');
    }
    if (_smartQuotes) {
      text = text.replaceAllMapped(
        RegExp(r'(^|[\s(\[{])"([^\s"])'),
        (m) => '${m.group(1)}“${m.group(2)}',
      );
      text = text.replaceAll('"', '”');
    }

    _controller!.document = Document()..insert(0, text);
    _onContentChanged();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Auto-Correction applied to entire chapter!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _updateWordCount() {
    if (_controller == null) return;
    final plainText = _controller!.document.toPlainText();
    setState(() {
      _wordStats = countWordsAndCharacters(plainText);
    });
  }

  Future<void> _handleInsertImage(String pickedPath) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir =
          Directory('${appDir.path}/workspace_images/${widget.novelId}');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }
      final ext = p.extension(pickedPath);
      final newName = '${generateUuid()}$ext';
      final savedFile =
          await File(pickedPath).copy('${imagesDir.path}/$newName');

      final item = WorkspaceImageItem(
        id: generateUuid(),
        path: savedFile.path,
        alignment: WorkspaceImageFloat.center,
      );
      setState(() {
        _workspaceImages.add(item);
      });
      _onContentChanged();
    } catch (_) {
      final item = WorkspaceImageItem(
        id: generateUuid(),
        path: pickedPath,
        alignment: WorkspaceImageFloat.center,
      );
      setState(() {
        _workspaceImages.add(item);
      });
      _onContentChanged();
    }
  }

  Future<void> _mirrorToRecoveryFile() async {
    if (_controller == null) return;
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/draft_${widget.chapterId}.json');
      final payload = {
        'delta': _controller!.document.toDelta().toJson(),
        'images': _workspaceImages.map((e) => e.toJson()).toList(),
        'entities': _referencedEntities.map((e) => e.toJson()).toList(),
      };
      await file.writeAsString(jsonEncode(payload));
    } catch (_) {}
  }

  Future<void> _saveToDatabase() async {
    _debounceTimer?.cancel();
    _maxWaitTimer?.cancel();
    _maxWaitTimer = null;

    if (_controller == null || !_isDirty) return;

    final deltaList = _controller!.document.toDelta().toJson();
    final imagesList = _workspaceImages.map((e) => e.toJson()).toList();
    final entitiesList = _referencedEntities.map((e) => e.toJson()).toList();
    final payload = {
      'delta': deltaList,
      'images': imagesList,
      'entities': entitiesList,
    };
    final deltaJson = jsonEncode(payload);
    final plainText = _controller!.document.toPlainText();

    // Cache image list and entities in SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'chapter_images_${widget.chapterId}',
        jsonEncode(imagesList),
      );
      await prefs.setString(
        'chapter_entities_${widget.chapterId}',
        jsonEncode(entitiesList),
      );
    } catch (_) {}

    // Mirror to recovery file asynchronously during debounced save
    unawaited(_mirrorToRecoveryFile());

    try {
      await ref.read(manuscriptActionsControllerProvider).saveChapterContent(
            widget.chapterId,
            deltaJson: deltaJson,
            plainText: plainText,
            wordCount: _wordStats.words,
            charCount: _wordStats.characters,
          );

      if (mounted) {
        setState(() {
          _isDirty = false;
          _saveStatus = NvSaveState.saved;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _saveStatus = NvSaveState.failed;
        });
      }
    }
  }

  void _flushPendingSave() {
    _wordCountDebounceTimer?.cancel();
    if (_controller != null) {
      _wordStats = countWordsAndCharacters(_controller!.document.toPlainText());
    }
    if (_isDirty) {
      _saveToDatabase();
    }
  }

  Future<void> _updateChapterTitle(String newTitle) async {
    final chapter = await ref
        .read(manuscriptRepositoryProvider)
        .getChapter(widget.chapterId);
    if (chapter != null) {
      final updated = ChapterModel(
        id: chapter.id,
        novelId: chapter.novelId,
        arcId: chapter.arcId,
        title: newTitle.trim(),
        position: chapter.position,
        sequenceNumber: chapter.sequenceNumber,
        status: chapter.status,
        wordCount: _wordStats.words,
        createdAt: chapter.createdAt,
        updatedAt: DateTime.now().toUtc(),
      );
      await ref
          .read(manuscriptActionsControllerProvider)
          .updateChapter(updated);
    }
  }

  void _showRenameTitleDialog() {
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    final controller = TextEditingController(text: _titleController.text);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isIndo ? 'Ubah Judul Bab' : 'Edit Chapter Title'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: isIndo ? 'Judul Bab' : 'Chapter Title',
            hintText: isIndo ? 'mis. Bab 1: Keberangkatan' : 'e.g. Chapter 1: The Departure',
          ),
          onSubmitted: (val) {
            Navigator.of(ctx).pop();
            final trimmed = val.trim();
            if (trimmed.isNotEmpty) {
              setState(() => _titleController.text = trimmed);
              _updateChapterTitle(trimmed);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(isIndo ? 'Batal' : 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              final trimmed = controller.text.trim();
              if (trimmed.isNotEmpty) {
                setState(() => _titleController.text = trimmed);
                _updateChapterTitle(trimmed);
              }
            },
            child: Text(isIndo ? 'Simpan' : 'Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _createSnapshot() async {
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    final defaultLabel = isIndo
        ? 'Snapshot ${DateFormat('d MMM, HH:mm').format(DateTime.now())}'
        : 'Snapshot ${DateFormat('MMM d, h:mm a').format(DateTime.now())}';
    final controller = TextEditingController(text: defaultLabel);

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isIndo ? 'Buat Snapshot Manual' : 'Create Manual Snapshot'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: isIndo ? 'Label Versi / Catatan' : 'Version Label / Note',
            hintText: isIndo ? 'mis. Sebelum penulisan ulang klimaks' : 'e.g. Before climax rewrite',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(isIndo ? 'Batal' : 'Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final label = controller.text.trim();
              Navigator.of(ctx).pop();
              if (_controller == null) return;

              final db = ref.read(appDatabaseProvider);
              final deltaJson =
                  jsonEncode(_controller!.document.toDelta().toJson());
              final now = DateTime.now().toUtc().millisecondsSinceEpoch;

              await db.into(db.chapterVersions).insert(
                    ChapterVersionsCompanion(
                      id: drift.Value(generateUuid()),
                      novelId: drift.Value(widget.novelId),
                      chapterId: drift.Value(widget.chapterId),
                      kind: const drift.Value('manual'),
                      label: drift.Value(
                        label.isNotEmpty
                            ? label
                            : (isIndo ? 'Cadangan Manual' : 'Manual Backup'),
                      ),
                      deltaZlib: drift.Value(utf8.encode(deltaJson)),
                      wordCount: drift.Value(_wordStats.words),
                      createdAt: drift.Value(now),
                    ),
                  );

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isIndo
                          ? 'Snapshot manual berhasil dibuat!'
                          : 'Manual snapshot created successfully!',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: Text(isIndo ? 'Buat Snapshot' : 'Create Snapshot'),
          ),
        ],
      ),
    );
  }

  void _showAutoCorrectionOptionsDialog() {
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isIndo ? 'Mesin Koreksi Otomatis' : 'Auto-Correction Engine'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: Text(isIndo ? 'Tanda Petik Pintar' : 'Smart Quotes'),
                subtitle: Text(
                  isIndo
                      ? 'Ganti " " dengan tanda petik lengkung “ ”'
                      : 'Replace " " with “ ” curly quotes',
                ),
                value: _smartQuotes,
                onChanged: (val) {
                  setDialogState(() => _smartQuotes = val);
                  setState(() => _smartQuotes = val);
                },
              ),
              SwitchListTile(
                title: Text(isIndo ? 'Guillemet' : 'Guillemets'),
                subtitle: Text(
                  isIndo ? 'Ganti << >> dengan « »' : 'Replace << >> with « »',
                ),
                value: _guillemets,
                onChanged: (val) {
                  setDialogState(() => _guillemets = val);
                  setState(() => _guillemets = val);
                },
              ),
              SwitchListTile(
                title: Text(isIndo ? 'Tanda Pisah (Em Dash)' : 'Em Dash'),
                subtitle: Text(
                  isIndo
                      ? 'Ganti tanda hubung ganda -- dengan —'
                      : 'Replace double hyphen -- with —',
                ),
                value: _hyphens,
                onChanged: (val) {
                  setDialogState(() => _hyphens = val);
                  setState(() => _hyphens = val);
                },
              ),
              SwitchListTile(
                title: Text(isIndo ? 'Elipsis Tipografi' : 'Typographic Ellipsis'),
                subtitle: Text(
                  isIndo ? 'Ganti ... dengan …' : 'Replace ... with …',
                ),
                value: _ellipsis,
                onChanged: (val) {
                  setDialogState(() => _ellipsis = val);
                  setState(() => _ellipsis = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _runAutoCorrectionOnEntireChapter();
              },
              child: Text(
                isIndo ? 'Terapkan ke Seluruh Bab' : 'Run on Entire Chapter',
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(isIndo ? 'Selesai' : 'Done'),
            ),
          ],
        ),
      ),
    );
  }

  void _insertTextFromAi(String text) {
    if (_controller == null) return;
    final doc = AiMarkdownToQuill.parse(text);
    final selection = _controller!.selection;
    var currentOffset = selection.baseOffset >= 0 ? selection.baseOffset : 0;

    _controller!.replaceText(currentOffset, 0, '\n', null);
    currentOffset += 1;

    for (final op in doc.toDelta().operations) {
      if (op.isInsert && op.data is String) {
        final str = op.data as String;
        _controller!.replaceText(currentOffset, 0, str, null);
        if (op.attributes != null && op.attributes!.isNotEmpty) {
          for (final attr in op.attributes!.entries) {
            final key = attr.key;
            final val = attr.value;
            Attribute<dynamic>? quAttr;
            if (key == 'bold') quAttr = Attribute.bold;
            if (key == 'italic') quAttr = Attribute.italic;
            if (key == 'strike') quAttr = Attribute.strikeThrough;
            if (key == 'header') {
              if (val == 1) quAttr = Attribute.h1;
              if (val == 2) quAttr = Attribute.h2;
              if (val == 3) quAttr = Attribute.h3;
            }
            if (key == 'blockquote') quAttr = Attribute.blockQuote;
            if (key == 'list') {
              if (val == 'bullet') quAttr = Attribute.ul;
              if (val == 'ordered') quAttr = Attribute.ol;
            }
            if (quAttr != null) {
              _controller!.formatText(currentOffset, str.length, quAttr);
            }
          }
        }
        currentOffset += str.length;
      }
    }

    _controller!.updateSelection(
      TextSelection.collapsed(offset: currentOffset),
      ChangeSource.local,
    );
  }

  void _handleInsertEntity(IndexEntityItem entity) {
    if (!_referencedEntities.any((e) => e.id == entity.id)) {
      setState(() => _referencedEntities.add(entity));
    }

    if (_controller == null) return;
    final selection = _controller!.selection;
    final offset = selection.baseOffset >= 0 ? selection.baseOffset : 0;
    // Clean index imports: Strip any unwanted @ prefix from workspace index imports
    final cleanIdentifier =
        entity.boundIdentifier.replaceFirst(RegExp(r'^@+'), '').trim();

    _controller!.replaceText(offset, 0, cleanIdentifier, null);
    _controller!.formatText(
      offset,
      cleanIdentifier.length,
      LinkAttribute(entity.entityLink),
    );
    _controller!.updateSelection(
      TextSelection.collapsed(offset: offset + cleanIdentifier.length),
      ChangeSource.local,
    );
  }

  void _removeReferencedEntity(IndexEntityItem entity, {bool showUndo = true}) {
    final index = _referencedEntities.indexWhere((e) => e.id == entity.id);

    // 1. Remove the link and its blue text from the workspace editor
    int? removedOffset;
    String? removedText;
    if (_controller != null) {
      final docDelta = _controller!.document.toDelta();
      var currentOffset = 0;
      final rangesToRemove = <({int offset, int length, String text})>[];

      for (final op in docDelta.operations) {
        final len =
            op.length ?? (op.data is String ? (op.data as String).length : 1);
        if (op.attributes != null &&
            op.attributes![Attribute.link.key] == entity.entityLink) {
          final text = op.data is String ? op.data as String : '';
          rangesToRemove.add((offset: currentOffset, length: len, text: text));
        }
        currentOffset += len;
      }

      // Remove in reverse order so character offsets do not shift
      for (final r in rangesToRemove.reversed) {
        removedOffset = r.offset;
        removedText = r.text;
        _controller!.replaceText(r.offset, r.length, '', null);
      }
    }

    // 2. Remove from referenced entities state
    if (index != -1) {
      setState(() {
        _referencedEntities.removeAt(index);
        _isDirty = true;
      });
      _saveToDatabase();
    }

    // 3. Fast auto-dismissing toast with Undo option
    if (showUndo && mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed "${entity.name}" from mentioned lore'),
          duration: const Duration(milliseconds: 2500),
          behavior: SnackBarBehavior.floating,
          dismissDirection: DismissDirection.horizontal,
          showCloseIcon: true,
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              setState(() {
                if (!_referencedEntities.any((e) => e.id == entity.id)) {
                  if (index != -1 && index <= _referencedEntities.length) {
                    _referencedEntities.insert(index, entity);
                  } else {
                    _referencedEntities.add(entity);
                  }
                  _isDirty = true;
                }
              });

              // Restore blue text in workspace document if it was removed
              if (_controller != null &&
                  removedOffset != null &&
                  removedText != null &&
                  removedText.isNotEmpty) {
                final safeOffset = removedOffset <= _controller!.document.length
                    ? removedOffset
                    : _controller!.document.length;
                _controller!.replaceText(safeOffset, 0, removedText, null);
                _controller!.formatText(
                  safeOffset,
                  removedText.length,
                  LinkAttribute(entity.entityLink),
                );
              }

              _saveToDatabase();
            },
          ),
        ),
      );
    }
  }

  Future<LinkMenuAction> _handleLinkActionPicker(
    BuildContext context,
    String link,
    Node node,
  ) async {
    if (link.startsWith('entity://')) {
      final uri = Uri.tryParse(link);
      final entityTypeStr = uri?.host ?? '';
      final entityId =
          uri?.pathSegments.isNotEmpty == true ? uri!.pathSegments.first : '';

      // Find referenced entity in current chapter's list
      IndexEntityItem? entity =
          _referencedEntities.cast<IndexEntityItem?>().firstWhere(
                (e) => e?.id == entityId,
                orElse: () => null,
              );

      // Fallback: Reconstruct IndexEntityItem from node text and URI
      if (entity == null) {
        final nodeText = node.toPlainText().trim();
        final type = entityTypeStr == 'character'
            ? NvEntityType.character
            : (entityTypeStr == 'location'
                ? NvEntityType.location
                : (entityTypeStr == 'faction'
                    ? NvEntityType.faction
                    : NvEntityType.worldEntry));
        entity = IndexEntityItem(
          id: entityId,
          name: nodeText.isNotEmpty ? nodeText : 'Entity Mention',
          type: type,
        );
      }

      _showEntityDetailsModal(entity);
      return LinkMenuAction.none;
    }

    // Default web link action dialog for regular URLs
    return _showCustomWebLinkMenu(context, link);
  }

  Future<LinkMenuAction> _showCustomWebLinkMenu(
    BuildContext context,
    String link,
  ) async {
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    final result = await showModalBottomSheet<LinkMenuAction>(
      context: context,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                link,
                style: AppTypography.labelMd,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Symbols.open_in_new),
              title: Text(isIndo ? 'Buka di Browser' : 'Open in Browser'),
              onTap: () => Navigator.of(ctx).pop(LinkMenuAction.launch),
            ),
            ListTile(
              leading: const Icon(Symbols.content_copy),
              title: Text(isIndo ? 'Salin Tautan' : 'Copy Link'),
              onTap: () => Navigator.of(ctx).pop(LinkMenuAction.copy),
            ),
            ListTile(
              leading: Icon(Symbols.link_off, color: context.colors.error),
              title: Text(
                isIndo ? 'Hapus Tautan' : 'Remove Link',
                style: TextStyle(color: context.colors.error),
              ),
              onTap: () => Navigator.of(ctx).pop(LinkMenuAction.remove),
            ),
          ],
        ),
      ),
    );
    return result ?? LinkMenuAction.none;
  }

  void _showEntityDetailsModal(IndexEntityItem entity) {
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.75,
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.sheet),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Symbols.bookmark, color: context.colors.primary),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            entity.name,
                            style: AppTypography.screenTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Symbols.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${entity.type.name.toUpperCase()} · ${entity.subtitle ?? (isIndo ? "Referensi Lore Indeks" : "Index Lore Reference")}',
                style: AppTypography.bodySm.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: NvButton(
                      label: isIndo ? 'Buka di Indeks' : 'Open in Index',
                      variant: NvButtonVariant.primary,
                      icon: Symbols.open_in_new,
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        await Future<void>.delayed(
                          const Duration(milliseconds: 100),
                        );
                        if (!mounted) return;
                        if (entity.type == NvEntityType.character) {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => CharacterDetailScreen(
                                characterId: entity.id,
                              ),
                            ),
                          );
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => WorldEntryDetailScreen(
                                entryId: entity.id,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  NvButton(
                    label: isIndo ? 'Hapus Sebutan' : 'Remove Mention',
                    variant: NvButtonVariant.destructive,
                    icon: Symbols.delete,
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _removeReferencedEntity(entity);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showWorkspaceToolsDrawer(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    final c = context.colors;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.sheet),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top drag indicator
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 6),
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: c.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Symbols.tune, color: c.primary, size: 22),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            isIndo ? 'Alat Lembar Kerja' : 'Workspace Tools',
                            style: AppTypography.screenTitle.copyWith(
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Symbols.close),
                        onPressed: () => Navigator.of(sheetContext).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    children: [
                      // Section 1: Editor & Display Controls
                      Text(
                        isIndo ? 'EDITOR & TAMPILAN' : 'EDITOR & VIEW',
                        style: AppTypography.labelSm.copyWith(
                          color: c.textSecondary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),

                      // 1. Find & Replace
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _showFindReplace
                                ? c.primary.withValues(alpha: 0.15)
                                : c.surfaceSecondary,
                            borderRadius: BorderRadius.circular(AppRadius.card),
                          ),
                          child: Icon(
                            Symbols.find_replace,
                            color: _showFindReplace ? c.primary : c.textPrimary,
                            size: 20,
                          ),
                        ),
                        title: Text(isIndo ? 'Cari & Ganti' : 'Find & Replace'),
                        subtitle: Text(
                          _showFindReplace
                              ? (isIndo
                                  ? 'Bilah pencarian sedang aktif'
                                  : 'Search bar is currently active')
                              : (isIndo
                                  ? 'Cari dan ganti kata dalam bab'
                                  : 'Search and replace words in chapter'),
                          style: AppTypography.bodySm.copyWith(
                            color: c.textSecondary,
                          ),
                        ),
                        trailing: Switch(
                          value: _showFindReplace,
                          onChanged: (val) {
                            setState(() => _showFindReplace = val);
                            setSheetState(() {});
                          },
                        ),
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          setState(() => _showFindReplace = true);
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // 2. Workspace Zoom Scale with Interactive Chips
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: c.surfaceSecondary,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Symbols.zoom_in,
                                      size: 18,
                                      color: c.primary,
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    Text(
                                      isIndo ? 'Skala Lembar Kerja' : 'Workspace Zoom',
                                      style: AppTypography.cardTitle,
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: c.surface,
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.pill,
                                    ),
                                  ),
                                  child: Text(
                                    '${(_zoomScale * 100).toInt()}%',
                                    style: AppTypography.labelMd.copyWith(
                                      color: c.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Wrap(
                              spacing: AppSpacing.xs,
                              runSpacing: AppSpacing.xs,
                              children: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
                                  .map((scale) {
                                final isSelected =
                                    (_zoomScale - scale).abs() < 0.01;
                                return ChoiceChip(
                                  label: Text(
                                    scale == 1.0
                                        ? (isIndo ? '100% (Normal)' : '100% (Normal)')
                                        : '${(scale * 100).toInt()}%',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() => _zoomScale = scale);
                                      setSheetState(() {});
                                    }
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // 3. Auto-Correction Engine
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: c.surfaceSecondary,
                            borderRadius: BorderRadius.circular(AppRadius.card),
                          ),
                          child: Icon(
                            Symbols.auto_fix_high,
                            color: c.primary,
                            size: 20,
                          ),
                        ),
                        title: Text(isIndo ? 'Mesin Koreksi Otomatis' : 'Auto-Correction Engine'),
                        subtitle: Text(
                          isIndo
                              ? 'Tanda petik, em-dash, guillemet, elipsis'
                              : 'Quotes, em-dashes, guillemets, ellipsis',
                          style: AppTypography.bodySm.copyWith(
                            color: c.textSecondary,
                          ),
                        ),
                        trailing: const Icon(Symbols.chevron_right, size: 18),
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          _showAutoCorrectionOptionsDialog();
                        },
                      ),

                      // 4. Writer Notes (Google Keep style scratchpad)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppRadius.card),
                          ),
                          child: const Icon(
                            Symbols.note_alt,
                            color: Color(0xFFD97706),
                            size: 20,
                          ),
                        ),
                        title: Text(isIndo ? 'Catatan Penulis' : 'Writer Notes'),
                        subtitle: Text(
                          isIndo
                              ? 'Papan catatan, ide plot, dan daftar tugas untuk novel ini'
                              : 'Scratchpad, plot ideas, and checklists for this novel',
                          style: AppTypography.bodySm.copyWith(
                            color: c.textSecondary,
                          ),
                        ),
                        trailing: const Icon(Symbols.chevron_right, size: 18),
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => WriterNotesScreen(
                                initialNovelId: widget.novelId,
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: AppSpacing.lg),
                      const Divider(height: 1),
                      const SizedBox(height: AppSpacing.md),

                      // Section 2: History & Revisions
                      Text(
                        isIndo
                            ? 'RIWAYAT & CADANGAN NASKAH'
                            : 'MANUSCRIPT HISTORY & BACKUPS',
                        style: AppTypography.labelSm.copyWith(
                          color: c.textSecondary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),

                      // 4. Create Manual Snapshot
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: c.surfaceSecondary,
                            borderRadius: BorderRadius.circular(AppRadius.card),
                          ),
                          child: Icon(
                            Symbols.save_as,
                            color: c.primary,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          isIndo ? 'Buat Snapshot Manual' : 'Create Manual Snapshot',
                        ),
                        subtitle: Text(
                          isIndo
                              ? 'Simpan titik pemeriksaan bernama untuk teks bab saat ini'
                              : 'Save a named checkpoint of current chapter text',
                          style: AppTypography.bodySm.copyWith(
                            color: c.textSecondary,
                          ),
                        ),
                        trailing: const Icon(Symbols.chevron_right, size: 18),
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          _createSnapshot();
                        },
                      ),

                      // 5. Version History
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: c.surfaceSecondary,
                            borderRadius: BorderRadius.circular(AppRadius.card),
                          ),
                          child: Icon(
                            Symbols.history,
                            color: c.primary,
                            size: 20,
                          ),
                        ),
                        title: Text(isIndo ? 'Riwayat Versi' : 'Version History'),
                        subtitle: Text(
                          isIndo
                              ? 'Jelajahi penyimpanan otomatis dan cadangan manual terdahulu'
                              : 'Browse past auto-saves and manual backups',
                          style: AppTypography.bodySm.copyWith(
                            color: c.textSecondary,
                          ),
                        ),
                        trailing: const Icon(Symbols.chevron_right, size: 18),
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          context.push(
                            Routes.versionHistory(
                              widget.novelId,
                              widget.chapterId,
                            ),
                          );
                        },
                      ),

                      // 6. AI Consistency Checker
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: c.surfaceSecondary,
                            borderRadius: BorderRadius.circular(AppRadius.card),
                          ),
                          child: Icon(
                            Symbols.fact_check,
                            color: c.primary,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          isIndo
                              ? 'Pemeriksa Konsistensi AI'
                              : 'AI Consistency Checker',
                        ),
                        subtitle: Text(
                          isIndo
                              ? 'Pindai bab terhadap lore dunia dan profil karakter'
                              : 'Scan chapter against world lore and character profiles',
                          style: AppTypography.bodySm.copyWith(
                            color: c.textSecondary,
                          ),
                        ),
                        trailing: const Icon(Symbols.chevron_right, size: 18),
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          unawaited(
                            ConsistencyCheckerDialog.show(
                              context,
                              widget.novelId,
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: AppSpacing.lg),
                      const Divider(height: 1),
                      const SizedBox(height: AppSpacing.md),

                      // Section 3: Mentioned Lore
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isIndo
                                ? 'LORE DISEBUTKAN (${_referencedEntities.length})'
                                : 'MENTIONED LORE (${_referencedEntities.length})',
                            style: AppTypography.labelSm.copyWith(
                              color: c.textSecondary,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (_referencedEntities.isNotEmpty)
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                              icon: const Icon(Symbols.clear_all, size: 16),
                              label: Text(isIndo ? 'Hapus Semua' : 'Clear All'),
                              onPressed: () {
                                setState(() {
                                  _referencedEntities.clear();
                                  _isDirty = true;
                                });
                                setSheetState(() {});
                                _saveToDatabase();
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      if (_referencedEntities.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            isIndo
                                ? 'Belum ada entitas lore yang disebutkan. Tandai karakter atau lore dunia menggunakan "@" di editor atau ikon buku pada toolbar.'
                                : 'No lore entities mentioned yet. Tag characters or world lore using "@" in the editor or the book icon on the toolbar.',
                            style: AppTypography.bodySm.copyWith(
                              color: c.textMuted,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        )
                      else
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: _referencedEntities.map((entity) {
                            return NvEntityPill(
                              name: entity.boundIdentifier
                                  .replaceFirst(RegExp(r'^@+'), ''),
                              type: entity.type,
                              onCard: true,
                              onTap: () {
                                Navigator.of(sheetContext).pop();
                                _showEntityDetailsModal(entity);
                              },
                              onDeleted: () {
                                _removeReferencedEntity(entity);
                                setSheetState(() {});
                              },
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    final c = context.colors;

    // Listen to AI text insert bus
    ref.listen<String?>(aiInsertToEditorProvider, (prev, next) {
      if (next != null && next.isNotEmpty) {
        _insertTextFromAi(next);
        ref.read(aiInsertToEditorProvider.notifier).state = null;
      }
    });

    final displayTitle = _titleController.text.isNotEmpty
        ? _titleController.text
        : (isIndo ? 'Lembar Kerja Bab' : 'Chapter Workspace');

    if (!_isInitialized || _controller == null) {
      return Scaffold(
        appBar: NvAppBar(
          showBack: true,
          onBack: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(Routes.novelWorkspace(widget.novelId));
            }
          },
          title: displayTitle,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      resizeToAvoidBottomInset: true,
      bottomSheet: null,
      endDrawer: Drawer(
        width: MediaQuery.of(context).size.width > 500 ? 440 : 340,
        child: SafeArea(
          child: AiChatPanel(
            isDocked: true,
            chapterContent: _controller?.document.toPlainText(),
            onClose: () => Navigator.of(context).pop(),
            onInsertToEditor: (text) {
              _insertTextFromAi(text);
              Navigator.of(context).pop();
            },
          ),
        ),
      ),
      appBar: NvAppBar(
        showBack: true,
        onBack: () {
          _flushPendingSave();
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(Routes.novelWorkspace(widget.novelId));
          }
        },
        title: displayTitle,
        subtitle: Row(
          children: [
            InkWell(
              onTap: _showRenameTitleDialog,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isIndo ? 'Ubah Nama' : 'Rename',
                    style: AppTypography.bodySm.copyWith(
                      color: c.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(Symbols.edit, size: 12, color: c.primary),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            NvSaveStatus(state: _saveStatus),
          ],
        ),
        actions: [
          // 1. Reading Mode Toggle
          IconButton(
            icon: Icon(
              _isReadingMode ? Symbols.edit_document : Symbols.menu_book,
              color: _isReadingMode ? c.primary : null,
            ),
            tooltip: _isReadingMode
                ? (isIndo ? 'Keluar Mode Baca' : 'Exit Reading Mode')
                : (isIndo ? 'Mode Baca' : 'Reading Mode'),
            onPressed: () {
              setState(() => _isReadingMode = !_isReadingMode);
            },
          ),

          // 2. AI Writing Partner
          IconButton(
            icon: const Icon(Symbols.auto_awesome),
            tooltip: isIndo ? 'Asisten Penulis AI' : 'AI Writing Partner',
            onPressed: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
          ),

          // 3. Workspace Options & Tools Drawer (":")
          IconButton(
            icon: const Icon(Symbols.more_vert),
            tooltip: isIndo ? 'Opsi Lembar Kerja' : 'Workspace Options',
            onPressed: () => _showWorkspaceToolsDrawer(context),
          ),
        ],
      ),
      body: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.keyF, control: true): () {
            setState(() => _showFindReplace = true);
          },
          const SingleActivator(LogicalKeyboardKey.keyF, meta: true): () {
            setState(() => _showFindReplace = true);
          },
          const SingleActivator(LogicalKeyboardKey.keyH, control: true): () {
            setState(() => _showFindReplace = true);
          },
          const SingleActivator(LogicalKeyboardKey.keyH, meta: true): () {
            setState(() => _showFindReplace = true);
          },
          const SingleActivator(LogicalKeyboardKey.escape): () {
            if (_showFindReplace) {
              setState(() => _showFindReplace = false);
            }
          },
        },
        child: SafeArea(
          child: Column(
            children: [
              // Live Statistics Sub-bar directly beneath top navigation
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: c.surfaceSecondary,
                  border: Border(
                    bottom: BorderSide(color: c.outlineVariant, width: 0.5),
                  ),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatBadge(
                        label: isIndo ? 'Kata' : 'Words',
                        value: '${_wordStats.words}',
                        c: c,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _buildStatBadge(
                        label: isIndo
                            ? 'Karakter (dg spasi)'
                            : 'Chars (with spaces)',
                        value: '${_wordStats.characters}',
                        c: c,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _buildStatBadge(
                        label: isIndo
                            ? 'Karakter (tanpa spasi)'
                            : 'Chars (no spaces)',
                        value: '${_wordStats.charactersNoSpaces}',
                        c: c,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _buildStatBadge(
                        label: isIndo ? 'Kalimat' : 'Sentences',
                        value: '${_wordStats.sentences}',
                        c: c,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _buildStatBadge(
                        label: isIndo ? 'Paragraf' : 'Paragraphs',
                        value: '${_wordStats.paragraphs}',
                        c: c,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _buildStatBadge(
                        label: isIndo ? 'Waktu Baca' : 'Read Time',
                        value: isIndo
                            ? '~${_wordStats.readingTimeMinutes} mnt'
                            : '~${_wordStats.readingTimeMinutes} min',
                        c: c,
                      ),
                    ],
                  ),
                ),
              ),

              // Find & Replace Floating / Docked Bar (if enabled)
              if (_showFindReplace) ...[
                EditorFindReplaceBar(
                  controller: _controller!,
                  scrollController: _scrollController,
                  onClose: () => setState(() => _showFindReplace = false),
                ),
              ],

              // Referenced Lore Entities Tray (blue entity pills with direct tap and delete)
              if (_referencedEntities.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 4,
                  ),
                  color: c.surface,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Text(
                          isIndo ? 'Lore Disebutkan: ' : 'Mentioned Lore: ',
                          style: AppTypography.labelSm.copyWith(
                            color: c.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        ..._referencedEntities.map((entity) {
                          return Padding(
                            padding: const EdgeInsets.only(right: AppSpacing.xs),
                            child: NvEntityPill(
                              name: entity.boundIdentifier
                                  .replaceFirst(RegExp(r'^@+'), ''),
                              type: entity.type,
                              onCard: true,
                              onTap: () => _showEntityDetailsModal(entity),
                              onDeleted: () => _removeReferencedEntity(entity),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],

              // Editor / Reading Mode Workspace Area with Zoom Scaling
              Expanded(
                child: _isReadingMode
                    ? _buildReadingModeView(c)
                    : _buildEditingModeView(c),
              ),

              // Compact Fixed/Docked Editor Toolbar (h-12 / 48px slim bar):
              // Sits at the bottom of the screen when no keyboard is open,
              // and remains directly above the keyboard whenever the on-screen keyboard appears.
              if (!_isReadingMode && _controller != null)
                EditorToolbar(
                  controller: _controller!,
                  novelId: widget.novelId,
                  onInsertImage: _handleInsertImage,
                  onInsertEntity: _handleInsertEntity,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBadge({
    required String label,
    required String value,
    required AppColors c,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: c.outlineVariant, width: 0.5),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: AppTypography.bodySm.copyWith(
                color: c.textSecondary,
                fontSize: 11,
              ),
            ),
            TextSpan(
              text: value,
              style: AppTypography.bodySm.copyWith(
                color: c.primary,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _moveImage(int currentIndex, int delta) {
    final newIndex = currentIndex + delta;
    if (newIndex >= 0 && newIndex < _workspaceImages.length) {
      setState(() {
        final item = _workspaceImages.removeAt(currentIndex);
        _workspaceImages.insert(newIndex, item);
      });
      _onContentChanged();
    }
  }

  void _showImageLightbox(BuildContext context, WorkspaceImageItem item) {
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.caption.isNotEmpty
                        ? item.caption
                        : (isIndo ? 'Ilustrasi' : 'Illustration'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Symbols.close, color: Colors.white),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.card),
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.file(
                    File(item.path),
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      padding: const EdgeInsets.all(32),
                      color: Colors.black54,
                      child: Center(
                        child: Text(
                          isIndo
                              ? 'Gambar tidak ditemukan di perangkat'
                              : 'Image not found on device',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditingModeView(AppColors c) {
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    final editorFontSize = ref.watch(editorFontSizeProvider);
    final editorFontFamily = ref.watch(editorFontFamilyProvider);

    final topImages = _workspaceImages
        .where((img) => img.position == WorkspaceImagePosition.top)
        .toList();
    final bottomImages = _workspaceImages
        .where((img) => img.position == WorkspaceImagePosition.bottom)
        .toList();

    Widget editorContent = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Images (Header illustrations)
        ...topImages.map((img) {
          final idx = _workspaceImages.indexOf(img);
          return InteractiveWorkspaceImage(
            item: img,
            onMoveUp: idx > 0 ? () => _moveImage(idx, -1) : null,
            onMoveDown: idx < _workspaceImages.length - 1
                ? () => _moveImage(idx, 1)
                : null,
            onTogglePosition: () => setState(() {}),
            onDelete: () {
              setState(() => _workspaceImages.remove(img));
              _onContentChanged();
            },
            onChanged: (_) {
              setState(() {});
              _onContentChanged();
            },
          );
        }),

        // Primary Quill Editor wrapped in min-height constraint so tapping anywhere focuses it
        ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          child: QuillEditor.basic(
            controller: _controller!,
            focusNode: _focusNode,
            config: QuillEditorConfig(
              placeholder: isIndo
                  ? 'Mulai menulis adegan atau bab Anda...'
                  : 'Begin writing your scene or chapter...',
              autoFocus: false,
              expands: false,
              scrollable: false,
              padding: EdgeInsets.zero,
              linkActionPickerDelegate: _handleLinkActionPicker,
              customStyles: AppEditorTypography.buildQuillStyles(
                context,
                fontSize: editorFontSize,
                fontFamily: editorFontFamily,
                textColor: c.textPrimary,
              ),
            ),
          ),
        ),

        // Bottom Images (Footer / Scene end illustrations)
        ...bottomImages.map((img) {
          final idx = _workspaceImages.indexOf(img);
          return InteractiveWorkspaceImage(
            item: img,
            onMoveUp: idx > 0 ? () => _moveImage(idx, -1) : null,
            onMoveDown: idx < _workspaceImages.length - 1
                ? () => _moveImage(idx, 1)
                : null,
            onTogglePosition: () => setState(() {}),
            onDelete: () {
              setState(() => _workspaceImages.remove(img));
              _onContentChanged();
            },
            onChanged: (_) {
              setState(() {});
              _onContentChanged();
            },
          );
        }),

        const SizedBox(height: 250), // Bottom breathing room for toolbar & keyboard
      ],
    );

    if (_zoomScale != 1.0) {
      editorContent = Transform.scale(
        scale: _zoomScale,
        alignment: Alignment.topCenter,
        child: editorContent,
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (!_focusNode.hasFocus) {
          _focusNode.requestFocus();
        }
        if (_controller != null && _controller!.selection.baseOffset < 0) {
          final len = _controller!.document.length;
          _controller!.updateSelection(
            TextSelection.collapsed(offset: len > 0 ? len - 1 : 0),
            ChangeSource.local,
          );
        }
      },
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: editorContent,
      ),
    );
  }

  Widget _buildReadingModeView(AppColors c) {
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    final editorFontSize = ref.watch(editorFontSizeProvider);
    final editorFontFamily = ref.watch(editorFontFamilyProvider);

    final plainText = _controller!.document.toPlainText();
    final topImages = _workspaceImages
        .where((img) => img.position == WorkspaceImagePosition.top)
        .toList();
    final bottomImages = _workspaceImages
        .where((img) => img.position == WorkspaceImagePosition.bottom)
        .toList();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Reading Mode Banner
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.md),
                      child: Text(
                        _titleController.text.isNotEmpty
                            ? _titleController.text
                            : (isIndo ? 'Membaca Naskah' : 'Manuscript Reading'),
                        style: AppTypography.screenTitle.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        softWrap: true,
                        maxLines: null,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Symbols.edit, size: 16),
                    label: Text(
                      isIndo ? 'Keluar Mode Baca' : 'Exit Reading Mode',
                    ),
                    onPressed: () => setState(() => _isReadingMode = false),
                  ),
                ],
              ),
              const Divider(height: 24),
              const SizedBox(height: AppSpacing.md),

              // Render Top Images in Reading Mode
              ...topImages.map((img) => _buildReadingImageItem(img, c)),

              // Render text with comfortable typography
              SelectableText(
                plainText,
                style: AppEditorTypography.resolveTextStyle(
                  fontSize: editorFontSize,
                  fontFamily: editorFontFamily,
                  color: c.textPrimary,
                  height: 1.8,
                ),
              ),

              // Render Bottom Images in Reading Mode
              ...bottomImages.map((img) => _buildReadingImageItem(img, c)),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadingImageItem(WorkspaceImageItem img, AppColors c) {
    Alignment align;
    switch (img.alignment) {
      case WorkspaceImageFloat.floatLeft:
        align = Alignment.centerLeft;
        break;
      case WorkspaceImageFloat.center:
        align = Alignment.center;
        break;
      case WorkspaceImageFloat.floatRight:
        align = Alignment.centerRight;
        break;
      case WorkspaceImageFloat.fullWidth:
        align = Alignment.center;
        break;
    }

    final isFullWidth = img.alignment == WorkspaceImageFloat.fullWidth;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Align(
        alignment: align,
        child: GestureDetector(
          onTap: () => _showImageLightbox(context, img),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.card),
                child: Container(
                  width: isFullWidth ? double.infinity : img.width,
                  height: img.height,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Image.file(
                    File(img.path),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: c.surfaceSecondary,
                      child: Center(
                        child: Icon(
                          Symbols.broken_image,
                          color: c.textMuted,
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (img.caption.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  img.caption,
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
}
