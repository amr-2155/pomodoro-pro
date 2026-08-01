import 'dart:async';
import 'package:web/web.dart' as web;

class AudioService {
  static bool _alarmPlaying = false;
  static Timer? _alarmTimer;

  static void _playTone(double frequency, int durationMs, double volume,
      {String type = 'sine'}) {
    try {
      final ctx = web.AudioContext();
      final osc = ctx.createOscillator();
      final gain = ctx.createGain();

      osc.type = type;
      osc.frequency.setValueAtTime(frequency, ctx.currentTime);
      gain.gain.setValueAtTime(volume, ctx.currentTime);
      gain.gain.exponentialRampToValueAtTime(
          0.001, ctx.currentTime + (durationMs / 1000.0));

      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start();
      Future.delayed(Duration(milliseconds: durationMs), () {
        try {
          osc.stop();
        } catch (_) {}
      });
    } catch (_) {}
  }

  static void playTick() {
    _playTone(800, 80, 0.03, type: 'sine');
  }

  static void playFinish() {
    try {
      final ctx = web.AudioContext();
      final osc = ctx.createOscillator();
      final gain = ctx.createGain();

      osc.type = 'sine';
      final now = ctx.currentTime;
      gain.gain.setValueAtTime(0.3, now);

      osc.frequency.setValueAtTime(523.25, now);
      osc.frequency.setValueAtTime(659.25, now + 0.2);
      osc.frequency.setValueAtTime(783.99, now + 0.4);
      osc.frequency.setValueAtTime(1046.50, now + 0.6);

      gain.gain.exponentialRampToValueAtTime(0.001, now + 1.2);

      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start();
      osc.stop(now + 1.3);
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
      final ctx = web.AudioContext();
      final osc = ctx.createOscillator();
      final gain = ctx.createGain();

      osc.type = 'square';
      final now = ctx.currentTime;
      gain.gain.setValueAtTime(0.15, now);

      osc.frequency.setValueAtTime(880, now);
      osc.frequency.setValueAtTime(660, now + 0.15);
      osc.frequency.setValueAtTime(880, now + 0.3);

      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.5);

      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start();
      osc.stop(now + 0.55);
    } catch (_) {}

    _alarmTimer = Timer(const Duration(milliseconds: 600), _alarmLoop);
  }

  static void stopAlarm() {
    _alarmPlaying = false;
    _alarmTimer?.cancel();
    _alarmTimer = null;
  }

  static bool get isAlarmPlaying => _alarmPlaying;
}
