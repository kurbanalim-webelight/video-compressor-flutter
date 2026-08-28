import 'dart:io';

import '../../../../core/error/app_failure.dart';
import '../../../../core/error/result.dart';
import '../../../../services/video/video_service.dart';
import '../../domain/entities/compression_outcome.dart';
import '../../domain/entities/compression_plan.dart';
import '../../domain/entities/compression_progress.dart';
import '../../domain/entities/video_metadata.dart';
import '../../domain/entities/video_thumbnail.dart';
import '../../domain/repositories/video_compression_repository.dart';
import '../models/service_mappers.dart';

class VideoCompressionRepositoryImpl implements VideoCompressionRepository {
  const VideoCompressionRepositoryImpl(this._service, this._level);

  final VideoService _service;
  final CompressionLevel _level;

  @override
  Stream<CompressionProgress> get progress => _service.progress.map(CompressionProgress.new);

  @override
  Future<Result<VideoMetadata>> analyze(File file) async {
    final details = await _service.inspect(file);
    if (details == null) return const Failed(VideoAnalysisFailure());
    return Success(details.toEntity());
  }

  @override
  Future<Result<VideoThumbnail?>> thumbnail(File file, Duration at) async {
    final frames = await _service.extractFrames(file, [at]);
    return Success(frames.isEmpty ? null : frames.first.toEntity());
  }

  @override
  CompressionPlan buildPlan(VideoMetadata metadata) => _service.plan(metadata.toDetails(), level: _level).toEntity();

  @override
  Future<Result<CompressionOutcome>> compress(File file, CompressionPlan plan) async {
    final result = await _service.compress(file, level: _level);

    return switch (result) {
      CompressionSucceeded(:final output) => Success(output.toEntity()),
      CompressionFailed(:final type) => Failed(_failureFor(type)),
    };
  }

  @override
  Future<void> cancel() => _service.cancel();

  AppFailure _failureFor(CompressionErrorType type) => switch (type) {
    CompressionErrorType.cancelled => const CompressionCancelledFailure(),
    CompressionErrorType.unreadableSource => const VideoAnalysisFailure(),
    CompressionErrorType.encodingFailed => const CompressionFailure(),
  };
}
