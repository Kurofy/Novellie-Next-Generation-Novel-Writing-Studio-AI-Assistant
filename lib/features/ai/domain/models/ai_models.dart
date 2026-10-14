enum AiProviderType {
  gemini('Google Gemini', 'gemini-3.8-flash'),
  openAi('OpenAI', 'gpt-4o-mini'),
  anthropic('Anthropic Claude', 'claude-3-5-sonnet-20241022'),
  custom('Custom / Ollama', 'llama3');

  final String label;
  final String defaultModel;
  const AiProviderType(this.label, this.defaultModel);

  List<String> get availableModels {
    switch (this) {
      case AiProviderType.gemini:
        return const [
          'gemini-3.8-flash',
          'gemini-3.8-pro',
          'gemini-3.5-flash',
          'gemini-3.5-flash-lite',
          'gemini-2.5-flash',
          'gemini-2.0-flash',
          'gemini-1.5-pro',
        ];
      case AiProviderType.openAi:
        return const [
          'gpt-4o',
          'gpt-4o-mini',
          'gpt-4-turbo',
          'gpt-3.5-turbo',
          'o1',
          'o3-mini',
        ];
      case AiProviderType.anthropic:
        return const [
          'claude-3-5-sonnet-20241022',
          'claude-3-5-haiku-20241022',
          'claude-3-opus-20240229',
          'claude-3-haiku-20240307',
        ];
      case AiProviderType.custom:
        return const [
          'llama3',
          'mistral',
          'deepseek-r1',
          'qwen2.5',
        ];
    }
  }

  String localizedLabel([bool isIndo = false]) {
    if (this == AiProviderType.custom) {
      return isIndo ? 'Kustom / Ollama' : 'Custom / Ollama';
    }
    return label;
  }
}

class AiConfigModel {
  final AiProviderType provider;
  final Map<AiProviderType, String> apiKeys;
  final Map<AiProviderType, String> models;
  final String? customBaseUrl;
  final String? _legacyApiKey;
  final String? _legacyModel;

  const AiConfigModel({
    this.provider = AiProviderType.gemini,
    this.apiKeys = const {},
    this.models = const {},
    this.customBaseUrl,
    String? apiKey,
    String? model,
  })  : _legacyApiKey = apiKey,
        _legacyModel = model;

  /// Legacy compatibility constructor for single key/model
  factory AiConfigModel.single({
    AiProviderType provider = AiProviderType.gemini,
    String apiKey = '',
    String? model,
    String? customBaseUrl,
  }) {
    return AiConfigModel(
      provider: provider,
      apiKeys: {provider: apiKey},
      models: {provider: model ?? provider.defaultModel},
      customBaseUrl: customBaseUrl,
    );
  }

  /// Current provider's scoped API key
  String get apiKey {
    if (apiKeys.containsKey(provider)) return apiKeys[provider]!;
    if (_legacyApiKey != null) return _legacyApiKey;
    return '';
  }

  /// Current provider's selected model
  String get model {
    String m = provider.defaultModel;
    if (models.containsKey(provider)) {
      m = models[provider]!;
    } else if (_legacyModel != null && _legacyModel.isNotEmpty) {
      m = _legacyModel;
    }
    // Prevent deprecated/not-found legacy model aliases from being used
    if (provider == AiProviderType.gemini &&
        (m.contains('latest') ||
            m.contains('1.5-flash') ||
            m == 'gemini-2.5-flash')) {
      return provider.defaultModel;
    }
    return m;
  }

  bool get isConfigured => apiKey.trim().isNotEmpty;

  AiConfigModel copyWith({
    AiProviderType? provider,
    Map<AiProviderType, String>? apiKeys,
    Map<AiProviderType, String>? models,
    String? apiKey,
    String? model,
    String? customBaseUrl,
  }) {
    final nextProvider = provider ?? this.provider;
    final nextKeys = Map<AiProviderType, String>.from(apiKeys ?? this.apiKeys);
    if (_legacyApiKey != null && !nextKeys.containsKey(this.provider)) {
      nextKeys[this.provider] = _legacyApiKey;
    }
    if (apiKey != null) {
      nextKeys[nextProvider] = apiKey;
    }

    final nextModels = Map<AiProviderType, String>.from(models ?? this.models);
    if (_legacyModel != null && !nextModels.containsKey(this.provider)) {
      nextModels[this.provider] = _legacyModel;
    }
    if (model != null) {
      nextModels[nextProvider] = model;
    }

    return AiConfigModel(
      provider: nextProvider,
      apiKeys: nextKeys,
      models: nextModels,
      customBaseUrl: customBaseUrl ?? this.customBaseUrl,
    );
  }
}

class AiChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;

  const AiChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'isUser': isUser,
        'timestamp': timestamp.toIso8601String(),
      };

  factory AiChatMessage.fromJson(Map<String, dynamic> json) => AiChatMessage(
        id: json['id'] as String,
        text: json['text'] as String,
        isUser: json['isUser'] as bool? ?? false,
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
            DateTime.now().toUtc(),
      );
}

class AiChatSession {
  final String id;
  final String title;
  final String? novelId;
  final List<AiChatMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AiChatSession({
    required this.id,
    required this.title,
    this.novelId,
    this.messages = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'novelId': novelId,
        'messages': messages.map((m) => m.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory AiChatSession.fromJson(Map<String, dynamic> json) => AiChatSession(
        id: json['id'] as String,
        title: json['title'] as String? ?? 'New Chat',
        novelId: json['novelId'] as String?,
        messages: (json['messages'] as List<dynamic>?)
                ?.map((m) => AiChatMessage.fromJson(m as Map<String, dynamic>))
                .toList() ??
            [],
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now().toUtc(),
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
            DateTime.now().toUtc(),
      );

  AiChatSession copyWith({
    String? title,
    String? novelId,
    List<AiChatMessage>? messages,
    DateTime? updatedAt,
  }) {
    return AiChatSession(
      id: id,
      title: title ?? this.title,
      novelId: novelId ?? this.novelId,
      messages: messages ?? this.messages,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class AiContextOptions {
  final bool includeNovel;
  final bool includeChapter;
  final bool includeCharacters;
  final bool includeWorldLore;

  const AiContextOptions({
    this.includeNovel = true,
    this.includeChapter = true,
    this.includeCharacters = true,
    this.includeWorldLore = true,
  });

  bool get isEmpty =>
      !includeNovel && !includeChapter && !includeCharacters && !includeWorldLore;

  int get activeCount =>
      (includeNovel ? 1 : 0) +
      (includeChapter ? 1 : 0) +
      (includeCharacters ? 1 : 0) +
      (includeWorldLore ? 1 : 0);

  AiContextOptions copyWith({
    bool? includeNovel,
    bool? includeChapter,
    bool? includeCharacters,
    bool? includeWorldLore,
  }) {
    return AiContextOptions(
      includeNovel: includeNovel ?? this.includeNovel,
      includeChapter: includeChapter ?? this.includeChapter,
      includeCharacters: includeCharacters ?? this.includeCharacters,
      includeWorldLore: includeWorldLore ?? this.includeWorldLore,
    );
  }
}
