import 'dart:math' as math;

import 'compression_level.dart';
import 'models.dart';

/// Decides the output size and bitrate for a video.
///
/// This is pure maths with no plugins, so it is fast and predictable.
/// It never makes a video bigger than it already is.
class CompressionPlanner {
  const CompressionPlanner();

  static const int maxFrameRate = 30;
  static const int audioBitrate = 128000;
  static const int passthroughSizeLimitBytes = 15 * 1024 * 1024;
  static const double passthroughBitrateTolerance = 1.1;

  static const int _sdPixelCeiling = 1280 * 720;
  static const int _hdPixelCeiling = 1920 * 1080;

  /// Turns a video plus a level into a full set of encode settings.
  ///
  /// Shrinks the long edge to fit the level's cap, keeps the shape of the
  /// picture, and picks a bitrate. The whole clip is always kept.
  CompressionSettings plan(VideoDetails details, {CompressionLevel level = CompressionLevel.balanced}) {
    final (width, height) = _targetSize(details, level);

    return CompressionSettings(
      level: level,
      width: width,
      height: height,
      videoBitrate: bitrateFor(width * height, level),
      audioBitrate: audioBitrate,
      frameRate: maxFrameRate,
      skipEncoding: _isAlreadyEfficient(details, level),
    );
  }

  /// Picks a bitrate from how many pixels each frame has.
  ///
  /// Bigger pictures need more bits to look good: about 2.5 Mbps up to
  /// 720p, 4.5 Mbps up to 1080p, 6 Mbps above that. The level then
  /// scales that number up or down.
  int bitrateFor(int pixelCount, CompressionLevel level) {
    final base = switch (pixelCount) {
      <= _sdPixelCeiling => 2500000,
      <= _hdPixelCeiling => 4500000,
      _ => 6000000,
    };
    return (base * level.bitrateScale).round();
  }

  /// True when the video is already small and neat, so we leave it alone.
  ///
  /// Squeezing an already-squeezed video wastes time and loses quality
  /// for almost no saving. We skip only when it is under 15 MB, it fits
  /// the size cap, and its bitrate is already close to what we would
  /// have chosen anyway.
  bool _isAlreadyEfficient(VideoDetails details, CompressionLevel level) {
    if (details.sizeBytes > passthroughSizeLimitBytes) return false;
    if (details.longestEdge > level.maxLongestEdge) return false;
    final ceiling = bitrateFor(details.pixelCount, level) * passthroughBitrateTolerance;
    return details.averageBitrate > 0 && details.averageBitrate <= ceiling;
  }

  /// Works out the output width and height.
  ///
  /// Shrinks both sides by the same amount so the picture is not
  /// stretched, and never scales up past the original.
  (int, int) _targetSize(VideoDetails details, CompressionLevel level) {
    final scale = math.min(1.0, level.maxLongestEdge / math.max(1, details.longestEdge));
    return (_alignTo16(details.width * scale), _alignTo16(details.height * scale));
  }

  /// Rounds a width or height to a multiple of 16.
  ///
  /// Video chips work in blocks of 16 pixels. Sizes that do not fit can
  /// come out with green edges or fuzzy bars. Rounding to the nearest
  /// multiple can go over the cap, so we step down one block instead.
  int _alignTo16(double value) {
    var aligned = ((value.round() + 8) ~/ 16) * 16;
    if (aligned > value.ceil()) aligned -= 16;
    return math.max(16, aligned);
  }
}
