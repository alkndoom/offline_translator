import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../core/ports/model_downloader.dart';

/// Downloads the GGUF model over HTTP(S) into the app documents directory on
/// first run, streaming to a temporary `.part` file and renaming on success so
/// a partial download is never mistaken for a complete one.
class HttpModelDownloader implements ModelDownloader {
  HttpModelDownloader({
    required this.url,
    this.fileName = 'model.gguf',
    this.version = '',
    this.manifestUrl = '',
  });

  /// Direct download URL for the `.gguf` (use HTTPS — iOS ATS blocks cleartext).
  final String url;
  final String fileName;

  /// Build-time model version. When this changes, the model is re-downloaded.
  final String version;

  /// Optional JSON manifest URL. When present, this is checked before using the
  /// cached model so the app can pick up model updates without an app rebuild.
  final String manifestUrl;

  Future<String> _targetPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$fileName';
  }

  @override
  Future<String> ensureModelFile({
    void Function(double progress)? onProgress,
  }) async {
    final descriptor = await _resolveDescriptor();
    final path = await _targetPath();
    final file = File(path);
    final meta = await _readMetadata(path);
    final expectedVersion = descriptor.version.trim();

    if (await file.exists() && await file.length() > 0) {
      if (expectedVersion.isEmpty || meta.version == expectedVersion) {
        return path; // Already provisioned and current.
      }
    }
    if (descriptor.url.isEmpty) {
      throw StateError(
        'No model on device and no MODEL_URL configured to download one.',
      );
    }

    final partial = File('$path.part');
    final client = HttpClient();
    try {
      final response = await (await client.getUrl(
        Uri.parse(descriptor.url),
      )).close();
      if (response.statusCode != HttpStatus.ok) {
        throw StateError('Model download failed: HTTP ${response.statusCode}.');
      }
      final total = response.contentLength; // -1 if unknown
      var received = 0;
      onProgress?.call(0); // mark the download phase as started

      final sink = partial.openWrite();
      try {
        await for (final chunk in response) {
          sink.add(chunk);
          received += chunk.length;
          if (total > 0) onProgress?.call(received / total);
        }
      } finally {
        await sink.flush();
        await sink.close();
      }
      await partial.rename(path);
      await _writeMetadata(
        path,
        _ModelMetadata(
          version: expectedVersion,
          url: descriptor.url,
          downloadedAt: DateTime.now(),
        ),
      );
      return path;
    } catch (_) {
      if (await partial.exists()) await partial.delete();
      rethrow;
    } finally {
      client.close();
    }
  }

  Future<_ModelDescriptor> _resolveDescriptor() async {
    final fallback = _ModelDescriptor(url: url, version: version);
    if (manifestUrl.trim().isEmpty) return fallback;

    try {
      final client = HttpClient();
      try {
        final response = await (await client.getUrl(
          Uri.parse(manifestUrl),
        )).close();
        if (response.statusCode != HttpStatus.ok) {
          throw StateError(
            'Model manifest failed: HTTP ${response.statusCode}.',
          );
        }
        final body = await utf8.decoder.bind(response).join();
        final json = jsonDecode(body) as Map<String, dynamic>;
        final manifestVersion = (json['version'] as String?)?.trim() ?? '';
        if (manifestVersion.isEmpty) {
          throw StateError('Model manifest is missing a non-empty version.');
        }
        final manifestModelUrl = (json['url'] as String?)?.trim() ?? '';
        return _ModelDescriptor(
          url: manifestModelUrl.isNotEmpty ? manifestModelUrl : fallback.url,
          version: manifestVersion,
        );
      } finally {
        client.close();
      }
    } catch (_) {
      return fallback;
    }
  }

  Future<_ModelMetadata> _readMetadata(String modelPath) async {
    final file = File('$modelPath.meta.json');
    if (!await file.exists()) return const _ModelMetadata();
    try {
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return _ModelMetadata(
        version: json['version'] as String? ?? '',
        url: json['url'] as String? ?? '',
        downloadedAt: DateTime.tryParse(json['downloadedAt'] as String? ?? ''),
      );
    } catch (_) {
      return const _ModelMetadata();
    }
  }

  Future<void> _writeMetadata(String modelPath, _ModelMetadata metadata) {
    final file = File('$modelPath.meta.json');
    return file.writeAsString(jsonEncode(metadata.toJson()));
  }
}

class _ModelDescriptor {
  final String url;
  final String version;

  const _ModelDescriptor({required this.url, required this.version});
}

class _ModelMetadata {
  final String version;
  final String url;
  final DateTime? downloadedAt;

  const _ModelMetadata({this.version = '', this.url = '', this.downloadedAt});

  Map<String, dynamic> toJson() => {
    'version': version,
    'url': url,
    'downloadedAt': downloadedAt?.toIso8601String(),
  };
}
