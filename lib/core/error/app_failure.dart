import 'package:equatable/equatable.dart';

sealed class AppFailure extends Equatable {
  const AppFailure();

  String get userMessage;

  @override
  List<Object?> get props => [userMessage];
}

final class VideoPickFailure extends AppFailure {
  const VideoPickFailure();

  @override
  String get userMessage => 'We could not open your video. Please try picking it again.';
}

final class CameraPermissionDeniedFailure extends AppFailure {
  const CameraPermissionDeniedFailure({required this.permanentlyDenied});

  final bool permanentlyDenied;

  @override
  String get userMessage => permanentlyDenied
      ? 'Camera access is turned off. Enable it in Settings to record a video.'
      : 'Camera access is needed to record a video.';

  @override
  List<Object?> get props => [permanentlyDenied];
}

final class VideoAnalysisFailure extends AppFailure {
  const VideoAnalysisFailure();

  @override
  String get userMessage => 'This file could not be read as a video. Try a different one.';
}

final class CompressionFailure extends AppFailure {
  const CompressionFailure();

  @override
  String get userMessage => 'Compression did not finish. Your original video is untouched.';
}

final class CompressionCancelledFailure extends AppFailure {
  const CompressionCancelledFailure();

  @override
  String get userMessage => 'Compression cancelled.';
}

final class GalleryPermissionDeniedFailure extends AppFailure {
  const GalleryPermissionDeniedFailure();

  @override
  String get userMessage => 'Photo library access is needed to save this video.';
}

final class GallerySaveFailure extends AppFailure {
  const GallerySaveFailure();

  @override
  String get userMessage => 'The video could not be saved to your gallery.';
}
