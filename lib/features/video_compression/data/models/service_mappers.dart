import '../../../../services/video/video_service.dart';
import '../../domain/entities/compression_outcome.dart';
import '../../domain/entities/compression_plan.dart';
import '../../domain/entities/video_codec.dart';
import '../../domain/entities/video_metadata.dart';
import '../../domain/entities/video_thumbnail.dart';

extension VideoDetailsMapper on VideoDetails {
  VideoMetadata toEntity() =>
      VideoMetadata(path: path, name: name, width: width, height: height, duration: duration, fileSizeBytes: sizeBytes);
}

extension VideoMetadataMapper on VideoMetadata {
  VideoDetails toDetails() =>
      VideoDetails(path: path, name: name, width: width, height: height, duration: duration, sizeBytes: fileSizeBytes);
}

extension VideoFrameMapper on VideoFrame {
  VideoThumbnail toEntity() => VideoThumbnail(path: path, position: position);
}

extension CompressionSettingsMapper on CompressionSettings {
  CompressionPlan toEntity() => CompressionPlan(
    targetWidth: width,
    targetHeight: height,
    videoBitrate: videoBitrate,
    audioBitrate: audioBitrate,
    frameRate: frameRate,
    codec: VideoCodec.h264,
    shouldSkipCompression: skipEncoding,
  );
}

extension CompressionOutputMapper on CompressionOutput {
  CompressionOutcome toEntity() => CompressionOutcome(
    outputPath: path,
    originalSizeBytes: originalSizeBytes,
    compressedSizeBytes: compressedSizeBytes,
    originalResolution: originalResolution,
    compressedResolution: compressedResolution,
    duration: duration,
    wasSkipped: skipped,
  );
}
