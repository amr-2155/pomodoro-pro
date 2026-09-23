/// Productivity & self-development quotes ONLY.
/// No Quranic verses, no hadiths, no religious content.
/// Uncertain attributions are left without an author.
///
/// Structure:
///   1. Hand-curated flagship quotes (stable ids).
///   2. Curated famous attributions (ids m*).
///   3. Deterministic generated families (ids g*) — grammatically safe
///      template x curated word-bank combinations, expanding the library
///      into the hundreds while every entry stays a coherent aphorism.
class ProductivityQuotes {
  static const String focus = 'focus';
  static const String discipline = 'discipline';
  static const String work = 'work';
  static const String success = 'success';
  static const String consistency = 'consistency';
  static const String learning = 'learning';

  static List<String> get categories => [
        focus,
        discipline,
        work,
        success,
        consistency,
        learning,
      ];

  // ══════════════════════════════════════════════════════════
  // 1) Flagship hand-curated quotes
  // ══════════════════════════════════════════════════════════
  static const List<Map<String, String>> _flagship = [
    {'id': 'f1', 'cat': focus, 'ar': 'ركّز الآن، واترك الباقي لاحقًا.', 'en': 'Stay focused. Make progress.', 'author': ''},
    {'id': 'f2', 'cat': focus, 'ar': 'عمق التركيز يساوي جودة النتيجة.', 'en': 'Depth of focus equals quality of results.', 'author': ''},
    {'id': 'f3', 'cat': focus, 'ar': 'القدرة على تركيز انتباهك على مهمة واحدة هي اختبار القوة الحقيقي.', 'en': 'The ability to concentrate on a single task is a true test of strength.', 'author': ''},
    {'id': 'f4', 'cat': focus, 'ar': 'كلما قلّت المهام، زاد الإنجاز.', 'en': 'Fewer tasks, more done.', 'author': ''},
    {'id': 'f5', 'cat': focus, 'ar': 'الهاتف الصامت عقلٌ صافٍ.', 'en': 'A silent phone is a clear mind.', 'author': ''},
    {'id': 'f6', 'cat': focus, 'ar': 'ابدأ بواحد. واحد فقط.', 'en': 'Start with one. Just one.', 'author': ''},
    {'id': 'f7', 'cat': focus, 'ar': 'الانتباه أثمن عملة تملكها؛ أنفقها بعناية.', 'en': 'Attention is your most valuable currency; spend it carefully.', 'author': ''},

    {'id': 'd1', 'cat': discipline, 'ar': 'الانضباط هو الجسر بين الأهداف والإنجاز.', 'en': 'Discipline is the bridge between goals and accomplishment.', 'author': 'جيم رون'},
    {'id': 'd2', 'cat': discipline, 'ar': 'الحافز يبدأ الأمر، والعادة تكمل المسيرة.', 'en': 'Motivation gets you started. Habit keeps you going.', 'author': 'جيم رون'},
    {'id': 'd3', 'cat': discipline, 'ar': 'الانضباط الذاتي هو الفرق بين ما تريد الآن وما تريده أكثر.', 'en': 'Self-discipline is the difference between what you want now and what you want most.', 'author': ''},
    {'id': 'd4', 'cat': discipline, 'ar': 'افعل الشيء الصعب وهو سهل، فتجده سهلًا حين يصعب.', 'en': 'Do the hard thing while it is easy.', 'author': ''},
    {'id': 'd5', 'cat': discipline, 'ar': 'النظام يحرّر، ولا يقيد.', 'en': 'Order liberates; it does not confine.', 'author': ''},
    {'id': 'd6', 'cat': discipline, 'ar': 'قرار صغير متكرر يبني حياة مختلفة.', 'en': 'One small repeated decision builds a different life.', 'author': ''},

    {'id': 'w1', 'cat': work, 'ar': 'من يريد أن يفعل شيئًا يجد وسيلة، ومن لا يريد يجد عذرًا.', 'en': 'Those who want to do something find a way; those who do not find an excuse.', 'author': ''},
    {'id': 'w2', 'cat': work, 'ar': 'العمل بذكاء يبدأ بالعمل أولًا.', 'en': 'Working smart starts with working, first.', 'author': ''},
    {'id': 'w3', 'cat': work, 'ar': 'اجعل عملك يتحدث عنك.', 'en': 'Let your work speak for you.', 'author': ''},
    {'id': 'w4', 'cat': work, 'ar': 'الإتقان ليس تفصيلًا زائدًا؛ إنه الرسالة نفسها.', 'en': 'Craftsmanship is not a detail; it is the message.', 'author': ''},
    {'id': 'w5', 'cat': work, 'ar': 'المهمة الكبيرة ليست إلا مهامًا صغيرة مرتبة.', 'en': 'A big task is just small tasks in order.', 'author': ''},
    {'id': 'w6', 'cat': work, 'ar': 'أنجز اليوم ما يشكرك غدًا.', 'en': 'Finish today what tomorrow will thank you for.', 'author': ''},

    {'id': 's1', 'cat': success, 'ar': 'النجاح هو مجموع جهود صغيرة تتكرر يومًا بعد يوم.', 'en': 'Success is the sum of small efforts repeated day in and day out.', 'author': 'روبرت كوليير'},
    {'id': 's2', 'cat': success, 'ar': 'لن تحتاج أن تكون عظيمًا لتبدأ، لكن ستحتاج أن تبدأ لتكون عظيمًا.', 'en': 'You do not have to be great to start, but you have to start to be great.', 'author': 'زيغ زيغلار'},
    {'id': 's3', 'cat': success, 'ar': 'لا تحكم على كل يوم بما تحصده، بل بالبذور التي تزرعها.', 'en': 'Do not judge each day by the harvest you reap, but by the seeds you plant.', 'author': 'روبرت لويس ستيفنسون'},
    {'id': 's4', 'cat': success, 'ar': 'الطريق الطويل يبدأ بخطوة.', 'en': 'A long journey begins with a single step.', 'author': ''},
    {'id': 's5', 'cat': success, 'ar': 'الفشل ليس عكس النجاح؛ إنه جزء منه.', 'en': 'Failure is not the opposite of success; it is part of it.', 'author': ''},
    {'id': 's6', 'cat': success, 'ar': 'قارن نفسك بمن كنت أمس، لا بغيرك اليوم.', 'en': 'Compare yourself to who you were yesterday, not to others today.', 'author': ''},
    {'id': 's7', 'cat': success, 'ar': 'الأحلام لا تعمل إلا إذا عملت أنت.', 'en': 'Dreams do not work unless you do.', 'author': ''},

    {'id': 'c1', 'cat': consistency, 'ar': 'الاستمرارية أهم من الكمال.', 'en': 'Consistency beats perfection.', 'author': ''},
    {'id': 'c2', 'cat': consistency, 'ar': 'قطرات المطر تملأ الجرة؛ الجلسة الواحدة تبني العادة.', 'en': 'Raindrops fill the jar; one session builds the habit.', 'author': ''},
    {'id': 'c3', 'cat': consistency, 'ar': 'لا تتوقف بعد خطأ واحد؛ توقف بعد ألف إنجاز فقط.', 'en': 'Do not stop after one slip; stop only after a thousand wins.', 'author': ''},
    {'id': 'c4', 'cat': consistency, 'ar': 'خمس وعشرون دقيقة كل يوم تساوي مئة ساعة في السنة.', 'en': 'Twenty-five minutes a day equals a hundred hours a year.', 'author': ''},
    {'id': 'c5', 'cat': consistency, 'ar': 'الأعمدة الكبيرة تُبنى بطوب صغير متكرر.', 'en': 'Great pillars are built from small repeated bricks.', 'author': ''},
    {'id': 'c6', 'cat': consistency, 'ar': 'اليوم الذي لا تشعر فيه بالمزاج هو أهم يوم.', 'en': 'The day you least feel like it is the day that counts most.', 'author': ''},

    {'id': 'l1', 'cat': learning, 'ar': 'اسأل، تتعلم. اصمتَ، تظن أنك تعلم.', 'en': 'Ask and you learn; stay silent and you only assume you know.', 'author': ''},
    {'id': 'l2', 'cat': learning, 'ar': 'التعلم استثمار لا ينخفض سعره.', 'en': 'Learning is an investment that never loses value.', 'author': ''},
    {'id': 'l3', 'cat': learning, 'ar': 'علّم غيرك ما تعلمته؛ ستكتشف ما لم تفهمه بعد.', 'en': 'Teach what you learned; you will discover what you have not yet understood.', 'author': ''},
    {'id': 'l4', 'cat': learning, 'ar': 'خطوة صغيرة في التعلم اليوم أفضل من خطة كبيرة للغد.', 'en': 'A small learning step today beats a grand plan for tomorrow.', 'author': ''},
    {'id': 'l5', 'cat': learning, 'ar': 'العقل كالفراغ؛ يزداد سعة كلما وضعت فيه.', 'en': 'The mind is like a room: the more you fill it, the larger it grows.', 'author': ''},
    {'id': 'l6', 'cat': learning, 'ar': 'لا توجد مهمة صعبة، هناك مهام لم تتكرر بعد.', 'en': 'There are no hard tasks, only tasks not yet practiced enough.', 'author': ''},
    {'id': 'l7', 'cat': learning, 'ar': 'الفضول وقود التعلم؛ احتفظ به مشتعلًا.', 'en': 'Curiosity fuels learning; keep it burning.', 'author': ''},

    {'id': 't1', 'cat': work, 'ar': 'الوقت أثمن ما تملك، لأنه الشيء الوحيد الذي لا يعود.', 'en': 'Time is your most precious asset, the only thing that never returns.', 'author': ''},
    {'id': 't2', 'cat': work, 'ar': 'من ضيّع ساعة صباحه سيبحث عنها في مساءه.', 'en': 'Who wastes his morning hour searches for it at night.', 'author': ''},
    {'id': 't3', 'cat': work, 'ar': 'لا تقل ليس لدي وقت؛ قل ليس لهذا الأولوية.', 'en': 'Do not say "I have no time"; say "it is not a priority".', 'author': ''},
  ];

  // ══════════════════════════════════════════════════════════
  // 2) Curated attributions (well-known, safely sourced)
  // ══════════════════════════════════════════════════════════
  static const List<Map<String, String>> _manual = [
    {'id': 'm01', 'cat': discipline, 'ar': 'نحن ما نفعله بشكل متكرر؛ التميز إذن ليس فعلًا بل عادة.', 'en': 'We are what we repeatedly do. Excellence, then, is not an act but a habit.', 'author': 'أرسطو'},
    {'id': 'm02', 'cat': work, 'ar': 'لا تحسب الأيام، اجعل الأيام تُحسب.', 'en': "Don't count the days, make the days count.", 'author': 'محمد علي كلاي'},
    {'id': 'm03', 'cat': focus, 'ar': 'أخشى الرجل الذي تدرّب على ركلة واحدة عشرة آلاف مرة.', 'en': 'I fear not the man who has practiced 10,000 kicks once.', 'author': 'بروس لي'},
    {'id': 'm04', 'cat': success, 'ar': 'أفضل وقت للغرس كان قبل عشرين عامًا؛ ثاني أفضل وقت هو الآن.', 'en': 'The best time to plant a tree was twenty years ago. The second best time is now.', 'author': 'مثل صيني'},
    {'id': 'm05', 'cat': success, 'ar': 'أنت لا ترتقي إلى مستوى أهدافك؛ بل تهبط إلى مستوى أنظمتك.', 'en': 'You do not rise to the level of your goals; you fall to the level of your systems.', 'author': 'جيمس كلير'},
    {'id': 'm06', 'cat': work, 'ar': 'سرّ التقدم هو البدء.', 'en': 'The secret of getting ahead is getting started.', 'author': 'مارك توين'},
    {'id': 'm07', 'cat': consistency, 'ar': 'البطء الثابت يقطع المسافة.', 'en': 'Slow and steady wins the race.', 'author': 'إيسوب'},
    {'id': 'm08', 'cat': focus, 'ar': 'التركيز يعني قول «لا» لمئة فكرة جيدة.', 'en': 'Focus means saying no to a hundred good ideas.', 'author': ''},
    {'id': 'm09', 'cat': learning, 'ar': 'العقل الذي يفتح بفكرة جديدة لن يعود إلى حجمه القديم.', 'en': 'A mind stretched by a new idea never returns to its original size.', 'author': ''},
    {'id': 'm10', 'cat': discipline, 'ar': 'ستحصل على ما تتحمله، لا ما تريده.', 'en': 'You get what you tolerate, not what you desire.', 'author': ''},
    {'id': 'm11', 'cat': success, 'ar': 'ابدأ حيث أنت؛ استخدم ما لديك؛ افعل ما تستطيع.', 'en': 'Start where you are. Use what you have. Do what you can.', 'author': 'آرثر آش'},
    {'id': 'm12', 'cat': consistency, 'ar': 'لا شيء أكثر قوة من عادة تُكرَّر في مكانها الصحيح.', 'en': 'Nothing is more powerful than a habit repeated in its right place.', 'author': ''},
    {'id': 'm13', 'cat': work, 'ar': 'اجعل مهام اليوم قليلة واضحة، فتنجز أكثر مما تتصور.', 'en': 'Keep today\'s list short and clear; you will achieve more than you expect.', 'author': ''},
    {'id': 'm14', 'cat': learning, 'ar': 'من يقرأ صفحة يوميًا يقرأ كتابًا كل شهر.', 'en': 'One page a day becomes a book every month.', 'author': ''},
  ];

  // ══════════════════════════════════════════════════════════
  // 3) Generated families — curated banks x safe templates
  // ══════════════════════════════════════════════════════════

  // G1: virtue comparisons (a > b)
  static const _cmpA_ar = [
    'الصبر', 'الاستمرارية', 'الهدوء', 'الجودة', 'البداية', 'الإتقان',
    'الوضوح', 'العمق', 'الراحة المدروسة', 'الحركة', 'التخطيط',
    'المراجعة', 'الشجاعة', 'التواضع',
  ];
  static const _cmpA_en = [
    'Patience', 'Consistency', 'Calm', 'Quality', 'Starting', 'Mastery',
    'Clarity', 'Depth', 'Smart rest', 'Movement', 'Planning',
    'Review', 'Courage', 'Humility',
  ];
  static const _cmpB_ar = [
    'السرعة', 'الكمال', 'الضجيج', 'الكم', 'التأجيل', 'العشوائية',
    'التشتت', 'السطحية', 'الإجهاد', 'الجمود', 'المبالغة',
    'المقارنة', 'انتظار اللحظة المثالية',
  ];
  static const _cmpB_en = [
    'speed', 'perfection', 'noise', 'quantity', 'procrastination',
    'randomness', 'distraction', 'shallowness', 'burnout', 'rigidity',
    'exaggeration', 'comparison', 'waiting for the perfect moment',
  ];

  // G2: best-time-is-now actions
  static const _nowAct_ar = [
    'القراءة', 'الكتابة', 'المذاكرة', 'الرياضة', 'المشي', 'التخطيط',
    'المراجعة', 'الحفظ', 'التدريب', 'ترتيب مكتبك', 'البرمجة',
    'التصميم', 'التدوين', 'العناية بصحتك', 'تعلم مهارة', 'تجربة فكرة',
    'إنهاء مهمة مؤجلة', 'الاتصال بعزيز', 'التأمل الهادئ', 'شرب الماء',
  ];
  static const _nowAct_en = [
    'read', 'write', 'study', 'exercise', 'walk', 'plan', 'review',
    'memorize', 'practice', 'tidy your desk', 'code', 'design',
    'journal', 'care for your health', 'learn a skill', 'test an idea',
    'finish that delayed task', 'call someone dear', 'sit quietly', 'drink water',
  ];

  // G3: small-step-today subjects
  static const _stepAr = [
    'قراءة صفحة', 'كتابة فكرة واحدة', 'مشوار قصير', 'تمرين خفيف',
    'جلسة تركيز واحدة', 'مراجعة سريعة', 'حفظ سطر', 'تدوينة قصيرة',
    'مسح سطح مكتبك', 'سؤال ذكي', 'تصحيح خطأ صغير', 'قائمة مهام واقعية',
    'كلمة جديدة', 'دقيقة تنفس', 'تنظيم بريدك', 'لقطة تقدم',
  ];
  static const _stepEn = [
    'Reading one page', 'Writing one idea', 'A short walk',
    'A light workout', 'One focus session', 'A quick review',
    'Memorizing one line', 'A short journal entry',
    'Clearing your desk', 'Asking one smart question',
    'Fixing one small bug', 'A realistic task list',
    'One new word', 'One minute of breathing',
    'Organizing your inbox', 'One progress snapshot',
  ];

  // G4: swap-for-25-minutes
  static const _swapBad_ar = [
    'تصفح بلا هدف', 'أخبار سلبية', 'مقارنة نفسك بغيرك', 'انتظار الحافز',
    'تعدد المهام', 'تأجيل الصغير', 'كمالية البداية', 'ضجيج المجموعات',
    'الشكوى من ضيق الوقت', 'البحث عن أداة أفضل',
  ];
  static const _swapBad_en = [
    'mindless scrolling', 'negative news', 'comparing yourself to others',
    'waiting for motivation', 'multitasking', 'delaying the small stuff',
    'perfectionist starts', 'group-chat noise',
    'complaining about time', 'hunting for a better tool',
  ];
  static const _swapGood_ar = [
    'جلسة عمل عميقة', 'مشي قصير', 'كتابة بخط اليد', 'تنفس بطيء',
    'مهمة واحدة فقط', 'تنظيم مساحة عملك', 'تعلم مصغر', 'استراحة حقيقية',
    'كوب ماء', 'نوم مبكر',
  ];
  static const _swapGood_en = [
    'deep work', 'a short walk', 'writing by hand', 'slow breathing',
    'one single task', 'organizing your workspace', 'micro-learning',
    'a real break', 'a glass of water', 'an early night',
  ];

  // G5: unit-of-time + companion
  static const _timeAr = [
    'دقيقة', 'ساعة', 'صباح', 'مساء', 'يوم', 'أسبوع', 'شهر', 'سنة',
  ];
  static const _timeEn = [
    'minute', 'hour', 'morning', 'evening', 'day', 'week', 'month', 'year',
  ];
  static const _compAr = [
    'نية واضحة', 'عمل هادئ', 'قرار صائب', 'كلمة طيبة',
    'خطوة عملية', 'فكرة مسجلة', 'مراجعة صادقة', 'راحة مستحقة',
  ];
  static const _compEn = [
    'a clear intention', 'quiet work', 'a sound decision', 'a kind word',
    'a practical step', 'a recorded idea', 'an honest review', 'deserved rest',
  ];

  /// Builds the full list deterministically.
  static List<Map<String, String>> _buildAll() {
    final list = <Map<String, String>>[];
    list.addAll(_flagship);
    list.addAll(_manual);

    var gi = 0;
    void add(String cat, String ar, String en) {
      gi++;
      list.add({
        'id': 'g$gi',
        'cat': cat,
        'ar': ar,
        'en': en,
        'author': '',
      });
    }

    // G1 — comparisons (skip identical index & known duplicate).
    for (var i = 0; i < _cmpA_ar.length; i++) {
      for (var j = 0; j < _cmpB_ar.length; j++) {
        if (i == j && i < _cmpB_ar.length - 1) continue;
        if (_cmpA_en[i] == 'Consistency' && _cmpB_en[j] == 'perfection') {
          continue; // covered verbatim by c1
        }
        add(focus, '${_cmpA_ar[i]} أهم من ${_cmpB_ar[j]}.',
            '${_cmpA_en[i]} beats ${_cmpB_en[j]}.');
      }
    }

    // G2 — best-time-is-now.
    for (var i = 0; i < _nowAct_ar.length; i++) {
      add(work,
          'أفضل وقت ل${_nowAct_ar[i]} هو الآن.',
          'The best time to ${_nowAct_en[i]} is now.');
    }

    // G3 — small step today.
    for (var i = 0; i < _stepAr.length; i++) {
      add(consistency,
          '${_stepAr[i]} اليوم خير من خطة مثالية غدًا.',
          '${_stepEn[i]} today beats a perfect plan tomorrow.');
    }

    // G4 — swap for 25 minutes.
    for (var b = 0; b < _swapBad_ar.length; b++) {
      for (var g = 0; g < _swapGood_ar.length; g++) {
        add(discipline,
            'بدل ${_swapBad_ar[b]}، خصص 25 دقيقة لـ${_swapGood_ar[g]}.',
            'Instead of ${_swapBad_en[b]}, spend 25 minutes on ${_swapGood_en[g]}.');
      }
    }

    // G5 — unit of time + companion.
    for (var t = 0; t < _timeAr.length; t++) {
      for (var c = 0; c < _compAr.length; c++) {
        add(success,
            '${_timeAr[t]} واحدة مع ${_compAr[c]} تساوي أكثر مما تتخيل.',
            'One ${_timeEn[t]} with ${_compEn[c]} is worth more than you imagine.');
      }
    }

    return list;
  }

  static final List<Map<String, String>> all = _buildAll();

  /// Deterministic pick by date (stable across rebuilds).
  static Map<String, String> quoteOfDay(DateTime date, {int offset = 0}) {
    final seed = date.year * 372 + date.month * 31 + date.day + offset;
    return all[seed % all.length];
  }

  static String textOf(Map<String, String> q, bool isArabic) =>
      isArabic ? q['ar']! : q['en']!;
}
