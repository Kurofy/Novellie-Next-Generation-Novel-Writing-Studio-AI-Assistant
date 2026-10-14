import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/utils/uuid_generator.dart';
import '../../characters/application/character_providers.dart';
import '../../novels/application/novel_providers.dart';
import '../../novels/domain/models/novel_model.dart';
import '../../world/application/world_providers.dart';
import '../data/services/ai_client_service.dart';
import '../data/services/ai_storage_service.dart';
import '../domain/models/ai_models.dart';

final aiContextOptionsProvider =
    StateProvider<AiContextOptions>((ref) => const AiContextOptions());

/// Selected novel ID for AI context.
/// null = Use active novel (default)
/// '__none__' = No novel context (general writing)
/// '<uuid>' = Specific novel ID
final selectedAiNovelIdProvider = StateProvider<String?>((ref) => null);

/// Provides the novel model selected for AI context
final selectedAiNovelProvider = Provider<AsyncValue<NovelModel?>>((ref) {
  final selectedId = ref.watch(selectedAiNovelIdProvider);
  if (selectedId == '__none__') {
    return const AsyncValue.data(null);
  }
  if (selectedId != null) {
    return ref.watch(novelDetailStreamProvider(selectedId));
  }
  return ref.watch(activeNovelProvider);
});

final aiStorageServiceProvider = Provider<AiStorageService>((ref) {
  return AiStorageService();
});

final aiClientServiceProvider = Provider<AiClientService>((ref) {
  return AiClientService();
});

final aiConfigProvider =
    StateNotifierProvider<AiConfigNotifier, AsyncValue<AiConfigModel>>((ref) {
  return AiConfigNotifier(ref.watch(aiStorageServiceProvider));
});

class AiConfigNotifier extends StateNotifier<AsyncValue<AiConfigModel>> {
  final AiStorageService _storage;

  AiConfigNotifier(this._storage)
      : super(const AsyncValue.data(AiConfigModel())) {
    _load();
  }

  Future<void> _load() async {
    try {
      final config = await _storage.loadConfig();
      state = AsyncValue.data(config);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  Future<void> updateConfig(AiConfigModel newConfig) async {
    state = AsyncValue.data(newConfig);
    await _storage.saveConfig(newConfig);
  }

  Future<void> clearConfig() async {
    state = const AsyncValue.data(AiConfigModel());
    await _storage.clearConfig();
  }
}

final aiSendingProvider = StateProvider<bool>((ref) => false);

/// Global bus for inserting AI text into the active chapter editor
final aiInsertToEditorProvider = StateProvider<String?>((ref) => null);

/// Chat sessions list provider
final aiSessionsProvider =
    StateNotifierProvider<AiSessionsNotifier, List<AiChatSession>>((ref) {
  return AiSessionsNotifier(ref.watch(aiStorageServiceProvider));
});

class AiSessionsNotifier extends StateNotifier<List<AiChatSession>> {
  final AiStorageService _storage;

  AiSessionsNotifier(this._storage) : super([]) {
    loadSessions();
  }

  Future<void> loadSessions() async {
    final sessions = await _storage.loadSessions();
    state = sessions;
  }

  Future<void> saveSession(AiChatSession session) async {
    await _storage.saveSession(session);
    await loadSessions();
  }

  Future<void> deleteSession(String sessionId) async {
    await _storage.deleteSession(sessionId);
    await loadSessions();
  }
}

/// Active session ID provider
final activeAiSessionIdProvider = StateProvider<String?>((ref) => null);

/// Active chat messages provider
final aiChatMessagesProvider =
    StateNotifierProvider<AiChatMessagesNotifier, List<AiChatMessage>>((ref) {
  return AiChatMessagesNotifier();
});

class AiChatMessagesNotifier extends StateNotifier<List<AiChatMessage>> {
  AiChatMessagesNotifier() : super([]);

  void setMessages(List<AiChatMessage> messages) {
    state = messages;
  }

  void addMessage(String text, {required bool isUser}) {
    final msg = AiChatMessage(
      id: generateUuid(),
      text: text,
      isUser: isUser,
      timestamp: DateTime.now().toUtc(),
    );
    state = [...state, msg];
  }

  void clear() {
    state = [];
  }
}

final aiActionsControllerProvider = Provider<AiActionsController>((ref) {
  return AiActionsController(ref);
});

class AiActionsController {
  final Ref _ref;

  AiActionsController(this._ref);

  void startNewSession() {
    final newId = generateUuid();
    _ref.read(activeAiSessionIdProvider.notifier).state = newId;
    _ref.read(aiChatMessagesProvider.notifier).clear();
  }

  void resumeSession(AiChatSession session) {
    _ref.read(activeAiSessionIdProvider.notifier).state = session.id;
    _ref.read(aiChatMessagesProvider.notifier).setMessages(session.messages);
  }

  Future<void> deleteSession(String sessionId) async {
    await _ref.read(aiSessionsProvider.notifier).deleteSession(sessionId);
    if (_ref.read(activeAiSessionIdProvider) == sessionId) {
      startNewSession();
    }
  }

  Future<void> sendMessage(String prompt, {String? chapterContext}) async {
    final trimmed = prompt.trim();
    if (trimmed.isEmpty) return;

    final configAsync = _ref.read(aiConfigProvider);
    final config = configAsync.valueOrNull;
    if (config == null || !config.isConfigured) return;

    // Ensure session ID exists
    var sessionId = _ref.read(activeAiSessionIdProvider);
    if (sessionId == null) {
      sessionId = generateUuid();
      _ref.read(activeAiSessionIdProvider.notifier).state = sessionId;
    }

    final chatNotifier = _ref.read(aiChatMessagesProvider.notifier);
    chatNotifier.addMessage(trimmed, isUser: true);

    _ref.read(aiSendingProvider.notifier).state = true;

    try {
      final targetNovel = _ref.read(selectedAiNovelProvider).valueOrNull;
      final options = _ref.read(aiContextOptionsProvider);

      final StringBuffer contextBuffer = StringBuffer();

      if (options.includeNovel && targetNovel != null) {
        contextBuffer.writeln('=== NOVEL OVERVIEW ===');
        contextBuffer.writeln('Title: ${targetNovel.title}');
        if (targetNovel.subtitle != null && targetNovel.subtitle!.isNotEmpty) {
          contextBuffer.writeln('Subtitle: ${targetNovel.subtitle}');
        }
        if (targetNovel.genre != null && targetNovel.genre!.isNotEmpty) {
          contextBuffer.writeln('Genre: ${targetNovel.genre}');
        }
        if (targetNovel.description != null &&
            targetNovel.description!.isNotEmpty) {
          contextBuffer.writeln('Premise: ${targetNovel.description}');
        }
        contextBuffer.writeln();
      }

      if (options.includeChapter &&
          chapterContext != null &&
          chapterContext.trim().isNotEmpty) {
        contextBuffer.writeln('=== CURRENT CHAPTER EXCERPT ===');
        final clean = chapterContext.trim();
        final excerpt = clean.length > 2500
            ? '...${clean.substring(clean.length - 2500)}'
            : clean;
        contextBuffer.writeln(excerpt);
        contextBuffer.writeln();
      }

      if (options.includeCharacters && targetNovel != null) {
        try {
          final characters = await _ref
              .read(characterRepositoryProvider)
              .watchCharacters(targetNovel.id)
              .first
              .timeout(const Duration(milliseconds: 600));
          if (characters.isNotEmpty) {
            contextBuffer.writeln('=== KEY CHARACTERS ===');
            for (final char in characters.take(8)) {
              final details = [
                char.role.label,
                if (char.goal != null && char.goal!.isNotEmpty)
                  'Goal: ${char.goal}',
                if (char.flaw != null && char.flaw!.isNotEmpty)
                  'Flaw: ${char.flaw}',
              ].join(', ');
              contextBuffer.writeln('- ${char.displayName} ($details)');
            }
            contextBuffer.writeln();
          }
        } catch (_) {}
      }

      if (options.includeWorldLore && targetNovel != null) {
        try {
          final entries = await _ref
              .read(worldRepositoryProvider)
              .watchEntries(targetNovel.id)
              .first
              .timeout(const Duration(milliseconds: 600));
          if (entries.isNotEmpty) {
            contextBuffer.writeln('=== WORLD ENCYCLOPEDIA ===');
            for (final entry in entries.take(8)) {
              final summary = entry.summary != null && entry.summary!.isNotEmpty
                  ? ': ${entry.summary}'
                  : '';
              contextBuffer.writeln(
                '- ${entry.name}${entry.subtitle != null ? " (${entry.subtitle})" : ""}$summary',
              );
            }
            contextBuffer.writeln();
          }
        } catch (_) {}
      }

      final client = _ref.read(aiClientServiceProvider);
      final responseText = await client.sendMessage(
        config: config,
        prompt: trimmed,
        novelContext:
            contextBuffer.isNotEmpty ? contextBuffer.toString().trim() : null,
      );

      chatNotifier.addMessage(responseText, isUser: false);
    } catch (err) {
      final msg = err.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      chatNotifier.addMessage(msg, isUser: false);
    } finally {
      _ref.read(aiSendingProvider.notifier).state = false;

      // Persist the current session state
      final currentMessages = _ref.read(aiChatMessagesProvider);
      if (currentMessages.isNotEmpty) {
        final targetNovel = _ref.read(selectedAiNovelProvider).valueOrNull;
        final title = currentMessages.first.text.length > 36
            ? '${currentMessages.first.text.substring(0, 36)}...'
            : currentMessages.first.text;

        final session = AiChatSession(
          id: sessionId,
          title: title,
          novelId: targetNovel?.id,
          messages: currentMessages,
          createdAt: currentMessages.first.timestamp,
          updatedAt: DateTime.now().toUtc(),
        );

        await _ref.read(aiSessionsProvider.notifier).saveSession(session);
      }
    }
  }
}
