import 'ambient_sound_types.dart';

class AmbientSoundService {
  static bool _playing = false;
  static AmbientSoundType? _currentType;

  static bool get isPlaying => _playing;
  static AmbientSoundType? get currentType => _currentType;

  static void play(AmbientSoundType type) {
    _playing = true;
    _currentType = type;
  }

  static void stop() {
    _playing = false;
    _currentType = null;
  }

  static void setVolume(double volume) {}

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
  }
}
