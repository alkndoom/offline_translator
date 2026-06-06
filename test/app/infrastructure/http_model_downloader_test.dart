import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:offline_translator/app/infrastructure/http_model_downloader.dart';

void main() {
  group('HttpModelDownloader', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp(
        'http_model_downloader_test_',
      );
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('replaces a cached model when the manifest version changes', () async {
      final modelFile = File('${tempDir.path}/model.gguf');
      await modelFile.writeAsString('old model');
      await File('${modelFile.path}.meta.json').writeAsString(
        jsonEncode({
          'version': 'v1',
          'url': 'https://example.com/model-v1.gguf',
          'downloadedAt': DateTime(2026).toIso8601String(),
        }),
      );

      final server = await _startServer((request) async {
        request.response
          ..statusCode = HttpStatus.ok
          ..write('new model');
      });
      addTearDown(() => server.close(force: true));

      final downloader = HttpModelDownloader(
        url: 'https://example.com/fallback.gguf',
        manifestUrl: 'https://example.com/manifest.json',
        directoryProvider: () async => tempDir,
        manifestFetcher: (_) async => jsonEncode({
          'version': 'v2',
          'url': 'http://${server.address.host}:${server.port}/model.gguf',
        }),
      );

      final path = await downloader.ensureModelFile();

      expect(path, modelFile.path);
      expect(await modelFile.readAsString(), 'new model');
      final metadata =
          jsonDecode(await File('${modelFile.path}.meta.json').readAsString())
              as Map<String, dynamic>;
      expect(metadata['version'], 'v2');
      expect(metadata['url'], contains('/model.gguf'));
    });

    test('keeps a cached model when the manifest version matches', () async {
      final modelFile = File('${tempDir.path}/model.gguf');
      await modelFile.writeAsString('cached model');
      await File('${modelFile.path}.meta.json').writeAsString(
        jsonEncode({
          'version': 'v1',
          'url': 'https://example.com/model-v1.gguf',
          'downloadedAt': DateTime(2026).toIso8601String(),
        }),
      );

      final downloader = HttpModelDownloader(
        url: '',
        manifestUrl: 'https://example.com/manifest.json',
        directoryProvider: () async => tempDir,
        manifestFetcher: (_) async => jsonEncode({
          'version': 'v1',
          'url': 'https://example.com/model-v1.gguf',
        }),
      );

      final path = await downloader.ensureModelFile();

      expect(path, modelFile.path);
      expect(await modelFile.readAsString(), 'cached model');
    });
  });
}

Future<HttpServer> _startServer(
  Future<void> Function(HttpRequest request) handler,
) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((request) async {
    try {
      await handler(request);
    } finally {
      await request.response.close();
    }
  });
  return server;
}
