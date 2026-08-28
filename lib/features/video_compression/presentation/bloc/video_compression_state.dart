part of 'video_compression_bloc.dart';

enum VideoCompressionStatus { initial, picking, analyzing, ready, compressing, completed, failed }

class VideoCompressionState extends Equatable {
  const VideoCompressionState({
    this.status = VideoCompressionStatus.initial,
    this.source,
    this.metadata,
    this.thumbnailPath,
    this.plan,
    this.progress = 0,
    this.outcome,
    this.failure,
  });

  final VideoCompressionStatus status;
  final File? source;
  final VideoMetadata? metadata;
  final String? thumbnailPath;
  final CompressionPlan? plan;
  final double progress;
  final CompressionOutcome? outcome;
  final AppFailure? failure;

  bool get isBusy => status == VideoCompressionStatus.picking || status == VideoCompressionStatus.analyzing;

  VideoCompressionState copyWith({
    VideoCompressionStatus? status,
    File? source,
    VideoMetadata? metadata,
    String? thumbnailPath,
    CompressionPlan? plan,
    double? progress,
    CompressionOutcome? outcome,
    AppFailure? failure,
    bool clearFailure = false,
    bool clearOutcome = false,
  }) {
    return VideoCompressionState(
      status: status ?? this.status,
      source: source ?? this.source,
      metadata: metadata ?? this.metadata,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      plan: plan ?? this.plan,
      progress: progress ?? this.progress,
      outcome: clearOutcome ? null : outcome ?? this.outcome,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }

  @override
  List<Object?> get props => [status, source?.path, metadata, thumbnailPath, plan, progress, outcome, failure];
}
