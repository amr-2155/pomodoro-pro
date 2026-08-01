import 'dart:js_interop';
import 'package:flutter/foundation.dart';

@JS()
@anonymous
extension type WindowEvent._(JSObject _) implements JSObject {
  external JSFunction addEventListener(String type, JSFunction? callback);
  external JSFunction removeEventListener(String type, JSFunction? callback);
}

@JS('window')
external WindowEvent get _window;

class PwaService {
  static bool _installable = false;

  static void init() {
    if (!kIsWeb) return;
    try {
      _window.addEventListener('beforeinstallprompt', (JSObject event) {
        _installable = true;
      }.toJS);
    } catch (_) {}
  }

  static bool get isInstallable => _installable;

  static bool get isStandalone {
    if (!kIsWeb) return false;
    try {
      return false;
    } catch (_) {
      return false;
    }
  }
}
