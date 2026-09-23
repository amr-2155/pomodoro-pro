import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pomodoro_app/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';
import '../models/project.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';
import '../utils/page_transitions.dart';
import '../widgets/app_ui.dart';
import '../widgets/project_card.dart';
import 'project_detail_screen.dart';
import 'immersive_focus_screen.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  List<Project> _projects = [];
  List<Project> _filteredProjects = [];
  bool _showArchived = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  static const _themes = [
    {'key': 'default', 'name': 'Default', 'icon': '🎯', 'gradient': [Color(0xFF6C63FF), Color(0xFF8B83FF)]},
    {'key': 'reading', 'name': 'Reading', 'icon': '📚', 'gradient': [Color(0xFF5D4037), Color(0xFF8D6E63)]},
    {'key': 'coding', 'name': 'Coding', 'icon': '💻', 'gradient': [Color(0xFF1B5E20), Color(0xFF4CAF50)]},
    {'key': 'design', 'name': 'Design', 'icon': '🎨', 'gradient': [Color(0xFFE65100), Color(0xFFFF9800)]},
    {'key': 'writing', 'name': 'Writing', 'icon': '✍️', 'gradient': [Color(0xFF4A148C), Color(0xFF9C27B0)]},
    {'key': 'study', 'name': 'Study', 'icon': '🎓', 'gradient': [Color(0xFF0D47A1), Color(0xFF2196F3)]},
    {'key': 'music', 'name': 'Music', 'icon': '🎵', 'gradient': [Color(0xFF880E4F), Color(0xFFE91E63)]},
    {'key': 'fitness', 'name': 'Fitness', 'icon': '🏋️', 'gradient': [Color(0xFFBF360C), Color(0xFFFF5722)]},
    {'key': 'meditation', 'name': 'Meditate', 'icon': '🧘', 'gradient': [Color(0xFF004D40), Color(0xFF009688)]},
    {'key': 'art', 'name': 'Art', 'icon': '🖌️', 'gradient': [Color(0xFF311B92), Color(0xFF673AB7)]},
  ];

  static const _durations = [5, 10, 15, 20, 25, 30, 45, 60, 90];

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadProjects() {
    setState(() {
      _projects = _showArchived
          ? DatabaseService.getArchivedProjects()
          : DatabaseService.getAllProjects();
      _applyFilter();
    });
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filteredProjects = List.from(_projects);
    } else {
      _filteredProjects = _projects
          .where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
  }

  int get _totalSessions => _projects.fold(0, (sum, p) => sum + p.totalSessions);
  double get _totalHours => _projects.fold(0.0, (sum, p) => sum + p.totalHours);
  int get _activeProjects => _projects.where((p) => !p.isArchived).length;

  void _showAddProjectDialog({Project? project}) {
    final nameController = TextEditingController(text: project?.name ?? '');
    final descController = TextEditingController(text: project?.description ?? '');
    int selectedColor = project?.colorValue ?? AppColors.projectColors[0].toARGB32();
    String selectedIcon = project?.icon ?? '🎯';
    int weeklyGoal = project?.weeklyGoalMinutes ?? 0;
    int dailyGoal = project?.dailyGoalMinutes ?? 0;
    bool includeInWeekly = project?.includeInWeeklyGoal ?? true;
    final defaultDuration = project?.defaultDuration ?? 1500;
    String selectedTheme = project?.theme ?? 'default';
    final durationMinController =
        TextEditingController(text: '${defaultDuration ~/ 60}');
    final durationSecController = TextEditingController(
        text: (defaultDuration % 60).toString().padLeft(2, '0'));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.82,
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20, right: 20, top: 12,
              ),
              child: Column(
                children: [
                  const SheetHandleBar(),                  const SizedBox(height: 16),
                  Text(
                    project != null ? AppLocalizations.of(context).editProject : AppLocalizations.of(context).newProject,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: nameController,
                            decoration: InputDecoration(
                              hintText: AppLocalizations.of(context).projectName,
                              filled: true,
                              fillColor: isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.grey.withValues(alpha: 0.08),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            autofocus: project == null,
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: descController,
                            decoration: InputDecoration(
                              hintText: AppLocalizations.of(context).descriptionOptional,
                              filled: true,
                              fillColor: isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.grey.withValues(alpha: 0.08),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(AppLocalizations.of(context).theme, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 80,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _themes.length,
                              itemBuilder: (context, index) {
                                final theme = _themes[index];
                                final isSelected = selectedTheme == theme['key'];
                                final gradient = theme['gradient'] as List<Color>;
                                return GestureDetector(
                                  onTap: () => setModalState(() => selectedTheme = theme['key'] as String),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 70,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: gradient,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                      border: isSelected
                                          ? Border.all(color: Colors.white, width: 2.5)
                                          : null,
                                      boxShadow: isSelected
                                          ? [BoxShadow(color: gradient[0].withValues(alpha: 0.4), blurRadius: 10)]
                                          : null,
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(theme['icon'] as String, style: const TextStyle(fontSize: 22)),
                                        const SizedBox(height: 4),
                                        Text(
                                          theme['name'] as String,
                                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(AppLocalizations.of(context).defaultTimer, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDurationField(
                                  controller: durationMinController,
                                  label: AppLocalizations.of(context).minutes,
                                  isDark: isDark,
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6),
                                child: Text(':',
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              ),
                              Expanded(
                                child: _buildDurationField(
                                  controller: durationSecController,
                                  label: AppLocalizations.of(context).seconds,
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _durations.map((m) {
                              final isSelected =
                                  durationMinController.text == '$m' &&
                                      durationSecController.text == '00';
                              return GestureDetector(
                                onTap: () => setModalState(() {
                                  durationMinController.text = '$m';
                                  durationSecController.text = '00';
                                }),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary.withValues(alpha: 0.15)
                                        : isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(16),
                                    border: isSelected ? Border.all(color: AppColors.primary, width: 1.5) : null,
                                  ),
                                  child: Text(
                                    '${m}m',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected ? AppColors.primary : null,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 14),
                           Row(
                            children: [
                              Text(AppLocalizations.of(context).color, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              const Spacer(),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10, runSpacing: 10,
                            children: AppColors.projectColors.map((c) {
                              final isSelected = selectedColor == c.toARGB32();
                              return GestureDetector(
                                onTap: () => setModalState(() => selectedColor = c.toARGB32()),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 36, height: 36,
                                  decoration: BoxDecoration(
                                    color: c, shape: BoxShape.circle,
                                    border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                                    boxShadow: isSelected ? [BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 10)] : null,
                                  ),
                                  child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 14),
                          Text(AppLocalizations.of(context).icon, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8, runSpacing: 8,
                            children: AppConstants.projectIcons.map((icon) {
                              final isSelected = selectedIcon == icon;
                              return GestureDetector(
                                onTap: () => setModalState(() => selectedIcon = icon),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  width: 38, height: 38,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary.withValues(alpha: 0.15)
                                        : isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(10),
                                    border: isSelected ? Border.all(color: AppColors.primary, width: 2) : null,
                                  ),
                                  child: Center(child: Text(icon, style: const TextStyle(fontSize: 18))),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 18),
                          _GoalEditorCard(
                            title: AppLocalizations.of(context).weeklyGoalMin,
                            value: weeklyGoal,
                            step: 10,
                            presets: const [60, 120, 300, 450, 600, 900],
                            accent: AppColors.primary,
                            isDark: isDark,
                            onChanged: (v) => setModalState(() => weeklyGoal = v),
                          ),
                          const SizedBox(height: 14),
                          _GoalEditorCard(
                            title: AppLocalizations.of(context).dailyGoalMin,
                            value: dailyGoal,
                            step: 5,
                            presets: const [15, 30, 45, 60, 90, 120],
                            accent: AppColors.success,
                            isDark: isDark,
                            onChanged: (v) => setModalState(() => dailyGoal = v),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: includeInWeekly
                                  ? AppColors.success.withValues(alpha: 0.08)
                                  : isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: includeInWeekly
                                    ? AppColors.success.withValues(alpha: 0.35)
                                    : Colors.grey.withValues(alpha: 0.15),
                              ),
                            ),
                            child: Row(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: includeInWeekly
                                        ? AppColors.success
                                        : Colors.grey.withValues(alpha: 0.3),
                                  ),
                                  child: includeInWeekly
                                      ? const Icon(Icons.check_rounded,
                                          color: Colors.white, size: 17)
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    AppLocalizations.of(context).countWeeklyGoalClear,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.5,
                                      color: includeInWeekly
                                          ? isDark ? Colors.white : Colors.black87
                                          : Colors.grey[500],
                                    ),
                                  ),
                                ),
                                Switch(
                                  value: includeInWeekly,
                                  activeThumbColor: AppColors.success,
                                  onChanged: (v) => setModalState(() => includeInWeekly = v),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity, height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        final name = nameController.text.trim();
                        if (name.isEmpty) return;
                        final mins = int.tryParse(durationMinController.text) ?? 0;
                        final secs = int.tryParse(durationSecController.text) ?? 0;
                        final totalSeconds = (mins.clamp(0, 120)) * 60 + (secs.clamp(0, 59));
                        if (project != null) {
                          project.name = name;
                          project.description = descController.text.trim();
                          project.colorValue = selectedColor;
                          project.icon = selectedIcon;
                          project.weeklyGoalMinutes = weeklyGoal;
                          project.dailyGoalMinutes = dailyGoal;
                          project.includeInWeeklyGoal = includeInWeekly;
                          project.defaultDuration = totalSeconds;
                          project.theme = selectedTheme;
                          project.save();
                        } else {
                          DatabaseService.addProject(Project(
                            id: const Uuid().v4(),
                            name: name,
                            colorValue: selectedColor,
                            icon: selectedIcon,
                            description: descController.text.trim(),
                            weeklyGoalMinutes: weeklyGoal,
                            dailyGoalMinutes: dailyGoal,
                            includeInWeeklyGoal: includeInWeekly,
                            defaultDuration: totalSeconds,
                            theme: selectedTheme,
                          ));
                        }
                        Navigator.pop(context);
                        _loadProjects();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        project != null ? AppLocalizations.of(context).update : AppLocalizations.of(context).create,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDurationField({
    required TextEditingController controller,
    required String label,
    required bool isDark,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 12, color: Colors.grey[500]),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.withValues(alpha: 0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      ),
    );
  }

  void _showProjectOptions(Project project) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SheetHandleBar(),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.play_circle_fill_rounded, color: AppColors.success, size: 24),
                  title: Text(AppLocalizations.of(context).quickStart, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${project.defaultDuration ~/ 60}:${(project.defaultDuration % 60).toString().padLeft(2, '0')} ${AppLocalizations.of(context).focusSession}'),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      AppModalRoute(page: ImmersiveFocusScreen(project: project)),
                    ).then((_) => _loadProjects());
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded, size: 22),
                  title: Text(AppLocalizations.of(context).viewDetails),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      AppPageRoute(page: ProjectDetailScreen(project: project)),
                    ).then((_) => _loadProjects());
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.edit_rounded, size: 22),
                  title: Text(AppLocalizations.of(context).edit),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  onTap: () {
                    Navigator.pop(context);
                    _showAddProjectDialog(project: project);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.archive_rounded, size: 22),
                  title: Text(project.isArchived ? AppLocalizations.of(context).unarchive : AppLocalizations.of(context).archive),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  onTap: () {
                    if (project.isArchived) {
                      project.isArchived = false;
                      project.save();
                    } else {
                      DatabaseService.archiveProject(project.id);
                    }
                    Navigator.pop(context);
                    _loadProjects();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_forever_rounded, color: AppColors.error, size: 22),
                  title: Text(AppLocalizations.of(context).deleteCompletely, style: const TextStyle(color: AppColors.error)),
                  subtitle: Text(AppLocalizations.of(context).projectAndSessions, style: const TextStyle(fontSize: 11)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDelete(project);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(Project project) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(AppLocalizations.of(context).deleteProject),
        content: Text(AppLocalizations.of(context).deleteConfirmMsg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          FilledButton(
            onPressed: () {
              DatabaseService.deleteProjectCompletely(project.id);
              Navigator.pop(context);
              _loadProjects();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${project.name} ${AppLocalizations.of(context).projectDeleted}'),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(AppLocalizations.of(context).delete),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmDeleteSwipe(Project project) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(AppLocalizations.of(context).deleteProject),
        content: Text(AppLocalizations.of(context).deleteConfirmMsg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(AppLocalizations.of(context).delete),
          ),
        ],
      ),
    ).then((result) {
      if (result == true && mounted) {
        DatabaseService.deleteProjectCompletely(project.id);
        _loadProjects();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${project.name} ${AppLocalizations.of(context).projectDeleted}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
      return result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                           Row(
                            children: [
                      Text(AppLocalizations.of(context).projects, style: Theme.of(context).textTheme.displaySmall),
                      const Spacer(),
                      Container(
                        decoration: BoxDecoration(
                          color: _showArchived ? AppColors.primary.withValues(alpha: 0.15) : isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          onPressed: () => setState(() { _showArchived = !_showArchived; _searchQuery = ''; _searchController.clear(); _loadProjects(); }),
                          icon: Icon(_showArchived ? Icons.unarchive_rounded : Icons.archive_rounded, color: _showArchived ? AppColors.primary : Colors.grey, size: 22),
                        ),
                      ),
                    ],
                  ),
                  if (!_showArchived && _projects.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildSummaryBar(isDark),
                  ],
                  const SizedBox(height: 12),
                  if (_projects.isNotEmpty)
                    TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() { _searchQuery = v; _applyFilter(); }),
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context).searchProjects,
                        prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[400], size: 22),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(onPressed: () { _searchController.clear(); setState(() { _searchQuery = ''; _applyFilter(); }); }, icon: Icon(Icons.clear, color: Colors.grey[400], size: 18))
                            : null,
                        filled: true,
                        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.08),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        isDense: true,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: _filteredProjects.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 80, height: 80, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), shape: BoxShape.circle), child: Icon(Icons.folder_open_rounded, size: 40, color: AppColors.primary.withValues(alpha: 0.4))),
                          const SizedBox(height: 16),
                          Text(_showArchived ? AppLocalizations.of(context).noArchivedProjects : _searchQuery.isNotEmpty ? AppLocalizations.of(context).noMatchingProjects : AppLocalizations.of(context).noProjectsYet, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: isDark ? Colors.grey[400] : Colors.grey[600])),
                          const SizedBox(height: 6),
                          Text(_showArchived ? '' : _searchQuery.isNotEmpty ? 'Try a different search' : AppLocalizations.of(context).createProjectToStart, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                      itemCount: _filteredProjects.length,
                      itemBuilder: (context, index) {
                        final project = _filteredProjects[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Dismissible(
                            key: Key(project.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Icon(Icons.delete_forever_rounded, color: Colors.white, size: 28),
                            ),
                            confirmDismiss: (_) async {
                              return await _confirmDeleteSwipe(project);
                            },
                            onDismissed: (_) {
                            },
                            child: ProjectCard(
                              project: project,
                              showStats: true,
                              onTap: () => Navigator.push(context, AppPageRoute(page: ProjectDetailScreen(project: project))).then((_) => _loadProjects()),
                              onLongPress: () => _showProjectOptions(project),
                              onDelete: () => _confirmDelete(project),
                              onEdit: () => _showAddProjectDialog(project: project),
                              onQuickStart: () {
                                Navigator.push(
                                  context,
                                  AppModalRoute(page: ImmersiveFocusScreen(project: project)),
                                ).then((_) => _loadProjects());
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: FloatingActionButton.extended(
          onPressed: () => _showAddProjectDialog(),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          icon: const Icon(Icons.add_rounded),
          label: Text(AppLocalizations.of(context).newProject, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _buildSummaryBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primary.withValues(alpha: 0.08), AppColors.accent.withValues(alpha: 0.06)]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('$_activeProjects', AppLocalizations.of(context).projects, AppColors.primary),
          Container(height: 24, width: 1, color: AppColors.primary.withValues(alpha: 0.15)),
          _buildSummaryItem('${_totalHours.toStringAsFixed(1)}h', AppLocalizations.of(context).total, AppColors.success),
          Container(height: 24, width: 1, color: AppColors.primary.withValues(alpha: 0.15)),
          _buildSummaryItem('$_totalSessions', AppLocalizations.of(context).sessionsCount, AppColors.warning),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ],
    );
  }
}

/// Modern goal editor card used inside the New/Edit Project sheet.
/// Big animated value, +/− step chips, quick presets, live derived hint.
class _GoalEditorCard extends StatelessWidget {
  final String title;
  final int value;
  final int step;
  final List<int> presets;
  final Color accent;
  final bool isDark;
  final ValueChanged<int> onChanged;

  const _GoalEditorCard({
    required this.title,
    required this.value,
    required this.step,
    required this.presets,
    required this.accent,
    required this.isDark,
    required this.onChanged,
  });

  void _bump(int delta) {
    final next = (value + delta).clamp(0, 100000);
    if (next != value) onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: accent)),
          const SizedBox(height: 10),

          // Value row: − [big number] +
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StepBtn(
                icon: Icons.remove_rounded,
                accent: accent,
                enabled: value > 0,
                onTap: () => _bump(-step),
              ),
              Expanded(
                child: Column(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      switchInCurve: Curves.easeOutCubic,
                      transitionBuilder: (child, anim) {
                        final isIn = child.key == ValueKey(value);
                        return FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: isIn
                                  ? const Offset(0, 0.3)
                                  : const Offset(0, -0.3),
                              end: Offset.zero,
                            ).animate(anim),
                            child: child,
                          ),
                        );
                      },
                      child: Row(
                        key: ValueKey(value),
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$value',
                            style: TextStyle(
                              fontSize: 40,
                              height: 1.05,
                              fontWeight: FontWeight.w800,
                              color: value > 0
                                  ? accent
                                  : Colors.grey[400],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l10n.unitMinutesWord,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[500],
                            ),
                          ),
                          if (title == AppLocalizations.of(context).dailyGoalMin)
                            Text(
                              ' (${l10n.dailySuffix})',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Derived weekly->daily hint only on the weekly card.
                    if (title == AppLocalizations.of(context).weeklyGoalMin &&
                        value >= 7)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          l10n.weeklyPerDayHint
                              .replaceAll('{n}', '$value')
                              .replaceAll('{d}',
                                  '${(value / 7).floor()}'),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[500],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              _StepBtn(
                icon: Icons.add_rounded,
                accent: accent,
                enabled: true,
                onTap: () => _bump(step),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Presets.
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: presets.map((p) {
              final active = p == value;
              return GestureDetector(
                onTap: () => onChanged(p),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: active ? accent : accent.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color:
                          active ? accent : accent.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    '$p ${l10n.unitMinuteShort}',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: active ? Colors.white : accent,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final bool enabled;
  final VoidCallback onTap;

  const _StepBtn({
    required this.icon,
    required this.accent,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled ? accent.withValues(alpha: 0.1) : Colors.transparent,
          border: Border.all(
            color: enabled
                ? accent.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        child: Icon(icon,
            size: 22,
            color: enabled ? accent : Colors.grey[400]),
      ),
    );
  }
}
