import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioPlayer _tickPlayer = AudioPlayer();
  static final AudioPlayer _finishPlayer = AudioPlayer();
  static final AudioPlayer _alarmPlayer = AudioPlayer();
  static bool _alarmPlaying = false;
  static Timer? _alarmTimer;
  static bool _ready = false;

  static Future<void> _ensureReady() async {
    if (_ready) return;
    _ready = true;
    try {
      await _alarmPlayer.setReleaseMode(ReleaseMode.loop);
    } catch (_) {}
  }

  static Future<void> playTick() async {
    try {
      await _tickPlayer.stop();
      await _tickPlayer.play(AssetSource('sounds/tick.wav'), volume: 0.5);
    } catch (_) {}
  }

  static Future<void> playFinish() async {
    try {
      await _finishPlayer.stop();
      await _finishPlayer.play(AssetSource('sounds/finish.wav'), volume: 0.9);
    } catch (_) {}
  }

  static Future<void> startAlarm() async {
    if (_alarmPlaying) return;
    _alarmPlaying = true;
    await _ensureReady();
    try {
      await _alarmPlayer.play(AssetSource('sounds/alarm.wav'), volume: 1.0);
    } catch (_) {}
    _alarmTimer?.cancel();
    _alarmTimer = Timer(const Duration(seconds: 30), () async {
      await stopAlarm();
    });
  }

  static Future<void> stopAlarm() async {
    _alarmPlaying = false;
    _alarmTimer?.cancel();
    _alarmTimer = null;
    try {
      await _alarmPlayer.stop();
    } catch (_) {}
  }

  static bool get isAlarmPlaying => _alarmPlaying;

  static Future<void> dispose() async {
    try {
      await _tickPlayer.dispose();
      await _finishPlayer.dispose();
      await _alarmPlayer.dispose();
    } catch (_) {}
  }
}
