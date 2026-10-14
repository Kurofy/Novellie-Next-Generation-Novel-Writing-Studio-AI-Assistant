import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/world_providers.dart';
import '../../domain/models/world_models.dart';

class WorldEntryDetailScreen extends ConsumerStatefulWidget {
  final String entryId;

  const WorldEntryDetailScreen({
    super.key,
    required this.entryId,
  });

  @override
  ConsumerState<WorldEntryDetailScreen> createState() =>
      _WorldEntryDetailScreenState();
}

class _WorldEntryDetailScreenState
    extends ConsumerState<WorldEntryDetailScreen> {
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _subtitleController;
  late TextEditingController _summaryController;
  bool _verifiedCanon = false;
  Timer? _debounceTimer;
  late FocusNode _nameFocusNode;
  late FocusNode _subtitleFocusNode;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _subtitleController = TextEditingController();
    _summaryController = TextEditingController();
    _nameFocusNode = FocusNode();
    _subtitleFocusNode = FocusNode();
  }

  void _syncControllers(WorldEntryModel entry) {
    if (!_isEditing) {
      _nameController.text = entry.name;
      _subtitleController.text = entry.subtitle ?? '';
      _summaryController.text = entry.summary ?? '';
      _verifiedCanon = entry.verifiedCanon;
    }
  }

  void _onFieldChanged(WorldEntryModel entry) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _autoCommit(entry);
    });
  }

  Future<void> _autoCommit(WorldEntryModel entry) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final updated = WorldEntryModel(
      id: entry.id,
      novelId: entry.novelId,
      categoryId: entry.categoryId,
      parentId: entry.parentId,
      name: name,
      subtitle: _subtitleController.text.trim().isNotEmpty
          ? _subtitleController.text.trim()
          : null,
      summary: _summaryController.text.trim().isNotEmpty
          ? _summaryController.text.trim()
          : null,
      verifiedCanon: _verifiedCanon,
      createdAt: entry.createdAt,
      updatedAt: DateTime.now().toUtc(),
    );

    await ref.read(worldActionsControllerProvider).updateEntry(updated);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _nameFocusNode.dispose();
    _subtitleFocusNode.dispose();
    _nameController.dispose();
    _subtitleController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  Future<void> _handleSave(WorldEntryModel entry) async {
    final updated = WorldEntryModel(
      id: entry.id,
      novelId: entry.novelId,
      categoryId: entry.categoryId,
      parentId: entry.parentId,
      name: _nameController.text.trim(),
      subtitle: _subtitleController.text.trim().isNotEmpty
          ? _subtitleController.text.trim()
          : null,
      summary: _summaryController.text.trim().isNotEmpty
          ? _summaryController.text.trim()
          : null,
      verifiedCanon: _verifiedCanon,
      createdAt: entry.createdAt,
      updatedAt: DateTime.now().toUtc(),
    );

    await ref.read(worldActionsControllerProvider).updateEntry(updated);
    setState(() => _isEditing = false);
  }

  void _confirmDelete(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isIndo ? 'Hapus Entri?' : 'Delete Entry?'),
        content: Text(
          isIndo
              ? 'Yakin ingin menghapus entri dunia ini? Entri akan dipindahkan ke tempat sampah.'
              : 'Are you sure you want to remove this world entry? It will be moved to trash.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref
                  .read(worldActionsControllerProvider)
                  .deleteEntry(widget.entryId);
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: Text(
              l10n?.delete ?? 'Delete',
              style: TextStyle(color: context.colors.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    final entryAsync =
        ref.watch(worldEntryDetailStreamProvider(widget.entryId));

    return entryAsync.when(
      loading: () => Scaffold(
        appBar: NvAppBar(
          showBack: true,
          title: isIndo ? 'Detail Entri Dunia' : 'World Entry Details',
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        appBar: NvAppBar(
          showBack: true,
          title: isIndo ? 'Entri Dunia' : 'World Entry',
        ),
        body: Center(
          child: NvErrorState(
            title: isIndo
                ? 'Gagal memuat entri dunia'
                : 'Failed to load world entry',
            message: isIndo
                ? 'Terjadi kesalahan saat mengambil detail entri dunia.'
                : 'An error occurred while fetching world entry details.',
            onRetry: () =>
                ref.invalidate(worldEntryDetailStreamProvider(widget.entryId)),
          ),
        ),
      ),
      data: (entry) {
        if (entry == null) {
          return Scaffold(
            appBar: NvAppBar(
              showBack: true,
              title: isIndo ? 'Entri Tidak Ditemukan' : 'Entry Not Found',
            ),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Symbols.auto_stories, size: 48, color: c.textMuted),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    isIndo
                        ? 'Entri ini tidak lagi ada di indeks.'
                        : 'This entry no longer exists in index.',
                    style: AppTypography.body,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  NvButton(
                    label: isIndo ? 'Kembali' : 'Go Back',
                    variant: NvButtonVariant.secondary,
                    icon: Symbols.arrow_back,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),
          );
        }

        _syncControllers(entry);

        return Scaffold(
          appBar: NvAppBar(
            showBack: true,
            title: entry.name,
            actions: [
              IconButton(
                icon: Icon(
                  _isEditing ? Symbols.save : Symbols.edit,
                  color: c.textPrimary,
                ),
                onPressed: () {
                  if (_isEditing) {
                    _handleSave(entry);
                  } else {
                    setState(() => _isEditing = true);
                  }
                },
                tooltip: _isEditing
                    ? (l10n?.save ?? 'Save')
                    : (isIndo ? 'Edit' : 'Edit'),
              ),
              IconButton(
                icon: Icon(Symbols.delete, color: c.error),
                onPressed: () => _confirmDelete(context),
                tooltip: l10n?.delete ?? 'Delete',
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(AppSpacing.screenMargin(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NvCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isEditing) ...[
                        Text(isIndo ? 'Nama' : 'Name', style: AppTypography.labelMd),
                        const SizedBox(height: AppSpacing.xs),
                        NvTextField(
                          controller: _nameController,
                          focusNode: _nameFocusNode,
                          hintText: isIndo ? 'Nama entri' : 'Entry name',
                          onChanged: (_) => _onFieldChanged(entry),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          isIndo
                              ? 'Subjudul / Klasifikasi'
                              : 'Subtitle / Classification',
                          style: AppTypography.labelMd,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        NvTextField(
                          controller: _subtitleController,
                          focusNode: _subtitleFocusNode,
                          hintText: isIndo ? 'mis. Kerajaan Kuno' : 'e.g. Ancient Kingdom',
                          onChanged: (_) => _onFieldChanged(entry),
                        ),
                      ] else ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                entry.name,
                                style: AppTypography.screenTitle,
                              ),
                            ),
                            if (entry.verifiedCanon)
                              NvChip.status(
                                label: isIndo ? 'Kanon' : 'Canon',
                                statusKind: NvStatusTagKind.success,
                              ),
                          ],
                        ),
                        if (entry.subtitle != null &&
                            entry.subtitle!.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            entry.subtitle!,
                            style: AppTypography.bodySm,
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                Text(
                  isIndo ? 'Kisah & Deskripsi' : 'Lore & Description',
                  style: AppTypography.sectionTitle,
                ),
                const SizedBox(height: AppSpacing.md),

                NvCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isEditing) ...[
                        NvTextField(
                          controller: _summaryController,
                          hintText: isIndo
                              ? 'Kisah mendalam dan konteks pembangunan dunia'
                              : 'Detailed lore and worldbuilding context',
                          maxLines: 8,
                          onChanged: (_) => _onFieldChanged(entry),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        SwitchListTile(
                          title: Text(
                            isIndo ? 'Tandai sebagai Kanon' : 'Mark as Canon',
                          ),
                          subtitle: Text(
                            isIndo
                                ? 'Kebenaran cerita terverifikasi di semesta ini'
                                : 'Verified story truth in this universe',
                          ),
                          value: _verifiedCanon,
                          onChanged: (val) =>
                              setState(() => _verifiedCanon = val),
                          activeThumbColor: c.primary,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ] else ...[
                        Text(
                          (entry.summary != null && entry.summary!.isNotEmpty)
                              ? entry.summary!
                              : (isIndo
                                  ? 'Belum ada kisah detail yang dicatat.'
                                  : 'No detailed lore recorded yet.'),
                          style: AppTypography.body,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
