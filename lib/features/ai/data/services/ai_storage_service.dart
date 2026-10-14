import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/ai_models.dart';

class AiStorageService {
  final FlutterSecureStorage _storage;

  static const _keyProvider = 'novellie_ai_provider';
  static const _keyApiKey = 'novellie_ai_key';
  static const _keyModel = 'novellie_ai_model';
  static const _keyBaseUrl = 'novellie_ai_base_url';
  static const _keySessions = 'novellie_ai_sessions';
  static const _keyScopedKeys = 'novellie_ai_scoped_keys';

  AiStorageService([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  Future<AiConfigModel> loadConfig() async {
    try {
      final providerStr = await _storage.read(key: _keyProvider);
      final customBaseUrl = await _storage.read(key: _keyBaseUrl);

      final provider = AiProviderType.values.firstWhere(
        (p) => p.name == providerStr,
        orElse: () => AiProviderType.gemini,
      );

      final Map<AiProviderType, String> apiKeys = {};
      final Map<AiProviderType, String> models = {};

      // Helper to sanitize deprecated Gemini model strings
      String sanitizeModel(AiProviderType p, String m) {
        final trimmed = m.trim();
        if (p == AiProviderType.gemini &&
            (trimmed.contains('latest') ||
                trimmed.contains('1.5-flash') ||
                trimmed == 'gemini-2.5-flash')) {
          return p.defaultModel;
        }
        return trimmed;
      }

      // Load scoped keys and models
      for (final p in AiProviderType.values) {
        final keyVal = await _storage.read(key: '${_keyApiKey}_${p.name}');
        if (keyVal != null && keyVal.isNotEmpty) {
          apiKeys[p] = keyVal;
        }
        final modelVal = await _storage.read(key: '${_keyModel}_${p.name}');
        if (modelVal != null && modelVal.isNotEmpty) {
          models[p] = sanitizeModel(p, modelVal);
        }
      }

      // Check scoped keys JSON map if individual keys were not found
      if (apiKeys.isEmpty) {
        final rawScoped = await _storage.read(key: _keyScopedKeys);
        if (rawScoped != null && rawScoped.isNotEmpty) {
          try {
            final decoded = jsonDecode(rawScoped) as Map<String, dynamic>;
            for (final entry in decoded.entries) {
              final p = AiProviderType.values.firstWhere(
                (type) => type.name == entry.key,
                orElse: () => AiProviderType.gemini,
              );
              apiKeys[p] = entry.value.toString();
            }
          } catch (_) {}
        }
      }

      // Backward compatibility: If no provider keys yet, check legacy single key
      if (apiKeys.isEmpty) {
        final legacyKey = await _storage.read(key: _keyApiKey);
        if (legacyKey != null && legacyKey.isNotEmpty) {
          apiKeys[provider] = legacyKey;
        }
      }

      // Backward compatibility: Check legacy model
      if (!models.containsKey(provider)) {
        final legacyModel = await _storage.read(key: _keyModel);
        if (legacyModel != null && legacyModel.isNotEmpty) {
          models[provider] = sanitizeModel(provider, legacyModel);
        }
      }

      return AiConfigModel(
        provider: provider,
        apiKeys: apiKeys,
        models: models,
        customBaseUrl: customBaseUrl,
      );
    } catch (_) {
      return const AiConfigModel();
    }
  }

  Future<void> saveConfig(AiConfigModel config) async {
    await _storage.write(key: _keyProvider, value: config.provider.name);

    // Save individual scoped keys and models per provider
    final Map<String, String> jsonKeys = {};
    for (final p in AiProviderType.values) {
      final keyVal = config.apiKeys[p];
      if (keyVal != null && keyVal.isNotEmpty) {
        await _storage.write(key: '${_keyApiKey}_${p.name}', value: keyVal);
        jsonKeys[p.name] = keyVal;
      } else {
        await _storage.delete(key: '${_keyApiKey}_${p.name}');
      }

      final modelVal = config.models[p];
      if (modelVal != null && modelVal.isNotEmpty) {
        await _storage.write(key: '${_keyModel}_${p.name}', value: modelVal);
      } else {
        await _storage.delete(key: '${_keyModel}_${p.name}');
      }
    }

    // Save JSON object for scoped keys
    await _storage.write(key: _keyScopedKeys, value: jsonEncode(jsonKeys));

    // Save active provider legacy key and model
    if (config.apiKey.isNotEmpty) {
      await _storage.write(key: _keyApiKey, value: config.apiKey);
    } else {
      await _storage.delete(key: _keyApiKey);
    }
    await _storage.write(key: _keyModel, value: config.model);

    if (config.customBaseUrl != null) {
      await _storage.write(key: _keyBaseUrl, value: config.customBaseUrl);
    } else {
      await _storage.delete(key: _keyBaseUrl);
    }
  }

  Future<void> clearConfig() async {
    await _storage.delete(key: _keyProvider);
    await _storage.delete(key: _keyApiKey);
    await _storage.delete(key: _keyModel);
    await _storage.delete(key: _keyBaseUrl);
    await _storage.delete(key: _keyScopedKeys);
    for (final p in AiProviderType.values) {
      await _storage.delete(key: '${_keyApiKey}_${p.name}');
      await _storage.delete(key: '${_keyModel}_${p.name}');
    }
  }

  // --- Session Management ---

  Future<List<AiChatSession>> loadSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keySessions);
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((item) => AiChatSession.fromJson(item as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } catch (_) {
      return [];
    }
  }

  Future<void> saveSession(AiChatSession session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessions = await loadSessions();
      final index = sessions.indexWhere((s) => s.id == session.id);
      if (index >= 0) {
        sessions[index] = session;
      } else {
        sessions.insert(0, session);
      }
      final raw = jsonEncode(sessions.map((s) => s.toJson()).toList());
      await prefs.setString(_keySessions, raw);
    } catch (_) {}
  }

  Future<void> deleteSession(String sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessions = await loadSessions();
      sessions.removeWhere((s) => s.id == sessionId);
      final raw = jsonEncode(sessions.map((s) => s.toJson()).toList());
      await prefs.setString(_keySessions, raw);
    } catch (_) {}
  }

  Future<void> clearAllSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keySessions);
    } catch (_) {}
  }
}
