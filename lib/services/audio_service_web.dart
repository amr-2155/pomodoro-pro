import 'dart:async';
import 'package:flutter/services.dart';
import 'package:web/web.dart' as web;
import 'dart:js_interop';
import 'completion_sound.dart';

class AudioService {
  static web.HTMLAudioElement? _previewElement;
  static web.HTMLAudioElement? _completionElement;
  static web.HTMLAudioElement? _countdownElement;
  static bool _previewPlaying = false;
  static bool get isPreviewPlaying => _previewPlaying;
  static bool _completionLooping = false;
  static bool get isCompletionLooping => _completionLooping;

  static final Map<String, String> _urlCache = {};

  static Future<String?> _getUrl(String asset) async {
    final cached = _urlCache[asset];
    if (cached != null) return cached;
    try {
      final data = await rootBundle.load(asset);
      final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      final blob = web.Blob([bytes.toJS].toJS);
      final url = web.URL.createObjectURL(blob);
      _urlCache[asset] = url;
      return url;
    } catch (_) {
      return null;
    }
  }

  static Future<void> _stopElement(web.HTMLAudioElement? el) async {
    try {
      el?.pause();
      el?.currentTime = 0;
    } catch (_) {}
  }

  static Future<void> playPreviewTracked(CompletionSoundType type) async {
    await _stopElement(_previewElement);
    _previewPlaying = true;
    final url = await _getUrl(type.asset);
    if (url == null) { _previewPlaying = false; return; }
    _previewElement = web.HTMLAudioElement()
      ..src = url
      ..volume = 0.8;
    _previewElement!.onEnded.listen((_) { _previewPlaying = false; });
    _previewElement!.onError.listen((_) { _previewPlaying = false; });
    await _previewElement!.play().toDart;
  }

  static Future<void> playCountdownPreviewTracked(CountdownSoundType type) async {
    await _stopElement(_previewElement);
    _previewPlaying = true;
    final url = await _getUrl(type.asset);
    if (url == null) { _previewPlaying = false; return; }
    _previewElement = web.HTMLAudioElement()
      ..src = url
      ..volume = 0.4;
    _previewElement!.onEnded.listen((_) { _previewPlaying = false; });
    _previewElement!.onError.listen((_) { _previewPlaying = false; });
    await _previewElement!.play().toDart;
  }

  static Future<void> stopPreview() async {
    _previewPlaying = false;
    await _stopElement(_previewElement);
  }

  static Future<void> playCompletionSound([CompletionSoundType? type]) async {
    await _stopElement(_completionElement);
    final sound = type ?? completionSoundFromKey('soft_bell');
    final url = await _getUrl(sound.asset);
    if (url == null) return;
    _completionElement = web.HTMLAudioElement()
      ..src = url
      ..volume = 0.9;
    await _completionElement!.play().toDart;
  }

  static Future<void> startCompletionLoop([CompletionSoundType? type]) async {
    _completionLooping = true;
    await _stopElement(_completionElement);
    final sound = type ?? completionSoundFromKey('soft_bell');
    final url = await _getUrl(sound.asset);
    if (url == null) return;
    _completionElement = web.HTMLAudioElement()
      ..src = url
      ..volume = 0.9
      ..loop = true;
    await _completionElement!.play().toDart;
  }

  static Future<void> stopCompletionLoop() async {
    if (!_completionLooping) return;
    _completionLooping = false;
    await _stopElement(_completionElement);
  }

  static Future<void> playCountdownTick([CountdownSoundType? type]) async {
    await _stopElement(_countdownElement);
    final sound = type ?? countdownSoundFromKey('water_drops');
    final url = await _getUrl(sound.asset);
    if (url == null) return;
    _countdownElement = web.HTMLAudioElement()
      ..src = url
      ..volume = 0.3;
    await _countdownElement!.play().toDart;
  }

  static Future<void> stopAllSounds() async {
    _completionLooping = false;
    _previewPlaying = false;
    await _stopElement(_previewElement);
    await _stopElement(_completionElement);
    await _stopElement(_countdownElement);
  }

  static Future<void> dispose() async {
    await stopAllSounds();
  }
}
