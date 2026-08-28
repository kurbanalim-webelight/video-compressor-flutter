import 'compression_level.dart';

/// Facts about a video file, read straight from the file itself.
class VideoDetails {
  const VideoDetails({
    required this.path,
    required this.name,
    required this.width,
    required this.height,
    required this.duration,
    required this.sizeBytes,
  });

  final String path;
  final String name;
  final int width;
  final int height;
  final Duration duration;
  final int sizeBytes;

  /// How many pixels are in one frame. Drives the bitrate choice.
  int get pixelCount => width * height;

  /// The longer of width and height, whether the video is tall or wide.
  int get longestEdge => width > height ? width : height;

  /// Roughly how many bits each second of video uses.
  ///
  /// Worked out from file size and length. A high number for a small
  /// picture means the video was saved wastefully and will squeeze well.
  int get averageBitrate {
    final seconds = duration.inMilliseconds / 1000;
    if (seconds <= 0) return 0;
    return (sizeBytes * 8 / seconds).round();
  }

  /// False when the file has no picture or no length, so it is not usable.
  bool get isPlayable => width > 0 && height > 0 && duration > Duration.zero;
}

/// The exact plan for one encode job. Made by [CompressionPlanner].
class CompressionSettings {
  const CompressionSettings({
    required this.level,
    required this.width,
    required this.height,
    required this.videoBitrate,
    required this.audioBitrate,
    required this.frameRate,
    required this.skipEncoding,
  });

  final CompressionLevel level;
  final int width;
  final int height;
  final int videoBitrate;
  final int audioBitrate;
  final int frameRate;

  /// True when the video is already fine and should be passed through.
  final bool skipEncoding;

  String get resolution => '${width}x$height';
}

/// The finished result: where the new file is, and how much was saved.
class CompressionOutput {
  const CompressionOutput({
    required this.path,
    required this.originalSizeBytes,
    required this.compressedSizeBytes,
    required this.originalResolution,
    required this.compressedResolution,
    required this.duration,
    required this.skipped,
  });

  final String path;
  final int originalSizeBytes;
  final int compressedSizeBytes;
  final String originalResolution;
  final String compressedResolution;
  final Duration duration;

  /// True when no encoding happened and this is the original file.
  final bool skipped;
}

/// One still picture pulled out of a video at a given time.
class VideoFrame {
  const VideoFrame({required this.path, required this.position});

  final String path;
  final Duration position;
}

/// Why a job did not finish.
///
/// - [unreadableSource]: the file is missing, not a video, or broken.
/// - [encodingFailed]: the phone's encoder gave up part way.
/// - [cancelled]: someone called cancel.
enum CompressionErrorType { unreadableSource, encodingFailed, cancelled }

/// What came back from a job: either [CompressionSucceeded] or
/// [CompressionFailed]. Use a switch to handle both.
sealed class CompressionResult {
  const CompressionResult();
}

/// The job worked. [output] holds the new file and the size saved.
final class CompressionSucceeded extends CompressionResult {
  const CompressionSucceeded(this.output);

  final CompressionOutput output;
}

/// The job did not work. [type] says why.
final class CompressionFailed extends CompressionResult {
  const CompressionFailed(this.type);

  final CompressionErrorType type;
}
