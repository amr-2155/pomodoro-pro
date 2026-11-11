import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// Web implementation of the PWA helpers.
///
/// Previously `isStandalone` was hard-coded to `false`, so an already-installed
/// PWA kept advertising "install the app" in Settings. Reading the real
/// `display-mode` media query fixes that.
class PwaService {
  /// Always-newest APK of the **main app**. The GitHub release asset name is
  /// stable (`pomodoro-pro-arm64.apk`), so this URL never needs editing when a
  /// new version is published — unlike a versioned `releases/...` path.
  static const String apkUrl =
      'https://github.com/amr-2155/pomodoro-pro/releases/latest/download/pomodoro-pro-arm64.apk';

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

  /// Android browsers can install the real app (APK). A PWA shortcut is a
  /// different, weaker thing, so the UI offers the APK there instead.
  static bool get isAndroid {
    if (!kIsWeb) return false;
    try {
      return web.window.navigator.userAgent.toLowerCase().contains('android');
    } catch (_) {
      return false;
    }
  }

  /// Whether Settings should offer an install action at all.
  static bool get canOfferInstall => kIsWeb && !isStandalone;

  /// Opens the official APK download — the main app, not a PWA shortcut.
  static void downloadApk() {
    if (!kIsWeb) return;
    try {
      web.window.open(apkUrl, '_blank');
    } catch (_) {}
  }
}
