import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../l10n/app_localizations.dart';

enum SearchResultType {
  all,
  novel,
  chapter,
  character,
  lore,
  event,
  scene;

  String get label => getLabel(null);

  String getLabel([AppLocalizations? l10n]) {
    switch (this) {
      case SearchResultType.all:
        return l10n?.filterAll ?? 'All';
      case SearchResultType.novel:
        return l10n?.filterNovels ?? 'Novels';
      case SearchResultType.chapter:
        return l10n?.filterChapters ?? 'Chapters';
      case SearchResultType.character:
        return l10n?.filterCharacters ?? 'Characters';
      case SearchResultType.lore:
        return l10n?.filterLore ?? 'Lore';
      case SearchResultType.event:
        return l10n?.filterTimeline ?? 'Timeline';
      case SearchResultType.scene:
        return l10n?.filterScenes ?? 'Scenes';
    }
  }

  String get singularLabel => getSingularLabel(null);

  String getSingularLabel([AppLocalizations? l10n]) {
    final isIndo = l10n?.localeName == 'id';
    switch (this) {
      case SearchResultType.all:
        return isIndo ? 'Semua' : 'All';
      case SearchResultType.novel:
        return 'Novel';
      case SearchResultType.chapter:
        return isIndo ? 'Bab' : 'Chapter';
      case SearchResultType.character:
        return isIndo ? 'Karakter' : 'Character';
      case SearchResultType.lore:
        return 'Lore';
      case SearchResultType.event:
        return isIndo ? 'Garis Waktu' : 'Timeline';
      case SearchResultType.scene:
        return isIndo ? 'Adegan' : 'Scene';
    }
  }

  IconData get icon {
    switch (this) {
      case SearchResultType.all:
        return Symbols.search;
      case SearchResultType.novel:
        return Symbols.menu_book;
      case SearchResultType.chapter:
        return Symbols.description;
      case SearchResultType.character:
        return Symbols.person;
      case SearchResultType.lore:
        return Symbols.public;
      case SearchResultType.event:
        return Symbols.event;
      case SearchResultType.scene:
        return Symbols.movie;
    }
  }
}

class SearchResultItem {
  final String id;
  final SearchResultType type;
  final String title;
  final String? subtitle;
  final String? snippet;
  final String? novelId;
  final String? novelTitle;
  final String? tag;
  final String? coverPath;
  final DateTime? updatedAt;
  final Map<String, dynamic> metadata;

  const SearchResultItem({
    required this.id,
    required this.type,
    required this.title,
    this.subtitle,
    this.snippet,
    this.novelId,
    this.novelTitle,
    this.tag,
    this.coverPath,
    this.updatedAt,
    this.metadata = const {},
  });

  IconData get icon => type.icon;
}
