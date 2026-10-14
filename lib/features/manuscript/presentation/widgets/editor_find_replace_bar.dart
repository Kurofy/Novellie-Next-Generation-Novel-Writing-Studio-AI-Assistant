import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/app_localizations.dart';

class SearchMatch {
  final int start;
  final int end;

  const SearchMatch({required this.start, required this.end});

  int get length => end - start;

  TextSelection toSelection() =>
      TextSelection(baseOffset: start, extentOffset: end);
}

class EditorFindReplaceBar extends StatefulWidget {
  final QuillController controller;
  final ScrollController? scrollController;
  final VoidCallback onClose;
  final bool initialShowReplace;

  const EditorFindReplaceBar({
    super.key,
    required this.controller,
    this.scrollController,
    required this.onClose,
    this.initialShowReplace = false,
  });

  @override
  State<EditorFindReplaceBar> createState() => _EditorFindReplaceBarState();
}

class _EditorFindReplaceBarState extends State<EditorFindReplaceBar> {
  final TextEditingController _findController = TextEditingController();
  final TextEditingController _replaceController = TextEditingController();
  final FocusNode _findFocusNode = FocusNode();
  final FocusNode _replaceFocusNode = FocusNode();

  bool _matchCase = false;
  bool _wholeWord = false;
  bool _isRegex = false;
  late bool _showReplace;

  List<SearchMatch> _matches = [];
  int _currentMatchIndex = -1;

  @override
  void initState() {
    super.initState();
    _showReplace = widget.initialShowReplace;
    _findController.addListener(_onFindTextChanged);

    // Focus the find input immediately on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _findFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _findController.removeListener(_onFindTextChanged);
    _findController.dispose();
    _replaceController.dispose();
    _findFocusNode.dispose();
    _replaceFocusNode.dispose();
    super.dispose();
  }

  void _onFindTextChanged() {
    _search();
  }

  void _search({int? preferredIndex, int? targetOffset}) {
    final query = _findController.text;
    if (query.isEmpty) {
      setState(() {
        _matches = [];
        _currentMatchIndex = -1;
      });
      return;
    }

    final text = widget.controller.document.toPlainText();
    final matches = <SearchMatch>[];

    try {
      RegExp regExp;
      if (_isRegex) {
        regExp = RegExp(query, caseSensitive: _matchCase, multiLine: true);
      } else {
        final escaped = RegExp.escape(query);
        final pattern = _wholeWord ? r'\b' + escaped + r'\b' : escaped;
        regExp = RegExp(pattern, caseSensitive: _matchCase);
      }

      for (final m in regExp.allMatches(text)) {
        matches.add(SearchMatch(start: m.start, end: m.end));
      }
    } catch (_) {
      // Gracefully handle incomplete or invalid regex without throwing
    }

    var newIndex = -1;
    if (matches.isNotEmpty) {
      if (targetOffset != null) {
        newIndex = matches.indexWhere((m) => m.start >= targetOffset);
        if (newIndex == -1) newIndex = 0;
      } else if (preferredIndex != null && preferredIndex >= 0) {
        newIndex = preferredIndex.clamp(0, matches.length - 1);
      } else {
        newIndex = 0;
      }
    }

    setState(() {
      _matches = matches;
      _currentMatchIndex = newIndex;
    });

    if (newIndex >= 0 && matches.isNotEmpty) {
      _highlightMatch(newIndex);
    }
  }

  void _highlightMatch(int index) {
    if (index < 0 || index >= _matches.length) return;
    final match = _matches[index];

    // Highlight text in document
    widget.controller.updateSelection(
      match.toSelection(),
      ChangeSource.local,
    );

    // Smoothly scroll editor to match
    _scrollToMatch(match);
  }

  void _scrollToMatch(SearchMatch match) {
    final sc = widget.scrollController;
    if (sc == null || !sc.hasClients) return;

    final docLength = widget.controller.document.length;
    if (docLength <= 0 || sc.position.maxScrollExtent <= 0) return;

    final fraction = (match.start / docLength).clamp(0.0, 1.0);
    final targetY = fraction * sc.position.maxScrollExtent;
    sc.animateTo(
      targetY.clamp(0.0, sc.position.maxScrollExtent),
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  void _findNext() {
    if (_matches.isEmpty) return;
    final nextIndex = (_currentMatchIndex + 1) % _matches.length;
    setState(() {
      _currentMatchIndex = nextIndex;
    });
    _highlightMatch(nextIndex);
  }

  void _findPrev() {
    if (_matches.isEmpty) return;
    final prevIndex =
        (_currentMatchIndex - 1 + _matches.length) % _matches.length;
    setState(() {
      _currentMatchIndex = prevIndex;
    });
    _highlightMatch(prevIndex);
  }

  void _replaceCurrent() {
    if (_matches.isEmpty || _currentMatchIndex < 0) return;
    final current = _matches[_currentMatchIndex];
    final replaceWith = _replaceController.text;

    widget.controller.replaceText(
      current.start,
      current.length,
      replaceWith,
      null,
    );

    final nextOffset = current.start + replaceWith.length;
    _search(targetOffset: nextOffset);

    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isIndo ? '1 kemunculan diganti' : 'Replaced 1 occurrence',
        ),
        duration: const Duration(milliseconds: 1000),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _replaceAll() {
    if (_matches.isEmpty) return;
    final replaceWith = _replaceController.text;
    final count = _matches.length;

    // Replace in reverse order to preserve string offsets
    for (int i = _matches.length - 1; i >= 0; i--) {
      final match = _matches[i];
      widget.controller.replaceText(
        match.start,
        match.length,
        replaceWith,
        null,
      );
    }

    _search();

    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isIndo ? '$count kemunculan diganti' : 'Replaced $count occurrences',
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isIndo = l10n?.localeName == 'id';
    final c = context.colors;
    final hasMatches = _matches.isNotEmpty;
    final hasQuery = _findController.text.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(bottom: BorderSide(color: c.outlineVariant, width: 0.5)),
          boxShadow: AppShadows.resolve(context, AppShadows.soft),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Row 1: Find Input, Match count, Navigation, Toggles, Close
            Row(
              children: [
                // Find input field
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: TextField(
                      controller: _findController,
                      focusNode: _findFocusNode,
                      style: AppTypography.bodySm.copyWith(color: c.textPrimary),
                      decoration: InputDecoration(
                        hintText: isIndo ? 'Cari dalam bab…' : 'Find in chapter…',
                        hintStyle:
                            AppTypography.bodySm.copyWith(color: c.textMuted),
                        prefixIcon: Icon(Symbols.search, size: 18, color: c.textMuted),
                        prefixIconConstraints:
                            const BoxConstraints(minWidth: 32, minHeight: 32),
                        suffixIcon: hasQuery
                            ? IconButton(
                                icon: const Icon(Symbols.close, size: 16),
                                color: c.textMuted,
                                visualDensity: VisualDensity.compact,
                                onPressed: () {
                                  _findController.clear();
                                  _search();
                                },
                              )
                            : null,
                        suffixIconConstraints:
                            const BoxConstraints(minWidth: 28, minHeight: 28),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 8,
                        ),
                        filled: true,
                        fillColor: c.surfaceSecondary,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.input),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _findNext(),
                    ),
                  ),
                ),

                const SizedBox(width: AppSpacing.xs),

                // Match Counter Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: hasMatches
                        ? c.primary.withValues(alpha: 0.12)
                        : c.surfaceSecondary,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    hasQuery
                        ? (hasMatches
                            ? '${_currentMatchIndex + 1}/${_matches.length}'
                            : '0')
                        : '',
                    style: AppTypography.labelSm.copyWith(
                      fontWeight: FontWeight.w600,
                      color: hasMatches ? c.primary : c.textMuted,
                    ),
                  ),
                ),

                const SizedBox(width: 2),

                // Previous Match
                IconButton(
                  icon: const Icon(Symbols.keyboard_arrow_up, size: 20),
                  tooltip: isIndo
                      ? 'Kecocokan sebelumnya (Shift+Enter)'
                      : 'Previous match (Shift+Enter)',
                  visualDensity: VisualDensity.compact,
                  color: hasMatches ? c.textPrimary : c.textMuted,
                  onPressed: hasMatches ? _findPrev : null,
                ),

                // Next Match
                IconButton(
                  icon: const Icon(Symbols.keyboard_arrow_down, size: 20),
                  tooltip: isIndo
                      ? 'Kecocokan berikutnya (Enter)'
                      : 'Next match (Enter)',
                  visualDensity: VisualDensity.compact,
                  color: hasMatches ? c.textPrimary : c.textMuted,
                  onPressed: hasMatches ? _findNext : null,
                ),

                // Replace Mode Toggle Button
                IconButton(
                  icon: Icon(
                    Symbols.swap_horiz,
                    size: 20,
                    color: _showReplace ? c.primary : c.textSecondary,
                  ),
                  tooltip: _showReplace
                      ? (isIndo ? 'Sembunyikan Ganti' : 'Hide Replace')
                      : (isIndo ? 'Tampilkan Ganti' : 'Show Replace'),
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    setState(() => _showReplace = !_showReplace);
                    if (_showReplace) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _replaceFocusNode.requestFocus();
                      });
                    }
                  },
                ),

                // Close Button
                IconButton(
                  icon: const Icon(Symbols.close, size: 20),
                  tooltip: isIndo ? 'Tutup (Esc)' : 'Close (Esc)',
                  visualDensity: VisualDensity.compact,
                  color: c.textSecondary,
                  onPressed: widget.onClose,
                ),
              ],
            ),

            // Row 2: Search Mode Option Chips (Case, Whole Word, Regex)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 2),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildOptionChip(
                      label: isIndo ? 'Cocokkan Huruf' : 'Match Case',
                      symbol: 'Aa',
                      isActive: _matchCase,
                      c: c,
                      onTap: () {
                        setState(() => _matchCase = !_matchCase);
                        _search();
                      },
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _buildOptionChip(
                      label: isIndo ? 'Kata Utuh' : 'Whole Word',
                      symbol: 'W',
                      isActive: _wholeWord,
                      c: c,
                      onTap: () {
                        setState(() => _wholeWord = !_wholeWord);
                        _search();
                      },
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _buildOptionChip(
                      label: 'Regex',
                      symbol: '.*',
                      isActive: _isRegex,
                      c: c,
                      onTap: () {
                        setState(() => _isRegex = !_isRegex);
                        _search();
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Row 3: Replace Input & Action Buttons (when Replace is open)
            if (_showReplace) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  // Replace input field
                  Expanded(
                    child: SizedBox(
                      height: 38,
                      child: TextField(
                        controller: _replaceController,
                        focusNode: _replaceFocusNode,
                        style: AppTypography.bodySm.copyWith(color: c.textPrimary),
                        decoration: InputDecoration(
                          hintText: isIndo ? 'Ganti dengan…' : 'Replace with…',
                          hintStyle:
                              AppTypography.bodySm.copyWith(color: c.textMuted),
                          prefixIcon: Icon(
                            Symbols.swap_horiz,
                            size: 18,
                            color: c.textMuted,
                          ),
                          prefixIconConstraints:
                              const BoxConstraints(minWidth: 32, minHeight: 32),
                          suffixIcon: _replaceController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Symbols.close, size: 16),
                                  color: c.textMuted,
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () => _replaceController.clear(),
                                )
                              : null,
                          suffixIconConstraints:
                              const BoxConstraints(minWidth: 28, minHeight: 28),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 8,
                          ),
                          filled: true,
                          fillColor: c.surfaceSecondary,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.input),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) => _replaceCurrent(),
                      ),
                    ),
                  ),

                  const SizedBox(width: AppSpacing.sm),

                  // Replace Single Button
                  FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: const Size(64, 36),
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.control),
                      ),
                    ),
                    onPressed: hasMatches ? _replaceCurrent : null,
                    child: Text(isIndo ? 'Ganti' : 'Replace'),
                  ),

                  const SizedBox(width: AppSpacing.xs),

                  // Replace All Button
                  FilledButton(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: const Size(80, 36),
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.control),
                      ),
                    ),
                    onPressed: hasMatches ? _replaceAll : null,
                    child: Text(isIndo ? 'Semua' : 'All'),
                  ),
                ],
              ),
              const SizedBox(height: 2),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOptionChip({
    required String label,
    required String symbol,
    required bool isActive,
    required AppColors c,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isActive
              ? c.primary.withValues(alpha: 0.15)
              : c.surfaceSecondary,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: isActive ? c.primary : c.outlineVariant,
            width: isActive ? 1.0 : 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              symbol,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isActive ? c.primary : c.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.labelSm.copyWith(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? c.primary : c.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
