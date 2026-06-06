import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../core/ports/model_downloader.dart';

/// Downloads the GGUF model over HTTP(S) into the app documents directory on
/// first run, streaming to a temporary `.part` file and renaming on success so
/// a partial download is never mistaken for a complete one.
class HttpModelDownloader implements ModelDownloader {
  HttpModelDownloader({required this.url, this.fileName = 'model.gguf'});

  /// Direct download URL for the `.gguf` (use HTTPS — iOS ATS blocks cleartext).
  final String url;
  final String fileName;

  Future<String> _targetPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$fileName';
  }

  @override
  Future<String> ensureModelFile({
    void Function(double progress)? onProgress,
  }) async {
    final path = await _targetPath();
    final file = File(path);
    if (await file.exists() && await file.length() > 0) {
      return path; // Already provisioned (downloaded earlier or pushed manually).
    }
    if (url.isEmpty) {
      throw StateError(
        'No model on device and no MODEL_URL configured to download one.',
      );
    }

    final partial = File('$path.part');
    final client = HttpClient();
    try {
      final response = await (await client.getUrl(Uri.parse(url))).close();
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
      return path;
    } catch (_) {
      if (await partial.exists()) await partial.delete();
      rethrow;
    } finally {
      client.close();
    }
  }
}
