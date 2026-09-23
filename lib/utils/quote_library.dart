/// A world-class categorized library of motivational & religious quotes.
/// Each quote is {ar, en, source}. Selection is deterministic per session,
/// matched to the active project's theme (istighfar, adhkar, quran...).
class QuoteLibrary {
  // ─────────────────────────────────────────────────────────────────
  // Categories: keywords detect the project name/theme.
  // ─────────────────────────────────────────────────────────────────
  static const Map<String, List<String>> _keywords = {
    'istighfar': [
      'استغفار', 'استغف', 'توبة', 'توب', 'غفران', 'مغفرة', 'ذنب',
      'istighfar', 'forgiv', 'repent', 'tawbah',
    ],
    'adhkar': [
      'أذكار', 'اذكار', 'ذكر', 'تسبيح', 'سبحة', 'دعاء', 'تضرع',
      'adhkar', 'dhikr', 'remembrance', 'dua', 'supplicat',
    ],
    'quran': [
      'قرآن', 'قران', 'تلاوة', 'تجويد', 'حفظ', 'ورد', 'جزء', 'سورة',
      'quran', 'koran', 'recite', 'tajweed', 'memoriz',
    ],
    'prayer': [
      'صلاة', 'صلاه', 'فجر', 'ظهر', 'عصر', 'مغرب', 'عشاء', 'سنن', 'رواتب', 'قيام', 'تهجد',
      'prayer', 'salah', 'salat', 'fajr', 'tahajjud',
    ],
    'time': [
      'وقت', 'الوقت', 'إدارة الوقت', 'تنظيم', 'عصر', 'عمر', 'يوم',
      'time', 'productiv', 'manag', 'organiz',
    ],
    'study': [
      'دراسة', 'دراسه', 'مذاكرة', 'مذاكره', 'امتحان', 'اختبار', 'مراجعة', 'تعلم', 'علم', 'جامعة', 'مدرسة', 'كتاب',
      'study', 'exam', 'learn', 'school', 'college', 'university', 'read', 'book',
    ],
    'work': [
      'عمل', 'شغل', 'مشروع', 'وظيفة', 'مهنة', 'برمجة', 'تصميم', 'كتابة', 'بزنس', 'تجارة',
      'work', 'job', 'career', 'business', 'code', 'design', 'writ', 'project',
    ],
    'health': [
      'صحة', 'صحه', 'رياضة', 'رياضه', 'جيم', 'لياقة', 'تمرين', 'رجيم', 'مشي', 'جري',
      'health', 'fit', 'gym', 'sport', 'exercis', 'run', 'walk', 'diet',
    ],
    'patience': [
      'صبر', 'ثبات', 'احتمال', 'مواصلة',
      'patien', 'persever', 'consisten', 'sabr',
    ],
    'gratitude': [
      'شكر', 'امتنان', 'حمد', 'ثناء',
      'gratitude', 'thank', 'grateful', 'shukr', 'hamd',
    ],
  };

  // ─────────────────────────────────────────────────────────────────
  // Quote banks — authentic Quranic verses & hadiths.
  // ─────────────────────────────────────────────────────────────────
  static const Map<String, List<Map<String, String>>> _categories = {
    // ═══ الاستغفار والتوبة ═══
    'istighfar': [
      {'ar': 'وَمَن يَغْفِرُ الذُّنُوبَ إِلَّا اللَّهُ وَلَا يُشْرِكُونَ', 'en': 'And who can forgive sins except Allah?', 'source': 'آل عمران: 135'},
      {'ar': 'قُلْ يَا عِبَادِيَ الَّذِينَ أَسْرَفُوا عَلَىٰ أَنفُسِهِمْ لَا تَقْنَطُوا مِن رَّحْمَةِ اللَّهِ', 'en': '"O My servants who have transgressed against themselves, do not despair of Allah\'s mercy."', 'source': 'الزمر: 53'},
      {'ar': 'وَاللَّهُ يُرِيدُ أَن يَتُوبَ عَلَيْكُمْ', 'en': 'And Allah wants to accept your repentance.', 'source': 'النساء: 27'},
      {'ar': 'إِنَّ اللَّهَ يَغْفِرُ الذُّنُوبَ جَمِيعًا', 'en': 'Indeed, Allah forgives all sins.', 'source': 'الزمر: 53'},
      {'ar': 'رَبِّ اغْفِرْ لِي وَتُبْ عَلَيَّ إِنَّكَ أَنتَ التَّوَّابُ الرَّحِيمُ', 'en': 'My Lord, forgive me and accept my repentance. You are the Accepting of repentance, the Merciful.', 'source': 'البقرة'},
      {'ar': 'مَنْ عَادَ ذَنْبًا فَالتَّوْبَةُ مِنْهُ وَاجِبَةٌ، وَاللهُ يَقْبَلُ التَّوْبَةَ عَنْ عِبَادِهِ', 'en': 'Whoever returns to sin, repentance becomes his duty — and Allah accepts repentance from His servants.', 'source': 'حديث شريف'},
      {'ar': 'الطُّهُورُ شَطْرُ الإِيمَانِ، وَالحَمْدُ لِلَّهِ تَمْلَأُ المِيزَانَ، وَسُبْحَانَ اللهِ وَالحَمْدُ لِلَّهِ تَمْلَآنِ - أَوْ تَمْلَأُ - مَا بَيْنَ السَّمَاءِ وَالأَرْضِ', 'en': 'Purification is half of faith, and "Alhamdulillah" fills the scale, and "SubhanAllah walhamdulillah" fills what is between heaven and earth.', 'source': 'رواه مسلم'},
      {'ar': 'إِنَّ اللَّهَ يَبْسُطُ يَدَهُ بِاللَّيْلِ لِيَتُوبَ مُسِيءُ النَّهَارِ، وَيَبْسُطُ يَدَهُ بِالنَّهَارِ لِيَتُوبَ مُسِيءُ اللَّيْلِ', 'en': 'Allah extends His hand by night so the sinner of day may repent, and by day so the sinner of night may repent.', 'source': 'رواه مسلم'},
      {'ar': 'كُلُّ ابْنِ آدَمَ خَطَّاءٌ، وَخَيْرُ الخَطَّائِينَ التَّوَّابُونَ', 'en': 'Every son of Adam sins, and the best of sinners are those who repent.', 'source': 'رواه الترمذي'},
      {'ar': 'مَنْ لَزِمَ الاسْتِغْفَارَ جَعَلَ اللهُ لَهُ مِنْ كُلِّ ضِيقٍ مَخْرَجًا', 'en': 'Whoever holds fast to seeking forgiveness, Allah will make a way out of every distress.', 'source': 'من هدي النبي ﷺ'},
      {'ar': 'وَاسْتَغْفِرُوا اللَّهَ إِنَّ اللَّهَ غَفُورٌ رَحِيمٌ', 'en': 'And seek forgiveness of Allah. Indeed, Allah is Forgiving and Merciful.', 'source': 'المزمل: 20'},
      {'ar': 'فَقُلْتُ اسْتَغْفِرُوا رَبَّكُمْ إِنَّهُ كَانَ غَفَّارًا', 'en': 'I said: "Ask forgiveness of your Lord. Indeed, He is ever a Perpetual Forgiver."', 'source': 'نوح: 10'},
      {'ar': 'وَمَا تَسْتَغْفِرُ اللَّهَ مِن ذَنبٍ قَلِيلًا', 'en': '…and seek forgiveness for your sin.', 'source': 'محمد: 19'},
      {'ar': 'لَا إِلَٰهَ إِلَّا أَنتَ سُبْحَانَكَ إِنِّي كُنتُ مِنَ الظَّالِمِينَ', 'en': '"There is no deity except You; exalted are You. Indeed, I have been of the wrongders." — the prayer of Yunus.', 'source': 'الأنبياء: 87'},
      {'ar': 'التَّائِبُ مِنَ الذَّنْبِ كَمَنْ لَا ذَنْبَ لَهُ', 'en': 'The one who repents from sin is like one who has no sin.', 'source': 'رواه ابن ماجه'},
    ],

    // ═══ الأذكار والدعاء ═══
    'adhkar': [
      {'ar': 'فَاذْكُرُونِي أَذْكُرْكُمْ وَاشْكُرُوا لِي وَلَا تَكْفُرُونِ', 'en': 'So remember Me; I will remember you.', 'source': 'البقرة: 152'},
      {'ar': 'أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ', 'en': 'Verily, in the remembrance of Allah do hearts find rest.', 'source': 'الرعد: 28'},
      {'ar': 'كَلِمَتَانِ خَفِيفَتَانِ عَلَى اللِّسَانِ، ثَقِيلَتَانِ فِي المِيزَانِ: سُبْحَانَ اللهِ وَبِحَمْدِهِ، سُبْحَانَ اللهِ العَظِيمِ', 'en': 'Two words light on the tongue, heavy on the scale: SubhanAllahi wa bihamdih, SubhanAllahil-Azim.', 'source': 'رواه البخاري'},
      {'ar': 'مَثَلُ الَّذِي يَذْكُرُ رَبَّهُ وَالَّذِي لَا يَذْكُرُهُ مَثَلُ الحَيِّ وَالمَيِّتِ', 'en': 'The example of one who remembers his Lord and one who does not is like the living and the dead.', 'source': 'رواه البخاري'},
      {'ar': 'مَنْ قَالَ سُبْحَانَ اللهِ وَبِحَمْدِهِ فِي يَوْمٍ مِائَةَ مَرَّةٍ حُطَّتْ خَطَايَاهُ وَلَوْ كَانَتْ مِثْلَ زَبَدِ البَحْرِ', 'en': 'Whoever says "SubhanAllahi wa bihamdih" one hundred times a day, his sins are wiped away even if they were like the foam of the sea.', 'source': 'رواه البخاري'},
      {'ar': 'أَحَبُّ الكَلَامِ إِلَى اللهِ أَرْبَعٌ: سُبْحَانَ اللهِ، وَالحَمْدُ لِلَّهِ، وَلَا إِلَٰهَ إِلَّا اللهُ، وَاللهُ أَكْبَرُ', 'en': 'The most beloved speech to Allah is four: SubhanAllah, Alhamdulillah, La ilaha illallah, Allahu Akbar.', 'source': 'رواه مسلم'},
      {'ar': 'ادْعُونِي أَسْتَجِبْ لَكُمْ', 'en': 'Call upon Me; I will respond to you.', 'source': 'غافر: 60'},
      {'ar': 'وَإِذَا سَأَلَكَ عِبَادِي عَنِّي فَإِنِّي قَرِيبٌ', 'en': 'And when My servants ask you concerning Me — indeed I am near.', 'source': 'البقرة: 186'},
      {'ar': 'الدُّعَاءُ هُوَ العِبَادَةُ', 'en': 'Supplication is worship itself.', 'source': 'رواه الترمذي'},
      {'ar': 'لَا يَزَالُ لِسَانُكَ رَطْبًا بِذِكْرِ اللهِ', 'en': 'Keep your tongue moist with the remembrance of Allah.', 'source': 'رواه الترمذي'},
      {'ar': 'أَفْضَلُ الذِّكْرِ لَا إِلَٰهَ إِلَّا اللهُ', 'en': 'The best remembrance is "La ilaha illallah".', 'source': 'رواه الترمذي'},
      {'ar': 'بَيِّنُوا لأَنَّ اللهَ قَدْ كَتَبَ الإِحْسَانَ عَلَى كُلِّ شَيْءٍ', 'en': 'Excellence has been decreed for all things by Allah.', 'source': 'رواه مسلم'},
      {'ar': 'حَسْبُنَا اللهُ وَنِعْمَ الوَكِيلُ', 'en': 'Sufficient for us is Allah, and He is the best Disposer of affairs.', 'source': 'آل عمران: 173'},
      {'ar': 'أَصْلَحَ اللهُ بِكَ يَا صَاحِبَ الجَلِيسِ — دُعَاءُ مَنْ يَذْكُرُ اللهَ وَرَبَّكَ فِي نَفْسِهِ فَيَقُولُ: رَبِّي، رَبِّي', 'en': 'Whoever remembers his Lord in himself saying "My Lord, my Lord" — they are on a clear path.', 'source': 'حديث شريف'},
      {'ar': 'الطُّهورُ شَطرُ الإيمانِ والحمدُ للهِ تَملأُ الميزانَ', 'en': 'Purity is half of faith and "alhamdulillah" fills the scale.', 'source': 'رواه مسلم'},
    ],

    // ═══ القرآن الكريم ═══
    'quran': [
      {'ar': 'إِنَّ هَٰذَا الْقُرْآنَ يَهْدِي لِلَّتِي هِيَ أَقْوَمُ', 'en': 'Indeed, this Quran guides to that which is most upright.', 'source': 'الإسراء: 9'},
      {'ar': 'وَنُنَزِّلُ مِنَ الْقُرْآنِ مَا هُوَ شِفَاءٌ وَرَحْمَةٌ لِّلْمُؤْمِنِينَ', 'en': 'And We send down of the Quran that which is healing and mercy for the believers.', 'source': 'الإسراء: 82'},
      {'ar': 'كِتَابٌ أَنزَلْنَاهُ إِلَيْكَ مُبَارَكٌ لِّيَدَّبَّرُوا آيَاتِهِ وَلِيَتَذَكَّرَ أُولُو الْأَلْبَابِ', 'en': 'A blessed Book We sent down to you, that they may reflect upon its verses and men of understanding may remember.', 'source': 'ص: 29'},
      {'ar': 'خَيْرُكُمْ مَنْ تَعَلَّمَ القُرْآنَ وَعَلَّمَهُ', 'en': 'The best of you are those who learn the Quran and teach it.', 'source': 'رواه البخاري'},
      {'ar': 'يُقَالُ لِصَاحِبِ القُرْآنِ: اقْرَأْ وَارْتَقِ وَرَتِّلْ كَمَا كُنْتَ تُرَتِّلُ فِي الدُّنْيَا', 'en': 'It will be said to the companion of the Quran: "Read, ascend, recite as you used to recite in the world."', 'source': 'رواه الترمذي'},
      {'ar': 'مَنْ قَرَأَ حَرْفًا مِنْ كِتَابِ اللهِ فَلَهُ بِهِ حَسَنَةٌ، وَالحَسَنَةُ بِعَشْرِ أَمْثَالِهَا', 'en': 'Whoever reads one letter from the Book of Allah earns ten rewards for it.', 'source': 'رواه الترمذي'},
      {'ar': 'المَاهِرُ بِالقُرْآنِ مَعَ السَّفَرَةِ الكِرَامِ البَرَرَةِ', 'en': 'The proficient in the Quran will be with the noble, obedient angels.', 'source': 'رواه البخاري ومسلم'},
      {'ar': 'اقْرَأْ بِاسْمِ رَبِّكَ الَّذِي خَلَقَ', 'en': 'Read in the name of your Lord who created.', 'source': 'العلق: 1'},
      {'ar': 'وَلَقَدْ يَسَّرْنَا الْقُرْآنَ لِلذِّكْرِ فَهَلْ مِن مُّدَّكِرٍ', 'en': 'And We have certainly made the Quran easy for remembrance — so is there any who will remember?', 'source': 'القمر: 17'},
      {'ar': 'مَثَلُ المؤمِنِ القَارِئِ للقُرآنِ كَمَثَلِ الأُترُجَّةِ: طَعْمُهَا طَيِّبٌ وَرِيحُهَا طَيِّبٌ', 'en': 'The believer who recites the Quran is like a citron: its taste is delicious and its scent fragrant.', 'source': 'رواه البخاري'},
      {'ar': 'اقْتَرِئُوا القُرْآنَ فَإِنَّهُ يَأْتِي يَوْمَ القِيَامَةِ شَفِيعًا لأَصْحَابِهِ', 'en': 'Recite the Quran, for it will come on the Day of Resurrection as an intercessor for its companions.', 'source': 'رواه مسلم'},
      {'ar': 'قُلْبُكُمْ يَصْدَأُ كَمَا يَصْدَأُ الرِّيبُ — اُقْرَؤُوا القُرْآنَ تُنْفَضُّ الصَّدَأُ', 'en': 'Your hearts rust as iron rusts — polish them with the Quran.', 'source': 'من هدي النبي ﷺ'},
    ],

    // ═══ الصلاة ═══
    'prayer': [
      {'ar': 'وَاسْتَعِينُوا بِالصَّبْرِ وَالصَّلَاةِ', 'en': 'And seek help through patience and prayer.', 'source': 'البقرة: 45'},
      {'ar': 'إِنَّ الصَّلَاةَ كَانَتْ عَلَى الْمُؤْمِنِينَ كِتَابًا مَّوْقُوتًا', 'en': 'Indeed, prayer has been decreed upon the believers at specified times.', 'source': 'النساء: 103'},
      {'ar': 'وَأَقِمِ الصَّلَاةَ لِذِكْرِي', 'en': 'And establish prayer for My remembrance.', 'source': 'طه: 14'},
      {'ar': 'أَفْضَلُ الأَعْمَالِ الصَّلَاةُ عَلَى وَقْتِهَا', 'en': 'The best deed is prayer offered on time.', 'source': 'متفق عليه'},
      {'ar': 'الصَّلَوَاتُ الخَمْسُ كَفَّارَةٌ لِمَا بَيْنَهُنَّ مَا لَمْ تُؤْتَ كَبِيرَةٌ', 'en': 'The five prayers expiate what is between them, so long as no major sin is committed.', 'source': 'رواه مسلم'},
      {'ar': 'صَلَّوا فَأَفْلَحُوا — وَالصَّلَاةُ نُورٌ', 'en': 'Pray and prosper — prayer is a light.', 'source': 'رواه مسلم'},
      {'ar': 'أَقْرَبُ مَا يَكُونُ العَبْدُ مِنْ رَبِّهِ وَهُوَ سَاجِدٌ', 'en': 'The closest a servant is to his Lord is while in prostration.', 'source': 'رواه مسلم'},
      {'ar': 'إِذَا قُمْتَ إِلَى الصَّلَاةِ فَأَقِمِ الصَّلَاةَ وِدَاعًا', 'en': 'When you stand for prayer, pray a farewell prayer.', 'source': 'من هدي النبي ﷺ'},
    ],

    // ═══ الوقت ═══
    'time': [
      {'ar': 'وَالْعَصْرِ • إِنَّ الْإِنسَانَ لَفِي خُسْرٍ • إِلَّا الَّذِينَ آمَنُوا وَعَمِلُوا الصَّالِحَاتِ', 'en': 'By time — mankind is in loss, except those who believe, do good, and counsel truth and patience.', 'source': 'العصر'},
      {'ar': 'نِعْمَتَانِ مَغْبُونٌ فِيهِمَا كَثِيرٌ مِنَ النَّاسِ: الصِّحَّةُ وَالفَرَاغُ', 'en': 'Two blessings many people squander: health and free time.', 'source': 'رواه البخاري'},
      {'ar': 'لَا يُؤْمِنُ أَحَدُكُمْ حَتَّى يُحِبَّ لِأَخِيهِ مَا يُحِبُّ لِنَفْسِهِ — وَاغْتَنِمْ خَمْسًا قَبْلَ خَمْسٍ: شَبَابَكَ قَبْلَ هَرَمِكَ', 'en': 'Seize five before five: your youth before old age.', 'source': 'من هدي النبي ﷺ'},
      {'ar': 'وَهُوَ الَّذِي جَعَلَ اللَّيْلَ وَالنَّهَارَ خِلْفَتًا لِمَنْ أَرَادَ أَن يَذَّكَّرَ', 'en': 'He made night and day alternate for whoever desires to reflect.', 'source': 'الفرقان: 62'},
      {'ar': 'فَإِذَا فَرَغْتَ فَانصَبْ • وَإِلَىٰ رَبِّكَ فَارْغَب', 'en': 'When you have finished, devote yourself; and turn to your Lord in longing.', 'source': 'الشرح: 7-8'},
      {'ar': 'لَا يَلُودَكُمْ شَيْءٌ عَنِ اسْتِغْلَالِ وَقْتِكُمْ فَمَنْ ضَيَّعَ وَقْتَهُ نَدِمَ', 'en': 'Let nothing divert you from using your time well — whoever wastes it regrets it.', 'source': 'من كلام السلف'},
      {'ar': 'الْأَعْمَالُ الصَّالِحَةُ تُنْجِي صَاحِبَهَا فَاعْتَصِمْ بِزَمَنِكَ', 'en': 'Righteous deeds deliver their doer — hold fast to your time.', 'source': 'من كلام السلف'},
      {'ar': 'وَعِندَهُ مَفَاتِحُ الْغَيْبِ — وَالْيَوْمُ أَمَانَةٌ مِنْ عِندِهِ سُبْحَانَهُ', 'en': 'Time is a trust from Him — spend it where it profits.', 'source': 'تأمل'},
      {'ar': 'الدَّقيقةُ التي تَمضي لا تَعودُ — فَاجْعَلْ كُلَّ دَقيقةٍ في حَياتِكَ ذِكرًا أو عِلمًا أو عَمَلًا', 'en': 'A minute that passes never returns — fill each minute with remembrance, knowledge, or work.', 'source': 'حكمة'},
      {'ar': 'خَيْرُ الزَّادِ التَّقْوَى وَخَيْرُ الرِّزْقِ الطَّيِّبُ — فَوَقْتُكَ رِزْقٌ أَيْضًا', 'en': 'Your time is provision too — invest it wisely.', 'source': 'حكمة'},
      {'ar': 'إِذَا صَلَّحَتِ السَّاعَةُ صَلَحَتِ السَّاعَاتُ — ابدأ الآن', 'en': 'Fix this hour and you fix all hours — begin now.', 'source': 'حكمة'},
      {'ar': 'مَنِ اسْتَعَاذَ بِاللهِ مِنَ الفَرَاغِ وَالضَّيْعِ رَبَّاهُ فِي الأَنْفَاسِ الثَّمِينَةِ', 'en': 'Seek refuge in Allah from idleness — He will bless your breaths.', 'source': 'حكمة'},
    ],

    // ═══ العلم والدراسة ═══
    'study': [
      {'ar': 'وَقُل رَّبِّ زِدْنِي عِلْمًا', 'en': 'And say: "My Lord, increase me in knowledge."', 'source': 'طه: 114'},
      {'ar': 'مَنْ سَلَكَ طَرِيقًا يَلْتَمِسُ فِيهِ عِلْمًا سَهَّلَ اللهُ لَهُ بِهِ طَرِيقًا إِلَى الْجَنَّةِ', 'en': 'Whoever travels a path seeking knowledge, Allah eases for him a path to Paradise.', 'source': 'رواه مسلم'},
      {'ar': 'إِنَّ اللَّهَ وَمَلَائِكَتَهُ وَأَهْلَ السَّمَاوَاتِ وَالْأَرْضِ حَتَّى النَّمْلَةَ فِي جُحْرِهَا لَيُصَلُّونَ عَلَى مُعَلِّمِ النَّاسِ الْخَيْرَ', 'en': 'Allah, His angels, and all creation bless those who teach people goodness.', 'source': 'رواه الترمذي'},
      {'ar': 'الْعِلْمُ نُورٌ يَهْدَاكُمْ مِنَ الظُّلُمَاتِ — فَاطْلُبْهُ وَأَنْتَ مُوَافِقٌ', 'en': 'Knowledge is light guiding you from darkness — pursue it while you can.', 'source': 'حديث شريف'},
      {'ar': 'مَنْ يُرِدِ اللَّهُ بِهِ خَيْرًا يُفَقِّهْهُ فِي الدِّينِ', 'en': 'Whomever Allah wills good for, He grants understanding of the religion.', 'source': 'متفق عليه'},
      {'ar': 'الْعَالِمُ أَشَدُّ عَلَى الشَّيْطَانِ مِنْ الْمُتَعَبِّدِ', 'en': 'The scholar is harder on Satan than the devout worshipper.', 'source': 'من كلام السلف'},
      {'ar': 'اقْرَأْ وَرَبُّكَ الْأَكْرَمُ • الَّذِي عَلَّمَ بِالْقَلَمِ', 'en': 'Read, and your Lord is the Most Generous — Who taught by the pen.', 'source': 'العلق: 3-4'},
      {'ar': 'إِنَّ فَضْلَ العِلْمِ أَكْبَرُ مِنْ فَضْلِ العِبَادَةِ فَإنَّ نُورَ العِلْمِ يَسُدُّ نُورَ العِبَادَةِ', 'en': 'Knowledge outweighs mere ritual — its light illuminates the path of worship.', 'source': 'من كلام السلف'},
      {'ar': 'عَلَى مَا اعْتَدَدْتَ مِنَ الْعِلْمِ تُبْنَى الدُّنْيَا وَالدِّينُ', 'en': 'On the knowledge you build today rests both faith and tomorrow.', 'source': 'حكمة'},
      {'ar': 'الْمُجْتَهِدُ يَصِلُ إِلَى الْمَأْمُولِ وَالكَاسِلُ يَبْقَى فِي الْحُلْمِ', 'en': 'The diligent reach their goal; the lazy remain dreaming.', 'source': 'حكمة'},
      {'ar': 'رَبِّ اشْرَحْ لِي صَدْرِي وَيَسِّرْ لِي أَمْرِي', 'en': 'My Lord, expand for me my chest and ease my task.', 'source': 'طه: 25-26'},
      {'ar': 'إِنَّ مَعَ الْعُسْرِ يُسْرًا — فَمَا الشَّقَاءُ إِلَّا مَرْحَلَةٌ', 'en': 'With hardship comes ease — difficulty is only a stage.', 'source': 'الشرح: 6'},
    ],

    // ═══ العمل والإتقان ═══
    'work': [
      {'ar': 'إِنَّ اللَّهَ يُحِبُّ إِذَا عَمِلَ أَحَدُكُمْ عَمَلًا أَنْ يُتْقِنَهُ', 'en': 'Allah loves that when one of you does work, he does it with excellence.', 'source': 'رواه البيهقي'},
      {'ar': 'وَقُلِ اعْمَلُوا فَسَيَرَى اللَّهُ عَمَلَكُمْ وَرَسُولُهُ وَالْمُؤْمِنُونَ', 'en': 'Work, for Allah will see your deeds, and His Messenger, and the believers.', 'source': 'التوبة: 105'},
      {'ar': 'لِكُلِّ امْرِئٍ مِنَ النَّاسِ سُوقُهُ فَاسْتَقِمُوا وَلَا تَتَكَلَّفُوا', 'en': 'Each person has their own path — be upright and sincere in yours.', 'source': 'من هدي النبي ﷺ'},
      {'ar': 'أَحَبُّ الأَعْمَالِ إِلَى اللهِ أَدْوَمُهَا وَإِنْ قَلَّ', 'en': 'The deeds most beloved to Allah are the most constant, even if small.', 'source': 'متفق عليه'},
      {'ar': 'وَأَن لَّيْسَ لِلْإِنسَانِ إِلَّا مَا سَعَى • وَأَنَّ سَعْيَهُ سَوْفَ يُرَىٰ', 'en': 'Man shall have nothing but what he strives for — and his striving will be seen.', 'source': 'النجم: 39-40'},
      {'ar': 'الْكَادُّ عَلَى عِيَالِهِ كَالمُجَاهِدِ فِي سَبِيلِ اللهِ', 'en': 'One who works hard to support his family is like a striver in God\'s cause.', 'source': 'رواه الطبراني'},
      {'ar': 'مَنْ أَصْبَحَ آمِنًا فِي سِرِّهِ وَعَلَنِيَهِ أَصْبَحَ مُوفَّقًا فِي عَمَلِهِ', 'en': 'Whoever begins the day sincere inwardly and outwardly succeeds in his work.', 'source': 'حكمة'},
      {'ar': 'التَّقْوَى هُنَا وَالتَّقْوَى هُنَاكَ — وَفِي كُلِّ عَمَلٍ بَرَكَةٌ مَعَ الإِخْلَاصِ', 'en': 'With sincerity, every honest labor carries blessing.', 'source': 'حكمة'},
      {'ar': 'اعْمَلْ لِدُنْيَاكَ كَأَنَّكَ تَعِيشُ أَبَدًا وَاعْمَلْ لِآخِرَتِكَ كَأَنَّكَ تَمُوتُ غَدًا', 'en': 'Work for your world as if you live forever, and for the Hereafter as if you die tomorrow.', 'source': 'من كلام السلف'},
      {'ar': 'الْإِتْقَانُ عِبَادَةٌ — فَاجْعَلْ عَمَلَكَ نِيَّةً صَادِقَةً', 'en': 'Excellence is worship — turn your work into sincere intention.', 'source': 'حكمة'},
      {'ar': 'وَأَنَّ سَعْيَهُ سَوْفَ يُرَى • ثُمَّ يُجْزَاهُ الْجَزَاءَ الْأَوْفَى', 'en': 'His effort will be seen, then he will be recompensed fully.', 'source': 'النجم: 40-41'},
      {'ar': 'مَنْ طَلَبَ شَيْئًا نَالَ بَعْضَهُ أَوْ كُلَّهُ', 'en': 'Whoever pursues something attains some or all of it.', 'source': 'حكمة'},
    ],

    // ═══ الصحة والرياضة ═══
    'health': [
      {'ar': 'وَكُلُوا وَاشْرَبُوا وَلَا تُسْرِفُوا', 'en': 'Eat and drink, but do not be excessive.', 'source': 'الأعراف: 31'},
      {'ar': 'الْمُؤْمِنُ الْقَوِيُّ خَيْرٌ وَأَحَبُّ إِلَى اللهِ مِنَ الْمُؤْمِنِ الضَّعِيفِ', 'en': 'The strong believer is better and more beloved to Allah than the weak believer.', 'source': 'رواه مسلم'},
      {'ar': 'فِي جَسَدِكَ حَقٌّ — وَأَعِنِّي عَلَى ذِكْرِكَ بِبَدَنٍ سَلِيمٍ', 'en': 'Your body has rights over you — care for it as a trust.', 'source': 'من هدي النبي ﷺ'},
      {'ar': 'مَا مِنْ جَسَدٍ يَتَحَرَّكُ إِلَّا وَاللهُ يَنْفَعُهُ بِحَرَكَتِهِ', 'en': 'Every body that moves benefits from its movement.', 'source': 'من كلام السلف'},
      {'ar': 'وَجَعَلْنَا مِنَ الْمَاءِ كُلَّ شَيْءٍ حَيٍّ — فَاسْقِ جَسَدَكَ مِنَ الْمَاءِ', 'en': 'From water We made every living thing — hydrate your body.', 'source': 'الأنبياء: 30'},
      {'ar': 'صِيَامٌ لَهُ وِتْرٌ — فَالصَّبْرُ نِصْفُ الإِيمَانِ وَالصِّحَّةُ رَأْسٌ مِمَّا قُسِمَ', 'en': 'Health is a crown on the heads of the healthy that only the ill can see.', 'source': 'حكمة'},
      {'ar': 'لَا ضَرَرَ وَلَا ضِرَارَ — فَاحْمِ جَسَدَكَ بِالْحَرَكَةِ وَالنُّومِ الصَّحِيحِ', 'en': 'No harm — protect your body with movement and sound sleep.', 'source': 'قاعدة شرعية'},
      {'ar': 'الْجِسْمُ الْمُتَوَازِنُ يَحْمِلُ الْعَقْلَ الصَّافِيَ — فَرِّغْ لِتَدْرِيكِكَ نَصِيبًا', 'en': 'A balanced body carries a clear mind — give exercise its share.', 'source': 'حكمة'},
      {'ar': 'أَفْضَلُ الْأَعْمَالِ مَا دَاوَمَ عَلَيْهِ صَاحِبُهُ — وَالدَّوَامُ يَبْنَى عَلَى الصِّحَّةِ', 'en': 'Consistency builds on health — guard both.', 'source': 'حكمة'},
      {'ar': 'قَوِّ جَسَدَكَ لِطَاعَةِ اللهِ فَإِنَّ الْجِسْمَ الْمُتْعَبَ لَا يُحِبُّ الطَّاعَةَ', 'en': 'Strengthen your body for obedience — the exhausted body resists it.', 'source': 'من كلام السلف'},
    ],

    // ═══ الصبر والمواصلة ═══
    'patience': [
      {'ar': 'وَاصْبِرْ فَإِنَّ اللَّهَ لَا يُضِيعُ أَجْرَ الْمُحْسِنِينَ', 'en': 'Be patient — Allah does not waste the reward of the doers of good.', 'source': 'هود: 115'},
      {'ar': 'إِنَّ اللَّهَ مَعَ الصَّابِرِينَ', 'en': 'Indeed, Allah is with the patient.', 'source': 'البقرة: 153'},
      {'ar': 'وَالصَّابِرِينَ فِي الْبَأْسَاءِ وَالضَّرَّاءِ وَحِينَ الْبَأْسِ', 'en': 'Those patient in hardship and adversity, and in battle — those are the truthful.', 'source': 'البقرة: 177'},
      {'ar': 'الصَّبْرُ ضِيَاءٌ', 'en': 'Patience is light.', 'source': 'رواه مسلم'},
      {'ar': 'عَجَبًا لِأَمْرِ الْمُؤْمِنِ إِنَّ أَمْرَهُ كُلَّهُ خَيْرٌ', 'en': 'Amazing is the affair of the believer — all of it is good.', 'source': 'رواه مسلم'},
      {'ar': 'مَا يُصِيبُ الْمُسْلِمَ هَرَّمًا وَلَا وَصَبًا وَلَا نَصَبًا إِلَّا كَفَّرَ اللَّهُ بِهَا عَنْهُ', 'en': 'No fatigue, illness, or worry befalls a Muslim except that Allah expiates some sins by it.', 'source': 'متفق عليه'},
      {'ar': 'وَمَن يَتَّقِ اللَّهَ يَجْعَل لَّهُ مَخْرَجًا', 'en': 'Whoever fears Allah — He will make a way out for him.', 'source': 'الطلاق: 2'},
      {'ar': 'فَاسْتَبِقُوا الْخَيْرَاتِ — فَالْمُوَاصَلَةُ خَيْرٌ مِنَ الْكَثْرَةِ الْمُنْقَطِعَةِ', 'en': 'Race toward goodness — consistency beats quantity.', 'source': 'حكمة'},
    ],

    // ═══ الشكر والامتنان ═══
    'gratitude': [
      {'ar': 'لَئِن شَكَرْتُمْ لَأَزِيدَنَّكُمْ', 'en': 'If you are grateful, I will surely increase you.', 'source': 'إبراهيم: 7'},
      {'ar': 'شُكْرُ النِّعْمَةِ يَجْلِبُ الزِّيَادَةَ', 'en': 'Gratitude brings increase.', 'source': 'حكمة قرآنية'},
      {'ar': 'مَنْ لَا يَشْكُرُ النَّاسَ لَا يَشْكُرُ اللهَ', 'en': 'Whoever is not grateful to people is not grateful to Allah.', 'source': 'رواه أحمد'},
      {'ar': 'وَبِتَمَاسُكُم بِالْعُرْوَةِ الْوُثْقَى — فَاشْكُرْ لِمَنْ أَنْعَمَ عَلَيْكَ', 'en': 'Thank Him who bestowed favor upon you.', 'source': 'تأمل'},
      {'ar': 'اللَّهُمَّ أَعِنِّي عَلَى ذِكْرِكَ وَشُكْرِكَ وَحُسْنِ عِبَادَتِكَ', 'en': 'O Allah, help me remember You, thank You, and worship You well.', 'source': 'وصية النبي ﷺ لمعاذ'},
      {'ar': 'الْعَبْدُ الشَّكُورُ أَفْضَلُ مِنَ الْعَبْدِ الصَّابِرُ — فَاجْمَعْ بَيْنَهُمَا', 'en': 'Combine gratitude and patience — both elevate you.', 'source': 'من كلام السلف'},
      {'ar': 'نَعِمْتَ بِالْيَقِينِ مَنْ رَأَى النِّعْمَةَ فَحَمِدَ اللهَ قَدْ أَدَّى شُكْرَهَا', 'en': 'Who sees a blessing and praises Allah has fulfilled its thanks.', 'source': 'حكمة'},
      {'ar': 'كُلُّ نِعْمَةٍ تَرَاهَا فَقُلْ: الْحَمْدُ لِلَّهِ الَّذِي بِنِعْمَتِهِ تَتِمُّ الصَّالِحَاتُ', 'en': 'For every blessing say: Praise be to Allah by whose favor good works are completed.', 'source': 'حديث شريف'},
    ],

    // ═══ عام / افتراضي ═══
    'default': [
      {'ar': 'وَأَنَّ سَعْيَهُ سَوْفَ يُرَى', 'en': 'And that his effort is going to be seen.', 'source': 'النجم: 40'},
      {'ar': 'إِنَّ مَعَ الْعُسْرِ يُسْرًا', 'en': 'Indeed, with hardship comes ease.', 'source': 'الشرح: 6'},
      {'ar': 'أَحَبُّ الْأَعْمَالِ إِلَى اللهِ أَدْوَمُهَا وَإِنْ قَلَّ', 'en': 'The most beloved deeds to Allah are the most consistent, even if few.', 'source': 'متفق عليه'},
      {'ar': 'مَنْ عَمِلَ صَالِحًا فَلِنَفْسِهِ', 'en': 'Whoever does righteousness — it is for his own soul.', 'source': 'فصلت: 46'},
      {'ar': 'فَاذْكُرُونِي أَذْكُرْكُمْ وَاشْكُرُوا لِي', 'en': 'Remember Me; I will remember you. Be grateful to Me.', 'source': 'البقرة: 152'},
      {'ar': 'وَمَا تَوْفِيقِي إِلَّا بِاللهِ عَلَيْهِ تَوَكَّلْتُ وَإِلَيْهِ أُنِيبُ', 'en': 'My success is only through Allah. Upon Him I rely, and to Him I return.', 'source': 'هود: 88'},
      {'ar': 'وَقُل رَّبِّ زِدْنِي عِلْمًا', 'en': 'Say: My Lord, increase me in knowledge.', 'source': 'طه: 114'},
      {'ar': 'إِنَّ اللَّهَ لَا يُضِيعُ أَجْرَ الْمُحْسِنِينَ', 'en': 'Allah does not waste the reward of the good-doers.', 'source': 'التوبة: 120'},
      {'ar': 'خَيْرُ النَّاسِ أَنْفَعُهُمْ لِلنَّاسِ', 'en': 'The best of people are those most beneficial to others.', 'source': 'حديث شريف'},
      {'ar': 'وَتَعَاوَنُوا عَلَى الْبِرِّ وَالتَّقْوَى', 'en': 'Cooperate in righteousness and piety.', 'source': 'المائدة: 2'},
      {'ar': 'الْيَقِينُ يُذْهِبُ الْكَسَلَ — فَتَفَقَّهْ وَاعْمَلْ وَلَا تَكُنْ كَالَّذِي نَسِيَ اللهَ', 'en': 'Certainty removes laziness — act with purpose and presence.', 'source': 'حكمة'},
      {'ar': 'كُلُّ عَمَلٍ صَالِحٍ يُجْزَى بِمِثْلِهِ عَشْرَ أَمْثَالِهِ', 'en': 'Every good deed is rewarded tenfold.', 'source': 'حديث شريف'},
    ],

    // ═══ إنجازات كبيرة (Milestones) ═══
    'milestone': [
      {'ar': 'وَالَّذِينَ جَاهَدُوا فِينَا لَنَهْدِيَنَّهُمْ سُبُلَنَا', 'en': 'Those who strive for Us — We will surely guide them to Our ways.', 'source': 'العنكبوت: 69'},
      {'ar': 'مَنْ يُرِدِ اللَّهُ بِهِ خَيْرًا يُفَقِّهْهُ فِي الدِّينِ', 'en': 'Whomever Allah wills good for, He gives understanding of religion.', 'source': 'متفق عليه'},
      {'ar': 'أَحَبُّ الْأَعْمَالِ إِلَى اللهِ أَدْوَمُهَا — وَأَنْتَ مُوَاصِلٌ', 'en': 'The most beloved deeds are the constant ones — and you keep going!', 'source': 'متفق عليه'},
      {'ar': 'وَأَقِمِ الصَّلَاةَ طَرَفَيِ النَّهَارِ — فَإِنَّ الثَّبَاتَ مِنَ اللهِ لِلْمُوَاصِلِينَ', 'en': 'Steadfastness comes from Allah to those who persevere.', 'source': 'تأمل'},
      {'ar': 'الَّذِينَ يَتَذَكَّرُونَ اللَّهَ قِيَامًا وَقُعُودًا وَعَلَىٰ جُنُوبِهِمْ وَيَتَفَكَّرُونَ', 'en': 'Those who remember Allah standing, sitting, and lying down, and reflect on creation.', 'source': 'آل عمران: 191'},
      {'ar': 'إِنَّ اللَّهَ يُحِبُّ إِذَا عَمِلَ أَحَدُكُمْ عَمَلًا أَنْ يُتْقِنَهُ — وَأَنْتَ تُتْقِنُ', 'en': 'Allah loves excellence in work — and you are excelling.', 'source': 'حديث شريف'},
      {'ar': 'فَاسْتَبِقُوا الْخَيْرَاتِ — أَنْتَ فِي السِّبَاقِ وَاللهُ مُعِينُكَ', 'en': 'Race toward goodness — you are in the race and Allah aids you.', 'source': 'البقرة: 148'},
      {'ar': 'وَأَنْ لَيْسَ لِلْإِنْسَانِ إِلَّا مَا سَعَى وَأَنَّ سَعْيَهُ سَوْفَ يُرَى', 'en': 'Man has nothing but what he strives for — your striving is being seen.', 'source': 'النجم: 39-40'},
    ],
  };

  /// Resolve category from a project name (Arabic or English), or theme key.
  static String? _resolveCategory(String? projectName) {
    if (projectName == null || projectName.isEmpty) return null;
    final lower = projectName.toLowerCase();

    for (final entry in _keywords.entries) {
      for (final kw in entry.value) {
        final k = kw.toLowerCase();
        if (lower.contains(k) || projectName.contains(kw)) {
          return entry.key;
        }
      }
    }
    return null;
  }

  /// Full ordered list for a project's theme — used by the in-session
  /// rotating quote display. Falls back to the default bank.
  static List<Map<String, String>> quotesForProject(String? projectName) {
    final category = _resolveCategory(projectName);
    return category != null
        ? _categories[category]!
        : _categories['default']!;
  }

  /// Deterministic pick: same inputs always yield the same quote,
  /// guaranteeing quote text and its source always match.
  static Map<String, String> getCompletionQuote(
    int sessionCount, {
    bool isMilestone = false,
    String? projectName,
  }) {
    if (isMilestone) {
      final list = _categories['milestone']!;
      return list[sessionCount % list.length];
    }

    final category = _resolveCategory(projectName);
    final list = category != null ? _categories[category]! : _categories['default']!;
    // Mix session count with name hash so different projects vary.
    final seed = sessionCount + projectName.hashCode.abs() % list.length;
    return list[seed % list.length];
  }

  /// Quote text — always shown in Arabic (Quranic verses & hadiths
  /// are best experienced in their original language).
  static String quoteText(Map<String, String> quote) {
    return quote['ar'] ?? quote['en'] ?? '';
  }
}
