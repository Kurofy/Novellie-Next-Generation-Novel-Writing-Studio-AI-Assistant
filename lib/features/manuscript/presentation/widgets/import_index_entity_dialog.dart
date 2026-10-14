import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../ai/presentation/screens/ai_index_screen.dart';
import '../../../characters/application/character_providers.dart';
import '../../../characters/presentation/screens/create_character_dialog.dart';
import '../../../world/application/world_providers.dart';
import '../../../world/presentation/screens/create_world_entry_dialog.dart';

enum CharacterBindingMode {
  name('Bind via Name (Full Name)'),
  nickname('Bind via Nickname (Moniker)');

  final String label;
  const CharacterBindingMode(this.label);
}

class IndexEntityItem {
  final String id;
  final String name;
  final String? nickname;
  final String? subtitle;
  final NvEntityType type;
  final String boundIdentifier;

  IndexEntityItem({
    required this.id,
    required String name,
    String? nickname,
    this.subtitle,
    required this.type,
    String? boundIdentifier,
  })  : name = _stripAt(name),
        nickname = nickname != null && nickname.trim().isNotEmpty
            ? _stripAt(nickname)
            : null,
        boundIdentifier = _stripAt(boundIdentifier ?? name);

  static String _stripAt(String str) =>
      str.replaceFirst(RegExp(r'^@+'), '').trim();

  String get entityLink => 'entity://${type.name}/$id';

  IndexEntityItem copyWithBinding(String newBoundIdentifier) {
    return IndexEntityItem(
      id: id,
      name: name,
      nickname: nickname,
      subtitle: subtitle,
      type: type,
      boundIdentifier: _stripAt(newBoundIdentifier),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'nickname': nickname,
        'subtitle': subtitle,
        'type': type.name,
        'boundIdentifier': boundIdentifier,
      };

  factory IndexEntityItem.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String?;
    final resolvedType = NvEntityType.values.firstWhere(
      (t) => t.name == typeName,
      orElse: () => NvEntityType.character,
    );
    return IndexEntityItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      nickname: json['nickname'] as String?,
      subtitle: json['subtitle'] as String?,
      type: resolvedType,
      boundIdentifier: json['boundIdentifier'] as String?,
    );
  }
}

class ImportIndexEntityDialog extends ConsumerStatefulWidget {
  final String novelId;

  const ImportIndexEntityDialog({
    super.key,
    required this.novelId,
  });

  static Future<IndexEntityItem?> show(BuildContext context, String novelId) {
    return showModalBottomSheet<IndexEntityItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ImportIndexEntityDialog(novelId: novelId),
    );
  }

  @override
  ConsumerState<ImportIndexEntityDialog> createState() =>
      _ImportIndexEntityDialogState();
}

class _ImportIndexEntityDialogState
    extends ConsumerState<ImportIndexEntityDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _filter = '';
  NvEntityType? _selectedType;
  CharacterBindingMode _characterBindingMode = CharacterBindingMode.name;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    final charactersAsync =
        ref.watch(charactersStreamProvider(widget.novelId));
    final worldEntriesAsync = ref.watch(
      worldEntriesStreamProvider((novelId: widget.novelId, categoryId: null)),
    );

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
        child: Column(
          children: [
            // Top drag indicator handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: c.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header with Collision-safe Flex Alignment
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Symbols.auto_stories, color: c.primary, size: 22),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          isIndo ? 'Impor dari Indeks' : 'Import from Index',
                          style: AppTypography.screenTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                IconButton(
                  icon: Icon(Symbols.auto_awesome_motion, color: c.primary),
                  onPressed: () {
                    Navigator.of(context).pop();
                    AiIndexScreen.show(context, novelId: widget.novelId);
                  },
                  tooltip: isIndo ? 'Pemindai Indeks AI' : 'AI Index Scanner',
                ),
                IconButton(
                  icon: const Icon(Symbols.close),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: isIndo ? 'Tutup' : 'Close',
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: TextField(
              controller: _searchController,
              style: AppTypography.body,
              decoration: InputDecoration(
                hintText: isIndo
                    ? 'Cari karakter, lokasi, faksi...'
                    : 'Search characters, locations, factions...',
                isDense: true,
                prefixIcon: const Icon(Symbols.search, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.input),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
              ),
              onChanged: (val) => setState(() => _filter = val.trim()),
            ),
          ),

          // Dual Identifier Binding Toggle (when Characters are relevant)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: c.surfaceSecondary,
                borderRadius: BorderRadius.circular(AppRadius.input),
                border: Border.all(color: c.outlineVariant, width: 0.5),
              ),
              child: Row(
                children: [
                  Icon(Symbols.link, size: 16, color: c.primary),
                  const SizedBox(width: 8),
                  Text(
                    isIndo ? 'Pengikatan Karakter:' : 'Character Binding:',
                    style: AppTypography.labelSm.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  SegmentedButton<CharacterBindingMode>(
                    segments: [
                      ButtonSegment(
                        value: CharacterBindingMode.name,
                        label: Text(
                          isIndo ? 'Nama Lengkap' : 'Full Name',
                          style: const TextStyle(fontSize: 11),
                        ),
                        icon: const Icon(Symbols.badge, size: 14),
                      ),
                      ButtonSegment(
                        value: CharacterBindingMode.nickname,
                        label: Text(
                          isIndo ? 'Nama Panggilan' : 'Nickname',
                          style: const TextStyle(fontSize: 11),
                        ),
                        icon: const Icon(Symbols.tag, size: 14),
                      ),
                    ],
                    selected: {_characterBindingMode},
                    style: SegmentedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onSelectionChanged: (set) {
                      setState(() => _characterBindingMode = set.first);
                    },
                  ),
                ],
              ),
            ),
          ),

          // Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                ChoiceChip(
                  label: Text(isIndo ? 'Semua' : 'All'),
                  selected: _selectedType == null,
                  onSelected: (_) => setState(() => _selectedType = null),
                ),
                const SizedBox(width: AppSpacing.xs),
                ChoiceChip(
                  label: Text(isIndo ? 'Karakter' : 'Characters'),
                  selected: _selectedType == NvEntityType.character,
                  onSelected: (_) =>
                      setState(() => _selectedType = NvEntityType.character),
                ),
                const SizedBox(width: AppSpacing.xs),
                ChoiceChip(
                  label: Text(isIndo ? 'Lokasi' : 'Locations'),
                  selected: _selectedType == NvEntityType.location,
                  onSelected: (_) =>
                      setState(() => _selectedType = NvEntityType.location),
                ),
                const SizedBox(width: AppSpacing.xs),
                ChoiceChip(
                  label: Text(isIndo ? 'Faksi' : 'Factions'),
                  selected: _selectedType == NvEntityType.faction,
                  onSelected: (_) =>
                      setState(() => _selectedType = NvEntityType.faction),
                ),
                const SizedBox(width: AppSpacing.xs),
                ChoiceChip(
                  label: Text(isIndo ? 'Lore Dunia' : 'World Lore'),
                  selected: _selectedType == NvEntityType.worldEntry,
                  onSelected: (_) =>
                      setState(() => _selectedType = NvEntityType.worldEntry),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Entities List
          Expanded(
            child: Builder(
              builder: (ctx) {
                final isLoading =
                    charactersAsync.isLoading || worldEntriesAsync.isLoading;
                if (isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final characters = charactersAsync.valueOrNull ?? [];
                final worldEntries = worldEntriesAsync.valueOrNull ?? [];

                final allItems = <IndexEntityItem>[];

                for (final ch in characters) {
                  allItems.add(
                    IndexEntityItem(
                      id: ch.id,
                      name: ch.name,
                      nickname: ch.nickname,
                      subtitle: ch.role.label,
                      type: NvEntityType.character,
                    ),
                  );
                }

                for (final we in worldEntries) {
                  // Categorize based on subtitle or name heuristics
                  NvEntityType t = NvEntityType.worldEntry;
                  final sub = we.subtitle?.toLowerCase() ?? '';
                  if (sub.contains('location') ||
                      sub.contains('city') ||
                      sub.contains('realm') ||
                      sub.contains('place')) {
                    t = NvEntityType.location;
                  } else if (sub.contains('faction') ||
                      sub.contains('guild') ||
                      sub.contains('clan') ||
                      sub.contains('order')) {
                    t = NvEntityType.faction;
                  } else if (sub.contains('item') ||
                      sub.contains('relic') ||
                      sub.contains('weapon')) {
                    t = NvEntityType.item;
                  }

                  allItems.add(
                    IndexEntityItem(
                      id: we.id,
                      name: we.name,
                      subtitle: we.subtitle,
                      type: t,
                    ),
                  );
                }

                if (allItems.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Symbols.menu_book, size: 48, color: c.textMuted),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            isIndo
                                ? 'Belum Ada Lore Indeks'
                                : 'No Index Lore Created Yet',
                            style: AppTypography.cardTitle,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            isIndo
                                ? 'Buat karakter atau entri dunia untuk menyebut dan menautkannya di lembar kerja Anda.'
                                : 'Create characters or world entries to mention and link them in your workspace.',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySm.copyWith(
                              color: c.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.xs,
                            alignment: WrapAlignment.center,
                            children: [
                              NvButton(
                                label: isIndo ? 'Tambah Karakter' : 'Add Character',
                                icon: Symbols.person_add,
                                variant: NvButtonVariant.primary,
                                onPressed: () async {
                                  final created =
                                      await CreateCharacterDialog.show(
                                    context,
                                    widget.novelId,
                                  );
                                  if (created != null && context.mounted) {
                                    Navigator.of(context).pop(
                                      IndexEntityItem(
                                        id: created.id,
                                        name: created.name,
                                        nickname: created.nickname,
                                        subtitle: created.role.label,
                                        type: NvEntityType.character,
                                      ),
                                    );
                                  }
                                },
                              ),
                              NvButton(
                                label: isIndo ? 'Tambah Lore Dunia' : 'Add World Lore',
                                icon: Symbols.add_location_alt,
                                variant: NvButtonVariant.secondary,
                                onPressed: () async {
                                  final created =
                                      await CreateWorldEntryDialog.show(
                                    context,
                                    widget.novelId,
                                  );
                                  if (created != null && context.mounted) {
                                    Navigator.of(context).pop(
                                      IndexEntityItem(
                                        id: created.id,
                                        name: created.name,
                                        subtitle: created.subtitle,
                                        type: NvEntityType.worldEntry,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Filter items
                final filtered = allItems.where((item) {
                  if (_selectedType != null && item.type != _selectedType) {
                    return false;
                  }
                  if (_filter.isNotEmpty) {
                    final matchName = item.name
                        .toLowerCase()
                        .contains(_filter.toLowerCase());
                    final matchNick = item.nickname
                            ?.toLowerCase()
                            .contains(_filter.toLowerCase()) ??
                        false;
                    final matchSub = item.subtitle
                            ?.toLowerCase()
                            .contains(_filter.toLowerCase()) ??
                        false;
                    return matchName || matchNick || matchSub;
                  }
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  final isCharactersTab =
                      _selectedType == NvEntityType.character;
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isCharactersTab
                                ? Symbols.group
                                : Symbols.search_off,
                            size: 44,
                            color: c.textMuted,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            isCharactersTab
                                ? (isIndo ? 'Tidak Ada Karakter Ditemukan' : 'No Characters Found')
                                : (isIndo ? 'Tidak Ada Entri Indeks yang Cocok' : 'No Matching Index Entries'),
                            style: AppTypography.cardTitle,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            isCharactersTab
                                ? (isIndo
                                    ? 'Buat karakter untuk novel ini agar dapat ditautkan dan disebut dalam naskah Anda.'
                                    : 'Create characters for this novel to link and mention them in your manuscript.')
                                : (isIndo
                                    ? 'Coba hapus kueri pencarian atau pilih filter kategori lain.'
                                    : 'Try clearing the search query or selecting a different category filter.'),
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySm.copyWith(
                              color: c.textSecondary,
                            ),
                          ),
                          if (isCharactersTab) ...[
                            const SizedBox(height: AppSpacing.md),
                            NvButton(
                              label: isIndo ? 'Buat Karakter' : 'Create Character',
                              icon: Symbols.person_add,
                              variant: NvButtonVariant.primary,
                              onPressed: () async {
                                final created =
                                    await CreateCharacterDialog.show(
                                  context,
                                  widget.novelId,
                                );
                                if (created != null && context.mounted) {
                                  Navigator.of(context).pop(
                                    IndexEntityItem(
                                      id: created.id,
                                      name: created.name,
                                      nickname: created.nickname,
                                      subtitle: created.role.label,
                                      type: NvEntityType.character,
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, idx) {
                    final item = filtered[idx];
                    final isCharacter = item.type == NvEntityType.character;
                    final hasNickname = item.nickname != null &&
                        item.nickname!.trim().isNotEmpty;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 4,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: c.primarySoft,
                        child: Icon(
                          _getIconForType(item.type),
                          color: c.primary,
                          size: 18,
                        ),
                      ),
                      title: Text(item.name, style: AppTypography.labelMd),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (hasNickname)
                            Text(
                              '${isIndo ? "Panggilan" : "Nickname"}: "${item.nickname}" • ${item.subtitle ?? ""}',
                              style: AppTypography.bodySm.copyWith(
                                color: c.primary,
                                fontSize: 11,
                              ),
                            )
                          else if (item.subtitle != null)
                            Text(item.subtitle!, style: AppTypography.bodySm),
                          if (isCharacter && hasNickname)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  InkWell(
                                    onTap: () {
                                      Navigator.of(context).pop(
                                        item.copyWithBinding(item.name),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(AppRadius.pill),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: c.surfaceSecondary,
                                        borderRadius:
                                            BorderRadius.circular(AppRadius.pill),
                                        border: Border.all(
                                          color: c.outlineVariant,
                                          width: 0.5,
                                        ),
                                      ),
                                      child: Text(
                                        isIndo ? 'Ikat Nama' : 'Bind Name',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: c.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  InkWell(
                                    onTap: () {
                                      Navigator.of(context).pop(
                                        item.copyWithBinding(item.nickname!),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(AppRadius.pill),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: c.primarySoft,
                                        borderRadius:
                                            BorderRadius.circular(AppRadius.pill),
                                      ),
                                      child: Text(
                                        isIndo ? 'Ikat Panggilan' : 'Bind Nickname',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: c.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          NvEntityPill(
                            name: item.name,
                            type: item.type,
                            onCard: true,
                          ),
                          PopupMenuButton<String>(
                            icon: Icon(
                              Symbols.more_vert,
                              size: 18,
                              color: c.textSecondary,
                            ),
                            tooltip: isIndo ? 'Opsi' : 'Options',
                            padding: EdgeInsets.zero,
                            onSelected: (val) {
                              if (val == 'edit') _handleEdit(item);
                              if (val == 'delete') _handleDelete(item);
                            },
                            itemBuilder: (ctx) => [
                              PopupMenuItem<String>(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    const Icon(Symbols.edit, size: 18),
                                    const SizedBox(width: AppSpacing.sm),
                                    Text(isIndo ? 'Ubah Lore' : 'Edit Lore'),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Symbols.delete, size: 18, color: c.error),
                                    const SizedBox(width: AppSpacing.sm),
                                    Text(isIndo ? 'Hapus' : 'Delete', style: TextStyle(color: c.error)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      onTap: () {
                        // Use active character binding mode
                        if (isCharacter &&
                            _characterBindingMode ==
                                CharacterBindingMode.nickname &&
                            hasNickname) {
                          Navigator.of(context)
                              .pop(item.copyWithBinding(item.nickname!));
                        } else {
                          Navigator.of(context)
                              .pop(item.copyWithBinding(item.name));
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

  Future<void> _handleEdit(IndexEntityItem item) async {
    if (item.type == NvEntityType.character) {
      final character =
          await ref.read(characterRepositoryProvider).getCharacter(item.id);
      if (character != null && mounted) {
        await CreateCharacterDialog.show(
          context,
          widget.novelId,
          characterToEdit: character,
        );
      }
    } else {
      final entry = await ref.read(worldRepositoryProvider).getEntry(item.id);
      if (entry != null && mounted) {
        await CreateWorldEntryDialog.show(
          context,
          widget.novelId,
          entryToEdit: entry,
        );
      }
    }
  }

  Future<void> _handleDelete(IndexEntityItem item) async {
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    final isChar = item.type == NvEntityType.character;
    final entityTypeName = isChar
        ? (isIndo ? 'Karakter' : 'Character')
        : (isIndo ? 'Entri Dunia' : 'World Entry');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isIndo ? 'Hapus $entityTypeName?' : 'Delete $entityTypeName?'),
        content: Text(isIndo
            ? 'Apakah Anda yakin ingin menghapus "${item.name}"?'
            : 'Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(isIndo ? 'Batal' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(isIndo ? 'Hapus' : 'Delete',
                style: TextStyle(color: context.colors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      if (isChar) {
        await ref
            .read(characterActionsControllerProvider)
            .deleteCharacter(item.id);
      } else {
        await ref.read(worldActionsControllerProvider).deleteEntry(item.id);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isIndo
                ? '"${item.name}" telah dihapus.'
                : '"${item.name}" deleted.'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  IconData _getIconForType(NvEntityType type) {
    switch (type) {
      case NvEntityType.character:
        return Symbols.person;
      case NvEntityType.location:
        return Symbols.location_on;
      case NvEntityType.faction:
        return Symbols.shield;
      case NvEntityType.item:
        return Symbols.key;
      default:
        return Symbols.auto_stories;
    }
  }
}
