import 'package:equatable/equatable.dart';

class CompressionOutcome extends Equatable {
  const CompressionOutcome({
    required this.outputPath,
    required this.originalSizeBytes,
    required this.compressedSizeBytes,
    required this.originalResolution,
    required this.compressedResolution,
    required this.duration,
    required this.wasSkipped,
  });

  final String outputPath;
  final int originalSizeBytes;
  final int compressedSizeBytes;
  final String originalResolution;
  final String compressedResolution;
  final Duration duration;
  final bool wasSkipped;

  int get savedBytes {
    final saved = originalSizeBytes - compressedSizeBytes;
    return saved > 0 ? saved : 0;
  }

  double get savedFraction {
    if (originalSizeBytes <= 0) return 0;
    return savedBytes / originalSizeBytes;
  }

  @override
  List<Object?> get props => [
    outputPath,
    originalSizeBytes,
    compressedSizeBytes,
    originalResolution,
    compressedResolution,
    duration,
    wasSkipped,
  ];
}
