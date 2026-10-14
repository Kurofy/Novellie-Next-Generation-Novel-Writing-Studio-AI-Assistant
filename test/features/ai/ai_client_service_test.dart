import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novellie/features/ai/data/services/ai_client_service.dart';
import 'package:novellie/features/ai/domain/models/ai_models.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late AiClientService service;

  final testConfig = AiConfigModel.single(
    provider: AiProviderType.gemini,
    apiKey: 'test-api-key',
    model: 'gemini-1.5-flash',
  );

  setUp(() {
    mockDio = MockDio();
    service = AiClientService(mockDio);
  });

  test(
    'AiClientService maps host lookup SocketException to user-friendly error',
    () async {
      when(
        () => mockDio.post<Map<String, dynamic>>(
          any(),
          options: any(named: 'options'),
          data: any(named: 'data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.connectionError,
          error: const SocketException(
            'Failed host lookup: generativelanguage.googleapis.com',
          ),
        ),
      );

      expect(
        () => service.sendMessage(
          config: testConfig,
          prompt: 'Hello',
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Host address could not be resolved'),
          ),
        ),
      );
    },
  );

  test('AiClientService maps 401 authentication error nicely', () async {
    when(
      () => mockDio.post<Map<String, dynamic>>(
        any(),
        options: any(named: 'options'),
        data: any(named: 'data'),
      ),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 401,
          data: {'error': {'message': 'API key not valid'}},
        ),
      ),
    );

    expect(
      () => service.sendMessage(
        config: testConfig,
        prompt: 'Hello',
      ),
      throwsA(
        isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Authentication Error (401)'),
        ),
      ),
    );
  });

  test('AiClientService calls v1beta with clean model name and parses response', () async {
    when(
      () => mockDio.post<Map<String, dynamic>>(
        any(that: contains('v1beta/models/gemini-3.8-flash:generateContent')),
        options: any(named: 'options'),
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: ''),
        statusCode: 200,
        data: {
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': 'Generated story suggestion'},
                ],
              },
            },
          ],
        },
      ),
    );

    final config = AiConfigModel.single(
      provider: AiProviderType.gemini,
      apiKey: 'test-key',
      model: 'models/gemini-3.8-flash',
    );

    final reply = await service.sendMessage(
      config: config,
      prompt: 'Write something',
    );

    expect(reply, 'Generated story suggestion');
  });

  test('AiClientService strips -latest suffix and models/ prefix to call gemini-3.8-flash', () async {
    when(
      () => mockDio.post<Map<String, dynamic>>(
        any(that: contains('v1beta/models/gemini-3.8-flash:generateContent')),
        options: any(named: 'options'),
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: ''),
        statusCode: 200,
        data: {
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': 'Normalized model reply'},
                ],
              },
            },
          ],
        },
      ),
    );

    final config = AiConfigModel.single(
      provider: AiProviderType.gemini,
      apiKey: 'test-key',
      model: 'models/gemini-1.5-flash-latest',
    );

    final reply = await service.sendMessage(
      config: config,
      prompt: 'Write something',
    );

    expect(reply, 'Normalized model reply');
  });

  test('AiClientService retries alternate endpoint on 404', () async {
    var v1betaCalled = false;
    var v1Called = false;

    when(
      () => mockDio.post<Map<String, dynamic>>(
        any(),
        options: any(named: 'options'),
        data: any(named: 'data'),
      ),
    ).thenAnswer((invocation) async {
      final url = invocation.positionalArguments[0] as String;
      if (url.contains('/v1beta/models/gemini-1.5-pro:')) {
        v1betaCalled = true;
        throw DioException(
          requestOptions: RequestOptions(path: url),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: url),
            statusCode: 404,
            data: {'error': {'message': 'models/gemini-1.5-pro is not found for v1beta'}},
          ),
        );
      } else if (url.contains('/v1/models/gemini-1.5-pro:')) {
        v1Called = true;
        return Response(
          requestOptions: RequestOptions(path: url),
          statusCode: 200,
          data: {
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'Fallback response from v1 endpoint'},
                  ],
                },
              },
            ],
          },
        );
      }
      throw UnimplementedError();
    });

    final reply = await service.sendMessage(
      config: AiConfigModel.single(
        provider: AiProviderType.gemini,
        apiKey: 'test-key',
        model: 'gemini-1.5-pro',
      ),
      prompt: 'Hello',
    );

    expect(v1betaCalled, isTrue);
    expect(v1Called, isTrue);
    expect(reply, 'Fallback response from v1 endpoint');
  });
}
