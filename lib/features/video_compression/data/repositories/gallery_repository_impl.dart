import 'dart:io';

import 'package:gal/gal.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/repositories/gallery_repository.dart';

class GalleryRepositoryImpl implements GalleryRepository {
  const GalleryRepositoryImpl();

  @override
  Future<Result<void>> saveVideo(File file) async {
    try {
      if (!await file.exists()) return const Failed(GallerySaveFailure());

      if (!await Gal.hasAccess()) {
        final granted = await Gal.requestAccess();
        if (!granted) return const Failed(GalleryPermissionDeniedFailure());
      }

      await Gal.putVideo(file.path);
      return const Success(null);
    } on GalException catch (error, stackTrace) {
      AppLogger.error('Gallery save failed', error, stackTrace);
      return Failed(
        error.type == GalExceptionType.accessDenied
            ? const GalleryPermissionDeniedFailure()
            : const GallerySaveFailure(),
      );
    } catch (error, stackTrace) {
      AppLogger.error('Gallery save failed', error, stackTrace);
      return const Failed(GallerySaveFailure());
    }
  }
}
