import 'dart:async';
import 'package:flutter/services.dart';

class AudioService {
  static bool _alarmPlaying = false;
  static Timer? _alarmTimer;

  static void playTick() {
    try {
      SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }

  static void playFinish() {
    try {
      SystemSound.play(SystemSoundType.alert);
    } catch (_) {}
  }

  static void startAlarm() {
    if (_alarmPlaying) return;
    _alarmPlaying = true;
    _alarmLoop();
  }

  static void _alarmLoop() {
    if (!_alarmPlaying) return;
    try {
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.alert);
    } catch (_) {}
    _alarmTimer = Timer(const Duration(milliseconds: 700), _alarmLoop);
  }

  static void stopAlarm() {
    _alarmPlaying = false;
    _alarmTimer?.cancel();
    _alarmTimer = null;
  }

  static bool get isAlarmPlaying => _alarmPlaying;
}
