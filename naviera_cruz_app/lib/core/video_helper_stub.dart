import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

Future<String> createBlobOrFileUrl(Uint8List bytes) async {
  final tempDir = Directory.systemTemp;
  final file = File('${tempDir.path}/training_video_${DateTime.now().millisecondsSinceEpoch}.mp4');
  await file.writeAsBytes(bytes);
  return file.path;
}

/// Prepara y almacena en caché local el video de capacitación marítima.
/// En iOS AVPlayer requiere soporte de Range Requests (206 Partial Content).
/// Dado que el servidor Django no provee 206, descargar el video a disco local
/// permite que AVPlayer reproduzca el archivo directamente con rendimiento óptimo.
Future<String?> prepareVideoForPlayback(
  String rawUrl, {
  void Function(double progress, int received, int total)? onProgress,
}) async {
  if (rawUrl.isEmpty) return null;

  try {
    final safeName = rawUrl.split('?').first.split('/').last.replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '_');
    final hash = rawUrl.hashCode.abs();
    final tempDir = Directory.systemTemp;
    final cacheDir = Directory('${tempDir.path}/ncs_courses');
    if (!cacheDir.existsSync()) {
      cacheDir.createSync(recursive: true);
    }

    final cachedFile = File('${cacheDir.path}/${hash}_$safeName');
    // Si ya fue descargado previamente y tiene tamaño válido (> 500 KB), reutilizarlo de inmediato
    if (cachedFile.existsSync() && cachedFile.lengthSync() > 500000) {
      onProgress?.call(1.0, cachedFile.lengthSync(), cachedFile.lengthSync());
      return cachedFile.path;
    }

    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(rawUrl));
      final response = await client.send(request);

      if (response.statusCode != 200 && response.statusCode != 206) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final totalBytes = response.contentLength ?? 0;
      final tempDownloadingFile = File('${cachedFile.path}.tmp');
      final sink = tempDownloadingFile.openWrite();
      int receivedBytes = 0;

      await for (final chunk in response.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0) {
          onProgress?.call(receivedBytes / totalBytes, receivedBytes, totalBytes);
        } else {
          onProgress?.call(0.5, receivedBytes, 0);
        }
      }

      await sink.flush();
      await sink.close();

      if (tempDownloadingFile.existsSync() && tempDownloadingFile.lengthSync() > 100000) {
        if (cachedFile.existsSync()) cachedFile.deleteSync();
        tempDownloadingFile.renameSync(cachedFile.path);
        return cachedFile.path;
      }
    } finally {
      client.close();
    }
  } catch (e) {
    // Si falla la descarga local, devolver la URL original como último recurso
    return rawUrl;
  }
  return rawUrl;
}

VideoPlayerController createControllerForVideo(String resolvedPath) {
  if (resolvedPath.startsWith('http://') || resolvedPath.startsWith('https://')) {
    return VideoPlayerController.networkUrl(
      Uri.parse(resolvedPath),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
  }
  return VideoPlayerController.file(
    File(resolvedPath),
    videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
  );
}
