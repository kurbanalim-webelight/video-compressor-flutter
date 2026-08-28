part of 'video_compression_bloc.dart';

sealed class VideoCompressionEvent extends Equatable {
  const VideoCompressionEvent();

  @override
  List<Object?> get props => const [];
}

final class VideoPickRequested extends VideoCompressionEvent {
  const VideoPickRequested(this.source);

  final VideoSource source;

  @override
  List<Object?> get props => [source];
}

final class CompressionRequested extends VideoCompressionEvent {
  const CompressionRequested();
}

final class CompressionCancelRequested extends VideoCompressionEvent {
  const CompressionCancelRequested();
}

final class CompressionProgressReported extends VideoCompressionEvent {
  const CompressionProgressReported(this.fraction);

  final double fraction;

  @override
  List<Object?> get props => [fraction];
}

final class FlowResetRequested extends VideoCompressionEvent {
  const FlowResetRequested();
}
