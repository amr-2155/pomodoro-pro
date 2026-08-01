import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/project.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';
import '../utils/page_transitions.dart';
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
    int defaultDuration = project?.defaultDuration ?? 25;
    String selectedTheme = project?.theme ?? 'default';

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
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    project != null ? 'Edit Project' : 'New Project',
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
                              hintText: 'Project name',
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
                              hintText: 'Description (optional)',
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
                          const Text('Theme', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
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
                          Row(
                            children: [
                              const Text('Default Timer', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              const Spacer(),
                              Container(
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      onPressed: defaultDuration > 5
                                          ? () => setModalState(() {
                                                final idx = _durations.indexOf(defaultDuration);
                                                if (idx > 0) defaultDuration = _durations[idx - 1];
                                              })
                                          : null,
                                      icon: const Icon(Icons.remove, size: 18),
                                      color: AppColors.primary,
                                    ),
                                    Container(
                                      width: 52,
                                      alignment: Alignment.center,
                                      child: Text(
                                        '${defaultDuration}min',
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: defaultDuration < 90
                                          ? () => setModalState(() {
                                                final idx = _durations.indexOf(defaultDuration);
                                                if (idx < _durations.length - 1) defaultDuration = _durations[idx + 1];
                                              })
                                          : null,
                                      icon: const Icon(Icons.add, size: 18),
                                      color: AppColors.primary,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                           const Row(
                            children: [
                              Text('Color', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              Spacer(),
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
                          const Text('Icon', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
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
                          Row(
                            children: [
                              const Text('Weekly Goal', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              const Spacer(),
                              Container(
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      onPressed: weeklyGoal > 0
                                          ? () => setModalState(() => weeklyGoal -= 15)
                                          : null,
                                      icon: const Icon(Icons.remove, size: 18), color: AppColors.primary,
                                    ),
                                    Container(
                                      width: 52, alignment: Alignment.center,
                                      child: Text(
                                        weeklyGoal > 0 ? '${weeklyGoal}min' : 'Off',
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: weeklyGoal < 600
                                          ? () => setModalState(() => weeklyGoal += 15)
                                          : null,
                                      icon: const Icon(Icons.add, size: 18), color: AppColors.primary,
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
                        if (project != null) {
                          project.name = name;
                          project.description = descController.text.trim();
                          project.colorValue = selectedColor;
                          project.icon = selectedIcon;
                          project.weeklyGoalMinutes = weeklyGoal;
                          project.defaultDuration = defaultDuration;
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
                            defaultDuration: defaultDuration,
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
                        project != null ? 'Update' : 'Create',
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
                Center(
                  child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.play_circle_fill_rounded, color: AppColors.success, size: 24),
                  title: const Text('Quick Start', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${project.defaultDuration}min focus session'),
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
                  title: const Text('View Details'),
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
                  title: const Text('Edit'),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  onTap: () {
                    Navigator.pop(context);
                    _showAddProjectDialog(project: project);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.archive_rounded, size: 22),
                  title: Text(project.isArchived ? 'Unarchive' : 'Archive'),
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
                  title: const Text('Delete Completely', style: TextStyle(color: AppColors.error)),
                  subtitle: const Text('Project + all sessions', style: TextStyle(fontSize: 11)),
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
    final sessions = DatabaseService.getSessionsForProject(project.id);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Project'),
        content: Text(
          'Delete "${project.name}" and ${sessions.length} session${sessions.length != 1 ? 's' : ''}?\n\nThis cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              DatabaseService.deleteProjectCompletely(project.id);
              Navigator.pop(context);
              _loadProjects();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${project.name} deleted'),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmDeleteSwipe(Project project) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sessions = DatabaseService.getSessionsForProject(project.id);
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Project'),
        content: Text(
          'Delete "${project.name}" and ${sessions.length} session${sessions.length != 1 ? 's' : ''}?\n\nThis cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    ).then((result) {
      if (result == true && mounted) {
        DatabaseService.deleteProjectCompletely(project.id);
        _loadProjects();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${project.name} deleted'),
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
                      Text('Projects', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
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
                        hintText: 'Search projects...',
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
                          Text(_showArchived ? 'No archived projects' : _searchQuery.isNotEmpty ? 'No matching projects' : 'No projects yet', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: isDark ? Colors.grey[400] : Colors.grey[600])),
                          const SizedBox(height: 6),
                          Text(_showArchived ? '' : _searchQuery.isNotEmpty ? 'Try a different search' : 'Create a project to start tracking', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
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
          label: const Text('New Project', style: TextStyle(fontWeight: FontWeight.w600)),
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
          _buildSummaryItem('$_activeProjects', 'Projects', AppColors.primary),
          Container(height: 24, width: 1, color: AppColors.primary.withValues(alpha: 0.15)),
          _buildSummaryItem('${_totalHours.toStringAsFixed(1)}h', 'Total', AppColors.success),
          Container(height: 24, width: 1, color: AppColors.primary.withValues(alpha: 0.15)),
          _buildSummaryItem('$_totalSessions', 'Sessions', AppColors.warning),
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
