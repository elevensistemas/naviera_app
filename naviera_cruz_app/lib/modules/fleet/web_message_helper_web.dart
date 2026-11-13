import 'dart:convert';
import 'dart:html' as html;

DateTime? _lastWebMessageTime;

void listenToWebMessages(void Function() onStsClick) {
  html.window.onMessage.listen((event) {
    try {
      final data = event.data;
      if (data == null) return;

      final dataStr = data.toString();
      if (dataStr.contains('ncs_sts_click')) {
        final now = DateTime.now();
        if (_lastWebMessageTime != null && now.difference(_lastWebMessageTime!).inMilliseconds < 450) {
          html.window.console.log('[WebMessageHelper] Ignorando mensaje duplicado (debounce 450ms)');
          return;
        }
        _lastWebMessageTime = now;
        html.window.console.log('[WebMessageHelper] STS click ejecutado');
        onStsClick();
        return;
      }

      try {
        final decoded = jsonDecode(dataStr);
        if (decoded is Map && decoded['type'] == 'ncs_sts_click') {
          final now = DateTime.now();
          if (_lastWebMessageTime != null && now.difference(_lastWebMessageTime!).inMilliseconds < 450) {
            return;
          }
          _lastWebMessageTime = now;
          onStsClick();
          return;
        }
      } catch (_) {}
    } catch (e) {
      html.window.console.log('[WebMessageHelper] Error in onMessage: $e');
    }
  });
}
