import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injector.dart';
import 'core/routes.dart';
import 'core/theme/app_theme.dart';
import 'features/video_compression/presentation/bloc/video_compression_bloc.dart';
import 'features/video_compression/presentation/screens/compression_progress_screen.dart';
import 'features/video_compression/presentation/screens/compression_result_screen.dart';
import 'features/video_compression/presentation/screens/select_video_screen.dart';
import 'features/video_compression/presentation/screens/upload_video_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  configureDependencies();
  runApp(const VideoCompressionApp());
}

class VideoCompressionApp extends StatelessWidget {
  const VideoCompressionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<VideoCompressionBloc>(),
      child: MaterialApp(
        title: 'Video Compression',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialRoute: AppRoutes.select,
        routes: {
          AppRoutes.select: (_) => const SelectVideoScreen(),
          AppRoutes.progress: (_) => const CompressionProgressScreen(),
          AppRoutes.result: (_) => const CompressionResultScreen(),
          AppRoutes.upload: (_) => const UploadVideoScreen(),
        },
      ),
    );
  }
}
