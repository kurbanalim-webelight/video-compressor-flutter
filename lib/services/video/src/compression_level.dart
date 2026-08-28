/// How hard to squeeze the video. Further down means a smaller file
/// and a softer picture.
///
/// | Level    | Max side | Bitrate |
/// |----------|----------|---------|
/// | light    | 1080 px  | 1.3x    |
/// | balanced | 1080 px  | 1.0x    |
/// | strong   |  720 px  | 0.6x    |
/// | extreme  |  480 px  | 0.4x    |
enum CompressionLevel {
  light(label: 'Light', maxLongestEdge: 1080, bitrateScale: 1.3),
  balanced(label: 'Balanced', maxLongestEdge: 1080, bitrateScale: 1),
  strong(label: 'Strong', maxLongestEdge: 720, bitrateScale: 0.6),
  extreme(label: 'Extreme', maxLongestEdge: 480, bitrateScale: 0.4);

  const CompressionLevel({required this.label, required this.maxLongestEdge, required this.bitrateScale});

  /// Name to show in the app.
  final String label;

  /// The longest side of the output can never pass this.
  final int maxLongestEdge;

  /// Multiplies the normal bitrate. Below 1 means a smaller file.
  final double bitrateScale;
}
