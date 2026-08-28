part of 'gallery_save_cubit.dart';

enum GallerySaveStatus { idle, saving, saved, permissionDenied, failed }

class GallerySaveState extends Equatable {
  const GallerySaveState({this.status = GallerySaveStatus.idle, this.failure});

  final GallerySaveStatus status;
  final AppFailure? failure;

  bool get isSaving => status == GallerySaveStatus.saving;

  bool get hasError => status == GallerySaveStatus.failed || status == GallerySaveStatus.permissionDenied;

  @override
  List<Object?> get props => [status, failure];
}
