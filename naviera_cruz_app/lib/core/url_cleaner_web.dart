// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void cleanBrowserUrl() {
  try {
    html.window.history.replaceState(null, '', '/');
  } catch (_) {}
}
