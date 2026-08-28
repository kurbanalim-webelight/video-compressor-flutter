import 'package:equatable/equatable.dart';

class VideoThumbnail extends Equatable {
  const VideoThumbnail({required this.path, required this.position});

  final String path;
  final Duration position;

  @override
  List<Object?> get props => [path, position];
}
