/// Provisions the model file on the device. Implementations fetch the weights
/// from wherever they live (a URL, bundled asset, …) and cache them locally.
abstract class ModelDownloader {
  /// Ensures the model file exists locally, downloading it if missing, and
  /// returns its absolute path. Reports download progress as a 0–1 fraction
  /// (only while an actual download is in flight).
  Future<String> ensureModelFile({void Function(double progress)? onProgress});
}
