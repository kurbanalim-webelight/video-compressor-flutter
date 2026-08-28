import 'dart:io';

import '../../../../core/error/result.dart';
import '../entities/video_source.dart';

abstract interface class VideoPickerRepository {
  Future<Result<File?>> pick(VideoSource source);
}
