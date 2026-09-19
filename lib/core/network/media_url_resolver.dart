import 'package:flutter/foundation.dart';

class MediaUrlResolver {
  const MediaUrlResolver._();
  static String resolve(String? value, {required String apiBaseUrl}) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) return '';
    final parsed = Uri.tryParse(raw);
    if (parsed != null && parsed.hasScheme) {
      if (!kIsWeb && parsed.host == 'localhost') {
        return parsed.replace(host: '10.0.2.2').toString();
      }
      return raw;
    }
    final api = Uri.parse(apiBaseUrl);
    final mediaRoot = api.replace(path: '', query: null, fragment: null);
    return mediaRoot.resolve(raw.startsWith('/') ? raw : '/$raw').toString();
  }
}
