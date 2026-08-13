import 'package:audioplayers/audioplayers.dart';
import 'ambient_sound_types.dart';

class AmbientSoundService {
  static final AudioPlayer _player = AudioPlayer();
  static bool _playing = false;
  static AmbientSoundType? _currentType;
  static double _volume = 0.4;

  static bool get isPlaying => _playing;
  static AmbientSoundType? get currentType => _currentType;

  static String _assetFor(AmbientSoundType type) {
    switch (type) {
      case AmbientSoundType.rain:
        return 'sounds/rain.wav';
      case AmbientSoundType.forest:
        return 'sounds/forest.wav';
      case AmbientSoundType.ocean:
        return 'sounds/ocean.wav';
      case AmbientSoundType.cafe:
        return 'sounds/cafe.wav';
      case AmbientSoundType.whiteNoise:
        return 'sounds/white_noise.wav';
    }
  }

  static Future<void> play(AmbientSoundType type) async {
    try {
      await _player.stop();
      _currentType = type;
      _playing = true;
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(_volume.clamp(0.0, 1.0));
      await _player.play(AssetSource(_assetFor(type)));
    } catch (_) {
      _playing = false;
    }
  }

  static Future<void> stop() async {
    _playing = false;
    _currentType = null;
    try {
      await _player.stop();
    } catch (_) {}
  }

  static Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    try {
      await _player.setVolume(_volume);
    } catch (_) {}
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

  static Future<void> dispose() async {
    await stop();
    try {
      await _player.dispose();
    } catch (_) {}
  }
}
