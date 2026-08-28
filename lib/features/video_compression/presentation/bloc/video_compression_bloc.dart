import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/app_failure.dart';
import '../../domain/entities/compression_outcome.dart';
import '../../domain/entities/compression_plan.dart';
import '../../domain/entities/video_metadata.dart';
import '../../domain/entities/video_source.dart';
import '../../domain/repositories/video_compression_repository.dart';
import '../../domain/repositories/video_picker_repository.dart';

part 'video_compression_event.dart';
part 'video_compression_state.dart';

class VideoCompressionBloc extends Bloc<VideoCompressionEvent, VideoCompressionState> {
  VideoCompressionBloc({
    required VideoCompressionRepository compressionRepository,
    required VideoPickerRepository pickerRepository,
  }) : _compression = compressionRepository,
       _picker = pickerRepository,
       super(const VideoCompressionState()) {
    on<VideoPickRequested>(_onVideoPickRequested);
    on<CompressionRequested>(_onCompressionRequested);
    on<CompressionCancelRequested>(_onCompressionCancelRequested);
    on<CompressionProgressReported>(_onCompressionProgressReported);
    on<FlowResetRequested>(_onFlowResetRequested);

    _progressSubscription = _compression.progress.listen(
      (progress) => add(CompressionProgressReported(progress.fraction)),
    );
  }

  final VideoCompressionRepository _compression;
  final VideoPickerRepository _picker;

  late final StreamSubscription<void> _progressSubscription;

  Future<void> _onVideoPickRequested(VideoPickRequested event, Emitter<VideoCompressionState> emit) async {
    emit(state.copyWith(status: VideoCompressionStatus.picking, clearFailure: true));

    final picked = await _picker.pick(event.source);

    await picked.fold(
      onSuccess: (file) async {
        if (file == null) {
          emit(state.copyWith(status: _statusBeforePick));
          return;
        }
        await _analyze(file, emit);
      },
      onFailure: (failure) async => emit(state.copyWith(status: VideoCompressionStatus.failed, failure: failure)),
    );
  }

  Future<void> _analyze(File file, Emitter<VideoCompressionState> emit) async {
    emit(const VideoCompressionState(status: VideoCompressionStatus.analyzing).copyWith(source: file));

    final analysis = await _compression.analyze(file);

    await analysis.fold(
      onSuccess: (metadata) async {
        final thumbnail = await _compression.thumbnail(
          file,
          Duration(milliseconds: metadata.duration.inMilliseconds ~/ 10),
        );
        emit(
          state.copyWith(
            status: VideoCompressionStatus.ready,
            metadata: metadata,
            plan: _compression.buildPlan(metadata),
            thumbnailPath: thumbnail.fold(onSuccess: (frame) => frame?.path, onFailure: (_) => null),
          ),
        );
      },
      onFailure: (failure) async => emit(state.copyWith(status: VideoCompressionStatus.failed, failure: failure)),
    );
  }

  Future<void> _onCompressionRequested(CompressionRequested event, Emitter<VideoCompressionState> emit) async {
    final source = state.source;
    final metadata = state.metadata;
    if (source == null || metadata == null) return;

    final plan = _compression.buildPlan(metadata);

    emit(
      state.copyWith(
        status: VideoCompressionStatus.compressing,
        plan: plan,
        progress: 0,
        clearFailure: true,
        clearOutcome: true,
      ),
    );

    final result = await _compression.compress(source, plan);

    result.fold(
      onSuccess: (outcome) =>
          emit(state.copyWith(status: VideoCompressionStatus.completed, progress: 1, outcome: outcome)),
      onFailure: (failure) => emit(
        failure is CompressionCancelledFailure
            ? state.copyWith(status: VideoCompressionStatus.ready, progress: 0)
            : state.copyWith(status: VideoCompressionStatus.failed, progress: 0, failure: failure),
      ),
    );
  }

  Future<void> _onCompressionCancelRequested(
    CompressionCancelRequested event,
    Emitter<VideoCompressionState> emit,
  ) async {
    if (state.status != VideoCompressionStatus.compressing) return;
    await _compression.cancel();
  }

  void _onCompressionProgressReported(CompressionProgressReported event, Emitter<VideoCompressionState> emit) {
    if (state.status != VideoCompressionStatus.compressing) return;
    emit(state.copyWith(progress: event.fraction));
  }

  void _onFlowResetRequested(FlowResetRequested event, Emitter<VideoCompressionState> emit) {
    emit(const VideoCompressionState());
  }

  VideoCompressionStatus get _statusBeforePick =>
      state.metadata == null ? VideoCompressionStatus.initial : VideoCompressionStatus.ready;

  @override
  Future<void> close() {
    _progressSubscription.cancel();
    return super.close();
  }
}
