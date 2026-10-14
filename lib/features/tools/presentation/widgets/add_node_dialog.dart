import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/utils/uuid_generator.dart';
import '../../../manuscript/application/manuscript_providers.dart';
import '../../../manuscript/domain/models/manuscript_models.dart';
import '../../domain/models/mind_map_models.dart';

class AddNodeDialog extends ConsumerStatefulWidget {
  final String novelId;
  final MindMapNodeType initialType;

  const AddNodeDialog({
    super.key,
    required this.novelId,
    this.initialType = MindMapNodeType.brainstorm,
  });

  static Future<MindMapNode?> show(
    BuildContext context, {
    required String novelId,
    MindMapNodeType initialType = MindMapNodeType.brainstorm,
  }) {
    return showDialog<MindMapNode>(
      context: context,
      builder: (_) => AddNodeDialog(
        novelId: novelId,
        initialType: initialType,
      ),
    );
  }

  @override
  ConsumerState<AddNodeDialog> createState() => _AddNodeDialogState();
}

class _AddNodeDialogState extends ConsumerState<AddNodeDialog> {
  final _formKey = GlobalKey<FormState>();
  late MindMapNodeType _selectedType;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _arcNameController = TextEditingController();
  final _sequenceController = TextEditingController();

  ChapterModel? _selectedChapter;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _arcNameController.dispose();
    _sequenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    final c = context.colors;
    final chaptersAsync =
        ref.watch(chaptersStreamProvider(widget.novelId));

    return Dialog(
      backgroundColor: c.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sheet),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 660),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: c.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Symbols.hub, color: c.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isIndo ? 'Tambah Simpul Peta Pikiran Cerita' : 'Add Story Mind Map Node',
                            style: AppTypography.screenTitle.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: c.textPrimary,
                            ),
                          ),
                          Text(
                            isIndo
                                ? 'Konsep curah pendapat, urutan bab, dan alur cerita'
                                : 'Brainstorm concepts, chapter orders, and story arcs',
                            style: AppTypography.labelSm
                                .copyWith(color: c.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Symbols.close),
                      tooltip: isIndo ? 'Tutup' : 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Type selector
                Text(
                  isIndo ? 'Kategori Simpul' : 'Node Category',
                  style: AppTypography.labelSm.copyWith(
                    fontWeight: FontWeight.bold,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: MindMapNodeType.values.map((type) {
                      final isSelected = _selectedType == type;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          selected: isSelected,
                          label: Text(type.localizedLabel(isIndo)),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : c.textPrimary,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 12,
                          ),
                          backgroundColor: c.surfaceSecondary,
                          selectedColor: _getTypeColor(type),
                          showCheckmark: false,
                          onSelected: (_) {
                            setState(() => _selectedType = type);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 14),

                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Title
                        TextFormField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            labelText: _getTitleLabel(isIndo),
                            hintText: _getTitleHint(isIndo),
                            filled: true,
                            fillColor: c.surfaceSecondary,
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.card),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return isIndo ? 'Silakan masukkan judul' : 'Please enter a title';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 12),

                        // Description
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: isIndo ? 'Catatan & Rincian Narasi' : 'Narrative Notes & Details',
                            hintText: isIndo
                                ? 'Ketukan dramatis utama, motivasi, atau poin tematik...'
                                : 'Key dramatic beats, motivations, or thematic points...',
                            filled: true,
                            fillColor: c.surfaceSecondary,
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.card),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Sequence & Arc Name
                        Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                controller: _sequenceController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: isIndo ? 'Urutan #' : 'Sequence #',
                                  hintText: isIndo ? 'cth. 1, 2, 3' : 'e.g. 1, 2, 3',
                                  filled: true,
                                  fillColor: c.surfaceSecondary,
                                  border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.card),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _arcNameController,
                                decoration: InputDecoration(
                                  labelText: isIndo ? 'Alur Cerita / Kelompok Babak' : 'Story Arc / Act Group',
                                  hintText: isIndo ? 'cth. Babak I, Perjalanan Pahlawan' : 'e.g. Act I, Hero\'s Journey',
                                  filled: true,
                                  fillColor: c.surfaceSecondary,
                                  border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.card),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Optional manuscript chapter linking if Chapter Sequence type
                        if (_selectedType == MindMapNodeType.chapterOrder) ...[
                          const SizedBox(height: 12),
                          chaptersAsync.when(
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                            data: (chapters) {
                              if (chapters.isEmpty) return const SizedBox.shrink();

                              return DropdownButtonFormField<ChapterModel>(
                                initialValue: _selectedChapter,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText: isIndo ? 'Tautkan ke Bab Naskah (Opsional)' : 'Link to Manuscript Chapter (Optional)',
                                  filled: true,
                                  fillColor: c.surfaceSecondary,
                                  border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.card),
                                  ),
                                ),
                                hint: Text(isIndo ? 'Pilih bab naskah...' : 'Select manuscript chapter...'),
                                items: chapters.map((ch) {
                                  return DropdownMenuItem<ChapterModel>(
                                    value: ch,
                                    child: Text(
                                      '${isIndo ? 'Bab' : 'Ch.'} ${ch.sequenceNumber}: ${ch.title}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (ch) {
                                  setState(() {
                                    _selectedChapter = ch;
                                    if (ch != null &&
                                        _titleController.text.isEmpty) {
                                      _titleController.text = ch.title;
                                      _sequenceController.text =
                                          ch.sequenceNumber.toString();
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(isIndo ? 'Batal' : 'Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: _getTypeColor(_selectedType),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Symbols.add, size: 18),
                      label: Text(isIndo ? 'Tambah Simpul' : 'Add Node'),
                      onPressed: _handleSubmit,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getTitleLabel([bool isIndo = false]) {
    if (!isIndo) {
      switch (_selectedType) {
        case MindMapNodeType.brainstorm:
          return 'Brainstorm Idea Title *';
        case MindMapNodeType.storyArc:
          return 'Story Arc Name *';
        case MindMapNodeType.chapterOrder:
          return 'Chapter / Sequence Title *';
        case MindMapNodeType.plotPoint:
          return 'Plot Point / Beat *';
        case MindMapNodeType.theme:
          return 'Theme & Central Question *';
      }
    }
    switch (_selectedType) {
      case MindMapNodeType.brainstorm:
        return 'Judul Ide Curah Pendapat *';
      case MindMapNodeType.storyArc:
        return 'Nama Alur Cerita *';
      case MindMapNodeType.chapterOrder:
        return 'Judul Bab / Urutan *';
      case MindMapNodeType.plotPoint:
        return 'Titik Plot / Ketukan *';
      case MindMapNodeType.theme:
        return 'Tema & Pertanyaan Pokok *';
    }
  }

  String _getTitleHint([bool isIndo = false]) {
    if (!isIndo) {
      switch (_selectedType) {
        case MindMapNodeType.brainstorm:
          return 'e.g. Magic system corruption, Ancient relic';
        case MindMapNodeType.storyArc:
          return 'e.g. Redemption of Lucian, Fall of the Capital';
        case MindMapNodeType.chapterOrder:
          return 'e.g. Chapter 3: The Gathering Storm';
        case MindMapNodeType.plotPoint:
          return 'e.g. Inciting Incident, Midpoint Reversal';
        case MindMapNodeType.theme:
          return 'e.g. Sacrifice vs Duty';
      }
    }
    switch (_selectedType) {
      case MindMapNodeType.brainstorm:
        return 'cth. Korupsi sistem sihir, Relik kuno';
      case MindMapNodeType.storyArc:
        return 'cth. Penebusan Lucian, Kejatuhan Ibu Kota';
      case MindMapNodeType.chapterOrder:
        return 'cth. Bab 3: Badai yang Berkumpul';
      case MindMapNodeType.plotPoint:
        return 'cth. Insiden Pemicu, Pembalikan Tengah';
      case MindMapNodeType.theme:
        return 'cth. Pengorbanan vs Kewajiban';
    }
  }

  Color _getTypeColor(MindMapNodeType type) {
    switch (type) {
      case MindMapNodeType.brainstorm:
        return const Color(0xFFF59E0B);
      case MindMapNodeType.storyArc:
        return const Color(0xFF6366F1);
      case MindMapNodeType.chapterOrder:
        return const Color(0xFF06B6D4);
      case MindMapNodeType.plotPoint:
        return const Color(0xFFEF4444);
      case MindMapNodeType.theme:
        return const Color(0xFF8B5CF6);
    }
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    final seq = int.tryParse(_sequenceController.text.trim());

    final node = MindMapNode(
      id: generateUuid(),
      novelId: widget.novelId,
      type: _selectedType,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      sequenceOrder: seq,
      storyArcName: _arcNameController.text.trim().isEmpty
          ? null
          : _arcNameController.text.trim(),
      linkedChapterId: _selectedChapter?.id,
      x: 350.0,
      y: 300.0,
    );

    Navigator.of(context).pop(node);
  }
}
