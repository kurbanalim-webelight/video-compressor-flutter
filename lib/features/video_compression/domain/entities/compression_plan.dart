import 'package:equatable/equatable.dart';

import 'video_codec.dart';

class CompressionPlan extends Equatable {
  const CompressionPlan({
    required this.targetWidth,
    required this.targetHeight,
    required this.videoBitrate,
    required this.audioBitrate,
    required this.frameRate,
    required this.codec,
    required this.shouldSkipCompression,
  });

  final int targetWidth;
  final int targetHeight;
  final int videoBitrate;
  final int audioBitrate;
  final int frameRate;
  final VideoCodec codec;
  final bool shouldSkipCompression;

  String get resolutionLabel => '${targetWidth}x$targetHeight';

  @override
  List<Object?> get props => [
    targetWidth,
    targetHeight,
    videoBitrate,
    audioBitrate,
    frameRate,
    codec,
    shouldSkipCompression,
  ];
}
