import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const int sampleRate = 22050;

final Random _rng = Random(42);

void writeWav(String path, Float64List samples) {
  final bytes = BytesBuilder();

  void writeString(String s) => bytes.add(s.codeUnits);
  void writeUint32(int v) => bytes.add([
        v & 0xFF,
        (v >> 8) & 0xFF,
        (v >> 16) & 0xFF,
        (v >> 24) & 0xFF,
      ]);
  void writeUint16(int v) => bytes.add([v & 0xFF, (v >> 8) & 0xFF]);

  final dataSize = samples.length * 2;
  writeString('RIFF');
  writeUint32(36 + dataSize);
  writeString('WAVE');
  writeString('fmt ');
  writeUint32(16);
  writeUint16(1);
  writeUint16(1);
  writeUint32(sampleRate);
  writeUint32(sampleRate * 2);
  writeUint16(2);
  writeUint16(16);
  writeString('data');
  writeUint32(dataSize);

  for (var i = 0; i < samples.length; i++) {
    final v = samples[i].clamp(-1.0, 1.0).toDouble();
    final s = (v * 32767).round();
    bytes.add([s & 0xFF, (s >> 8) & 0xFF]);
  }
  File(path).writeAsBytesSync(bytes.toBytes());
  stdout.writeln('wrote $path (${samples.length} samples, '
      '${(samples.length / sampleRate).toStringAsFixed(1)}s)');
}

Float64List make(int seconds) => Float64List(seconds * sampleRate);
Float64List lowPass(Float64List x, double cutoffHz) {
  final out = Float64List(x.length);
  final a = 1.0 - exp(-2 * pi * cutoffHz / sampleRate);
  var y = 0.0;
  for (var i = 0; i < x.length; i++) {
    y += a * (x[i] - y);
    out[i] = y;
  }
  return out;
}

Float64List normalize(Float64List x, double peak) {
  var maxV = 0.0;
  for (var i = 0; i < x.length; i++) {
    final a = x[i].abs();
    if (a > maxV) maxV = a;
  }
  if (maxV == 0) return x;
  final scale = peak / maxV;
  for (var i = 0; i < x.length; i++) {
    x[i] *= scale;
  }
  return x;
}

Float64List crossfadeLoop(Float64List x) {
  final f = sampleRate ~/ 20;
  for (var i = 0; i < f; i++) {
    final gain = i / f;
    x[i] *= gain;
    x[x.length - 1 - i] *= gain;
  }
  return x;
}

Float64List whiteNoise(int seconds) {
  final x = make(seconds);
  for (var i = 0; i < x.length; i++) {
    x[i] = _rng.nextDouble() * 2 - 1;
  }
  return x;
}

Float64List pinkNoise(int seconds) {
  final x = make(seconds);
  var b0 = 0.0, b1 = 0.0, b2 = 0.0;
  for (var i = 0; i < x.length; i++) {
    final w = _rng.nextDouble() * 2 - 1;
    b0 = 0.99765 * b0 + w * 0.0990460;
    b1 = 0.96300 * b1 + w * 0.2965164;
    b2 = 0.57000 * b2 + w * 1.0526913;
    x[i] = (b0 + b1 + b2 + w * 0.1848) * 0.4;
  }
  return x;
}

Float64List brownNoise(int seconds) {
  final x = make(seconds);
  var last = 0.0;
  for (var i = 0; i < x.length; i++) {
    final w = _rng.nextDouble() * 2 - 1;
    last = (last + 0.02 * w) / 1.02;
    x[i] = last * 3.5;
  }
  return normalize(x, 1.0);
}

Float64List tick() {
  final x = make(1);
  final freq = 1050.0;
  for (var i = 0; i < sampleRate ~/ 10; i++) {
    final t = i / sampleRate;
    final env = exp(-t * 60);
    x[i] = sin(2 * pi * freq * t) * env * 0.7;
  }
  return x;
}

Float64List finish() {
  final notes = [523.25, 659.25, 783.99, 1046.50];
  final x = make(3);
  for (var n = 0; n < notes.length; n++) {
    final freq = notes[n];
    final start = n * 0.22;
    for (var i = 0; i < sampleRate; i++) {
      final t = i / sampleRate;
      final global = start + t;
      if (global >= 2.4) break;
      final env = (1 - exp(-t * 30)) * exp(-global * 2.2);
      x[i + (start * sampleRate).round()] +=
          (sin(2 * pi * freq * t) * 0.7 +
                  sin(2 * pi * freq * 2 * t) * 0.15) *
              env;
    }
  }
  return x;
}

Float64List alarm() {
  const beepMs = 400;
  const gapMs = 200;
  final x = make(2);
  var idx = 0;
  var beep = 0;
  while (idx < x.length) {
    final freq = beep % 2 == 0 ? 880.0 : 660.0;
    for (var i = 0; i < (beepMs * sampleRate ~/ 1000); i++) {
      if (idx >= x.length) break;
      final t = i / sampleRate;
      final env = sin(pi * t / (beepMs / 1000.0));
      x[idx] = (sin(2 * pi * freq * t) +
              sin(2 * pi * freq * 2 * t) * 0.4 +
              sin(2 * pi * freq * 3 * t) * 0.2) *
          env *
          0.45;
      idx++;
    }
    beep++;
    idx += gapMs * sampleRate ~/ 1000;
  }
  return crossfadeLoop(x);
}

Float64List rain() {
  final x = lowPass(whiteNoise(10), 2600);
  for (var i = 0; i < x.length; i++) {
    x[i] *= 0.6;
    if (_rng.nextDouble() < 0.0012) {
      final start = i;
      final len = 200 + _rng.nextInt(400);
      final freq = 1800 + _rng.nextDouble() * 3000;
      final amp = 0.15 + _rng.nextDouble() * 0.3;
      for (var j = 0; j < len && start + j < x.length; j++) {
        final t = j / sampleRate;
        x[start + j] += sin(2 * pi * freq * t) * exp(-t * 220) * amp;
      }
    }
  }
  return crossfadeLoop(normalize(x, 0.9));
}

Float64List forest() {
  final x = pinkNoise(10);
  for (var i = 0; i < x.length; i++) {
    final t = i / sampleRate;
    final gust = 0.7 + 0.3 * sin(2 * pi * 0.06 * t + sin(2 * pi * 0.023 * t));
    x[i] *= gust * 0.9;
    if (_rng.nextDouble() < 0.00045) {
      final start = i;
      final len = 300 + _rng.nextInt(500);
      final freq = 2600 + _rng.nextDouble() * 1800;
      final amp = 0.06 + _rng.nextDouble() * 0.09;
      for (var j = 0; j < len && start + j < x.length; j++) {
        final t = j / sampleRate;
        final chirp = sin(2 * pi * (freq + j * 8) * t);
        x[start + j] += chirp * exp(-t * 30) * amp * (0.5 + 0.5 * sin(2 * pi * 8 * t));
      }
    }
  }
  return crossfadeLoop(normalize(x, 0.9));
}

Float64List ocean() {
  final x = brownNoise(10);
  for (var i = 0; i < x.length; i++) {
    final t = i / sampleRate;
    final swell = 0.55 + 0.45 * sin(2 * pi * 0.075 * t + 0.6 * sin(2 * pi * 0.03 * t));
    x[i] *= 0.5 + 0.5 * swell;
  }
  return crossfadeLoop(normalize(x, 1.0));
}

Float64List cafe() {
  final x = lowPass(whiteNoise(10), 3500);
  final hp = Float64List(x.length);
  var lastIn = 0.0;
  var lastOut = 0.0;
  const rc = 1.0 / (2 * pi * 300);
  final dt = 1.0 / sampleRate;
  final alpha = rc / (rc + dt);
  for (var i = 0; i < x.length; i++) {
    lastOut = alpha * (lastOut + x[i] - lastIn);
    lastIn = x[i];
    hp[i] = lastOut;
  }
  for (var i = 0; i < x.length; i++) {
    x[i] = hp[i] * 1.1;
    if (_rng.nextDouble() < 0.0018) {
      final start = i;
      final len = 400 + _rng.nextInt(900);
      final freq = 200 + _rng.nextDouble() * 250;
      final amp = 0.1 + _rng.nextDouble() * 0.18;
      for (var j = 0; j < len && start + j < x.length; j++) {
        final t = j / sampleRate;
        x[start + j] +=
            sin(2 * pi * freq * t) * exp(-t * 45) * amp * (0.4 + 0.6 * _rng.nextDouble());
      }
    }
  }
  return crossfadeLoop(normalize(x, 0.9));
}

void main() {
  final outDir = Directory('assets/sounds');
  if (!outDir.existsSync()) outDir.createSync(recursive: true);

  writeWav('assets/sounds/tick.wav', tick());
  writeWav('assets/sounds/finish.wav', finish());
  writeWav('assets/sounds/alarm.wav', alarm());
  writeWav('assets/sounds/rain.wav', rain());
  writeWav('assets/sounds/forest.wav', forest());
  writeWav('assets/sounds/ocean.wav', ocean());
  writeWav('assets/sounds/cafe.wav', cafe());
  writeWav('assets/sounds/white_noise.wav',
      crossfadeLoop(normalize(whiteNoise(8), 0.7)));

  stdout.writeln('Done!');
}
