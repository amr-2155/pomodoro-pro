import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// Web implementation of the PWA helpers.
///
/// Previously `isStandalone` was hard-coded to `false`, so an already-installed
/// PWA kept advertising "install the app" in Settings. Reading the real
/// `display-mode` media query fixes that.
class PwaService {
  static bool _installable = false;

  static void init() {
    if (!kIsWeb) return;
    try {
      web.window.addEventListener(
        'beforeinstallprompt',
        ((web.Event _) {
          _installable = true;
        }).toJS,
      );
    } catch (_) {}
  }

  static bool get isInstallable => _installable;

  /// True when the page is running as an installed app (standalone display
  /// mode) rather than inside a browser tab.
  static bool get isStandalone {
    if (!kIsWeb) return false;
    try {
      return web.window.matchMedia('(display-mode: standalone)').matches;
    } catch (_) {
      return false;
    }
  }
}
