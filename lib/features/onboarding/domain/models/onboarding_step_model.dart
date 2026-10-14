import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../l10n/app_localizations.dart';

enum OnboardingStep {
  chooseLanguage,
  aiKeyPrompt,
  workspaceFeatures,
  characterWorldIndex,
  planningTab,
  toolsTab,
  aiTab,
  settingsTab;

  String get stepLabel => getStepLabel();
  String get title => getTitle();
  String get description => getDescription();
  String? get actionButtonLabel => getActionButtonLabel();
  String get proTip => getProTip();
  String get badgeLabel => getBadgeLabel();

  String getStepLabel([AppLocalizations? l10n]) {
    final isId = l10n?.localeName == 'id';
    switch (this) {
      case OnboardingStep.chooseLanguage:
        return isId ? 'Langkah 1 dari 8 · Pilih Bahasa' : 'Step 1 of 8 · Choose Language';
      case OnboardingStep.aiKeyPrompt:
        return isId ? 'Langkah 2 dari 8 · Setup AI (BYOK)' : 'Step 2 of 8 · Setup AI (BYOK)';
      case OnboardingStep.workspaceFeatures:
        return isId ? 'Langkah 3 dari 8 · Ruang Kerja' : 'Step 3 of 8 · Workspace';
      case OnboardingStep.characterWorldIndex:
        return isId ? 'Langkah 4 dari 8 · Karakter & Dunia' : 'Step 4 of 8 · Characters & World';
      case OnboardingStep.planningTab:
        return isId ? 'Langkah 5 dari 8 · Tab Perencanaan' : 'Step 5 of 8 · Planning Tab';
      case OnboardingStep.toolsTab:
        return isId ? 'Langkah 6 dari 8 · Tab Alat' : 'Step 6 of 8 · Tools Tab';
      case OnboardingStep.aiTab:
        return isId ? 'Langkah 7 dari 8 · Tab AI' : 'Step 7 of 8 · AI Tab';
      case OnboardingStep.settingsTab:
        return isId ? 'Langkah 8 dari 8 · Pengaturan' : 'Step 8 of 8 · Settings';
    }
  }

  String getTitle([AppLocalizations? l10n]) {
    final isId = l10n?.localeName == 'id';
    switch (this) {
      case OnboardingStep.chooseLanguage:
        return isId ? 'Pilih Bahasa Anda' : 'Choose Your Language';
      case OnboardingStep.aiKeyPrompt:
        return isId ? 'Konfigurasi Kunci AI (BYOK)' : 'Configure AI Provider Key (BYOK)';
      case OnboardingStep.workspaceFeatures:
        return isId ? 'Ruang Kerja Novel & Naskah' : 'Novel Workspace & Manuscript';
      case OnboardingStep.characterWorldIndex:
        return isId ? 'Koleksi Lore Karakter & Dunia' : 'Character & World Lore Codex';
      case OnboardingStep.planningTab:
        return isId ? 'Perencanaan Cerita & Alur Narasi' : 'Story Planning & Narrative Arcs';
      case OnboardingStep.toolsTab:
        return isId ? 'Bengkel Penulis & Peralatan' : 'Writer’s Workshop & Tools';
      case OnboardingStep.aiTab:
        return isId ? 'Asisten AI Sadar Konteks' : 'Context-Aware AI Assistant';
      case OnboardingStep.settingsTab:
        return isId ? 'Preferensi & Pengaturan Studio' : 'Studio Preferences & Settings';
    }
  }

  String getDescription([AppLocalizations? l10n]) {
    final isId = l10n?.localeName == 'id';
    switch (this) {
      case OnboardingStep.chooseLanguage:
        return isId
            ? 'Pilih bahasa preferensi Anda untuk antarmuka studio. Anda dapat mengubahnya kapan saja di Pengaturan.'
            : 'Select your preferred language for the studio interface. You can change this anytime in Settings.';
      case OnboardingStep.aiKeyPrompt:
        return isId
            ? 'Novellie menggunakan sistem Bring-Your-Own-Key untuk 100% privasi dan tanpa langganan terikat. Konfigurasikan kunci Google Gemini, OpenAI, atau Claude Anda terlebih dahulu untuk membuka generator nama, saran plot, dan draf naskah.'
            : 'Novellie is Bring-Your-Own-Key for 100% privacy and zero subscription lock-in. Configure your Google Gemini or OpenAI/Claude key first to unlock mythic names, plotting suggestions, and drafting.';
      case OnboardingStep.workspaceFeatures:
        return isId
            ? 'Kelola perpustakaan novel Anda, buat draf bab dengan format teks kaya, pantau target jumlah kata terhadap milestone, dan tulis tanpa gangguan dalam Mode Zen.'
            : 'Manage your library of novels, draft chapters with rich formatting, track word count targets against milestones, and write distraction-free in Zen focus mode.';
      case OnboardingStep.characterWorldIndex:
        return isId
            ? 'Perdalam pembangunan dunia: katalogkan faksi, sistem sihir, dan lokasi di Ensiklopedia Dunia, serta catat profil karakter, peran, dan tempat tinggalnya.'
            : 'Deepen your worldbuilding: catalog factions, magic systems, and locations in the World Encyclopedia, and track character profiles, roles, and residencies.';
      case OnboardingStep.planningTab:
        return isId
            ? 'Susun alur narasi, atur urutan bab, buat kerangka alur cerita, dan pantau kronologi garis waktu sebelum menulis prosa.'
            : 'Structure narrative arcs, arrange chapter sequences, outline plot threads, and track timeline chronology before writing prose.';
      case OnboardingStep.toolsTab:
        return isId
            ? 'Akses alat khusus: Generator Nama dari 14 asal budaya, Silsilah Keluarga dinasti kerajaan, Peta Pikiran alur cerita, dan Atlas Dunia SVG interaktif.'
            : 'Access specialized tools: Names Generator across 14 origins, Family Tree dynastic lineages, Mind Map story plotting, and interactive SVG World Atlas.';
      case OnboardingStep.aiTab:
        return isId
            ? 'Mengobrol dengan asisten AI yang memahami lore dan karakter dari novel aktif Anda untuk memikirkan plot twist, mengatasi kebuntuan ide, dan mengkritik tulisan.'
            : 'Chat with an AI companion that reads your active novel’s lore and characters to brainstorm twists, unblock scenes, and critique prose.';
      case OnboardingStep.settingsTab:
        return isId
            ? 'Personalisasikan tipografi editor, ukuran font, palet warna tema yang memukau, diagnostik, dan perbarui kunci penyedia AI Anda kapan saja.'
            : 'Personalize editor typography, font sizes, vibrant theme color palettes, diagnostics, and update your AI provider keys anytime.';
    }
  }

  IconData get icon {
    switch (this) {
      case OnboardingStep.chooseLanguage:
        return Symbols.language;
      case OnboardingStep.aiKeyPrompt:
        return Symbols.key;
      case OnboardingStep.workspaceFeatures:
        return Symbols.menu_book;
      case OnboardingStep.characterWorldIndex:
        return Symbols.auto_stories;
      case OnboardingStep.planningTab:
        return Symbols.schema;
      case OnboardingStep.toolsTab:
        return Symbols.handyman;
      case OnboardingStep.aiTab:
        return Symbols.auto_awesome;
      case OnboardingStep.settingsTab:
        return Symbols.tune;
    }
  }

  Color get accentColor {
    switch (this) {
      case OnboardingStep.chooseLanguage:
        return const Color(0xFF6366F1); // Indigo
      case OnboardingStep.aiKeyPrompt:
        return const Color(0xFFF59E0B); // Amber gold
      case OnboardingStep.workspaceFeatures:
        return const Color(0xFF3B82F6); // Blue
      case OnboardingStep.characterWorldIndex:
        return const Color(0xFF10B981); // Emerald
      case OnboardingStep.planningTab:
        return const Color(0xFF8B5CF6); // Purple
      case OnboardingStep.toolsTab:
        return const Color(0xFFEC4899); // Pink
      case OnboardingStep.aiTab:
        return const Color(0xFF06B6D4); // Cyan
      case OnboardingStep.settingsTab:
        return const Color(0xFF64748B); // Slate
    }
  }

  /// Target bottom nav branch index in ShellScaffold, or null if modal
  int? get targetBranchIndex {
    switch (this) {
      case OnboardingStep.chooseLanguage:
        return null;
      case OnboardingStep.aiKeyPrompt:
        return null;
      case OnboardingStep.workspaceFeatures:
        return 1; // Novels
      case OnboardingStep.characterWorldIndex:
        return 0; // Home
      case OnboardingStep.planningTab:
        return 2; // Planning
      case OnboardingStep.toolsTab:
        return 3; // Tools
      case OnboardingStep.aiTab:
        return 4; // AI
      case OnboardingStep.settingsTab:
        return 5; // More
    }
  }

  String? getActionButtonLabel([AppLocalizations? l10n]) {
    final isId = l10n?.localeName == 'id';
    switch (this) {
      case OnboardingStep.chooseLanguage:
        return null;
      case OnboardingStep.aiKeyPrompt:
        return isId ? 'Konfigurasi Kunci AI (BYOK)' : 'Configure AI Key (BYOK)';
      case OnboardingStep.workspaceFeatures:
        return isId ? 'Lihat Tab Novel' : 'View Novels Tab';
      case OnboardingStep.characterWorldIndex:
        return isId ? 'Lihat Karakter & Dunia' : 'View Characters & World';
      case OnboardingStep.planningTab:
        return isId ? 'Buka Tab Perencanaan' : 'Go to Planning Tab';
      case OnboardingStep.toolsTab:
        return isId ? 'Jelajahi Tab Alat' : 'Explore Tools Tab';
      case OnboardingStep.aiTab:
        return isId ? 'Buka Asisten AI' : 'Open AI Assistant';
      case OnboardingStep.settingsTab:
        return isId ? 'Buka Pengaturan' : 'Open Settings';
    }
  }

  String getProTip([AppLocalizations? l10n]) {
    final isId = l10n?.localeName == 'id';
    switch (this) {
      case OnboardingStep.chooseLanguage:
        return isId
            ? 'Novellie mendukung Bahasa Inggris dan Bahasa Indonesia. Perubahan berlaku seketika di seluruh studio.'
            : 'Novellie supports English and Bahasa Indonesia. Changes take effect instantly throughout the studio.';
      case OnboardingStep.aiKeyPrompt:
        return isId
            ? 'Google Gemini 1.5 Flash menyediakan paket gratis yang cepat dan ideal untuk drafting serta pembangunan dunia.'
            : 'Google Gemini 1.5 Flash provides a fast, free tier ideal for drafting and worldbuilding.';
      case OnboardingStep.workspaceFeatures:
        return isId
            ? 'Gunakan Mode Zen untuk menyembunyikan semua toolbar demi alur menulis yang murni dan fokus.'
            : 'Use Zen Mode to hide all toolbars for a distraction-free, pure writing flow.';
      case OnboardingStep.characterWorldIndex:
        return isId
            ? 'Tautkan karakter ke faksi dan lokasi untuk secara otomatis memberikan konteks mendalam ke AI.'
            : 'Link characters to factions and locations to automatically provide deep context to the AI.';
      case OnboardingStep.planningTab:
        return isId
            ? 'Titik alur garis waktu memungkinkan Anda menyusun arc berdasarkan urutan kronologis atau urutan pengungkapan narasi.'
            : 'Timeline beats allow you to structure arcs across chronological order or narrative reveal order.';
      case OnboardingStep.toolsTab:
        return isId
            ? 'Gunakan Silsilah Keluarga mode ganda (Kanvas atau Bagan Garis) untuk memetakan dinasti multi-generasi yang kompleks.'
            : 'Use the dual-mode Family Tree (Canvas or Pedigree Outline) to chart complex multi-generational dynasties.';
      case OnboardingStep.aiTab:
        return isId
            ? 'Asisten AI secara otomatis merujuk silang ensiklopedia lore aktif Anda agar dialog dan fakta karakter tetap konsisten.'
            : 'The AI assistant automatically cross-references your active lore codex for character-accurate prose.';
      case OnboardingStep.settingsTab:
        return isId
            ? 'Personalisasikan tipografi editor, ukuran font, dan warna tema di pengaturan kapan saja.'
            : 'Personalize editor typography, font sizes, and warm amber theme tones in settings anytime.';
    }
  }

  String getBadgeLabel([AppLocalizations? l10n]) {
    final isId = l10n?.localeName == 'id';
    switch (this) {
      case OnboardingStep.chooseLanguage:
        return isId ? 'Bahasa & Wilayah' : 'Language & Region';
      case OnboardingStep.aiKeyPrompt:
        return isId ? 'Privasi Utama' : 'Privacy First';
      case OnboardingStep.workspaceFeatures:
        return isId ? 'Editor & Pustaka' : 'Editor & Library';
      case OnboardingStep.characterWorldIndex:
        return isId ? 'Koleksi Lore' : 'Lore Codex';
      case OnboardingStep.planningTab:
        return isId ? 'Arsitektur Cerita' : 'Story Architecture';
      case OnboardingStep.toolsTab:
        return isId ? 'Bengkel Penulis' : 'Writer Workshop';
      case OnboardingStep.aiTab:
        return isId ? 'Teman Menulis Lore' : 'Lore Companion';
      case OnboardingStep.settingsTab:
        return isId ? 'Kustomisasi Studio' : 'Studio Customization';
    }
  }
}
