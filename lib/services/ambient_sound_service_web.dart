import 'dart:async';
import 'dart:math';
import 'package:web/web.dart' as web;
import 'ambient_sound_types.dart';

class AmbientSoundService {
  static web.AudioContext? _ctx;
  static web.GainNode? _masterGain;
  static bool _playing = false;
  static AmbientSoundType? _currentType;
  static Timer? _loopTimer;
  static final _random = Random();

  static bool get isPlaying => _playing;
  static AmbientSoundType? get currentType => _currentType;

  static void _ensureContext() {
    _ctx ??= web.AudioContext();
    _masterGain ??= _ctx!.createGain();
    _masterGain!.connect(_ctx!.destination);
    _masterGain!.gain.setValueAtTime(0.4, _ctx!.currentTime);
  }

  static void play(AmbientSoundType type) {
    stop();
    _ensureContext();
    _playing = true;
    _currentType = type;
    _generateLoop(type);
  }

  static void stop() {
    _playing = false;
    _currentType = null;
    _loopTimer?.cancel();
    _loopTimer = null;
  }

  static void setVolume(double volume) {
    _masterGain?.gain.setValueAtTime(
        volume.clamp(0.0, 1.0), _ctx?.currentTime ?? 0);
  }

  static void _generateLoop(AmbientSoundType type) {
    if (!_playing) return;

    try {
      switch (type) {
        case AmbientSoundType.rain:
          _generateRain();
          break;
        case AmbientSoundType.forest:
          _generateForest();
          break;
        case AmbientSoundType.ocean:
          _generateOcean();
          break;
        case AmbientSoundType.cafe:
          _generateCafe();
          break;
        case AmbientSoundType.whiteNoise:
          _generateWhiteNoise();
          break;
      }
    } catch (_) {}

    _loopTimer = Timer(
      Duration(milliseconds: type == AmbientSoundType.ocean ? 2500 : 1500),
      () => _generateLoop(type),
    );
  }

  static void _generateRain() {
    if (_ctx == null || _masterGain == null) return;
    final now = _ctx!.currentTime;

    for (int i = 0; i < 8; i++) {
      final osc = _ctx!.createOscillator();
      final gain = _ctx!.createGain();
      final filter = _ctx!.createBiquadFilter();

      filter.type = 'bandpass';
      filter.frequency.setValueAtTime(
          3000 + _random.nextDouble() * 4000, now);
      filter.Q.setValueAtTime(0.5, now);

      osc.type = 'sawtooth';
      osc.frequency.setValueAtTime(
          100 + _random.nextDouble() * 200, now);

      final vol = 0.01 + _random.nextDouble() * 0.015;
      gain.gain.setValueAtTime(0, now);
      gain.gain.linearRampToValueAtTime(vol, now + 0.05);
      gain.gain.linearRampToValueAtTime(0, now + 0.15);

      osc.connect(filter);
      filter.connect(gain);
      gain.connect(_masterGain!);
      osc.start();
      osc.stop(now + 0.2);
    }
  }

  static void _generateForest() {
    if (_ctx == null || _masterGain == null) return;
    final now = _ctx!.currentTime;

    final osc = _ctx!.createOscillator();
    final gain = _ctx!.createGain();

    osc.type = 'sine';
    final baseFreq = 2000 + _random.nextDouble() * 2000;
    osc.frequency.setValueAtTime(baseFreq, now);
    osc.frequency.linearRampToValueAtTime(
        baseFreq + 500, now + 0.05);
    osc.frequency.linearRampToValueAtTime(
        baseFreq - 200, now + 0.1);

    gain.gain.setValueAtTime(0, now);
    gain.gain.linearRampToValueAtTime(0.008, now + 0.02);
    gain.gain.linearRampToValueAtTime(0, now + 0.12);

    osc.connect(gain);
    gain.connect(_masterGain!);
    osc.start();
    osc.stop(now + 0.15);
  }

  static void _generateOcean() {
    if (_ctx == null || _masterGain == null) return;
    final now = _ctx!.currentTime;

    final osc = _ctx!.createOscillator();
    final gain = _ctx!.createGain();
    final filter = _ctx!.createBiquadFilter();

    filter.type = 'lowpass';
    filter.frequency.setValueAtTime(200, now);
    filter.frequency.linearRampToValueAtTime(600, now + 1.0);
    filter.frequency.linearRampToValueAtTime(200, now + 2.0);

    osc.type = 'sawtooth';
    osc.frequency.setValueAtTime(60 + _random.nextDouble() * 40, now);

    gain.gain.setValueAtTime(0, now);
    gain.gain.linearRampToValueAtTime(0.04, now + 0.5);
    gain.gain.linearRampToValueAtTime(0.03, now + 1.5);
    gain.gain.linearRampToValueAtTime(0, now + 2.4);

    osc.connect(filter);
    filter.connect(gain);
    gain.connect(_masterGain!);
    osc.start();
    osc.stop(now + 2.5);
  }

  static void _generateCafe() {
    if (_ctx == null || _masterGain == null) return;
    final now = _ctx!.currentTime;

    for (int i = 0; i < 3; i++) {
      final osc = _ctx!.createOscillator();
      final gain = _ctx!.createGain();
      final filter = _ctx!.createBiquadFilter();

      filter.type = 'bandpass';
      filter.frequency.setValueAtTime(
          500 + _random.nextDouble() * 1000, now);
      filter.Q.setValueAtTime(2, now);

      osc.type = 'triangle';
      osc.frequency.setValueAtTime(
          150 + _random.nextDouble() * 200, now + i * 0.3);

      final vol = 0.005 + _random.nextDouble() * 0.005;
      final start = i * 0.2 + _random.nextDouble() * 0.1;
      gain.gain.setValueAtTime(0, now + start);
      gain.gain.linearRampToValueAtTime(vol, now + start + 0.05);
      gain.gain.linearRampToValueAtTime(0, now + start + 0.3);

      osc.connect(filter);
      filter.connect(gain);
      gain.connect(_masterGain!);
      osc.start();
      osc.stop(now + start + 0.35);
    }
  }

  static void _generateWhiteNoise() {
    if (_ctx == null || _masterGain == null) return;
    final now = _ctx!.currentTime;

    for (int i = 0; i < 6; i++) {
      final osc = _ctx!.createOscillator();
      final gain = _ctx!.createGain();
      final filter = _ctx!.createBiquadFilter();

      filter.type = 'bandpass';
      filter.frequency.setValueAtTime(
          500 + _random.nextDouble() * 4000, now);
      filter.Q.setValueAtTime(0.3, now);

      osc.type = 'sawtooth';
      osc.frequency.setValueAtTime(
          40 + _random.nextDouble() * 80, now);

      final vol = 0.008 + _random.nextDouble() * 0.008;
      gain.gain.setValueAtTime(0, now);
      gain.gain.linearRampToValueAtTime(vol, now + 0.1);
      gain.gain.linearRampToValueAtTime(0, now + 1.4);

      osc.connect(filter);
      filter.connect(gain);
      gain.connect(_masterGain!);
      osc.start();
      osc.stop(now + 1.5);
    }
  }

  static String getSoundName(AmbientSoundType type) {
    switch (type) {
      case AmbientSoundType.rain:
        return 'Rain';
      case AmbientSoundType.forest:
        return 'Forest';
      case AmbientSoundType.ocean:
        return 'Ocean';
      case AmbientSoundType.cafe:
        return 'Cafe';
      case AmbientSoundType.whiteNoise:
        return 'White Noise';
    }
  }

  static String getSoundIcon(AmbientSoundType type) {
    switch (type) {
      case AmbientSoundType.rain:
        return '🌧️';
      case AmbientSoundType.forest:
        return '🌳';
      case AmbientSoundType.ocean:
        return '🌊';
      case AmbientSoundType.cafe:
        return '☕';
      case AmbientSoundType.whiteNoise:
        return '🔊';
    }
  }

  static void dispose() {
    stop();
    _masterGain?.disconnect();
    _ctx?.close();
    _ctx = null;
    _masterGain = null;
  }
}
