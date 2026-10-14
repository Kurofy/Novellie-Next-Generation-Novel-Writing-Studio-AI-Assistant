import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/utils/uuid_generator.dart';
import '../../../novels/application/novel_providers.dart';
import '../../application/writer_notes_providers.dart';
import '../../domain/models/writer_note_model.dart';

class NoteEditorDialog extends ConsumerStatefulWidget {
  final WriterNote? initialNote;
  final bool startAsChecklist;
  final String? initialNovelId;
  final String? initialNovelTitle;

  const NoteEditorDialog({
    super.key,
    this.initialNote,
    this.startAsChecklist = false,
    this.initialNovelId,
    this.initialNovelTitle,
  });

  static Future<void> show(
    BuildContext context, {
    WriterNote? initialNote,
    bool startAsChecklist = false,
    String? initialNovelId,
    String? initialNovelTitle,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => NoteEditorDialog(
        initialNote: initialNote,
        startAsChecklist: startAsChecklist,
        initialNovelId: initialNovelId,
        initialNovelTitle: initialNovelTitle,
      ),
    );
  }

  @override
  ConsumerState<NoteEditorDialog> createState() => _NoteEditorDialogState();
}

class _NoteEditorDialogState extends ConsumerState<NoteEditorDialog> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _newChecklistController;
  late TextEditingController _newLabelController;

  late bool _isPinned;
  late bool _isArchived;
  late bool _isChecklist;
  late String _selectedColorId;
  late List<NoteChecklistItem> _checklist;
  late List<String> _labels;
  String? _selectedNovelId;
  String? _selectedNovelTitle;

  bool _showColorPicker = false;
  bool _showLabelPicker = false;

  @override
  void initState() {
    super.initState();
    final note = widget.initialNote;

    _titleController = TextEditingController(text: note?.title ?? '');
    _contentController = TextEditingController(text: note?.content ?? '');
    _newChecklistController = TextEditingController();
    _newLabelController = TextEditingController();

    _isPinned = note?.isPinned ?? false;
    _isArchived = note?.isArchived ?? false;
    _isChecklist = note?.isChecklist ?? widget.startAsChecklist;
    _selectedColorId = note?.colorId ?? 'default';
    _checklist = List<NoteChecklistItem>.from(note?.checklist ?? []);
    _labels = List<String>.from(note?.labels ?? []);
    _selectedNovelId = note?.novelId ?? widget.initialNovelId;
    _selectedNovelTitle = note?.novelTitle ?? widget.initialNovelTitle;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _newChecklistController.dispose();
    _newLabelController.dispose();
    super.dispose();
  }

  void _saveAndClose() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    // Check if completely empty
    final isCompletelyEmpty = title.isEmpty &&
        content.isEmpty &&
        (_checklist.isEmpty ||
            _checklist.every((item) => item.text.trim().isEmpty));

    if (isCompletelyEmpty) {
      if (widget.initialNote != null) {
        // If editing an existing note and emptied out, delete it
        ref
            .read(writerNotesProvider.notifier)
            .deleteNote(widget.initialNote!.id);
      }
      Navigator.of(context).pop();
      return;
    }

    final notifier = ref.read(writerNotesProvider.notifier);

    if (widget.initialNote != null) {
      final updated = widget.initialNote!.copyWith(
        title: title,
        content: content,
        isChecklist: _isChecklist,
        checklist: _checklist,
        isPinned: _isPinned,
        isArchived: _isArchived,
        colorId: _selectedColorId,
        labels: _labels,
        novelId: _selectedNovelId,
        novelTitle: _selectedNovelTitle,
      );
      notifier.updateNote(updated);
    } else {
      notifier.createNote(
        title: title,
        content: content,
        isChecklist: _isChecklist,
        checklist: _checklist,
        isPinned: _isPinned,
        colorId: _selectedColorId,
        labels: _labels,
        novelId: _selectedNovelId,
        novelTitle: _selectedNovelTitle,
      );
    }

    Navigator.of(context).pop();
  }

  void _addChecklistItem() {
    final text = _newChecklistController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _checklist.add(
        NoteChecklistItem(
          id: generateUuid(),
          text: text,
          isDone: false,
        ),
      );
      _newChecklistController.clear();
    });
  }

  void _toggleChecklistItem(int index) {
    setState(() {
      final item = _checklist[index];
      _checklist[index] = item.copyWith(isDone: !item.isDone);
    });
  }

  void _removeChecklistItem(int index) {
    setState(() {
      _checklist.removeAt(index);
    });
  }

  void _addLabel() {
    final raw = _newLabelController.text.trim();
    if (raw.isEmpty) return;
    final formatted = raw.startsWith('#') ? raw : '#$raw';
    if (!_labels.contains(formatted)) {
      setState(() {
        _labels.add(formatted);
        _newLabelController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final preset = NoteColorPreset.fromId(_selectedColorId);
    final novelsAsync = ref.watch(novelListStreamProvider);

    final bgColor = preset == NoteColorPreset.defaultColor
        ? c.surface
        : preset.resolveBackground(isDark);

    final borderColor = preset == NoteColorPreset.defaultColor
        ? c.outlineVariant.withValues(alpha: 0.8)
        : preset.resolveBorder(isDark);

    return Dialog(
      backgroundColor: bgColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: borderColor, width: 1.5),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Action Row: Pinned Icon, Novel selector chip, and Close
              Row(
                children: [
                  // Pin toggle
                  IconButton(
                    icon: Icon(
                      Symbols.push_pin,
                      fill: _isPinned ? 1.0 : 0.0,
                      color:
                          _isPinned ? const Color(0xFFD97706) : c.textSecondary,
                    ),
                    tooltip: _isPinned
                        ? (isIndo ? 'Lepas Sematan' : 'Unpin Note')
                        : (isIndo ? 'Sematkan ke Atas' : 'Pin Note to Top'),
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      setState(() => _isPinned = !_isPinned);
                    },
                  ),

                  // Novel link badge / selector
                  novelsAsync.when(
                    data: (novels) {
                      return PopupMenuButton<String?>(
                        tooltip: isIndo ? 'Tautkan ke Novel' : 'Link to Novel',
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: c.surfaceSecondary.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(
                              color: c.outlineVariant.withValues(alpha: 0.7),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Symbols.menu_book,
                                size: 14,
                                color: Color(0xFFD97706),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _selectedNovelTitle ?? (isIndo ? 'Catatan Global' : 'Global Note'),
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: c.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Symbols.arrow_drop_down,
                                size: 16,
                                color: c.textSecondary,
                              ),
                            ],
                          ),
                        ),
                        onSelected: (val) {
                          setState(() {
                            if (val == null) {
                              _selectedNovelId = null;
                              _selectedNovelTitle = null;
                            } else {
                              final matched =
                                  novels.firstWhere((n) => n.id == val);
                              _selectedNovelId = matched.id;
                              _selectedNovelTitle = matched.title;
                            }
                          });
                        },
                        itemBuilder: (ctx) => [
                          PopupMenuItem<String?>(
                            value: null,
                            child: Row(
                              children: [
                                const Icon(Symbols.public, size: 16),
                                const SizedBox(width: 8),
                                Text(isIndo ? 'Catatan Global / Tanpa Tautan' : 'Global / Unlinked Note'),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          ...novels.map(
                            (n) => PopupMenuItem<String?>(
                              value: n.id,
                              child: Row(
                                children: [
                                  const Icon(
                                    Symbols.menu_book,
                                    size: 16,
                                    color: Color(0xFFD97706),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(n.title),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),

                  const Spacer(),

                  // Archive toggle button
                  IconButton(
                    icon: Icon(
                      _isArchived ? Symbols.unarchive : Symbols.archive,
                      size: 20,
                      color: c.textSecondary,
                    ),
                    tooltip: _isArchived
                        ? (isIndo ? 'Batalkan Arsip' : 'Unarchive')
                        : (isIndo ? 'Arsipkan Catatan' : 'Archive Note'),
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      setState(() => _isArchived = !_isArchived);
                    },
                  ),

                  // Close button
                  IconButton(
                    icon: const Icon(Symbols.close, size: 20),
                    tooltip: isIndo ? 'Simpan & Tutup' : 'Save & Close',
                    visualDensity: VisualDensity.compact,
                    onPressed: _saveAndClose,
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Title Input Box Container
              Container(
                decoration: BoxDecoration(
                  color: c.surfaceSecondary.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  border: Border.all(
                    color: c.outlineVariant.withValues(alpha: 0.7),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: TextField(
                  controller: _titleController,
                  minLines: 1,
                  maxLines: 3,
                  style: AppTypography.sectionTitle.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: c.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: isIndo ? 'Judul Catatan...' : 'Note Title...',
                    hintStyle: AppTypography.sectionTitle.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: c.textMuted,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Content Area: Plain text or Checklists
              Expanded(
                child: _isChecklist
                    ? _buildChecklistEditor(c, isIndo)
                    : TextField(
                        controller: _contentController,
                        style: AppTypography.body.copyWith(
                          fontSize: 14,
                          height: 1.45,
                          color: c.textPrimary,
                        ),
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: InputDecoration(
                          hintText: isIndo ? 'Tulis catatan...' : 'Take a note...',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: c.textMuted,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
              ),

              // Labels Tag Row
              if (_labels.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _labels.map((label) {
                    return Chip(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      label: Text(label, style: const TextStyle(fontSize: 11)),
                      deleteIcon: const Icon(Symbols.close, size: 14),
                      onDeleted: () {
                        setState(() => _labels.remove(label));
                      },
                    );
                  }).toList(),
                ),
              ],

              // Popover Section for Color Palette
              if (_showColorPicker) ...[
                const SizedBox(height: 10),
                _buildColorPaletteRow(isDark),
              ],

              // Popover Section for adding Labels
              if (_showLabelPicker) ...[
                const SizedBox(height: 10),
                _buildLabelInputRow(c, isIndo),
              ],

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),

              // Bottom Toolbar
              Row(
                children: [
                  // Palette button
                  IconButton(
                    icon: Icon(
                      Symbols.palette,
                      color: _showColorPicker ? const Color(0xFFD97706) : c.textSecondary,
                    ),
                    tooltip: isIndo ? 'Ubah Warna' : 'Change Color',
                    onPressed: () {
                      setState(() {
                        _showColorPicker = !_showColorPicker;
                        if (_showColorPicker) _showLabelPicker = false;
                      });
                    },
                  ),

                  // Toggle Checklist button
                  IconButton(
                    icon: Icon(
                      _isChecklist ? Symbols.subject : Symbols.check_box,
                      color: _isChecklist ? const Color(0xFFD97706) : c.textSecondary,
                    ),
                    tooltip: _isChecklist
                        ? (isIndo ? 'Beralih ke Teks Biasa' : 'Switch to Plain Text')
                        : (isIndo ? 'Beralih ke Daftar Tugas' : 'Switch to Checklist'),
                    onPressed: () {
                      setState(() {
                        _isChecklist = !_isChecklist;
                        if (_isChecklist && _contentController.text.isNotEmpty) {
                          // Convert lines into checklist items
                          final lines = _contentController.text.split('\n');
                          for (final line in lines) {
                            if (line.trim().isNotEmpty) {
                              _checklist.add(
                                NoteChecklistItem(
                                  id: generateUuid(),
                                  text: line.trim(),
                                ),
                              );
                            }
                          }
                          _contentController.clear();
                        } else if (!_isChecklist && _checklist.isNotEmpty) {
                          // Convert checklist to text lines
                          _contentController.text =
                              _checklist.map((e) => e.text).join('\n');
                        }
                      });
                    },
                  ),

                  // Add Label button
                  IconButton(
                    icon: Icon(
                      Symbols.label,
                      color: _showLabelPicker ? const Color(0xFFD97706) : c.textSecondary,
                    ),
                    tooltip: isIndo ? 'Tambah Label' : 'Add Label',
                    onPressed: () {
                      setState(() {
                        _showLabelPicker = !_showLabelPicker;
                        if (_showLabelPicker) _showColorPicker = false;
                      });
                    },
                  ),

                  if (widget.initialNote != null)
                    IconButton(
                      icon: const Icon(Symbols.delete, size: 20, color: Colors.red),
                      tooltip: isIndo ? 'Hapus Catatan' : 'Delete Note',
                      onPressed: () {
                        ref
                            .read(writerNotesProvider.notifier)
                            .deleteNote(widget.initialNote!.id);
                        Navigator.of(context).pop();
                      },
                    ),

                  const Spacer(),

                  // Save & Close Button
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onPressed: _saveAndClose,
                    child: Text(isIndo ? 'Selesai' : 'Done',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChecklistEditor(AppColors c, bool isIndo) {
    return Column(
      children: [
        // List of items
        Expanded(
          child: ListView.builder(
            itemCount: _checklist.length,
            itemBuilder: (ctx, index) {
              final item = _checklist[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Checkbox(
                      value: item.isDone,
                      activeColor: const Color(0xFF10B981),
                      visualDensity: VisualDensity.compact,
                      onChanged: (_) => _toggleChecklistItem(index),
                    ),
                    Expanded(
                      child: TextField(
                        controller: TextEditingController(text: item.text)
                          ..selection = TextSelection.fromPosition(
                            TextPosition(offset: item.text.length),
                          ),
                        style: TextStyle(
                          fontSize: 13.5,
                          color: item.isDone ? c.textMuted : c.textPrimary,
                          decoration: item.isDone
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 4),
                        ),
                        onChanged: (newText) {
                          _checklist[index] = item.copyWith(text: newText);
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Symbols.close, size: 16),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _removeChecklistItem(index),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // New Item Input
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: c.surfaceSecondary.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppRadius.input),
          ),
          child: Row(
            children: [
              const Icon(Symbols.add, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _newChecklistController,
                  decoration: InputDecoration(
                    hintText: isIndo ? 'Tambah item daftar...' : 'Add list item...',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onSubmitted: (_) => _addChecklistItem(),
                ),
              ),
              IconButton(
                icon: const Icon(Symbols.check, size: 18),
                onPressed: _addChecklistItem,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildColorPaletteRow(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: NoteColorPreset.values.map((preset) {
          final isSelected = _selectedColorId == preset.id;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () {
                setState(() => _selectedColorId = preset.id);
              },
              customBorder: const CircleBorder(),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: preset.resolveBackground(isDark),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFD97706)
                        : preset.resolveBorder(isDark),
                    width: isSelected ? 2.5 : 1.2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Symbols.check, size: 16, color: Color(0xFFD97706))
                    : null,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLabelInputRow(AppColors c, bool isIndo) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _newLabelController,
            decoration: InputDecoration(
              hintText: isIndo ? 'contoh: #Plot, #Lore, #Dialog' : 'e.g. #Plot, #Lore, #Dialogue',
              isDense: true,
              filled: true,
              fillColor: c.surfaceSecondary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            onSubmitted: (_) => _addLabel(),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          style: FilledButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          onPressed: _addLabel,
          child: Text(isIndo ? 'Tambah Label' : 'Add Tag'),
        ),
      ],
    );
  }
}
