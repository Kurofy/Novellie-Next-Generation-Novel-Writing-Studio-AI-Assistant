import 'package:flutter_test/flutter_test.dart';
import 'package:novellie/features/ai/domain/models/ai_models.dart';

void main() {
  group('Multi-Provider AI & Scoped API Key Management', () {
    test('Each provider maintains independent scoped keys without cross-leakage', () {
      const config = AiConfigModel(
        provider: AiProviderType.gemini,
        apiKeys: {
          AiProviderType.gemini: 'gemini-secret-key-123',
          AiProviderType.openAi: 'openai-secret-key-456',
        },
        models: {
          AiProviderType.gemini: 'gemini-1.5-pro',
          AiProviderType.openAi: 'gpt-4o',
        },
      );

      // Verify active Gemini key & model
      expect(config.provider, equals(AiProviderType.gemini));
      expect(config.apiKey, equals('gemini-secret-key-123'));
      expect(config.model, equals('gemini-1.5-pro'));

      // Switch to OpenAI
      final openAiConfig = config.copyWith(provider: AiProviderType.openAi);
      expect(openAiConfig.provider, equals(AiProviderType.openAi));
      expect(openAiConfig.apiKey, equals('openai-secret-key-456'));
      expect(openAiConfig.model, equals('gpt-4o'));
      expect(openAiConfig.apiKey, isNot(contains('gemini')));

      // Switch to Anthropic (no saved key yet -> resets to empty)
      final anthropicConfig =
          config.copyWith(provider: AiProviderType.anthropic);
      expect(anthropicConfig.provider, equals(AiProviderType.anthropic));
      expect(anthropicConfig.apiKey, isEmpty);
      expect(anthropicConfig.isConfigured, isFalse);
      expect(anthropicConfig.model, equals('claude-3-5-sonnet-20241022'));
    });

    test('Available models are dynamically populated per provider', () {
      final geminiModels = AiProviderType.gemini.availableModels;
      expect(geminiModels, contains('gemini-3.8-flash'));
      expect(geminiModels, contains('gemini-3.5-flash'));
      expect(geminiModels, contains('gemini-2.0-flash'));
      expect(geminiModels, isNot(contains('gpt-4o')));

      final openAiModels = AiProviderType.openAi.availableModels;
      expect(openAiModels, contains('gpt-4o'));
      expect(openAiModels, contains('gpt-4o-mini'));
      expect(openAiModels, isNot(contains('gemini-1.5-flash')));

      final anthropicModels = AiProviderType.anthropic.availableModels;
      expect(anthropicModels, contains('claude-3-5-sonnet-20241022'));
      expect(anthropicModels, contains('claude-3-5-haiku-20241022'));
      expect(anthropicModels, contains('claude-3-opus-20240229'));
    });

    test('Legacy constructors maintain backwards compatibility', () {
      const legacyConfig = AiConfigModel(
        provider: AiProviderType.gemini,
        apiKey: 'legacy-key',
        model: 'gemini-1.5-pro',
      );

      expect(legacyConfig.apiKey, equals('legacy-key'));
      expect(legacyConfig.model, equals('gemini-1.5-pro'));
      expect(legacyConfig.isConfigured, isTrue);
    });
  });
}
