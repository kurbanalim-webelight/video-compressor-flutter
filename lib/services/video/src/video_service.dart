import 'dart:developer' as developer;
import 'dart:io';

import 'package:v_video_compressor/v_video_compressor.dart';

import 'compression_level.dart';
import 'compression_planner.dart';
import 'models.dart';

/// Makes videos smaller using the phone's own video chip.
///
/// Give it a video file and a [CompressionLevel]. It reads the video,
/// works out good settings, encodes it, and hands back the new file.
class VideoService {
  VideoService({VVideoCompressor? compressor, CompressionPlanner? planner})
    : _compressor = compressor ?? VVideoCompressor(),
      _planner = planner ?? const CompressionPlanner();

  final VVideoCompressor _compressor;
  final CompressionPlanner _planner;

  /// A crop that keeps the whole frame apart from a sliver too small to see.
  ///
  /// Without a crop the plugin builds its rotation transform itself and gets
  /// it wrong: rotated clips land outside the render canvas, so the file
  /// plays back with sound but no picture. A crop routes the same job through
  /// the plugin's correct transform maths. Anything closer to 1.0 than this
  /// counts as the full frame and is dropped.
  static const fullFrameCrop = VVideoCropRect(left: 0, top: 0, right: 0.99999, bottom: 0.99999);

  bool _cancelRequested = false;
  String? _lastOutputPath;

  /// How far the current job has got, from 0.0 to 1.0.
  ///
  /// Listen to this to drive a progress bar. It stays quiet when
  /// nothing is being compressed.
  Stream<double> get progress => VVideoCompressor.progressStream.map((event) => event.progress.clamp(0.0, 1.0));

  /// Reads a video's size, length and dimensions without changing it.
  ///
  /// Returns null if the file is missing, is not a video, or is broken.
  /// Always check for null before using the result.
  Future<VideoDetails?> inspect(File file) async {
    try {
      if (!await file.exists()) return null;
      final info = await _compressor.getVideoInfo(file.path);
      if (info == null) return null;
      final details = VideoDetails(
        path: info.path,
        name: info.name,
        width: info.width,
        height: info.height,
        duration: Duration(milliseconds: info.durationMillis),
        sizeBytes: info.fileSizeBytes,
      );
      return details.isPlayable ? details : null;
    } catch (error, stackTrace) {
      _log('inspect failed for ${file.path}', error, stackTrace);
      return null;
    }
  }

  /// Works out what the output will look like, before any encoding.
  ///
  /// Use this to show the user the target size and quality up front.
  /// It only does maths, so it is instant and safe to call often.
  CompressionSettings plan(VideoDetails details, {CompressionLevel level = CompressionLevel.balanced}) =>
      _planner.plan(details, level: level);

  /// Grabs still pictures from the video at the times you ask for.
  ///
  /// Handy for thumbnails and preview strips. Returns an empty list if
  /// the frames cannot be read, so it never throws.
  Future<List<VideoFrame>> extractFrames(File file, List<Duration> positions) async {
    try {
      final results = await _compressor.getVideoThumbnails(
        file.path,
        positions
            .map(
              (position) =>
                  VVideoThumbnailConfig(timeMs: position.inMilliseconds, maxWidth: 160, maxHeight: 160, quality: 70),
            )
            .toList(growable: false),
      );
      return results
          .map(
            (result) => VideoFrame(
              path: result.thumbnailPath,
              position: Duration(milliseconds: result.timeMs),
            ),
          )
          .toList(growable: false);
    } catch (error, stackTrace) {
      _log('frame extraction failed', error, stackTrace);
      return const [];
    }
  }

  /// The main job: makes the video smaller.
  ///
  /// Pass a [level] to choose how hard to squeeze. The whole clip is
  /// always kept, however long it is.
  ///
  /// Returns [CompressionSucceeded] with the new file, or
  /// [CompressionFailed] saying what went wrong.
  Future<CompressionResult> compress(File file, {CompressionLevel level = CompressionLevel.balanced}) async {
    final details = await inspect(file);
    if (details == null) {
      return const CompressionFailed(CompressionErrorType.unreadableSource);
    }
    return compressWith(file, plan(details, level: level), details);
  }

  /// Same as [compress], but you supply the settings yourself.
  ///
  /// Use this when you already called [plan] and showed those numbers to
  /// the user, so the result matches exactly what they were promised.
  ///
  /// If the settings say the video is already small and efficient, it is
  /// handed back untouched instead of being encoded again.
  Future<CompressionResult> compressWith(File file, CompressionSettings settings, [VideoDetails? knownDetails]) async {
    await _discardPreviousOutput(keep: file.path);

    final details = knownDetails ?? await inspect(file);
    if (details == null) {
      return const CompressionFailed(CompressionErrorType.unreadableSource);
    }

    if (settings.skipEncoding) {
      return CompressionSucceeded(
        CompressionOutput(
          path: details.path,
          originalSizeBytes: details.sizeBytes,
          compressedSizeBytes: details.sizeBytes,
          originalResolution: '${details.width}x${details.height}',
          compressedResolution: '${details.width}x${details.height}',
          duration: details.duration,
          skipped: true,
        ),
      );
    }

    _cancelRequested = false;
    // The plugin treats outputPath as a directory and names the file itself.
    final outputDir = '${Directory.systemTemp.path}/compressed_${DateTime.now().millisecondsSinceEpoch}';

    try {
      final result = await _compressor.compressVideo(file.path, _configFor(settings, outputDir));

      if (result == null) {
        await _deleteQuietly(outputDir, keep: file.path);
        return CompressionFailed(
          _cancelRequested ? CompressionErrorType.cancelled : CompressionErrorType.encodingFailed,
        );
      }

      _lastOutputPath = result.compressedFilePath == file.path ? null : result.compressedFilePath;

      final encoded = await _compressor.getVideoInfo(result.compressedFilePath);

      return CompressionSucceeded(
        CompressionOutput(
          path: result.compressedFilePath,
          originalSizeBytes: result.originalSizeBytes,
          compressedSizeBytes: result.compressedSizeBytes,
          originalResolution: result.originalResolution,
          compressedResolution: encoded == null
              ? result.compressedResolution
              : '${encoded.width}x${encoded.height}',
          duration: details.duration,
          skipped: result.usedOriginalFile,
        ),
      );
    } catch (error, stackTrace) {
      _log('compression failed for ${file.path}', error, stackTrace);
      await _deleteQuietly(outputDir, keep: file.path);
      return CompressionFailed(_cancelRequested ? CompressionErrorType.cancelled : CompressionErrorType.encodingFailed);
    } finally {
      _cancelRequested = false;
    }
  }

  /// Stops the job that is running now.
  ///
  /// The half-finished file is deleted for you. The waiting [compress]
  /// call finishes with [CompressionErrorType.cancelled].
  Future<void> cancel() async {
    _cancelRequested = true;
    try {
      await _compressor.cancelCompression();
    } catch (error, stackTrace) {
      _log('cancel failed', error, stackTrace);
    }
  }

  VVideoCompressionConfig _configFor(CompressionSettings settings, String outputDir) {
    return VVideoCompressionConfig(
      // Quality only picks the export preset, and the preset caps the frame
      // size. Ours is always the widest one so it never cuts below the width
      // and height we ask for below; the file size is set by the bitrate.
      quality: VVideoCompressQuality.high,
      outputPath: outputDir,
      advanced: VVideoAdvancedConfig(
        customWidth: settings.width,
        customHeight: settings.height,
        videoBitrate: settings.videoBitrate,
        audioBitrate: settings.audioBitrate,
        frameRate: settings.frameRate.toDouble(),
        videoCodec: VVideoCodec.h264,
        audioCodec: VAudioCodec.aac,
        hardwareAcceleration: true,
        autoCorrectOrientation: true,
        dimensionHandling: VDimensionHandling.autoAlign,
        cropRect: fullFrameCrop,
      ),
    );
  }

  Future<void> _discardPreviousOutput({required String keep}) async {
    final previous = _lastOutputPath;
    _lastOutputPath = null;
    if (previous != null) await _deleteQuietly(previous, keep: keep);
  }

  Future<void> _deleteQuietly(String path, {required String keep}) async {
    if (path == keep) return;
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      } else {
        final dir = Directory(path);
        if (await dir.exists()) await dir.delete(recursive: true);
      }
    } catch (error, stackTrace) {
      _log('failed to delete $path', error, stackTrace);
    }
  }

  void _log(String message, Object error, StackTrace stackTrace) {
    developer.log(message, name: 'video_service', level: 1000, error: error, stackTrace: stackTrace);
  }
}
