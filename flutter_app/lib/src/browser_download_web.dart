import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'alooy_policy.dart';

@JS('document')
external JSObject get _document;

/// Hand the validated public file to the browser; never buffer a movie in RAM.
/// Cross-origin download behavior is ultimately controlled by browser/upstream.
void startBrowserDownload(Uri uri, String name, Map<String, String> headers) {
  if (!isPublicMediaUri(uri) || !uri.path.toLowerCase().endsWith('.mp4')) {
    throw const FormatException('INVALID_DOWNLOAD_REFERENCE');
  }
  // Anchors cannot attach provider cookies, Referer or custom User-Agent.
  if (headers.isNotEmpty) {
    throw const FormatException('BROWSER_DOWNLOAD_HEADERS_REQUIRED');
  }
  final safeName = name.replaceAll(RegExp(r'[\x00-\x1f/\\:*?"<>|]'), '_');
  final anchor = _document.callMethod<JSObject>('createElement'.toJS, 'a'.toJS);
  anchor.setProperty('href'.toJS, uri.toString().toJS);
  anchor.setProperty(
    'download'.toJS,
    '${safeName.substring(0, safeName.length.clamp(0, 160))}.mp4'.toJS,
  );
  anchor.setProperty('target'.toJS, '_blank'.toJS);
  anchor.setProperty('rel'.toJS, 'noopener noreferrer'.toJS);
  _document
      .getProperty<JSObject>('body'.toJS)
      .callMethod<JSAny?>('appendChild'.toJS, anchor);
  try {
    anchor.callMethod<JSAny?>('click'.toJS);
  } finally {
    anchor.callMethod<JSAny?>('remove'.toJS);
  }
}
