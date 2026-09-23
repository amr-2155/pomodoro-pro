import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

import 'completion_sound.dart';
import 'database_service.dart';
import 'vibration_service.dart';
import 'notification_service.dart';

class AudioService {
  static final AudioPlayer _previewPlayer = AudioPlayer();
  static final AudioPlayer _completionPlayer = AudioPlayer();
  static final AudioPlayer _countdownPlayer = AudioPlayer();
  static bool _ready = false;

  static bool _completionLooping = false;
  static bool get isCompletionLooping => _completionLooping;
  static Timer? _vibrationTimer;

  static AudioContext get _audioContext => AudioContext(
        android: AudioContextAndroid(
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.alarm,
          audioFocus: AndroidAudioFocus.gain,
          stayAwake: true,
        ),
      );

  static Future<void> _ensureReady() async {
    if (_ready) return;
    _ready = true;
    try {
      await _completionPlayer.setAudioContext(_audioContext);
      await _countdownPlayer.setAudioContext(_audioContext);
    } catch (_) {}
  }

  static Future<void> playPreview(CompletionSoundType type) async {
    try {
      await _ensureReady();
      await _previewPlayer.stop();
      await _previewPlayer.play(AssetSource(type.asset), volume: 0.8);
    } catch (_) {}
  }

  static Future<void> playCountdownPreview(CountdownSoundType type) async {
    try {
      await _ensureReady();
      await _previewPlayer.stop();
      await _previewPlayer.play(AssetSource(type.asset), volume: 0.4);
    } catch (_) {}
  }

  static Future<void> stopPreview() async {
    try {
      await _previewPlayer.stop();
    } catch (_) {}
  }

  static bool _previewPlaying = false;
  static bool get isPreviewPlaying => _previewPlaying;

  static StreamSubscription? _previewStreamSub;

  static Future<void> playPreviewTracked(CompletionSoundType type) async {
    _previewPlaying = true;
    await playPreview(type);
    _monitorPreview();
  }

  static Future<void> playCountdownPreviewTracked(CountdownSoundType type) async {
    _previewPlaying = true;
    await playCountdownPreview(type);
    _monitorPreview();
  }

  static void _monitorPreview() {
    _previewStreamSub?.cancel();
    _previewStreamSub = _previewPlayer.onPlayerComplete.listen((_) {
      _previewPlaying = false;
    });
    _previewPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.stopped || state == PlayerState.completed) {
        _previewPlaying = false;
      }
    });
  }

  static Future<void> playCompletionSound([CompletionSoundType? type]) async {
    try {
      await _ensureReady();
      await _completionPlayer.stop();
      final sound = type ?? completionSoundFromKey('soft_bell');
      await _completionPlayer.play(AssetSource(sound.asset), volume: 0.9);
    } catch (_) {}
  }

  static Future<void> startCompletionLoop([CompletionSoundType? type]) async {
    _completionLooping = true;
    _startVibrationLoop();
    // Start repeating OS notification for continuous vibration in background.
    _startRepeatNotification();
    if (type != null) {
      await _ensureReady();
      try {
        await _completionPlayer.stop();
        await _completionPlayer.setReleaseMode(ReleaseMode.loop);
        await _completionPlayer.play(AssetSource(type.asset), volume: 0.9);
      } catch (_) {}
    }
  }

  static Future<void> startVibrationOnly() async {
    _completionLooping = true;
    _startVibrationLoop();
  }

  static void _startVibrationLoop() {
    _vibrationTimer?.cancel();
    if (!DatabaseService.completionVibrationEnabled) return;
    try {
      _strongPulse();
      // Repeat every 1.8s for a persistent, aggressive pattern.
      _vibrationTimer = Timer.periodic(const Duration(milliseconds: 1800), (_) {
        if (_completionLooping) _strongPulse();
      });
    } catch (_) {}
  }

  static void _strongPulse() {
    // Maximum-strength: native vibrator pattern [vibrate,pause,vibrate,pause,vibrate].
    VibrationService.pattern(
      timings: [400, 120, 400, 120, 500],
      amplitudes: [255, 0, 255, 0, 255],
    );
  }

  /// Starts a repeating OS notification with strong vibration.
  /// Works even when app is backgrounded or killed (unlike Timer.periodic).
  static void _startRepeatNotification() {
    if (!DatabaseService.completionVibrationEnabled) return;
    NotificationService.startRepeatVibration(
      title: 'Pomodoro',
      body: 'Session complete!',
      intervalMs: 2500,
    );
  }

  static Future<void> stopCompletionLoop() async {
    if (!_completionLooping) return;
    _completionLooping = false;
    _vibrationTimer?.cancel();
    _vibrationTimer = null;
    NotificationService.cancelRepeatVibration();
    try {
      await _completionPlayer.setReleaseMode(ReleaseMode.release);
      await _completionPlayer.stop();
    } catch (_) {}
  }

  static Future<void> playCountdownTick([CountdownSoundType? type]) async {
    try {
      await _ensureReady();
      await _countdownPlayer.stop();
      final sound = type ?? countdownSoundFromKey('water_drops');
      await _countdownPlayer.play(AssetSource(sound.asset), volume: 0.3);
    } catch (_) {}
  }

  static Future<void> stopAllSounds() async {
    try {
      _completionLooping = false;
      _vibrationTimer?.cancel();
      _vibrationTimer = null;
      NotificationService.cancelRepeatVibration();
      await _previewPlayer.stop();
      await _completionPlayer.setReleaseMode(ReleaseMode.release);
      await _completionPlayer.stop();
      await _countdownPlayer.stop();
      _previewPlaying = false;
      _previewStreamSub?.cancel();
    } catch (_) {}
  }

  static Future<void> dispose() async {
    try {
      _vibrationTimer?.cancel();
      await _previewPlayer.dispose();
      await _completionPlayer.dispose();
      await _countdownPlayer.dispose();
    } catch (_) {}
  }
}
