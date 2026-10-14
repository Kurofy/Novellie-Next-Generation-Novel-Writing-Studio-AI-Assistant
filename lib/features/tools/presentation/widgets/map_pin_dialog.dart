import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../characters/application/character_providers.dart';
import '../../../manuscript/application/manuscript_providers.dart';
import '../../../world/application/world_providers.dart';
import '../../application/world_map_providers.dart';
import '../../domain/models/world_map_models.dart';

class MapPinDialog extends ConsumerStatefulWidget {
  final String novelId;
  final String mapId;
  final double x;
  final double y;
  final MapPin? pinToEdit;

  const MapPinDialog({
    super.key,
    required this.novelId,
    required this.mapId,
    required this.x,
    required this.y,
    this.pinToEdit,
  });

  static Future<MapPin?> show(
    BuildContext context, {
    required String novelId,
    required String mapId,
    required double x,
    required double y,
    MapPin? pinToEdit,
  }) {
    return showModalBottomSheet<MapPin>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MapPinDialog(
        novelId: novelId,
        mapId: mapId,
        x: x,
        y: y,
        pinToEdit: pinToEdit,
      ),
    );
  }

  @override
  ConsumerState<MapPinDialog> createState() => _MapPinDialogState();
}

class _MapPinDialogState extends ConsumerState<MapPinDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late MapPinCategory _category;
  String? _selectedEntryId;
  late Set<String> _selectedCharacterIds;
  late Set<String> _selectedChapterIds;

  @override
  void initState() {
    super.initState();
    final p = widget.pinToEdit;
    _titleController = TextEditingController(text: p?.title ?? '');
    _descController = TextEditingController(text: p?.description ?? '');
    _category = p?.category ?? MapPinCategory.settlement;
    _selectedEntryId = p?.linkedEntryId;
    _selectedCharacterIds =
        p != null ? Set.from(p.linkedCharacterIds) : <String>{};
    _selectedChapterIds = p != null ? Set.from(p.linkedChapterIds) : <String>{};
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final now = DateTime.now();
    final pin = MapPin(
      id: widget.pinToEdit?.id ?? const Uuid().v4(),
      novelId: widget.novelId,
      mapId: widget.mapId,
      title: title,
      description: _descController.text.trim().isNotEmpty
          ? _descController.text.trim()
          : null,
      category: _category,
      x: widget.pinToEdit?.x ?? widget.x,
      y: widget.pinToEdit?.y ?? widget.y,
      linkedEntryId: _selectedEntryId,
      linkedCharacterIds: _selectedCharacterIds.toList(),
      linkedChapterIds: _selectedChapterIds.toList(),
      createdAt: widget.pinToEdit?.createdAt ?? now,
      updatedAt: now,
    );

    if (widget.pinToEdit != null) {
      ref.read(worldMapProvider(widget.novelId).notifier).updatePin(pin);
    } else {
      ref.read(worldMapProvider(widget.novelId).notifier).addPin(pin);
    }

    Navigator.of(context).pop(pin);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    final c = context.colors;
    final isEdit = widget.pinToEdit != null;

    final codexEntriesAsync = ref.watch(
      worldEntriesStreamProvider(
        (novelId: widget.novelId, categoryId: null),
      ),
    );
    final charactersAsync = ref.watch(charactersStreamProvider(widget.novelId));
    final chaptersAsync = ref.watch(chaptersStreamProvider(widget.novelId));

    return NvBottomSheet(
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEdit
                            ? (isIndo ? 'Ubah Penanda Peta' : 'Edit Map Marker')
                            : (isIndo ? 'Pasang Penanda Peta' : 'Place Map Marker'),
                        style: AppTypography.screenTitle,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${isIndo ? 'Koordinat' : 'Coordinates'}: ${(widget.x * 100).toStringAsFixed(1)}% X · ${(widget.y * 100).toStringAsFixed(1)}% Y',
                        style: AppTypography.bodySm
                            .copyWith(color: c.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Symbols.close),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: isIndo ? 'Tutup' : 'Close',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Pin Title
            Text(
              isIndo ? 'Judul Lokasi / Penanda *' : 'Location / Marker Title *',
              style: AppTypography.labelMd,
            ),
            const SizedBox(height: AppSpacing.sm),
            NvTextField(
              controller: _titleController,
              hintText: isIndo
                  ? 'cth. Benteng Besi, Lembah Kabut, Makam Kuno'
                  : 'e.g. Iron Citadel, Mistwood Pass, Sunken Crypt',
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Category Selector Chips
            Text(
              isIndo ? 'Kategori Penanda' : 'Marker Category',
              style: AppTypography.labelMd,
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: MapPinCategory.values.map((cat) {
                final isSelected = _category == cat;
                return ChoiceChip(
                  avatar: Icon(
                    cat.icon,
                    size: 14,
                    color: isSelected ? Colors.white : cat.color,
                  ),
                  label: Text(cat.localizedLabel(isIndo)),
                  selected: isSelected,
                  selectedColor: cat.color,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : c.textPrimary,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _category = cat);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Description
            Text(
              isIndo ? 'Deskripsi / Lore Kartografi' : 'Description / Cartographic Lore',
              style: AppTypography.labelMd,
            ),
            const SizedBox(height: AppSpacing.sm),
            NvTextField(
              controller: _descController,
              hintText: isIndo
                  ? 'Kepentingan strategis, medan, iklim, atau sejarah...'
                  : 'Strategic importance, terrain, climate, or history...',
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Linked Codex Entry
            Text(
              isIndo ? 'Tautkan ke Entri Kodeks / Lokasi Dunia' : 'Link to Codex / World Location',
              style: AppTypography.labelMd,
            ),
            const SizedBox(height: AppSpacing.sm),
            codexEntriesAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => Text(isIndo ? 'Tidak dapat memuat entri Kodeks' : 'Unable to load Codex entries'),
              data: (entries) {
                return DropdownButtonFormField<String?>(
                  initialValue: _selectedEntryId,
                  isExpanded: true,
                  dropdownColor: c.surface,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: c.surfaceSecondary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.input),
                      borderSide: BorderSide(color: c.outlineVariant),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                  hint: Text(isIndo ? 'Tidak Ada (Penanda Peta Mandiri)' : 'None (Standalone Map Marker)'),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(isIndo ? 'Tidak Ada (Penanda Peta Mandiri)' : 'None (Standalone Map Marker)'),
                    ),
                    ...entries.map(
                      (e) => DropdownMenuItem<String?>(
                        value: e.id,
                        child: Row(
                          children: [
                            Icon(Symbols.auto_stories,
                                size: 16, color: c.primary),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(e.name,
                                    overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ),
                    ),
                  ],
                  onChanged: (val) => setState(() => _selectedEntryId = val),
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // Linked Characters
            Text(
              isIndo ? 'Karakter yang Tinggal atau Berasal dari Sini' : 'Characters Residing or Originating Here',
              style: AppTypography.labelMd,
            ),
            const SizedBox(height: AppSpacing.sm),
            charactersAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (characters) {
                if (characters.isEmpty) {
                  return Text(
                    isIndo ? 'Belum ada karakter yang dibuat di novel ini.' : 'No characters created yet in this novel.',
                    style:
                        AppTypography.bodySm.copyWith(color: c.textSecondary),
                  );
                }

                return Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: characters.map((ch) {
                    final isLinked = _selectedCharacterIds.contains(ch.id);
                    return FilterChip(
                      avatar: Icon(
                        Symbols.person,
                        size: 14,
                        color: isLinked ? c.primary : c.textSecondary,
                      ),
                      label: Text(ch.name),
                      selected: isLinked,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedCharacterIds.add(ch.id);
                          } else {
                            _selectedCharacterIds.remove(ch.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // Linked Chapters
            Text(
              isIndo ? 'Tampil dalam Bab' : 'Featured in Chapters',
              style: AppTypography.labelMd,
            ),
            const SizedBox(height: AppSpacing.sm),
            chaptersAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (chapters) {
                if (chapters.isEmpty) {
                  return Text(
                    isIndo ? 'Belum ada bab yang dirancang.' : 'No chapters drafted yet.',
                    style:
                        AppTypography.bodySm.copyWith(color: c.textSecondary),
                  );
                }

                return Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: chapters.map((ch) {
                    final isLinked = _selectedChapterIds.contains(ch.id);
                    return FilterChip(
                      avatar: Icon(
                        Symbols.menu_book,
                        size: 14,
                        color: isLinked ? c.primary : c.textSecondary,
                      ),
                      label: Text(ch.displayTitle),
                      selected: isLinked,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedChapterIds.add(ch.id);
                          } else {
                            _selectedChapterIds.remove(ch.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: AppSpacing.x2),

            // Submit Button
            NvButton(
              label: isEdit
                  ? (isIndo ? 'Simpan Perubahan' : 'Save Changes')
                  : (isIndo ? 'Pasang Penanda di Sini' : 'Drop Marker Here'),
              variant: NvButtonVariant.primary,
              icon: Symbols.pin_drop,
              onPressed: _handleSubmit,
            ),
          ],
        ),
      ),
    );
  }
}
