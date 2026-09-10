import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Keeps a compression job alive while the app is off screen.
///
/// Encoding runs inside this process, so the job dies when the process is
/// frozen or killed. This holds the process up for as long as each platform
/// allows, and keeps the screen awake so the common case never gets there:
///
/// - Android: a `mediaProcessing` foreground service with a progress
///   notification. Lasts as long as the encode needs.
/// - iOS 26+: a `BGContinuedProcessingTask`, which draws its own system
///   progress UI and survives backgrounding.
/// - iOS 13-25: a background task assertion worth roughly thirty seconds.
///   Nothing longer exists, so [supportsBackground] reports false and the
///   caller should tell the user to stay on the screen.
///
/// Every call swallows its own errors. This class only babysits the encode,
/// so it must never be the reason one fails.
class BackgroundTask {
  BackgroundTask({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('com.webelight.poc/background_task');

  final MethodChannel _channel;

  bool? _supportsBackground;
  int _lastPercent = -1;
  bool _unavailable = false;

  /// Whether the encode survives the app leaving the screen.
  ///
  /// Cached after the first call: the answer cannot change while the app runs.
  Future<bool> supportsBackground() async {
    final cached = _supportsBackground;
    if (cached != null) return cached;

    final answer = await _call<bool>('supportsBackground') ?? false;
    _supportsBackground = answer;
    _note(answer ? 'platform can encode in the background' : 'platform cannot encode in the background');
    return answer;
  }

  /// Asks for anything needed later, while the user is still choosing.
  ///
  /// Kept separate from [start] so the permission dialog lands when the user
  /// picks a video rather than on top of a job that has just begun.
  Future<void> prepare() async {
    if (!Platform.isAndroid) return;
    await _guard('notification permission', _requestNotifications);
  }

  /// Starts holding the process up and keeps the screen awake.
  ///
  /// [title] and [subtitle] are shown to the user in the Android notification
  /// and in the iOS system progress UI, so keep them short and readable.
  Future<void> start({required String title, required String subtitle}) async {
    _lastPercent = -1;
    _note('starting: $title / $subtitle');
    await _guard('wakelock', WakelockPlus.enable);
    await _call<void>('start', {'title': title, 'subtitle': subtitle});
  }

  /// Reports how far the encode has got, at most once per whole percent.
  ///
  /// Android throttles notification updates and iOS wants progress reported
  /// continuously, so a whole percent is the granularity that suits both.
  Future<void> update(double progress) async {
    final percent = (progress.clamp(0.0, 1.0) * 100).round();
    if (percent == _lastPercent) return;
    _lastPercent = percent;
    await _call<void>('update', {'progress': percent / 100});
  }

  /// Releases the process and the screen. Safe to call when nothing started.
  Future<void> stop() async {
    _lastPercent = -1;
    _note('stopping');
    await _call<void>('stop');
    await _guard('wakelock', WakelockPlus.disable);
  }

  /// Android 13+ hides the notification without this, though the foreground
  /// service still runs. Asking is cheap and a refusal costs only the
  /// notification, so a denied permission is not treated as an error.
  Future<void> _requestNotifications() async {
    if (await Permission.notification.isGranted) return;
    final status = await Permission.notification.request();
    _note('notification permission ${status.name}');
  }

  Future<T?> _call<T>(String method, [Map<String, Object?>? arguments]) async {
    if (_unavailable) return null;

    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on MissingPluginException catch (error, stackTrace) {
      // Nothing is listening on the native side and nothing ever will be, so
      // stop asking. Progress arrives many times a second, and retrying each
      // one buries the rest of the log in identical stack traces.
      _unavailable = true;
      _log('channel unavailable, giving up', error, stackTrace);
      return null;
    } catch (error, stackTrace) {
      _log(method, error, stackTrace);
      return null;
    }
  }

  Future<void> _guard(String what, Future<void> Function() action) async {
    try {
      await action();
    } catch (error, stackTrace) {
      _log(what, error, stackTrace);
    }
  }

  void _note(String message) {
    developer.log(message, name: 'background_task');
  }

  void _log(String what, Object error, StackTrace stackTrace) {
    developer.log('$what failed', name: 'background_task', level: 900, error: error, stackTrace: stackTrace);
  }
}
