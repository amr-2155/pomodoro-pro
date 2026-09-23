enum CompletionSoundType {
  softBell,
  windChime,
  waterDrops,
  birds,
  woodenKnock,
  rain,
  ocean,
  forest,
}

enum CountdownSoundType {
  breeze,
  waterDrops,
  rain,
  ocean,
  forest,
}

extension CompletionSoundTypeX on CompletionSoundType {
  String get key => switch (this) {
        CompletionSoundType.softBell => 'soft_bell',
        CompletionSoundType.windChime => 'wind_chime',
        CompletionSoundType.waterDrops => 'water_drops',
        CompletionSoundType.birds => 'birds',
        CompletionSoundType.woodenKnock => 'wooden_knock',
        CompletionSoundType.rain => 'rain',
        CompletionSoundType.ocean => 'ocean',
        CompletionSoundType.forest => 'forest',
      };

  String get nameAr => switch (this) {
        CompletionSoundType.softBell => 'نسيم هادئ',
        CompletionSoundType.windChime => 'ريح خفيفة',
        CompletionSoundType.waterDrops => 'قطرات ماء',
        CompletionSoundType.birds => 'عصافير خفيفة',
        CompletionSoundType.woodenKnock => 'طقطقة نار',
        CompletionSoundType.rain => 'مطر خفيف',
        CompletionSoundType.ocean => 'موج هادئ',
        CompletionSoundType.forest => 'خشخشة أوراق',
      };

  String get descAr => switch (this) {
        CompletionSoundType.softBell => 'صوت نسيم هادئ وطبيعي',
        CompletionSoundType.windChime => 'نسيم خفيف بين الأغصان',
        CompletionSoundType.waterDrops => 'قطرات ماء نقية',
        CompletionSoundType.birds => 'غناء عصافير الصباح',
        CompletionSoundType.woodenKnock => 'طقطقة نار هادئة',
        CompletionSoundType.rain => 'أمطار خفيفة مريحة',
        CompletionSoundType.ocean => 'أمواج بحر هادئة',
        CompletionSoundType.forest => 'خشخشة أوراق الشجر',
      };

  String get icon => switch (this) {
        CompletionSoundType.softBell => '🌿',
        CompletionSoundType.windChime => '🎐',
        CompletionSoundType.waterDrops => '💧',
        CompletionSoundType.birds => '🐦',
        CompletionSoundType.woodenKnock => '🔥',
        CompletionSoundType.rain => '🌧️',
        CompletionSoundType.ocean => '🌊',
        CompletionSoundType.forest => '🍃',
      };

  String get asset => 'sounds/$key.wav';
}

extension CountdownSoundTypeX on CountdownSoundType {
  String get key => switch (this) {
        CountdownSoundType.breeze => 'wind_chime',
        CountdownSoundType.waterDrops => 'water_drops',
        CountdownSoundType.rain => 'rain',
        CountdownSoundType.ocean => 'ocean',
        CountdownSoundType.forest => 'forest',
      };

  String get nameAr => switch (this) {
        CountdownSoundType.breeze => 'نسيم خفيف',
        CountdownSoundType.waterDrops => 'قطرات ماء',
        CountdownSoundType.rain => 'مطر خفيف',
        CountdownSoundType.ocean => 'موج هادئ',
        CountdownSoundType.forest => 'أصوات طبيعية',
      };

  String get icon => switch (this) {
        CountdownSoundType.breeze => '🍃',
        CountdownSoundType.waterDrops => '💧',
        CountdownSoundType.rain => '🌧️',
        CountdownSoundType.ocean => '🌊',
        CountdownSoundType.forest => '🌿',
      };

  String get asset => 'sounds/$key.wav';
}

CompletionSoundType completionSoundFromKey(String? value) {
  return CompletionSoundType.values.firstWhere(
    (t) => t.key == value,
    orElse: () => CompletionSoundType.softBell,
  );
}

CountdownSoundType countdownSoundFromKey(String? value) {
  return CountdownSoundType.values.firstWhere(
    (t) => t.key == value,
    orElse: () => CountdownSoundType.waterDrops,
  );
}
