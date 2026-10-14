import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../novels/application/novel_providers.dart';
import '../../../novels/domain/models/novel_model.dart';
import '../../application/ai_providers.dart';
import '../../domain/models/ai_models.dart';
import '../screens/ai_config_dialog.dart';
import '../screens/ai_index_screen.dart';
import 'ai_quill_message_view.dart';

class AiChatPanel extends ConsumerStatefulWidget {
  final bool isDocked;
  final String? chapterContent;
  final void Function(String text)? onInsertToEditor;
  final VoidCallback? onClose;

  const AiChatPanel({
    super.key,
    this.isDocked = false,
    this.chapterContent,
    this.onInsertToEditor,
    this.onClose,
  });

  @override
  ConsumerState<AiChatPanel> createState() => _AiChatPanelState();
}

class _AiChatPanelState extends ConsumerState<AiChatPanel> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _showHistory = false;

  List<Map<String, dynamic>> _getQuickPrompts(bool isIndo) => [
    {
      'icon': Symbols.lightbulb,
      'title': isIndo ? 'Plot Twist' : 'Plot Twists',
      'prompt': isIndo
          ? 'Beri 3 plot twist tak terduga untuk adegan saya berikutnya.'
          : 'Brainstorm 3 unpredictable plot twists for my next scene.',
    },
    {
      'icon': Symbols.forum,
      'title': isIndo ? 'Subteks Dialog' : 'Dialogue Subtext',
      'prompt': isIndo
          ? 'Perdalam konflik dan subteks dialog antar dua karakter.'
          : 'Deepen dialogue conflict & subtext between two characters.',
    },
    {
      'icon': Symbols.public,
      'title': isIndo ? 'Membangun Dunia Indrawi' : 'Sensory Worldbuilding',
      'prompt': isIndo
          ? 'Gambarkan lingkungan yang imersif dengan detail indrawi yang kaya.'
          : 'Describe an immersive environment with rich sensory details.',
    },
    {
      'icon': Symbols.auto_fix_high,
      'title': isIndo ? 'Kritik Prosa' : 'Prose Critique',
      'prompt': isIndo
          ? 'Analisis ritme (pacing), tempo, dan keseimbangan show-vs-tell untuk cerita saya.'
          : 'Analyze pacing, rhythm, and show-vs-tell balance for my story.',
    },
  ];

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend([String? preset]) async {
    final text = preset ?? _inputController.text;
    if (text.trim().isEmpty) return;

    _inputController.clear();
    await ref
        .read(aiActionsControllerProvider)
        .sendMessage(text, chapterContext: widget.chapterContent);
    _scrollToBottom();
  }

  void _handleCopy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n?.copiedToClipboard ?? 'Copied to clipboard!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleInsert(String text) {
    if (widget.onInsertToEditor != null) {
      widget.onInsertToEditor!(text);
    } else {
      ref.read(aiInsertToEditorProvider.notifier).state = text;
    }
    final isIndo = AppLocalizations.of(context)?.localeName == 'id';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isIndo
              ? 'Teks dimasukkan ke Editor Bab!'
              : 'Inserted text into Chapter Editor!',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    final configAsync = ref.watch(aiConfigProvider);
    final selectedNovelAsync = ref.watch(selectedAiNovelProvider);
    final selectedNovelId = ref.watch(selectedAiNovelIdProvider);
    final isSending = ref.watch(aiSendingProvider);
    final messages = ref.watch(aiChatMessagesProvider);
    final sessions = ref.watch(aiSessionsProvider);

    return configAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: NvErrorState(
          title: isIndo ? 'Kesalahan Pengaturan AI' : 'AI Settings Error',
          message: err.toString(),
          onRetry: () => ref.invalidate(aiConfigProvider),
        ),
      ),
      data: (config) {
        if (!config.isConfigured) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: NvEmptyState.notConfigured(
                icon: Symbols.auto_awesome,
                title: isIndo ? 'Asisten AI Belum Dikonfigurasi' : 'AI Assistant Not Configured',
                body: isIndo
                    ? 'Konfigurasikan Google Gemini atau kunci API kustom Anda untuk mengaktifkan rekan menulis AI.'
                    : 'Configure your Google Gemini or custom API key to unlock the AI writing partner.',
                actionLabel: isIndo ? 'Atur Penyedia' : 'Setup Provider',
                onAction: () => AiConfigDialog.show(context),
              ),
            ),
          );
        }

        final selectedNovel = selectedNovelAsync.valueOrNull;
        final isGeneralWriting = selectedNovelId == '__none__';

        return Column(
          children: [
            // Single unified top bar
            _buildUnifiedTopBar(
              c: c,
              config: config,
              selectedNovel: selectedNovel,
              isGeneralWriting: isGeneralWriting,
            ),

            // Main Content: History or Chat View
            Expanded(
              child: _showHistory
                  ? _buildHistoryView(sessions, c)
                  : _buildChatView(
                      messages: messages,
                      isSending: isSending,
                      c: c,
                      selectedNovel: selectedNovel,
                      isGeneralWriting: isGeneralWriting,
                    ),
            ),

            // Modern capsule input bar (chat mode only)
            if (!_showHistory)
              _buildInputArea(
                c: c,
                isSending: isSending,
                selectedNovel: selectedNovel,
                isGeneralWriting: isGeneralWriting,
              ),
          ],
        );
      },
    );
  }

  /// Single, clean top header bar with Novel Selector and essential actions
  Widget _buildUnifiedTopBar({
    required AppColors c,
    required AiConfigModel config,
    required NovelModel? selectedNovel,
    required bool isGeneralWriting,
  }) {
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';

    final String novelTitle = isGeneralWriting
        ? (isIndo ? 'Penulisan Umum' : 'General Writing')
        : (selectedNovel?.title ?? (isIndo ? 'Pilih Konteks Novel' : 'Select Novel Context'));

    final IconData novelIcon = isGeneralWriting
        ? Symbols.edit_note
        : (selectedNovel != null ? Symbols.menu_book : Symbols.auto_stories);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(
          bottom: BorderSide(
            color: c.outlineVariant.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        top: false,
        child: Row(
          children: [
            // Left: Novel Selector Pill Button
            Expanded(
              child: InkWell(
                onTap: () => _showNovelPickerSheet(context),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: c.surfaceSecondary,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: c.outlineVariant.withValues(alpha: 0.8),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: c.primarySoft,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(novelIcon, size: 16, color: c.primary),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              novelTitle,
                              style: AppTypography.labelMd.copyWith(
                                fontWeight: FontWeight.bold,
                                height: 1.15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${config.provider.label} • ${config.model}',
                              style: AppTypography.bodySm.copyWith(
                                fontSize: 10,
                                color: c.textSecondary,
                                height: 1.15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Symbols.arrow_drop_down,
                        size: 20,
                        color: c.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),

            // Right: New Chat button
            IconButton(
              icon: Icon(
                Symbols.edit_square,
                size: 20,
                color: c.textPrimary,
              ),
              tooltip: l10n?.newChat ?? 'New Chat',
              onPressed: () {
                ref.read(aiActionsControllerProvider).startNewSession();
                if (_showHistory) {
                  setState(() => _showHistory = false);
                }
              },
            ),

            // History toggle
            IconButton(
              icon: Icon(
                _showHistory ? Symbols.chat : Symbols.history,
                size: 20,
                color: _showHistory ? c.primary : c.textSecondary,
              ),
              tooltip: _showHistory
                  ? (l10n?.backToChat ?? 'Back to Chat')
                  : (l10n?.chatHistory ?? 'Chat History'),
              onPressed: () {
                setState(() => _showHistory = !_showHistory);
              },
            ),

            // Overflow Menu
            PopupMenuButton<String>(
              icon: Icon(Symbols.more_vert, size: 20, color: c.textSecondary),
              tooltip: l10n?.moreOptions ?? 'More options',
              onSelected: (value) {
                switch (value) {
                  case 'ai_index':
                    if (selectedNovel != null) {
                      AiIndexScreen.show(context, novelId: selectedNovel.id);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isIndo
                                ? 'Silakan pilih novel terlebih dahulu untuk memindai entitas Indeks.'
                                : 'Please select a novel first to scan for Index entities.',
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                    break;
                  case 'settings':
                    AiConfigDialog.show(context);
                    break;
                  case 'context_options':
                    _showContextSettingsSheet(context);
                    break;
                  case 'clear':
                    ref.read(aiChatMessagesProvider.notifier).clear();
                    break;
                }
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 'ai_index',
                  child: Row(
                    children: [
                      const Icon(Symbols.auto_awesome_motion, size: 18),
                      const SizedBox(width: 8),
                      Text(isIndo ? 'Pemindai Indeks AI' : 'AI Index Scanner'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'context_options',
                  child: Row(
                    children: [
                      const Icon(Symbols.tune, size: 18),
                      const SizedBox(width: 8),
                      Text(l10n?.contextPreferences ?? 'Context Preferences'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      const Icon(Symbols.settings, size: 18),
                      const SizedBox(width: 8),
                      Text(l10n?.aiProviderSettings ?? 'AI Provider Settings'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Symbols.delete_sweep, size: 18, color: c.error),
                      const SizedBox(width: 8),
                      Text(l10n?.clearChat ?? 'Clear Chat', style: TextStyle(color: c.error)),
                    ],
                  ),
                ),
              ],
            ),

            // Close button (if docked side drawer)
            if (widget.onClose != null) ...[
              IconButton(
                icon: Icon(Symbols.close, size: 20, color: c.textSecondary),
                tooltip: l10n?.closeAiPanel ?? 'Close AI Panel',
                onPressed: widget.onClose,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Novel Picker Modal Bottom Sheet
  void _showNovelPickerSheet(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    final novelsAsync = ref.read(novelListStreamProvider);
    final currentSelectedId = ref.read(selectedAiNovelIdProvider);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: c.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sheet Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Row(
                    children: [
                      Icon(Symbols.auto_stories, color: c.primary, size: 22),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n?.selectAiNovelContext ?? 'Select AI Novel Context',
                              style: AppTypography.cardTitle,
                            ),
                            Text(
                              l10n?.selectAiNovelContextDesc ??
                                  'The AI will tailor responses to the selected novel\'s lore and characters.',
                              style: AppTypography.bodySm.copyWith(
                                color: c.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Symbols.close, size: 20),
                        onPressed: () => Navigator.pop(sheetContext),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Divider(height: 1),

                // General Writing Option
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: currentSelectedId == '__none__'
                          ? c.primarySoft
                          : c.surfaceSecondary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Symbols.edit_note,
                      color: currentSelectedId == '__none__'
                          ? c.primary
                          : c.textSecondary,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    isIndo ? 'Penulisan Bebas / Umum' : 'General / Free Writing',
                    style: AppTypography.labelMd.copyWith(
                      fontWeight: currentSelectedId == '__none__'
                          ? FontWeight.bold
                          : FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    isIndo
                        ? 'Brainstorming tanpa merujuk ke novel tertentu'
                        : 'Brainstorm without referencing any specific novel',
                    style: AppTypography.bodySm.copyWith(
                      color: c.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  trailing: currentSelectedId == '__none__'
                      ? Icon(Symbols.check, color: c.primary, size: 20)
                      : null,
                  onTap: () {
                    ref.read(selectedAiNovelIdProvider.notifier).state =
                        '__none__';
                    Navigator.pop(sheetContext);
                  },
                ),

                const Divider(height: 1),

                // Novels List
                Flexible(
                  child: novelsAsync.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.md),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (err, _) => Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Text('Error loading novels: $err'),
                    ),
                    data: (novels) {
                      if (novels.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Center(
                            child: Text(
                              isIndo
                                  ? 'Belum ada novel yang dibuat.\nBuat novel terlebih dahulu untuk menggunakan konteks AI spesifik novel.'
                                  : 'No novels created yet.\nCreate a novel first to use novel-specific AI context.',
                              textAlign: TextAlign.center,
                              style: AppTypography.bodySm.copyWith(
                                color: c.textSecondary,
                              ),
                            ),
                          ),
                        );
                      }

                      final activeNovel =
                          ref.read(activeNovelProvider).valueOrNull;

                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: novels.length,
                        itemBuilder: (ctx, idx) {
                          final novel = novels[idx];
                          final isSelected = currentSelectedId != null
                              ? currentSelectedId == novel.id
                              : (activeNovel?.id == novel.id);

                          return ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? c.primarySoft
                                    : c.surfaceSecondary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Symbols.menu_book,
                                color: isSelected
                                    ? c.primary
                                    : c.textSecondary,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              novel.title,
                              style: AppTypography.labelMd.copyWith(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              [
                                if (novel.genre != null &&
                                    novel.genre!.isNotEmpty)
                                  novel.genre!,
                                novel.status.getLabel(l10n).toUpperCase(),
                              ].join(' • '),
                              style: AppTypography.bodySm.copyWith(
                                color: c.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                            trailing: isSelected
                                ? Icon(
                                    Symbols.check,
                                    color: c.primary,
                                    size: 20,
                                  )
                                : null,
                            onTap: () {
                              ref.read(selectedAiNovelIdProvider.notifier).state =
                                  novel.id;
                              Navigator.pop(sheetContext);
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
      },
    );
  }

  /// Context Preferences Sheet (Characters, Lore, Chapter toggles)
  void _showContextSettingsSheet(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final options = ref.watch(aiContextOptionsProvider);

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Symbols.tune, color: c.primary, size: 22),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            isIndo ? 'Preferensi Konteks AI' : 'AI Context Preferences',
                            style: AppTypography.cardTitle,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Symbols.close, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      isIndo
                          ? 'Pilih informasi latar belakang mana yang otomatis diberikan ke AI.'
                          : 'Choose what background information is automatically provided to the AI.',
                      style: AppTypography.bodySm.copyWith(
                        color: c.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SwitchListTile(
                      title: Text(isIndo ? 'Gambaran Umum Novel' : 'Novel Overview'),
                      subtitle: Text(isIndo ? 'Judul, genre, dan sinopsis' : 'Title, genre, and synopsis'),
                      value: options.includeNovel,
                      onChanged: (val) {
                        ref.read(aiContextOptionsProvider.notifier).state =
                            options.copyWith(includeNovel: val);
                        setSheetState(() {});
                      },
                    ),
                    SwitchListTile(
                      title: Text(isIndo ? 'Karakter Utama' : 'Key Characters'),
                      subtitle: Text(isIndo ? 'Peran, tujuan, dan kelemahan' : 'Roles, goals, and flaws'),
                      value: options.includeCharacters,
                      onChanged: (val) {
                        ref.read(aiContextOptionsProvider.notifier).state =
                            options.copyWith(includeCharacters: val);
                        setSheetState(() {});
                      },
                    ),
                    SwitchListTile(
                      title: Text(isIndo ? 'Ensiklopedia & Pengetahuan Dunia' : 'World Lore & Encyclopedia'),
                      subtitle: Text(isIndo ? 'Sistem sihir, lokasi, faksi' : 'Magic systems, locations, factions'),
                      value: options.includeWorldLore,
                      onChanged: (val) {
                        ref.read(aiContextOptionsProvider.notifier).state =
                            options.copyWith(includeWorldLore: val);
                        setSheetState(() {});
                      },
                    ),
                    SwitchListTile(
                      title: Text(isIndo ? 'Kutipan Bab Aktif' : 'Active Chapter Excerpt'),
                      subtitle: Text(
                        isIndo
                            ? 'Prosa adegan terkini saat dibuka dari editor'
                            : 'Recent scene prose when opened from editor',
                      ),
                      value: options.includeChapter,
                      onChanged: (val) {
                        ref.read(aiContextOptionsProvider.notifier).state =
                            options.copyWith(includeChapter: val);
                        setSheetState(() {});
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// History View
  Widget _buildHistoryView(List<AiChatSession> sessions, AppColors c) {
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';

    if (sessions.isEmpty) {
      return Center(
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
                Symbols.chat_bubble_outline,
                size: 36,
                color: c.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              isIndo ? 'Belum ada percakapan lampau' : 'No past conversations',
              style: AppTypography.cardTitle,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              isIndo
                  ? 'Percakapan lampau akan muncul di sini secara otomatis.'
                  : 'Past conversations will appear here automatically.',
              style: AppTypography.bodySm.copyWith(color: c.textSecondary),
            ),
          ],
        ),
      );
    }

    final activeId = ref.watch(activeAiSessionIdProvider);

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: sessions.length,
      itemBuilder: (ctx, idx) {
        final sess = sessions[idx];
        final isActive = sess.id == activeId;
        final dateStr = DateFormat.yMMMd().add_jm().format(sess.updatedAt);

        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          color: isActive ? c.primarySoft : c.surfaceSecondary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
            side: BorderSide(
              color: isActive
                  ? c.primary.withValues(alpha: 0.6)
                  : c.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            title: Text(
              sess.title,
              style: AppTypography.labelMd.copyWith(
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(Symbols.schedule, size: 12, color: c.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    dateStr,
                    style: AppTypography.bodySm.copyWith(
                      fontSize: 11,
                      color: c.textSecondary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '${sess.messages.length} msgs',
                    style: AppTypography.bodySm.copyWith(
                      fontSize: 11,
                      color: c.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            trailing: IconButton(
              icon: Icon(Symbols.delete_outline, size: 20, color: c.error),
              tooltip: isIndo ? 'Hapus Obrolan' : 'Delete Chat',
              onPressed: () {
                ref.read(aiActionsControllerProvider).deleteSession(sess.id);
              },
            ),
            onTap: () {
              ref.read(aiActionsControllerProvider).resumeSession(sess);
              setState(() => _showHistory = false);
            },
          ),
        );
      },
    );
  }

  /// Chat View: Empty State Hero or Messages List
  Widget _buildChatView({
    required List<AiChatMessage> messages,
    required bool isSending,
    required AppColors c,
    required NovelModel? selectedNovel,
    required bool isGeneralWriting,
  }) {
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';

    if (messages.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Glowing Hero Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      c.primary.withValues(alpha: 0.25),
                      c.primarySoft,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: c.primary.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Symbols.auto_awesome,
                  size: 32,
                  color: c.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Title
              Text(
                isIndo ? 'Rekan Penulisan Kreatif' : 'Creative Co-Pilot',
                style: AppTypography.cardTitle.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 6),

              // Active Novel Context Tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: c.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: c.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isGeneralWriting
                          ? Symbols.edit_note
                          : Symbols.menu_book,
                      size: 14,
                      color: c.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isGeneralWriting
                          ? (isIndo ? 'Mode Penulisan Umum' : 'General Writing Mode')
                          : '${isIndo ? "Konteks" : "Context"}: ${selectedNovel?.title ?? (isIndo ? "Novel Aktif" : "Active Novel")}',
                      style: AppTypography.bodySm.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: c.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              Text(
                isIndo
                    ? 'Brainstorming plot twist, kritik tensi adegan, poles dialog, atau kembangkan lore dunia.'
                    : 'Brainstorm plot twists, critique scene tension, refine dialogue, or expand world lore.',
                style: AppTypography.bodySm.copyWith(color: c.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),

              // 4 Sleek Prompt Suggestion Cards
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 420;
                  final cards = _getQuickPrompts(isIndo).map((item) {
                    return InkWell(
                      onTap: () => _handleSend(item['prompt'] as String),
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: c.surfaceSecondary,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(
                            color: c.outlineVariant.withValues(alpha: 0.7),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: c.primarySoft,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                item['icon'] as IconData,
                                size: 16,
                                color: c.primary,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['title'] as String,
                                    style: AppTypography.labelMd.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item['prompt'] as String,
                                    style: AppTypography.bodySm.copyWith(
                                      color: c.textSecondary,
                                      fontSize: 11,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList();

                  if (isWide) {
                    return GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: AppSpacing.sm,
                      mainAxisSpacing: AppSpacing.sm,
                      childAspectRatio: 2.8,
                      children: cards,
                    );
                  }

                  return Column(
                    children: cards
                        .map(
                          (card) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.xs,
                            ),
                            child: card,
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: messages.length + (isSending ? 1 : 0),
      itemBuilder: (ctx, index) {
        if (index == messages.length && isSending) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: c.surfaceSecondary,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(
                      color: c.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        isIndo
                            ? 'Novellie sedang menyusun prosa...'
                            : 'Novellie is crafting prose...',
                        style: AppTypography.bodySm.copyWith(
                          color: c.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        final msg = messages[index];
        final isUser = msg.isUser;

        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            padding: const EdgeInsets.all(AppSpacing.md),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width *
                  (widget.isDocked ? 0.95 : 0.85),
            ),
            decoration: BoxDecoration(
              color: isUser ? c.primarySoft : c.surfaceSecondary,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(AppRadius.card),
                topRight: Radius.circular(isUser ? 4 : AppRadius.card),
                bottomLeft: Radius.circular(isUser ? AppRadius.card : 4),
                bottomRight: const Radius.circular(AppRadius.card),
              ),
              border: Border.all(
                color: isUser
                    ? c.primary.withValues(alpha: 0.3)
                    : c.outlineVariant.withValues(alpha: 0.7),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header on bubble
                if (!isUser) ...[
                  Row(
                    children: [
                      Icon(Symbols.auto_awesome, size: 14, color: c.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Novellie AI',
                        style: AppTypography.labelSm.copyWith(
                          color: c.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],

                // Content
                if (isUser)
                  SelectableText(
                    msg.text,
                    style: AppTypography.body.copyWith(
                      color: c.textPrimary,
                    ),
                  )
                else
                  AiQuillMessageView(text: msg.text),

                const SizedBox(height: AppSpacing.xs),

                // Bottom actions on AI bubble
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Copy button
                    InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      onTap: () => _handleCopy(msg.text),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: 3,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Symbols.content_copy,
                              size: 13,
                              color: c.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isIndo ? 'Salin' : 'Copy',
                              style: AppTypography.bodySm.copyWith(
                                fontSize: 11,
                                color: c.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // "Insert to Editor" on AI responses
                    if (!isUser) ...[
                      const SizedBox(width: AppSpacing.md),
                      InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        onTap: () => _handleInsert(msg.text),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                            vertical: 3,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Symbols.input, size: 13, color: c.primary),
                              const SizedBox(width: 4),
                              Text(
                                l10n?.insertIntoEditor ?? 'Insert to Editor',
                                style: AppTypography.bodySm.copyWith(
                                  fontSize: 11,
                                  color: c.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Modern capsule input bar
  Widget _buildInputArea({
    required AppColors c,
    required bool isSending,
    required NovelModel? selectedNovel,
    required bool isGeneralWriting,
  }) {
    final isIndo = AppLocalizations.of(context)?.localeName == 'id';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(
          top: BorderSide(
            color: c.outlineVariant.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: c.surfaceSecondary,
            borderRadius: BorderRadius.circular(AppRadius.input),
            border: Border.all(
              color: c.outlineVariant.withValues(alpha: 0.8),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _inputController,
                  focusNode: _focusNode,
                  style: AppTypography.body,
                  minLines: 1,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: isGeneralWriting
                        ? (isIndo ? 'Tanyakan apa saja atau minta prosa...' : 'Ask anything or request prose...')
                        : (isIndo ? 'Tanyakan seputar ${selectedNovel?.title ?? "novel ini"}...' : 'Ask about ${selectedNovel?.title ?? "this novel"}...'),
                    hintStyle: AppTypography.bodySm.copyWith(
                      color: c.textSecondary,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _handleSend(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  right: AppSpacing.xs,
                  bottom: AppSpacing.xs,
                ),
                child: IconButton.filled(
                  icon: isSending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Symbols.arrow_upward, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: c.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(36, 36),
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: isSending ? null : () => _handleSend(),
                  tooltip: isIndo ? 'Kirim Prompt' : 'Send Prompt',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
