import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';

import '../../features/video_compression/data/repositories/gallery_repository_impl.dart';
import '../../features/video_compression/data/repositories/video_compression_repository_impl.dart';
import '../../features/video_compression/data/repositories/video_picker_repository_impl.dart';
import '../../features/video_compression/domain/repositories/gallery_repository.dart';
import '../../features/video_compression/domain/repositories/video_compression_repository.dart';
import '../../features/video_compression/domain/repositories/video_picker_repository.dart';
import '../../features/video_compression/presentation/bloc/video_compression_bloc.dart';
import '../../features/video_compression/presentation/cubit/gallery_save_cubit.dart';
import '../../services/video/video_service.dart';

final GetIt locator = GetIt.instance;

const CompressionLevel compressionLevel = CompressionLevel.balanced;

void configureDependencies() {
  locator
    ..registerLazySingleton(ImagePicker.new)
    ..registerLazySingleton(VideoService.new)
    ..registerLazySingleton<VideoCompressionRepository>(
      () => VideoCompressionRepositoryImpl(locator(), compressionLevel),
    )
    ..registerLazySingleton<VideoPickerRepository>(() => VideoPickerRepositoryImpl(locator()))
    ..registerLazySingleton<GalleryRepository>(() => const GalleryRepositoryImpl())
    ..registerFactory(
      () => VideoCompressionBloc(compressionRepository: locator(), pickerRepository: locator()),
    )
    ..registerFactory(() => GallerySaveCubit(locator()));
}
