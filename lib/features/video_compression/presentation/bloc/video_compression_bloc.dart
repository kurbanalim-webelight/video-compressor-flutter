import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../services/background/background_task.dart';
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
    BackgroundTask? backgroundTask,
  }) : _compression = compressionRepository,
       _picker = pickerRepository,
       _backgroundTask = backgroundTask ?? BackgroundTask(),
       super(const VideoCompressionState()) {
    on<VideoPickRequested>(_onVideoPickRequested);
    on<CompressionRequested>(_onCompressionRequested);
    on<CompressionCancelRequested>(_onCompressionCancelRequested);
    on<CompressionProgressReported>(_onCompressionProgressReported);
    on<AppLifecycleChanged>(_onAppLifecycleChanged);
    on<FlowResetRequested>(_onFlowResetRequested);

    _progressSubscription = _compression.progress.listen(
      (progress) => add(CompressionProgressReported(progress.fraction)),
    );
    _lifecycle = AppLifecycleListener(onStateChange: (state) => add(AppLifecycleChanged(state)));
  }

  final VideoCompressionRepository _compression;
  final VideoPickerRepository _picker;
  final BackgroundTask _backgroundTask;

  late final StreamSubscription<void> _progressSubscription;
  late final AppLifecycleListener _lifecycle;

  /// Which tenth of the job has been logged, so progress is reported once
  /// every ten percent instead of the many times a second it arrives.
  int _loggedTenth = -1;

  Future<void> _onVideoPickRequested(VideoPickRequested event, Emitter<VideoCompressionState> emit) async {
    // Asked here rather than at compression time so the dialog does not land
    // on top of a job that has already started.
    await _backgroundTask.prepare();

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
        stalledInBackground: false,
        clearFailure: true,
        clearOutcome: true,
      ),
    );

    _loggedTenth = -1;
    AppLogger.info(
      'compression started: ${metadata.width}x${metadata.height} '
      '(${Formatters.fileSize(metadata.fileSizeBytes)}) -> ${plan.resolutionLabel}',
    );

    await _backgroundTask.start(title: 'Compressing video', subtitle: plan.resolutionLabel);

    try {
      final result = await _compression.compress(source, plan);

      result.fold(
        onSuccess: (outcome) {
          AppLogger.info(
            'compression completed: ${Formatters.fileSize(outcome.originalSizeBytes)} -> '
            '${Formatters.fileSize(outcome.compressedSizeBytes)} '
            '(${(outcome.savedFraction * 100).round()}% saved)'
            '${outcome.wasSkipped ? ', source kept as-is' : ''}',
          );
          emit(state.copyWith(status: VideoCompressionStatus.completed, progress: 1, outcome: outcome));
        },
        onFailure: (failure) {
          if (failure is CompressionCancelledFailure) {
            AppLogger.info('compression cancelled');
            emit(state.copyWith(status: VideoCompressionStatus.ready, progress: 0));
          } else {
            AppLogger.error('compression failed: ${failure.userMessage}');
            emit(state.copyWith(status: VideoCompressionStatus.failed, progress: 0, failure: failure));
          }
        },
      );
    } finally {
      await _backgroundTask.stop();
    }
  }

  Future<void> _onCompressionCancelRequested(
    CompressionCancelRequested event,
    Emitter<VideoCompressionState> emit,
  ) async {
    if (state.status != VideoCompressionStatus.compressing) return;
    await _compression.cancel();
  }

  Future<void> _onCompressionProgressReported(
    CompressionProgressReported event,
    Emitter<VideoCompressionState> emit,
  ) async {
    if (state.status != VideoCompressionStatus.compressing) return;
    emit(state.copyWith(progress: event.fraction));
    _logProgress(event.fraction);
    await _backgroundTask.update(event.fraction);
  }

  void _logProgress(double fraction) {
    final tenth = (fraction.clamp(0.0, 1.0) * 10).floor();
    if (tenth == _loggedTenth) return;
    _loggedTenth = tenth;
    AppLogger.info('compressing ${tenth * 10}%');
  }

  /// Records that the app went away mid-encode on a platform that cannot
  /// carry on without it.
  ///
  /// The flag is deliberately not cleared when the app comes back: the user
  /// is only there to read it once they return, and a stalled encode that
  /// says so beats a progress bar that stopped in silence.
  Future<void> _onAppLifecycleChanged(AppLifecycleChanged event, Emitter<VideoCompressionState> emit) async {
    final isCompressing = state.status == VideoCompressionStatus.compressing;
    AppLogger.info('app ${event.state.name}${isCompressing ? ' while compressing' : ''}');

    if (event.state != AppLifecycleState.paused) return;
    if (!isCompressing) return;

    if (await _backgroundTask.supportsBackground()) {
      AppLogger.info('backgrounded mid-encode; the platform is carrying on');
      return;
    }

    AppLogger.info('backgrounded mid-encode; this platform cannot continue, so the job has stalled');
    emit(state.copyWith(stalledInBackground: true));
  }

  void _onFlowResetRequested(FlowResetRequested event, Emitter<VideoCompressionState> emit) {
    emit(const VideoCompressionState());
  }

  VideoCompressionStatus get _statusBeforePick =>
      state.metadata == null ? VideoCompressionStatus.initial : VideoCompressionStatus.ready;

  @override
  Future<void> close() {
    _progressSubscription.cancel();
    _lifecycle.dispose();
    return super.close();
  }
}
