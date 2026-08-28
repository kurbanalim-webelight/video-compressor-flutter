import 'package:equatable/equatable.dart';

class VideoMetadata extends Equatable {
  const VideoMetadata({
    required this.path,
    required this.name,
    required this.width,
    required this.height,
    required this.duration,
    required this.fileSizeBytes,
    this.frameRate,
    this.codec,
  });

  final String path;
  final String name;
  final int width;
  final int height;
  final Duration duration;
  final int fileSizeBytes;
  final double? frameRate;
  final String? codec;

  int get pixelCount => width * height;

  int get longestEdge => width > height ? width : height;

  double get aspectRatio => height == 0 ? 1 : width / height;

  int get averageBitrate {
    final seconds = duration.inMilliseconds / 1000;
    if (seconds <= 0) return 0;
    return (fileSizeBytes * 8 / seconds).round();
  }

  double get bitsPerPixelPerSecond {
    if (pixelCount == 0) return 0;
    return averageBitrate / pixelCount;
  }

  bool get isValid => width > 0 && height > 0 && duration > Duration.zero;

  @override
  List<Object?> get props => [path, name, width, height, duration, fileSizeBytes, frameRate, codec];
}
