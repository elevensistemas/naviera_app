import 'dart:html' as html;
import 'dart:typed_data';

Future<String> createBlobOrFileUrl(Uint8List bytes) async {
  final blob = html.Blob([bytes], 'video/mp4');
  return html.Url.createObjectUrlFromBlob(blob);
}
