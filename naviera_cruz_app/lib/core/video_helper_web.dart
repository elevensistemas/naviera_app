import 'dart:html' as html;
import 'dart:typed_data';
import 'package:video_player/video_player.dart';

Future<String> createBlobOrFileUrl(Uint8List bytes) async {
  final blob = html.Blob([bytes], 'video/mp4');
  return html.Url.createObjectUrlFromBlob(blob);
}

Future<String?> prepareVideoForPlayback(
  String rawUrl, {
  void Function(double progress, int received, int total)? onProgress,
}) async {
  onProgress?.call(1.0, 100, 100);
  return rawUrl;
}

VideoPlayerController createControllerForVideo(String resolvedPath) {
  return VideoPlayerController.networkUrl(
    Uri.parse(resolvedPath),
    videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
  );
}
