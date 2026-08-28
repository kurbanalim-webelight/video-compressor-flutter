abstract final class Formatters {
  static String fileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    const kb = 1024.0;
    const mb = kb * 1024;
    const gb = mb * 1024;
    if (bytes >= gb) return '${(bytes / gb).toStringAsFixed(2)} GB';
    if (bytes >= mb) return '${(bytes / mb).toStringAsFixed(1)} MB';
    return '${(bytes / kb).toStringAsFixed(0)} KB';
  }

  static String duration(Duration value) {
    final minutes = value.inMinutes;
    final seconds = value.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  static String preciseDuration(Duration value) {
    final minutes = value.inMinutes;
    final seconds = value.inSeconds % 60;
    final tenths = (value.inMilliseconds % 1000) ~/ 100;
    return '$minutes:${seconds.toString().padLeft(2, '0')}.$tenths';
  }

  static String bitrate(int bitsPerSecond) {
    final mbps = bitsPerSecond / 1000000;
    if (mbps >= 1) return '${mbps.toStringAsFixed(1)} Mbps';
    return '${(bitsPerSecond / 1000).toStringAsFixed(0)} kbps';
  }

  static String percent(double fraction) => '${(fraction * 100).clamp(0, 100).toStringAsFixed(0)}%';
}
