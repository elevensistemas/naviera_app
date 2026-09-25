import 'dart:io';
import 'dart:typed_data';

Future<String> createBlobOrFileUrl(Uint8List bytes) async {
  final tempDir = Directory.systemTemp;
  final file = File('${tempDir.path}/training_video_${DateTime.now().millisecondsSinceEpoch}.mp4');
  await file.writeAsBytes(bytes);
  return file.path;
}
