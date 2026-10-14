import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../tools/presentation/screens/family_tree_screen.dart';
import '../../application/character_providers.dart';
import '../../domain/models/character_model.dart';
import '../widgets/character_avatar.dart';
import 'character_detail_screen.dart';
import 'create_character_dialog.dart';

class CharacterListScreen extends ConsumerStatefulWidget {
  final String novelId;
  final bool showAppBar;

  const CharacterListScreen({
    super.key,
    required this.novelId,
    this.showAppBar = false,
  });

  @override
  ConsumerState<CharacterListScreen> createState() =>
      _CharacterListScreenState();
}

class _CharacterListScreenState extends ConsumerState<CharacterListScreen>
    with AutomaticKeepAliveClientMixin {
  CharacterRole? _selectedRoleFilter;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    final charactersAsync = ref.watch(charactersStreamProvider(widget.novelId));

    return Scaffold(
      backgroundColor: widget.showAppBar ? c.surface : Colors.transparent,
      appBar: widget.showAppBar
          ? NvAppBar(
              title: l10n?.characters ?? 'Characters',
              actions: [
                IconButton(
                  icon: const Icon(Symbols.family_restroom),
                  tooltip: isIndo ? 'Pohon Silsilah Karakter' : 'Character Family Trees',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            FamilyTreeScreen(initialNovelId: widget.novelId),
                      ),
                    );
                  },
                ),
              ],
            )
          : null,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'character_list_fab',
        onPressed: () => CreateCharacterDialog.show(context, widget.novelId),
        backgroundColor: c.primaryFill,
        foregroundColor: c.onPrimary,
        icon: const Icon(Symbols.person_add),
        label: Text(l10n?.addCharacter ?? 'Add Character'),
      ),
      body: charactersAsync.when(
        skipLoadingOnReload: true,
        loading: () => Center(
          child: CircularProgressIndicator(
            color: c.primary,
          ),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.screenMargin(context)),
            child: NvErrorState(
              title: isIndo ? 'Gagal memuat karakter' : 'Failed to load characters',
              message:
                  '${isIndo ? 'Terjadi kesalahan saat memuat daftar karakter:' : 'An error occurred while loading character roster:'} ${err.toString().replaceFirst(RegExp(r"^Exception:\s*"), "")}',
              onRetry: () =>
                  ref.invalidate(charactersStreamProvider(widget.novelId)),
            ),
          ),
        ),
        data: (characters) {
          if (characters.isEmpty) {
            return Center(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.screenMargin(context)),
                  child: NvEmptyState.nothingYet(
                    icon: Symbols.group,
                    title: l10n?.noCharactersYet ?? 'No characters yet',
                    body: l10n?.noCharactersBody ??
                        'Introduce protagonists, antagonists, and supporting cast for your novel.',
                    actionLabel: l10n?.createCharacter ?? 'Create Character',
                    onAction: () =>
                        CreateCharacterDialog.show(context, widget.novelId),
                  ),
                ),
              ),
            );
          }

          final filtered = _selectedRoleFilter == null
              ? characters
              : characters
                  .where((ch) => ch.role == _selectedRoleFilter)
                  .toList();

          return Column(
            children: [
              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Builder(
                      builder: (ctx) {
                        final isSelected = _selectedRoleFilter == null;
                        return ChoiceChip(
                          label: Text(l10n?.allRoles ?? 'All'),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedRoleFilter = null);
                            }
                          },
                          selectedColor: c.primarySoft,
                          backgroundColor: c.surfaceSecondary,
                          labelStyle: TextStyle(
                            color: isSelected ? c.primary : c.textSecondary,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ...CharacterRole.values.map((role) {
                      final isSelected = _selectedRoleFilter == role;
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: ChoiceChip(
                          label: Text(role.getLabel(l10n)),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedRoleFilter = selected ? role : null;
                            });
                          },
                          selectedColor: c.primarySoft,
                          backgroundColor: c.surfaceSecondary,
                          labelStyle: TextStyle(
                            color: isSelected ? c.primary : c.textSecondary,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),

              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: NvEmptyState.noMatches(
                          icon: Symbols.search_off,
                          title: isIndo ? 'Tidak ada karakter yang cocok' : 'No matching characters',
                          body: isIndo
                              ? 'Tidak ada karakter yang cocok dengan peran yang dipilih.'
                              : 'No characters found matching the selected role.',
                          actionLabel: l10n?.allRoles ?? 'Show All',
                          onAction: () =>
                              setState(() => _selectedRoleFilter = null),
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.screenMargin(context),
                          AppSpacing.screenMargin(context),
                          AppSpacing.screenMargin(context),
                          AppSpacing.screenMargin(context) + 88.0,
                        ),
                        itemCount: filtered.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, index) {
                          final character = filtered[index];
                          return _CharacterCard(
                            character: character,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (ctx) => CharacterDetailScreen(
                                    characterId: character.id,
                                  ),
                                ),
                              );
                            },
                            onEdit: () => _handleEditCharacter(character),
                            onDelete: () => _handleDeleteCharacter(character),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleEditCharacter(CharacterModel character) async {
    await CreateCharacterDialog.show(
      context,
      widget.novelId,
      characterToEdit: character,
    );
  }

  Future<void> _handleDeleteCharacter(CharacterModel character) async {
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${l10n?.delete ?? 'Delete'} ${character.name}?'),
        content: Text(
          isIndo
              ? 'Yakin ingin menghapus "${character.name}"? Anda dapat memulihkannya dari tempat sampah dalam 30 hari.'
              : 'Are you sure you want to delete "${character.name}"? You can restore it from trash within 30 days.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n?.delete ?? 'Delete',
              style: TextStyle(color: context.colors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref
          .read(characterActionsControllerProvider)
          .deleteCharacter(character.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isIndo
                  ? 'Karakter "${character.name}" dihapus.'
                  : 'Character "${character.name}" deleted.',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}

class _CharacterCard extends StatelessWidget {
  final CharacterModel character;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CharacterCard({
    required this.character,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  Widget _buildAvatar(BuildContext context) {
    return CharacterAvatar(
      name: character.name,
      portraitPath: character.portraitPath,
      gender: character.gender,
      size: 44,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';

    return NvCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(context),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        character.displayName,
                        style: AppTypography.cardTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    NvChip.status(
                      label: character.role.getLabel(l10n),
                      statusKind: NvStatusTagKind.neutral,
                    ),
                  ],
                ),
                if (character.goal != null &&
                    character.goal!.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${isIndo ? 'Tujuan' : 'Goal'}: ${character.goal!.trim()}',
                    style: AppTypography.bodySm,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (character.flaw != null &&
                    character.flaw!.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${isIndo ? 'Kelemahan' : 'Flaw'}: ${character.flaw!.trim()}',
                    style: AppTypography.bodySm,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          PopupMenuButton<String>(
            icon: Icon(Symbols.more_vert, size: 20, color: c.textSecondary),
            tooltip: l10n?.moreOptions ?? 'Options',
            padding: EdgeInsets.zero,
            onSelected: (val) {
              if (val == 'edit') onEdit();
              if (val == 'delete') onDelete();
            },
            itemBuilder: (ctx) => [
              PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    const Icon(Symbols.edit, size: 18),
                    const SizedBox(width: AppSpacing.sm),
                    Text(l10n?.editDetails ?? 'Edit Character'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Symbols.delete, size: 18, color: c.error),
                    const SizedBox(width: AppSpacing.sm),
                    Text(l10n?.delete ?? 'Delete', style: TextStyle(color: c.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
