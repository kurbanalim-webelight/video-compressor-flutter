import 'dart:io';

import '../../../../core/error/result.dart';

abstract interface class GalleryRepository {
  Future<Result<void>> saveVideo(File file);
}
