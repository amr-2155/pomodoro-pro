import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('ar'),
    Locale('en'),
  ];

  bool get isArabic => locale.languageCode == 'ar';
  bool get isEnglish => locale.languageCode == 'en';

  String _t(Map<String, String> map) => map[locale.languageCode] ?? map['en']!;

  // ─── Navigation ───
  String get timer => _t({'ar': 'المؤقت', 'en': 'Timer'});
  String get projects => _t({'ar': 'المشاريع', 'en': 'Projects'});
  String get tasks => _t({'ar': 'المهام', 'en': 'Tasks'});
  String get stats => _t({'ar': 'الإحصائيات', 'en': 'Stats'});
  String get settings => _t({'ar': 'الإعدادات', 'en': 'Settings'});

  // ─── Timer Modes ───
  String get focus => _t({'ar': 'تركيز', 'en': 'Focus'});
  String get shortBreak => _t({'ar': 'استراحة قصيرة', 'en': 'Short Break'});
  String get longBreak => _t({'ar': 'استراحة طويلة', 'en': 'Long Break'});
  String get stopwatch => _t({'ar': 'تصاعدي', 'en': 'Stopwatch'});

  // ─── Timer Controls ───
  String get reset => _t({'ar': 'إعادة', 'en': 'Reset'});
  String get skip => _t({'ar': 'تخطي', 'en': 'Skip'});
  String get start => _t({'ar': 'ابدأ', 'en': 'Start'});
  String get pause => _t({'ar': 'إيقاف مؤقت', 'en': 'Pause'});
  String get resume => _t({'ar': 'استئناف', 'en': 'Resume'});
  String get stopAlarm => _t({'ar': 'إيقاف التنبيه', 'en': 'Stop Alarm'});

  // ─── Timer Screen ───
  String get selectProject => _t({'ar': 'اختر مشروع', 'en': 'Select Project'});
  String get noProjectsYet => _t({'ar': 'لا توجد مشاريع بعد', 'en': 'No projects yet'});
  String get createProjectHint => _t({
    'ar': 'أنشئ مشروع في تبويب المشاريع\nثم اختره هنا لتبدأ التتبع',
    'en': 'Create a project in the Projects tab\nthen select it here to start tracking',
  });
  String get clearSelection => _t({'ar': 'إزالة الاختيار', 'en': 'Clear Selection'});
  String get setDuration => _t({'ar': 'تحديد المدة', 'en': 'Set Duration'});
  String get longPressHint => _t({'ar': 'اضغط مطولاً لتحديد المدة', 'en': 'Long press to set duration'});
  String get longPressOnTimer => _t({
    'ar': 'اضغط مطولاً على دائرة المؤقت للاختيار',
    'en': 'Long press on the timer circle to pick',
  });
  String get minutes => _t({'ar': 'دقائق', 'en': 'Minutes'});
  String get seconds => _t({'ar': 'ثوانٍ', 'en': 'Seconds'});
  String get todayProgress => _t({'ar': 'تقدم اليوم', 'en': "Today's Progress"});
  String get sessions => _t({'ar': 'جلسات', 'en': 'sessions'});
  String get untilLongBreak => _t({'ar': 'حتى الاستراحة الطويلة', 'en': 'until long break'});
  String get keyboardHint => _t({
    'ar': 'Space: تشغيل/إيقاف مؤقت | R: إعادة ضبط | S: تخطي',
    'en': 'Space: Start/Pause | R: Reset | S: Skip',
  });

  // ─── Stopwatch ───
  String get discardStopwatch => _t({'ar': 'إسقاط ساعة الإيقاف؟', 'en': 'Discard stopwatch?'});
  String get stopwatchRunning => _t({'ar': 'ساعة الإيقاف قيد التشغيل', 'en': 'Stopwatch running'});
  String get stopwatchSession => _t({'ar': 'جلسة ساعة الإيقاف', 'en': 'Stopwatch session'});
  String get restoreSession => _t({'ar': 'استكمال', 'en': 'Restore'});
  String get endSession => _t({'ar': 'إنهاء الجلسة', 'en': 'End Session'});
  String get discard => _t({'ar': 'إسقاط', 'en': 'Discard'});
  String get cancel => _t({'ar': 'إلغاء', 'en': 'Cancel'});
  String get delete => _t({'ar': 'حذف', 'en': 'Delete'});
  String get wellDone => _t({'ar': 'أحسنت', 'en': 'Well Done'});
  String get saveSession => _t({'ar': 'حفظ الجلسة', 'en': 'Save Session'});

  // ─── Completion ───
  String get sessionComplete => _t({'ar': 'اكتملت الجلسة!', 'en': 'Session Complete!'});
  String get greatJob => _t({'ar': 'عمل رائع!', 'en': 'Great Job!'});
  String get milestoneReached => _t({'ar': '!وصلت لمرحلة جديدة', 'en': 'Milestone Reached!'});
  String get greatWork => _t({'ar': 'عمل رائع! حان وقت الاستراحة.', 'en': 'Great work! Time for a break.'});
  String get readyToFocus => _t({'ar': 'مستعد للتركيز؟', 'en': 'Ready to focus again?'});
  String get howWasSession => _t({'ar': 'كيف كانت هذه الجلسة؟', 'en': 'How was this session?'});
  String get total => _t({'ar': 'المجموع', 'en': 'total'});
  String get continueLabel => _t({'ar': 'متابعة', 'en': 'Continue'});
  String get addNote => _t({'ar': 'أضف ملاحظة... (اختياري)', 'en': 'Add a note... (optional)'});
  String get continueBtn => _t({'ar': 'متابعة', 'en': 'Continue'});

  // ─── Settings Sections ───
  String get timerSettings => _t({'ar': 'المؤقت', 'en': 'Timer'});
  String get goalsSettings => _t({'ar': 'الأهداف', 'en': 'Goals'});
  String get soundSettings => _t({'ar': 'الصوت والاهتزاز', 'en': 'Sound & Vibration'});
  String get appearanceSettings => _t({'ar': 'المظهر', 'en': 'Appearance'});
  String get languageSettings => _t({'ar': 'اللغة', 'en': 'Language'});
  String get dataSettings => _t({'ar': 'البيانات', 'en': 'Data'});
  String get aboutSettings => _t({'ar': 'حول التطبيق', 'en': 'About'});

  // ─── Settings: Timer ───
  String get focusDuration => _t({'ar': 'مدة التركيز', 'en': 'Focus Duration'});
  String get shortBreakDuration => _t({'ar': 'الاستراحة القصيرة', 'en': 'Short Break'});
  String get longBreakDuration => _t({'ar': 'الاستراحة الطويلة', 'en': 'Long Break'});
  String get autoStartBreaks => _t({'ar': 'تشغيل الاستراحات تلقائياً', 'en': 'Auto-start Breaks'});
  String get autoStartBreaksDesc => _t({
    'ar': 'بدء الاستراحة تلقائياً بعد جلسة تركيز',
    'en': 'Automatically start break after a focus session',
  });
  String get autoStartFocus => _t({'ar': 'تشغيل التركيز تلقائياً', 'en': 'Auto-start Focus'});
  String get autoStartFocusDesc => _t({
    'ar': 'بدء التركيز تلقائياً بعد الاستراحة',
    'en': 'Automatically start focus after a break',
  });
  String get sessionsBeforeLongBreak => _t({'ar': 'جلسات قبل الاستراحة الطويلة', 'en': 'Sessions Before Long Break'});
  String get durationMinutes => _t({'ar': 'دقيقة', 'en': 'min'});

  // ─── Duration Input ───
  String get durationDialogTitle => _t({'ar': 'مدة التركيز', 'en': 'Focus Duration'});
  String get durationInputHint => _t({'ar': 'الدقائق', 'en': 'Minutes'});
  String get save => _t({'ar': 'حفظ', 'en': 'Save'});
  String get invalidNumber => _t({'ar': 'أدخل رقم صحيح', 'en': 'Enter a valid number'});

  // ─── Settings: Goals ───
  String get dailyGoal => _t({'ar': 'الهدف اليومي (ساعات)', 'en': 'Daily Goal (hours)'});
  String get weeklyGoal => _t({'ar': 'الهدف الأسبوعي', 'en': 'Weekly Goal'});
  String get dailyGoalTitle => _t({'ar': 'الهدف اليومي', 'en': 'Daily Goal'});
  String get targetFocusTime => _t({'ar': 'وقت التركيز المستهدف', 'en': 'Your target focus time'});
  String get changeToAnyValue => _t({'ar': 'يمكنك تغيير الهدف لأي قيمة تريدها', 'en': 'Tap the number to set any value you like'});
  String get editDailyGoal => _t({'ar': 'تعديل الهدف اليومي', 'en': 'Edit Daily Goal'});
  String get editWeeklyGoal => _t({'ar': 'تعديل الهدف الأسبوعي', 'en': 'Edit Weekly Goal'});
  String get quickPicks => _t({'ar': 'اختيارات سريعة', 'en': 'Quick picks'});
  String get customValue => _t({'ar': 'قيمة مخصصة', 'en': 'Custom value'});
  String get enterMinutesHint => _t({'ar': 'أدخل عدد الدقائق', 'en': 'Enter minutes'});
  String get invalidGoalValue => _t({'ar': 'أدخل رقماً بين 1 و100000', 'en': 'Enter a number between 1 and 100000'});
  String get unitMinutes => _t({'ar': 'دقيقة', 'en': 'minutes'});
  String get perDayAvg => _t({'ar': '≈ {n} دقيقة يومياً في المتوسط', 'en': '≈ {n} min/day on average'});
  String get goalSaved => _t({'ar': 'تم الحفظ', 'en': 'Saved'});

  // ─── Quote Library ───
  String get quoteLibrary => _t({'ar': 'مكتبة الاقتباسات', 'en': 'Quote Library'});
  String get addQuote => _t({'ar': 'إضافة اقتباس', 'en': 'Add Quote'});
  String get editQuote => _t({'ar': 'تعديل الاقتباس', 'en': 'Edit Quote'});
  String get deleteQuote => _t({'ar': 'حذف الاقتباس', 'en': 'Delete Quote'});
  String get deleteQuoteConfirm => _t({'ar': 'هل أنت متأكد من حذف هذا الاقتباس؟', 'en': 'Are you sure you want to delete this quote?'});
  String get quoteArabic => _t({'ar': 'الاقتباس بالعربي', 'en': 'Arabic Quote'});
  String get quoteArabicHint => _t({'ar': 'اكتب الاقتباس هنا...', 'en': 'Write the Arabic quote here...'});
  String get quoteEnglish => _t({'ar': 'الاقتباس بالانجليزي', 'en': 'English Quote'});
  String get quoteEnglishHint => _t({'ar': 'Write the English quote here...', 'en': 'Write the English quote here...'});
  String get quoteAuthor => _t({'ar': 'المؤلف', 'en': 'Author'});
  String get quoteAuthorHint => _t({'ar': 'اختياري', 'en': 'Optional'});
  String get quoteCategory => _t({'ar': 'التصنيف', 'en': 'Category'});
  String get custom => _t({'ar': 'مخصص', 'en': 'Custom'});
  String get quoteOfDay => _t({'ar': 'اقتباس اليوم', 'en': 'Quote of the Day'});
  String get anotherQuote => _t({'ar': 'اقتباس آخر', 'en': 'Another quote'});
  String get copiedToClipboard => _t({'ar': 'تم النسخ', 'en': 'Copied'});
  String get catAll => _t({'ar': 'الكل', 'en': 'All'});
  String get catFocus => _t({'ar': 'التركيز', 'en': 'Focus'});
  String get catDiscipline => _t({'ar': 'الانضباط', 'en': 'Discipline'});
  String get catWork => _t({'ar': 'العمل والوقت', 'en': 'Work & Time'});
  String get catSuccess => _t({'ar': 'النجاح', 'en': 'Success'});
  String get catConsistency => _t({'ar': 'الاستمرارية', 'en': 'Consistency'});
  String get catLearning => _t({'ar': 'التعلم', 'en': 'Learning'});

  // ─── Tasbih & Completion ───
  String get tasbih => _t({'ar': 'السبحة', 'en': 'Tasbih'});
  String get tapToCount => _t({'ar': 'اضغط للعد', 'en': 'Tap to count'});
  String get vibrateOnComplete => _t({'ar': 'اهتزاز عند انتهاء الجلسة', 'en': 'Vibrate on session complete'});
  String get vibrateOnCompleteDesc => _t({
    'ar': 'نمط تنبيه واضح يتكرر حتى توقفه',
    'en': 'A clear alert pattern that repeats until you stop it',
  });
  String get congratsTitle => _t({'ar': 'أحسنت!', 'en': 'Great job!'});
  String get projectCompletedBody => _t({'ar': 'اكتمل مشروع', 'en': 'Project completed'});
  String get minutesDoneLabel => _t({'ar': 'دقيقة مكتملة', 'en': 'minutes completed'});
  String get completedBadge => _t({'ar': 'مكتمل ✓', 'en': 'Done ✓'});
  String get noProject => _t({'ar': 'بدون مشروع', 'en': 'No project'});
  String get goalDoneMsg => _t({'ar': 'أحسنت، اكتمل هدفك', 'en': 'Goal complete, well done'});
  String get resetCountTitle => _t({'ar': 'إعادة العد؟', 'en': 'Reset counter?'});
  String get resetCountBody => _t({'ar': 'سيتم تصفير العد الحالي.', 'en': 'The current count will be zeroed.'});
  String get tasbeehGoalLabel => _t({'ar': 'هدف السبحة', 'en': 'Tasbeeh goal'});
  String get timesWord => _t({'ar': 'مرة', 'en': 'times'});
  String get tasbeehType => _t({'ar': 'سبحة', 'en': 'Tasbeeh'});
  String get chooseProjectHint => _t({'ar': 'اختر مشروعًا لتسجيل جلستك', 'en': 'Pick a project to record your session'});
  String get currentDhikrLabel => _t({'ar': 'الذكر الحالي', 'en': 'Current dhikr'});
  String get todaySessionWord => _t({'ar': 'جلسة اليوم', 'en': "Today's session"});
  String get totalTasbeehLabel => _t({'ar': 'إجمالي التسبيحات', 'en': 'Total tasbeeh'});
  String get goalCardTitle => _t({'ar': 'الهدف', 'en': 'Goal'});
  String get noGoalSet => _t({'ar': 'اضغط مطولًا على الدائرة لتحديد هدف', 'en': 'Long-press the circle to set a goal'});

  // ─── Project Goal Editor ───
  String get unitMinuteShort => _t({'ar': 'د', 'en': 'm'});
  String get unitMinutesWord => _t({'ar': 'دقيقة', 'en': 'minutes'});
  String get dailySuffix => _t({'ar': 'يوميًا', 'en': 'daily'});
  String get weeklyPerDayHint => _t({
    'ar': '{n} دقيقة أسبوعيًا ≈ {d} دقيقة يوميًا',
    'en': '{n} min/week ≈ {d} min/day',
  });
  String get countWeeklyGoalClear => _t({
    'ar': 'احتساب الجلسات ضمن الهدف الأسبوعي',
    'en': 'Count sessions toward the weekly goal',
  });

  // ─── Settings: Sound ───
  String get completionSoundTitle => _t({'ar': 'صوت انتهاء الجلسة', 'en': 'Completion Sound'});
  String get completionSoundDesc => _t({
    'ar': 'صوت طبيعي يخبرك بانتهاء الجلسة',
    'en': 'Natural sound when session completes',
  });
  String get countdownSoundTitle => _t({'ar': 'صوت العد التنازلي', 'en': 'Countdown Sound'});
  String get countdownSoundDesc => _t({
    'ar': 'صوت خفيف أثناء الثواني الأخيرة',
    'en': 'Gentle sound in the last seconds',
  });
  String get vibration => _t({'ar': 'الاهتزاز', 'en': 'Vibration'});
  String get vibrationDesc => _t({
    'ar': 'اهتزاز قوي عند انتهاء الجلسة',
    'en': 'Strong vibration on session complete',
  });
  String get lastSeconds => _t({'ar': 'آخر', 'en': 'last'});
  String get secondsLabel => _t({'ar': 'ثوانٍ', 'en': 'seconds'});

  // ─── Settings: Appearance ───
  String get darkMode => _t({'ar': 'الوضع الداكن', 'en': 'Dark Mode'});
  String get darkModeDesc => _t({'ar': 'استخدام السمة الداكنة', 'en': 'Use dark theme'});
  String get lightMode => _t({'ar': 'الوضع الفاتح', 'en': 'Light Mode'});
  String get startOfWeek => _t({'ar': 'بداية الأسبوع', 'en': 'Start of Week'});
  String get monday => _t({'ar': 'الاثنين', 'en': 'Monday'});
  String get sunday => _t({'ar': 'الأحد', 'en': 'Sunday'});

  // ─── Settings: Language ───
  String get arabic => _t({'ar': 'العربية', 'en': 'Arabic'});
  String get english => _t({'ar': 'English', 'en': 'English'});

  // ─── Settings: Data ───
  String get createBackup => _t({'ar': 'إنشاء نسخة احتياطية', 'en': 'Create Backup'});
  String get createBackupDesc => _t({
    'ar': 'تحميل جميع البيانات كملف احتياطي',
    'en': 'Download all data as a JSON backup file',
  });
  String get restoreBackup => _t({'ar': 'استعادة نسخة احتياطية', 'en': 'Restore Backup'});
  String get restoreBackupDesc => _t({
    'ar': 'استيراد البيانات من ملف احتياطي',
    'en': 'Import data from a backup file',
  });
  String get exportCsv => _t({'ar': 'تصدير CSV', 'en': 'Export CSV'});
  String get exportCsvDesc => _t({
    'ar': 'تصدير الجلسات بصيغة CSV',
    'en': 'Export sessions as a spreadsheet-friendly CSV file',
  });
  String get resetAllData => _t({'ar': 'مسح جميع البيانات', 'en': 'Reset All Data'});
  String get resetAllDataDesc => _t({
    'ar': 'حذف جميع الجلسات والمشاريع',
    'en': 'Delete all sessions and projects',
  });
  String get resetConfirmTitle => _t({'ar': 'مسح جميع البيانات', 'en': 'Reset All Data'});
  String get resetConfirmDesc => _t({
    'ar': 'سيتم حذف جميع جلساتك ومشاريعك. لا يمكن التراجع.',
    'en': 'This will delete all your sessions and projects. This cannot be undone.',
  });
  String get resetBtn => _t({'ar': 'مسح', 'en': 'Reset'});
  String get dataReset => _t({'ar': 'تم مسح جميع البيانات', 'en': 'All data has been reset'});
  String get dataExported => _t({'ar': 'تم التصدير!', 'en': 'Data exported!'});

  // ─── Settings: About ───
  String get installApp => _t({'ar': 'تثبيت التطبيق', 'en': 'Install App'});
  String get installAppDesc => _t({
    'ar': 'إضافة التطبيق إلى الشاشة الرئيسية',
    'en': 'Add Pomodoro Pro to your home screen',
  });
  String get appVersion => 'Pomodoro Pro v1.0.0';
  String get builtWith => _t({
    'ar': 'صُنع باستخدام Flutter',
    'en': 'Built with Flutter',
  });

  // ─── Projects ───
  String get newProject => _t({'ar': 'مشروع جديد', 'en': 'New Project'});
  String get editProject => _t({'ar': 'تعديل المشروع', 'en': 'Edit Project'});
  String get projectName => _t({'ar': 'اسم المشروع', 'en': 'Project name'});
  String get descriptionOptional => _t({'ar': 'الوصف (اختياري)', 'en': 'Description (optional)'});
  String get theme => _t({'ar': 'السمة', 'en': 'Theme'});
  String get defaultTimer => _t({'ar': 'المؤقت الافتراضي', 'en': 'Default Timer'});
  String get color => _t({'ar': 'اللون', 'en': 'Color'});
  String get icon => _t({'ar': 'الأيقونة', 'en': 'Icon'});
  String get weeklyGoalMin => _t({'ar': 'الهدف الأسبوعي', 'en': 'Weekly Goal'});
  String get dailyGoalMin => _t({'ar': 'الهدف اليومي', 'en': 'Daily Goal'});
  String get countWeeklyGoal => _t({'ar': 'احسب في الهدف الأسبوعي', 'en': 'Count toward weekly goal'});
  String get update => _t({'ar': 'تحديث', 'en': 'Update'});
  String get create => _t({'ar': 'إنشاء', 'en': 'Create'});
  String get quickStart => _t({'ar': 'تشغيل سريع', 'en': 'Quick Start'});
  String get viewDetails => _t({'ar': 'عرض التفاصيل', 'en': 'View Details'});
  String get edit => _t({'ar': 'تعديل', 'en': 'Edit'});
  String get archive => _t({'ar': 'أرشفة', 'en': 'Archive'});
  String get unarchive => _t({'ar': 'إلغاء الأرشفة', 'en': 'Unarchive'});
  String get deleteCompletely => _t({'ar': 'حذف نهائي', 'en': 'Delete Completely'});
  String get projectAndSessions => _t({'ar': 'المشروع + جميع الجلسات', 'en': 'Project + all sessions'});
  String get deleteProject => _t({'ar': 'حذف المشروع', 'en': 'Delete Project'});
  String get searchProjects => _t({'ar': 'بحث في المشاريع...', 'en': 'Search projects...'});
  String get noArchivedProjects => _t({'ar': 'لا توجد مشاريع مؤرشفة', 'en': 'No archived projects'});
  String get noMatchingProjects => _t({'ar': 'لا توجد نتائج مطابقة', 'en': 'No matching projects'});
  String get createProjectToStart => _t({'ar': 'أنشئ مشروع لبدء التتبع', 'en': 'Create a project to start tracking'});
  String get focusSession => _t({'ar': 'جلسة تركيز', 'en': 'focus session'});
  String get off => _t({'ar': 'متوقف', 'en': 'Off'});

  // ─── Tasks ───
  String get todayTasks => _t({'ar': 'مهام اليوم', 'en': "Today's Tasks"});
  String get searchTasks => _t({'ar': 'بحث في المهام...', 'en': 'Search tasks...'});
  String get all => _t({'ar': 'الكل', 'en': 'All'});
  String get sort => _t({'ar': 'ترتيب:', 'en': 'Sort:'});
  String get priority => _t({'ar': 'الأولوية', 'en': 'Priority'});
  String get date => _t({'ar': 'التاريخ', 'en': 'Date'});
  String get noTasksForToday => _t({'ar': 'لا توجد مهام اليوم', 'en': 'No tasks for today'});
  String get addTaskHint => _t({'ar': 'أضف مهمة...', 'en': 'Add a task...'});
  String get assignToProject => _t({'ar': 'تعيين لمشروع', 'en': 'Assign to Project'});
  String get editTask => _t({'ar': 'تعديل المهمة', 'en': 'Edit Task'});
  String get focusOnTask => _t({'ar': 'التركيز على هذه المهمة', 'en': 'Focus on this Task'});
  String get keepForTomorrow => _t({'ar': 'حفظ لغداً', 'en': 'Keep for Tomorrow'});
  String get markDone => _t({'ar': 'تحديد كمنجز', 'en': 'Mark as Done'});
  String get markNotDone => _t({'ar': 'تحديد كغير منجز', 'en': 'Mark as Not Done'});
  String get deleteTask => _t({'ar': 'حذف المهمة', 'en': 'Delete Task'});
  String get taskTitle => _t({'ar': 'عنوان المهمة', 'en': 'Task title'});
  String get estimatedPomodoros => _t({'ar': 'بومودورو تقريبي', 'en': 'Estimated Pomodoros'});
  String get completed => _t({'ar': 'منجز', 'en': 'completed'});

  // ─── Statistics ───
  String get statistics => _t({'ar': 'الإحصائيات', 'en': 'Statistics'});
  String get viewAllSessions => _t({'ar': 'عرض جميع الجلسات', 'en': 'View All Sessions'});
  String get today => _t({'ar': 'اليوم', 'en': 'Today'});
  String get thisWeek => _t({'ar': 'هذا الأسبوع', 'en': 'This Week'});
  String get thisMonth => _t({'ar': 'هذا الشهر', 'en': 'This Month'});
  String get avgSession => _t({'ar': 'متوسط الجلسة', 'en': 'Avg Session'});
  String get dayStreak => _t({'ar': 'أيام متتالية', 'en': 'Day Streak'});
  String get totalTime => _t({'ar': 'الوقت الكلي', 'en': 'Total Time'});
  String get dailyGoalStat => _t({'ar': 'الهدف اليومي', 'en': 'Daily Goal'});
  String get weeklyOverview => _t({'ar': 'نظرة أسبوعية', 'en': 'Weekly Overview'});
  String get projectBreakdown => _t({'ar': 'تفصيل المشاريع', 'en': 'Project Breakdown'});
  String get bestProjectThisWeek => _t({'ar': 'أفضل مشروع هذا الأسبوع', 'en': 'Best Project This Week'});
  String get goalStats => _t({'ar': 'إحصائيات الأهداف', 'en': 'Goal Stats'});
  String get daysAchieved => _t({'ar': 'أيام تحققت', 'en': 'Days achieved'});
  String get bestDay => _t({'ar': 'أفضل يوم', 'en': 'Best day'});
  String get weekTotal => _t({'ar': 'مجموع الأسبوع', 'en': 'Week total'});
  String get dailyAverage => _t({'ar': 'المتوسط اليومي', 'en': 'Daily average'});
  String get activityHeatMap => _t({'ar': 'خريطة النشاط', 'en': 'Activity Heat Map'});
  String get less => _t({'ar': 'أقل', 'en': 'Less'});
  String get more => _t({'ar': 'أكثر', 'en': 'More'});
  String get periodComparison => _t({'ar': 'مقارنة الفترات', 'en': 'Period Comparison'});
  String get filterByProject => _t({'ar': 'تصفية حسب المشروع', 'en': 'Filter by Project'});
  String get weeklyChart => _t({'ar': 'أسبوع', 'en': 'Week'});
  String get monthlyChart => _t({'ar': 'شهر', 'en': 'Month'});
  String get timeline => _t({'ar': "الخط الزمني لليوم", 'en': "Today's Timeline"});
  String get sessionsCount => _t({'ar': 'جلسات', 'en': 'sessions'});
  String get minDay => _t({'ar': 'دقيقة/يوم', 'en': 'min/day'});
  String get minShort => _t({'ar': 'د', 'en': 'min'});
  String get hourShort => _t({'ar': 'س', 'en': 'h'});
  String get daysWord => _t({'ar': 'أيام', 'en': 'days'});
  String get keyboardSpaceLabel => _t({'ar': 'تشغيل/إيقاف مؤقت', 'en': 'Start/Pause'});
  String get keyboardResetLabel => _t({'ar': 'إعادة ضبط', 'en': 'Reset'});

  // ─── Days ───
  String get mon => _t({'ar': 'الإثنين', 'en': 'Mon'});
  String get tue => _t({'ar': 'الثلاثاء', 'en': 'Tue'});
  String get wed => _t({'ar': 'الأربعاء', 'en': 'Wed'});
  String get thu => _t({'ar': 'الخميس', 'en': 'Thu'});
  String get fri => _t({'ar': 'الجمعة', 'en': 'Fri'});
  String get sat => _t({'ar': 'السبت', 'en': 'Sat'});
  String get sun => _t({'ar': 'الأحد', 'en': 'Sun'});
  String get tomorrow => _t({'ar': 'غداً', 'en': 'Tomorrow'});
  String get otherDay => _t({'ar': 'يوم آخر', 'en': 'Other day'});

  // ─── Break Screen ───
  String get breakTime => _t({'ar': 'وقت الاستراحة', 'en': 'Break Time'});
  String get skipBreak => _t({'ar': 'تخطي الاستراحة', 'en': 'Skip Break'});
  String get ambientSounds => _t({'ar': 'أصوات محيطية', 'en': 'Ambient Sounds'});
  String get breakTip => _t({'ar': 'نصيحة', 'en': 'Tip'});

  // ─── Tasks Extra ───
  String get done => _t({'ar': 'منجز', 'en': 'Done'});
  String get reorder => _t({'ar': 'إعادة ترتيب', 'en': 'Reorder'});
  String get taskCompleted => _t({'ar': 'تم إتمام المهمة!', 'en': 'Task completed!'});
  String get taskDeleted => _t({'ar': 'تم حذف المهمة', 'en': 'Task deleted'});
  String get undoLabel => _t({'ar': 'تراجع', 'en': 'UNDO'});
  String get clearDone => _t({'ar': 'مسح المنجز', 'en': 'Clear'});
  String get addTaskBelow => _t({'ar': 'أضف مهمة أدناه للبدء', 'en': 'Add a task below to get started'});
  String get focusOnTaskMsg => _t({'ar': 'جاري التركيز على', 'en': 'Focusing on'});
  String get deleteConfirmMsg => _t({'ar': 'هل تريد الحذف؟\nلا يمكن التراجع.', 'en': 'Delete?\nThis cannot be undone.'});
  String get taskMovedTo => _t({'ar': 'تم نقل المهمة إلى', 'en': 'Task moved to'});
  String get completedCleared => _t({'ar': 'مهمة منجزة تم مسحها', 'en': 'completed task(s) cleared'});
  String get priorityNone => _t({'ar': 'بدون', 'en': 'None'});
  String get priorityLow => _t({'ar': 'منخفضة', 'en': 'Low'});
  String get priorityMedium => _t({'ar': 'متوسطة', 'en': 'Medium'});
  String get priorityHigh => _t({'ar': 'عالية', 'en': 'High'});
  String get projectDeleted => _t({'ar': 'تم حذف المشروع', 'en': 'deleted'});
  String get countWeeklyGoalLabel => _t({'ar': 'احسب في الأسبوعي', 'en': 'Weekly goal'});

  // ─── Statistics Extra ───
  String get dailyGoalProgress => _t({'ar': 'دقيقة من', 'en': 'min of'});
  String get weekLabel => _t({'ar': 'أسبوع', 'en': 'Week'});
  String get monthLabel => _t({'ar': 'شهر', 'en': 'Month'});
  String get goalAchieved => _t({'ar': '✓ تم تحقيق الهدف', 'en': '✓ Goal achieved'});
  String get focusSessionLabel => _t({'ar': 'جلسة تركيز', 'en': 'Focus Session'});
  String get sessionHistory => _t({'ar': 'سجل الجلسات', 'en': 'Session History'});
  String get noSessionsYet => _t({
    'ar': 'لا توجد جلسات بعد.\nابدأ أول جلسة تركيز!',
    'en': 'No sessions yet.\nStart your first focus session!',
  });

  // ─── Motivational ───
  List<String> get breakTips => isArabic ? _breakTipsAr : _breakTipsEn;

  static const _breakTipsEn = [
    'Close your eyes and take 5 deep breaths.',
    'Stand up and stretch your arms above your head.',
    'Look at something far away for 20 seconds.',
    'Drink a glass of water to stay hydrated.',
    'Roll your shoulders backwards 10 times.',
    'Walk around for a minute to boost circulation.',
    'Massage your hands and fingers gently.',
    'Do 10 neck rotations slowly.',
    'Rest your eyes — close them for a minute.',
    'Take a moment to appreciate what you accomplished.',
    'Write down 3 things you are grateful for.',
    'Listen to your favorite calming song.',
  ];

  static const _breakTipsAr = [
    'أغمض عينك وخذ 5 تنفسات عميقة.',
    'قم وافرد ذراعيك فوق رأسك.',
    'انظر لشيء بعيد لمدة 20 ثانية.',
    'اشرب كوباً من الماء للترطيب.',
    'لف كتفيك إلى الخلف 10 مرات.',
    'امشِ دقيقة واحدة لتنشيط الدورة الدموية.',
    'دلك يديك وأصابعك بلطف.',
    'أقم ب10 دورانات رقبة ببطء.',
    'استرح لعينيك — أغمضهما دقيقة.',
    'خذ لحظة لتُقدّر ما أنجزته.',
    'اكتب 3 أشياء تشعر بالامتنان لها.',
    'استمع لأغنية المفضلة الهادئة.',
  ];

  // ─── Motivational ───
  List<String> get motivationalQuotes => isArabic ? _motivQuotesAr : _motivQuotesEn;
  List<String> get completionMessages => isArabic ? _compMsgsAr : _compMsgsEn;
  List<String> get milestoneMessages => isArabic ? _mileMsgsAr : _mileMsgsEn;

  static const _motivQuotesEn = [
    'Stay focused, stay powerful!',
    'Every minute counts!',
    "You're doing great!",
    'Deep work, deep results.',
    'One session at a time.',
    'Progress, not perfection.',
    'Your future self will thank you.',
    'Discipline is freedom.',
    'Focus is your superpower.',
    'Keep going, you\'re almost there!',
    'Small steps lead to big results.',
    'Consistency is key!',
    'Make this session count!',
    "You've got this!",
    'Stay in the zone.',
  ];

  static const _motivQuotesAr = [
    'ابقَ مركّزاً، ابقَ قوياً!',
    'كل دقيقة مهمة!',
    'أنت تُبهر!',
    'عمل عميق، نتائج عميقة.',
    'جلسة واحدة في كل مرة.',
    'تقدم، لا كمال.',
    'نفسك المستقبلية ستشكرك.',
    'الانضباط حرية.',
    'التركيز قدرتك الخارقة.',
    'استمر، أنت قريب!',
    'الخطوات الصغيرة تُحقق النتائج الكبرى.',
    'الاستمرارية هي المفتاح!',
    'اجعل هذه الجلسة تُحسب!',
    'يمكنك!',
    'ابقَ في المنطقة.',
  ];

  static const _compMsgsEn = [
    'Brilliant focus! Your dedication is paying off. Keep this momentum!',
    "Another one in the bag! You're building something amazing, one session at a time.",
    'That was intense! You gave it your all. Now recharge and come back stronger.',
    "Champion mindset! Every session makes you sharper and more unstoppable.",
    "Focused mind, powerful results. You just proved what you're capable of!",
    "Incredible work! Your discipline today is building tomorrow's success.",
    "You showed up and delivered. That's what separates winners from the rest.",
    "Peak performance! You're in the zone and nothing can stop you.",
    "Outstanding effort! Your consistency is your greatest weapon.",
    'One step closer to your goals. Every session is a victory!',
  ];

  static const _compMsgsAr = [
    'تركيز رائع! تفانيك يُثمر. حافظ على هذا الزخم!',
    'جلسة أخرى في الحصيلة! أنت تبني شيئاً مذهلاً.',
    'كانت مكثفة! أعطيت كل ما عندك. ارتقِ وعُد أقوى.',
    'عقل بطل! كل جلسة تُحدّك وتجعلك لا يُقهر.',
    'عقل مركّز، نتائج قوية. أثبت ما أنت قادر عليه!',
    'عمل لا يُصدق! انضباطك اليوم يبني نجاح الغد.',
    'ظهرت وقدّمت. هذا ما يُميّز الفائزين.',
    'أداء قمة! أنت في المنطقة ولا شيء يمكنه إيقافك.',
    'جهد استثنائي! استمراريتك سلاحك الأعظم.',
    'خطوة أقرب لأهدافك. كل جلسة انتصار!',
  ];

  static const _mileMsgsEn = [
    '4 sessions crushed! You\'re on a legendary streak!',
    'Milestone reached! Your dedication is truly inspiring!',
    "4 in a row! You're building unstoppable momentum!",
    "Incredible milestone! Your hard work is paying off big time!",
    "4 sessions strong! You're operating at an elite level!",
  ];

  static const _mileMsgsAr = [
    '4 جلسات أنجزتها! أنت في سلسلة أسطورية!',
    'milestone تحقق! تفانيك مُلهِم حقاً!',
    '4 متتالية! أنت تبني زخماً لا يُقهر!',
    'إنجاز لا يُصدق! جهدك يُثمر كبيراً!',
    '4 جلسات قوية! أنت تعمل على مستوى النخبة!',
  ];
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['ar', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
