import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../manuscript/application/manuscript_providers.dart';
import '../../../manuscript/domain/models/manuscript_models.dart';
import '../../application/ai_index_providers.dart';
import '../../domain/models/ai_index_models.dart';

class AiIndexScreen extends ConsumerStatefulWidget {
  final String novelId;
  final String? initialChapterId;

  const AiIndexScreen({
    super.key,
    required this.novelId,
    this.initialChapterId,
  });

  static Future<void> show(
    BuildContext context, {
    required String novelId,
    String? initialChapterId,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AiIndexScreen(
        novelId: novelId,
        initialChapterId: initialChapterId,
      ),
    );
  }

  @override
  ConsumerState<AiIndexScreen> createState() => _AiIndexScreenState();
}

class _AiIndexScreenState extends ConsumerState<AiIndexScreen> {
  late String? _selectedChapterId;
  bool _isAllChapters = true;

  @override
  void initState() {
    super.initState();
    _selectedChapterId = widget.initialChapterId;
    _isAllChapters = widget.initialChapterId == null;

    // Automatically trigger initial scan if initialChapterId was provided
    if (widget.initialChapterId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(aiIndexNotifierProvider.notifier).scanManuscript(
              novelId: widget.novelId,
              specificChapterId: widget.initialChapterId,
            );
      });
    }
  }

  void _triggerScan() {
    ref.read(aiIndexNotifierProvider.notifier).scanManuscript(
          novelId: widget.novelId,
          specificChapterId: _isAllChapters ? null : _selectedChapterId,
        );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final state = ref.watch(aiIndexNotifierProvider);
    final chaptersAsync = ref.watch(chaptersStreamProvider(widget.novelId));

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: c.outlineVariant.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),

            // Sheet Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: c.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Symbols.auto_awesome_motion,
                      color: c.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Index Scanner',
                          style: AppTypography.screenTitle.copyWith(fontSize: 18),
                        ),
                        Text(
                          'Scan manuscript to suggest characters, locations, factions, and religions.',
                          style: AppTypography.bodySm.copyWith(
                            color: c.textSecondary,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Symbols.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Scope & Scan Controls Card
            _buildScopeSelector(
              c: c,
              state: state,
              chaptersAsync: chaptersAsync,
            ),

            // Content Area
            Expanded(
              child: _buildBody(c, state),
            ),

            // Bottom Batch Actions Bar (shown when new entities are found)
            if (state.status == AiIndexStatus.success &&
                state.entities.isNotEmpty)
              _buildBottomBatchBar(c, state),
          ],
        ),
      ),
    );
  }

  /// Scope Selector & Scan trigger
  Widget _buildScopeSelector({
    required AppColors c,
    required AiIndexState state,
    required AsyncValue<List<ChapterModel>> chaptersAsync,
  }) {
    final isScanning = state.status == AiIndexStatus.scanning;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: c.surfaceSecondary.withValues(alpha: 0.6),
        border: Border(
          bottom: BorderSide(
            color: c.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 460;

          final scopeToggle = SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: true,
                label: Text('All Chapters'),
                icon: Icon(Symbols.library_books, size: 16),
              ),
              ButtonSegment(
                value: false,
                label: Text('Specific Chapter'),
                icon: Icon(Symbols.description, size: 16),
              ),
            ],
            selected: {_isAllChapters},
            onSelectionChanged: isScanning
                ? null
                : (newSelection) {
                    setState(() {
                      _isAllChapters = newSelection.first;
                      if (_isAllChapters) _selectedChapterId = null;
                    });
                  },
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              ),
            ),
          );

          final scanButton = FilledButton.icon(
            onPressed: isScanning ? null : _triggerScan,
            icon: isScanning
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Symbols.auto_awesome, size: 16),
            label: Text(
              isScanning
                  ? 'Scanning Manuscript...'
                  : (state.entities.isEmpty ? 'Start Index Scan' : 'Rescan Manuscript'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
            ),
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                scopeToggle,
                if (!_isAllChapters) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _buildChapterDropdown(c, chaptersAsync, isScanning),
                ],
                const SizedBox(height: AppSpacing.sm),
                scanButton,
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: scopeToggle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  scanButton,
                ],
              ),
              if (!_isAllChapters) ...[
                const SizedBox(height: AppSpacing.sm),
                _buildChapterDropdown(c, chaptersAsync, isScanning),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildChapterDropdown(
    AppColors c,
    AsyncValue<List<ChapterModel>> chaptersAsync,
    bool isScanning,
  ) {
    return chaptersAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (chapters) {
        if (chapters.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'No chapters available to scan.',
              style: AppTypography.bodySm.copyWith(color: c.textSecondary),
            ),
          );
        }

        // Default selection
        _selectedChapterId ??= chapters.first.id;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(AppRadius.input),
            border: Border.all(color: c.outlineVariant),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: chapters.any((ch) => ch.id == _selectedChapterId)
                  ? _selectedChapterId
                  : chapters.first.id,
              items: chapters.map((ch) {
                return DropdownMenuItem<String>(
                  value: ch.id,
                  child: Text(
                    ch.title.isNotEmpty ? ch.title : 'Untitled Chapter',
                    style: AppTypography.bodySm,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: isScanning
                  ? null
                  : (val) {
                      if (val != null) {
                        setState(() => _selectedChapterId = val);
                      }
                    },
            ),
          ),
        );
      },
    );
  }

  /// Main Body Switcher
  Widget _buildBody(AppColors c, AiIndexState state) {
    if (state.status == AiIndexStatus.scanning) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: c.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Symbols.auto_awesome_motion,
                size: 36,
                color: c.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Scanning Manuscript...',
              style: AppTypography.cardTitle,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Detecting characters, locations, factions, and religions...',
              style: AppTypography.bodySm.copyWith(color: c.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            const SizedBox(
              width: 160,
              child: LinearProgressIndicator(),
            ),
          ],
        ),
      );
    }

    if (state.status == AiIndexStatus.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: NvErrorState(
            title: 'Scan Encountered an Issue',
            message: state.errorMessage ?? 'Unable to complete manuscript scan.',
            onRetry: _triggerScan,
          ),
        ),
      );
    }

    if (state.status == AiIndexStatus.idle && state.entities.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: c.surfaceSecondary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Symbols.manage_search,
                  size: 40,
                  color: c.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Ready to Scan Your Story',
                style: AppTypography.cardTitle,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Novellie AI will read your chapters and automatically extract newly mentioned people, places, factions, and lore to enrich your World Index.',
                style: AppTypography.bodySm.copyWith(color: c.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: _triggerScan,
                icon: const Icon(Symbols.auto_awesome, size: 18),
                label: const Text('Start Discovery Scan'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.entities.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Symbols.check_circle, size: 40, color: c.primary),
              const SizedBox(height: AppSpacing.sm),
              Text('No New Entities Found', style: AppTypography.cardTitle),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'All named entities found in this manuscript are already cataloged in your Index.',
                style: AppTypography.bodySm.copyWith(color: c.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Results View
    final filtered = state.filteredEntities;

    return Column(
      children: [
        // Category Filter Chips
        _buildFilterBar(c, state),

        // Entity Cards List
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    'No entities in this category.',
                    style: AppTypography.bodySm.copyWith(
                      color: c.textSecondary,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, idx) {
                    final entity = filtered[idx];
                    return _buildEntityCard(c, entity);
                  },
                ),
        ),
      ],
    );
  }

  /// Filter bar for switching categories
  Widget _buildFilterBar(AppColors c, AiIndexState state) {
    final notifier = ref.read(aiIndexNotifierProvider.notifier);

    Widget chip({
      required String label,
      required int count,
      required bool isSelected,
      required VoidCallback onTap,
      IconData? icon,
    }) {
      return Padding(
        padding: const EdgeInsets.only(right: AppSpacing.xs),
        child: FilterChip(
          selected: isSelected,
          avatar: icon != null ? Icon(icon, size: 14) : null,
          label: Text('$label ($count)'),
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          onSelected: (_) => onTap(),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            chip(
              label: 'All',
              count: state.entities.length,
              isSelected: state.selectedFilter == null,
              onTap: () => notifier.setFilter(null),
            ),
            for (final type in AiIndexEntityType.values) ...[
              chip(
                label: type.label,
                count: state.entities.where((e) => e.type == type).length,
                isSelected: state.selectedFilter == type,
                icon: type.icon,
                onTap: () => notifier.setFilter(type),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Single Entity Suggestion Card
  Widget _buildEntityCard(AppColors c, AiIndexEntity entity) {
    final notifier = ref.read(aiIndexNotifierProvider.notifier);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      color: entity.isAdded ? c.primarySoft.withValues(alpha: 0.4) : c.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(
          color: entity.isAdded
              ? c.primary.withValues(alpha: 0.5)
              : c.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox for selection (if not already cataloged)
            if (!entity.isAlreadyInIndex && !entity.isAdded)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs),
                child: Checkbox(
                  value: entity.isSelected,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (_) => notifier.toggleSelect(entity.id),
                ),
              ),

            // Type Icon with color container
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: entity.type.color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                entity.type.icon,
                size: 16,
                color: entity.type.color,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),

            // Name, Category & Summary
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entity.name,
                          style: AppTypography.labelMd.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Type Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: entity.type.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          entity.type == AiIndexEntityType.character
                              ? entity.characterRole.label
                              : entity.type.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: entity.type.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),

                  // Summary
                  if (entity.summary.isNotEmpty)
                    Text(
                      entity.summary,
                      style: AppTypography.bodySm.copyWith(
                        fontSize: 11,
                        color: c.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                  if (entity.sourceChapterTitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Source: ${entity.sourceChapterTitle}',
                      style: AppTypography.bodySm.copyWith(
                        fontSize: 10,
                        color: c.textSecondary.withValues(alpha: 0.8),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),

            // Action / Status Badge
            if (entity.isAdded)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: c.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Symbols.check, size: 14, color: c.primary),
                    const SizedBox(width: 4),
                    Text(
                      'Added',
                      style: AppTypography.bodySm.copyWith(
                        fontSize: 11,
                        color: c.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            else if (entity.isAlreadyInIndex)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: c.surfaceSecondary,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: c.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  'In Index',
                  style: AppTypography.bodySm.copyWith(
                    fontSize: 10,
                    color: c.textSecondary,
                  ),
                ),
              )
            else
              FilledButton.tonal(
                onPressed: () => notifier.addToIndex(entity, widget.novelId),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 0,
                  ),
                ),
                child: const Text('Add', style: TextStyle(fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }

  /// Bottom Batch Actions Bar
  Widget _buildBottomBatchBar(AppColors c, AiIndexState state) {
    final notifier = ref.read(aiIndexNotifierProvider.notifier);
    final selectedCount = state.selectedCount;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(
          top: BorderSide(
            color: c.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
      ),
      child: Row(
        children: [
          TextButton(
            onPressed: () {
              final allSelected = selectedCount == state.newCount;
              notifier.selectAll(!allSelected);
            },
            child: Text(
              selectedCount == state.newCount ? 'Deselect All' : 'Select All New',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: selectedCount > 0 && !state.isAdding
                ? () async {
                    final count = await notifier.addSelected(widget.novelId);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Successfully added $count entities to your Index!',
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                : null,
            icon: state.isAdding
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Symbols.add_task, size: 16),
            label: Text(
              state.isAdding
                  ? 'Adding...'
                  : (selectedCount > 0
                      ? 'Add Selected ($selectedCount)'
                      : 'Select Entities'),
            ),
          ),
        ],
      ),
    );
  }
}
