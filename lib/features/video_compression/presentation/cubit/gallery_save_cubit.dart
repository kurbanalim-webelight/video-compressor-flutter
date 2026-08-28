import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/app_failure.dart';
import '../../domain/repositories/gallery_repository.dart';

part 'gallery_save_state.dart';

class GallerySaveCubit extends Cubit<GallerySaveState> {
  GallerySaveCubit(this._repository) : super(const GallerySaveState());

  final GalleryRepository _repository;

  Future<void> save(File file) async {
    if (state.isSaving) return;
    emit(const GallerySaveState(status: GallerySaveStatus.saving));

    final result = await _repository.saveVideo(file);

    emit(
      result.fold(
        onSuccess: (_) => const GallerySaveState(status: GallerySaveStatus.saved),
        onFailure: (failure) => GallerySaveState(
          status: failure is GalleryPermissionDeniedFailure
              ? GallerySaveStatus.permissionDenied
              : GallerySaveStatus.failed,
          failure: failure,
        ),
      ),
    );
  }

  void reset() => emit(const GallerySaveState());
}
