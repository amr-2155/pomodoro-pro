class PwaService {
  /// Always-newest APK of the main app (same URL as the web build uses).
  static const String apkUrl =
      'https://github.com/amr-2155/pomodoro-pro/releases/latest/download/pomodoro-pro-arm64.apk';

  static void init() {}

  static bool get isInstallable => false;

  static bool get isStandalone => false;

  static bool get isAndroid => false;

  /// The native app is already installed — nothing to offer.
  static bool get canOfferInstall => false;

  static void downloadApk() {}
}
