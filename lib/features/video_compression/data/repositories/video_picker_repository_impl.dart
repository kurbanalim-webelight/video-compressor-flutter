import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/video_source.dart';
import '../../domain/repositories/video_picker_repository.dart';

class VideoPickerRepositoryImpl implements VideoPickerRepository {
  const VideoPickerRepositoryImpl(this._picker);

  final ImagePicker _picker;

  @override
  Future<Result<File?>> pick(VideoSource source) async {
    if (source == VideoSource.camera) {
      final denial = await _ensureCameraAccess();
      if (denial != null) return Failed(denial);
    }

    try {
      final picked = switch (source) {
        VideoSource.gallery => await _picker.pickVideo(source: ImageSource.gallery),
        VideoSource.camera => await _picker.pickVideo(
          source: ImageSource.camera,
          preferredCameraDevice: CameraDevice.rear,
        ),
      };
      return Success(picked == null ? null : File(picked.path));
    } catch (error, stackTrace) {
      AppLogger.error('Video pick failed', error, stackTrace);
      return const Failed(VideoPickFailure());
    }
  }

  Future<AppFailure?> _ensureCameraAccess() async {
    final status = await Permission.camera.request();
    if (status.isGranted || status.isLimited) return null;
    return CameraPermissionDeniedFailure(permanentlyDenied: status.isPermanentlyDenied);
  }
}
