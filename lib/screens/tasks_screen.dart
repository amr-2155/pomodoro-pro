import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../services/database_service.dart';
import '../services/timer_service.dart';
import '../utils/constants.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with SingleTickerProviderStateMixin {
  List<Task> _tasks = [];
  final _controller = TextEditingController();
  final _searchController = TextEditingController();
  bool _showCompleted = false;
  String? _selectedProjectId;
  String? _filterProjectId;
  String _sortBy = 'priority';
  bool _reorderMode = false;
  bool _searchVisible = false;
  String _searchQuery = '';

  AnimationController? _confettiController;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    _confettiController?.dispose();
    _notificationTimer?.cancel();
    _notificationEntry?.remove();
    super.dispose();
  }

  void _loadTasks() {
    setState(() {
      _tasks = DatabaseService.getTodayTasks();
    });
    _checkAllDone();
  }

  void _checkAllDone() {
    final active = _tasks.where((t) => !t.isDone).toList();
    if (active.isEmpty && _tasks.isNotEmpty && _confettiController == null) {
      _showConfetti();
    }
  }

  void _showConfetti() {
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..forward().then((_) {
        _confettiController?.dispose();
        _confettiController = null;
      });
  }

  void _addTask() {
    if (_controller.text.trim().isEmpty) return;
    final task = Task(
      id: const Uuid().v4(),
      title: _controller.text.trim(),
      projectId: _selectedProjectId,
    );
    DatabaseService.addTask(task);
    _controller.clear();
    _selectedProjectId = null;
    _loadTasks();
  }

  void _toggleTask(Task task) {
    final wasDone = task.isDone;
    HapticFeedback.lightImpact();
    DatabaseService.toggleTask(task.id);
    _loadTasks();
    if (!wasDone) {
      _showNotification('Task completed!', AppColors.success, undo: () {
        DatabaseService.toggleTask(task.id);
        _loadTasks();
      });
    }
  }

  void _incrementPomodoro(Task task) {
    HapticFeedback.lightImpact();
    task.completedPomodoros++;
    DatabaseService.updateTask(task);
    _loadTasks();
  }

  void _decrementPomodoro(Task task) {
    if (task.completedPomodoros <= 0) return;
    HapticFeedback.lightImpact();
    task.completedPomodoros--;
    DatabaseService.updateTask(task);
    _loadTasks();
  }

  void _deleteTask(Task task) {
    DatabaseService.deleteTask(task.id);
    _loadTasks();
    _showNotification('Task deleted', AppColors.error, undo: () {
      DatabaseService.addTask(task);
      _loadTasks();
    });
  }

  void _moveTaskToDate(Task task, DateTime date) {
    task.createdAt = date;
    DatabaseService.updateTask(task);
    _loadTasks();
    final label = DateUtils.isSameDay(date, DateTime.now())
        ? 'today'
        : DateUtils.isSameDay(date,
                DateTime.now().add(const Duration(days: 1)))
            ? 'tomorrow'
            : 'other day';
    _showNotification('Task moved to $label', AppColors.primary);
  }

  void _clearCompleted() {
    final completed = _tasks.where((t) => t.isDone).toList();
    for (final task in completed) {
      DatabaseService.deleteTask(task.id);
    }
    _loadTasks();
    _showNotification(
        '${completed.length} completed task${completed.length != 1 ? 's' : ''} cleared',
        AppColors.primary, undo: () {
      for (final task in completed) {
        DatabaseService.addTask(task);
      }
      _loadTasks();
    });
  }

  OverlayEntry? _notificationEntry;
  Timer? _notificationTimer;

  void _showNotification(String message, Color color, {VoidCallback? undo}) {
    _notificationTimer?.cancel();
    _notificationEntry?.remove();
    _notificationEntry = null;

    _notificationEntry = OverlayEntry(builder: (ctx) {
      return Positioned(
        top: MediaQuery.of(ctx).padding.top + 12,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: AnimatedOpacity(
            opacity: 1.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                  if (undo != null)
                    GestureDetector(
                      onTap: () {
                        undo();
                        _notificationTimer?.cancel();
                        _notificationEntry?.remove();
                        _notificationEntry = null;
                      },
                      child: const Text(
                        'UNDO',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    });

    Overlay.of(context).insert(_notificationEntry!);

    _notificationTimer = Timer(const Duration(seconds: 3), () {
      _notificationEntry?.remove();
      _notificationEntry = null;
    });
  }

  void _startFocusOnTask(Task task, bool isDark) {
    final timer = context.read<TimerService>();
    timer.setTask(task.id);
    timer.setProject(task.projectId);
    final project = task.projectId != null
        ? DatabaseService.getProject(task.projectId!)
        : null;
    final duration = project?.defaultDuration ?? DatabaseService.focusDuration;
    timer.setDuration(TimerMode.focus, duration);
    _showNotification('Focusing on "${task.title}" — go to Timer tab', AppColors.primary);
  }

  List<Task> get _filteredActiveTasks {
    var tasks = _tasks.where((t) => !t.isDone).toList();
    if (_filterProjectId != null) {
      tasks = tasks.where((t) => t.projectId == _filterProjectId).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      tasks = tasks
          .where((t) =>
              t.title.toLowerCase().contains(q) ||
              (t.description?.toLowerCase().contains(q) ?? false))
          .toList();
    }
    switch (_sortBy) {
      case 'priority':
        tasks.sort((a, b) => b.priority.compareTo(a.priority));
        break;
      case 'date':
        tasks.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'alpha':
        tasks.sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
    }
    return tasks;
  }

  List<Task> get _filteredCompletedTasks {
    var tasks = _tasks.where((t) => t.isDone).toList();
    if (_filterProjectId != null) {
      tasks = tasks.where((t) => t.projectId == _filterProjectId).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      tasks = tasks
          .where((t) =>
              t.title.toLowerCase().contains(q) ||
              (t.description?.toLowerCase().contains(q) ?? false))
          .toList();
    }
    return tasks;
  }

  List<Task> get _allFilteredTasks =>
      [..._filteredActiveTasks, ..._filteredCompletedTasks];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeTasks = _filteredActiveTasks;
    final completedTasks = _filteredCompletedTasks;
    final total = _allFilteredTasks.length;
    final completedCount = completedTasks.length;
    final progress = total > 0 ? completedCount / total : 0.0;
    final projects = DatabaseService.getAllProjects();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildHeader(isDark, total, completedCount, progress),
                if (projects.isNotEmpty) _buildProjectFilter(isDark, projects),
                _buildSortBar(isDark, activeTasks.length),
                Expanded(
                  child: _tasks.isEmpty
                      ? _buildEmptyState(isDark)
                      : _buildTaskList(activeTasks, completedTasks, isDark),
                ),
                _buildInputBar(isDark),
              ],
            ),
          ),
          if (_confettiController != null) _buildConfettiOverlay(isDark),
        ],
      ),
    );
  }

  Widget _buildConfettiOverlay(bool isDark) {
    return AnimatedBuilder(
      animation: _confettiController!,
      builder: (context, _) {
        return IgnorePointer(
          child: CustomPaint(
            painter: _ConfettiPainter(
              progress: _confettiController!.value,
            ),
            size: MediaQuery.of(context).size,
          ),
        );
      },
    );
  }

  Widget _buildHeader(
      bool isDark, int total, int completedCount, double progress) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "Today's Tasks",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() {
                  _searchVisible = !_searchVisible;
                  if (!_searchVisible) {
                    _searchQuery = '';
                    _searchController.clear();
                  }
                }),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _searchVisible
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.grey.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _searchVisible
                        ? Icons.search_off_rounded
                        : Icons.search_rounded,
                    size: 18,
                    color:
                        _searchVisible ? AppColors.primary : Colors.grey[500],
                  ),
                ),
              ),
              if (completedCount > 0) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _clearCompleted,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.delete_sweep_rounded,
                            size: 14, color: AppColors.error),
                        const SizedBox(width: 4),
                        Text(
                          'Clear $completedCount',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (total > 0) ...[
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: progress >= 1
                        ? AppColors.success.withValues(alpha: 0.12)
                        : AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$completedCount/$total',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: progress >= 1
                          ? AppColors.success
                          : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (_searchVisible) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search tasks...',
                prefixIcon: Icon(Icons.search_rounded,
                    size: 18, color: Colors.grey[400]),
                suffixIcon: _searchQuery.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        child:
                            Icon(Icons.clear_rounded, size: 18, color: Colors.grey[400]),
                      )
                    : null,
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
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.5),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                isDense: true,
              ),
            ),
          ],
          if (total > 0) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress >= 1 ? AppColors.success : AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProjectFilter(bool isDark, List projects) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          GestureDetector(
            onTap: () => setState(() => _filterProjectId = null),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _filterProjectId == null
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _filterProjectId == null
                      ? AppColors.primary.withValues(alpha: 0.4)
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.all_inclusive_rounded,
                      size: 14,
                      color: _filterProjectId == null
                          ? AppColors.primary
                          : Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    'All',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _filterProjectId == null
                          ? AppColors.primary
                          : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          ...projects.map((p) {
            final color = Color(p.colorValue);
            final isActive = _filterProjectId == p.id;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () => setState(
                    () => _filterProjectId = isActive ? null : p.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive
                        ? color.withValues(alpha: 0.15)
                        : isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.grey.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive
                          ? color.withValues(alpha: 0.4)
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(p.icon, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      Text(
                        p.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isActive ? color : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSortBar(bool isDark, int activeCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          Icon(Icons.sort_rounded, size: 16, color: Colors.grey[500]),
          const SizedBox(width: 4),
          Text('Sort:', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          const SizedBox(width: 6),
          _sortChip('Priority', 'priority', isDark),
          const SizedBox(width: 4),
          _sortChip('Date', 'date', isDark),
          const SizedBox(width: 4),
          _sortChip('A-Z', 'alpha', isDark),
          const Spacer(),
          if (activeCount > 1)
            GestureDetector(
              onTap: () => setState(() => _reorderMode = !_reorderMode),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _reorderMode
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _reorderMode ? Icons.done_rounded : Icons.drag_handle_rounded,
                      size: 14,
                      color:
                          _reorderMode ? AppColors.primary : Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _reorderMode ? 'Done' : 'Reorder',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color:
                            _reorderMode ? AppColors.primary : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sortChip(String label, String value, bool isDark) {
    final isActive = _sortBy == value;
    return GestureDetector(
      onTap: () => setState(() => _sortBy = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.12)
              : isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? AppColors.primary : Colors.grey[500],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskList(
      List<Task> activeTasks, List<Task> completedTasks, bool isDark) {
    if (_reorderMode) {
      return _buildReorderableList(activeTasks, isDark);
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        ...activeTasks.map(
            (task) => _buildTaskItem(task, isDark, isActive: true)),
        if (completedTasks.isNotEmpty) ...[
          if (activeTasks.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: GestureDetector(
                onTap: () =>
                    setState(() => _showCompleted = !_showCompleted),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        _showCompleted
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${completedTasks.length} completed',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: AppColors.success.withValues(alpha: 0.15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_showCompleted)
            ...completedTasks.map(
                (task) => _buildTaskItem(task, isDark, isActive: false)),
        ],
      ],
    );
  }

  Widget _buildReorderableList(List<Task> activeTasks, bool isDark) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: activeTasks.length,
      // ignore: deprecated_member_use
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex--;
          final item = _filteredActiveTasks.removeAt(oldIndex);
          _filteredActiveTasks.insert(newIndex, item);
        });
      },
      itemBuilder: (context, index) {
        final task = activeTasks[index];
        return KeyedSubtree(
          key: ValueKey(task.id),
          child:
              _buildTaskItem(task, isDark, isActive: true, showDragHandle: true),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.checklist_rounded,
                size: 40, color: AppColors.primary.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 16),
          Text(
            'No tasks for today',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add a task below to get started',
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          ),
        ],
      ),
    );
  }

  Color _priorityColor(int priority) {
    switch (priority) {
      case 3:
        return AppColors.error;
      case 2:
        return AppColors.warning;
      case 1:
        return AppColors.success;
      default:
        return Colors.grey;
    }
  }

  Widget _buildTaskItem(Task task, bool isDark,
      {required bool isActive, bool showDragHandle = false}) {
    final priorityCol = _priorityColor(task.priority);
    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.horizontal,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_rounded, color: Colors.white),
            SizedBox(height: 4),
            Text('Delete', style: TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.success.withValues(alpha: 0.9)
              : AppColors.primary.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? Icons.check_rounded : Icons.replay_rounded,
              color: Colors.white,
            ),
            const SizedBox(height: 4),
            Text(
              isActive ? 'Done' : 'Undo',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        if (isActive) {
          _deleteTask(task);
          return true;
        }
        return false;
      },
      onDismissed: (_) {},
      child: GestureDetector(
        onTap: () => _toggleTask(task),
        onLongPress: () => _showTaskOptions(task, isDark),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: task.isDone
                ? AppColors.success.withValues(alpha: 0.04)
                : isDark
                    ? AppColors.surfaceDark
                    : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border(
              left: BorderSide(
                color: task.priority > 0 ? priorityCol : Colors.transparent,
                width: 3,
              ),
              right: BorderSide.none,
              top: BorderSide.none,
              bottom: BorderSide.none,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              if (showDragHandle) ...[
                Icon(Icons.drag_handle_rounded,
                    size: 18, color: Colors.grey[400]),
                const SizedBox(width: 6),
              ],
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: task.isDone ? AppColors.success : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: task.isDone
                        ? AppColors.success
                        : Colors.grey.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: task.isDone
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: task.isDone
                            ? Colors.grey[400]
                            : isDark
                                ? Colors.white70
                                : Colors.black87,
                        decoration: task.isDone
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    if (task.description != null &&
                        task.description!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        task.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    if (task.priority > 0 || task.projectId != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (task.priority > 0) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: priorityCol.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                task.priorityLabel,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: priorityCol,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (task.projectId != null)
                            Builder(builder: (context) {
                              final project = DatabaseService.getProject(
                                  task.projectId!);
                              if (project == null) {
                                return const SizedBox.shrink();
                              }
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Color(project.colorValue)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${project.icon} ${project.name}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: Color(project.colorValue),
                                  ),
                                ),
                              );
                            }),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (!task.isDone) ...[
                _buildPomodoroCounter(task, isDark),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => _startFocusOnTask(task, isDark),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Icon(Icons.play_arrow_rounded,
                        size: 16, color: AppColors.primary),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPomodoroCounter(Task task, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => _decrementPomodoro(task),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child:
                  const Icon(Icons.remove, size: 12, color: AppColors.error),
            ),
          ),
          const SizedBox(width: 6),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${task.completedPomodoros}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: task.completedPomodoros >= task.estimatedPomodoros
                      ? AppColors.success
                      : isDark
                          ? Colors.white70
                          : Colors.black87,
                ),
              ),
              Text(
                '/${task.estimatedPomodoros}',
                style: TextStyle(fontSize: 9, color: Colors.grey[500]),
              ),
            ],
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _incrementPomodoro(task),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child:
                  const Icon(Icons.add, size: 12, color: AppColors.success),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            GestureDetector(
              onTap: () => _showProjectSelector(isDark),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _selectedProjectId != null
                      ? Color(DatabaseService
                                  .getProject(_selectedProjectId!)
                              ?.colorValue ??
                          AppColors.primary.toARGB32())
                          .withValues(alpha: 0.12)
                      : isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: _selectedProjectId != null
                      ? Text(
                          DatabaseService
                                  .getProject(_selectedProjectId!)
                                  ?.icon ??
                              '📋',
                          style: const TextStyle(fontSize: 18),
                        )
                      : Icon(Icons.folder_outlined,
                          size: 20, color: Colors.grey[400]),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _controller,
                onSubmitted: (_) => _addTask(),
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: 'Add a task...',
                  prefixIcon: Icon(Icons.add_task_rounded,
                      color: Colors.grey[400], size: 20),
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
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _addTask,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.add_rounded,
                    color: Colors.white, size: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProjectSelector(bool isDark) {
    final projects = DatabaseService.getAllProjects();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              const Text('Assign to Project',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.close_rounded,
                      size: 18, color: Colors.grey),
                ),
                title: const Text('No Project'),
                onTap: () {
                  setState(() => _selectedProjectId = null);
                  Navigator.pop(ctx);
                },
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              ...projects.map((p) {
                final color = Color(p.colorValue);
                return ListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8)),
                    child: Center(
                        child: Text(p.icon,
                            style: const TextStyle(fontSize: 18))),
                  ),
                  title: Text(p.name),
                  trailing: _selectedProjectId == p.id
                      ? Icon(Icons.check_circle_rounded,
                          color: color, size: 20)
                      : null,
                  onTap: () {
                    setState(() => _selectedProjectId = p.id);
                    Navigator.pop(ctx);
                  },
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showTaskOptions(Task task, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text(
                task.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              _optionTile(
                icon: Icons.edit_rounded,
                label: 'Edit Task',
                color: AppColors.primary,
                isDark: isDark,
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditTaskDialog(task);
                },
              ),
              if (!task.isDone) ...[
                _optionTile(
                  icon: Icons.play_arrow_rounded,
                  label: 'Focus on this Task',
                  color: AppColors.focusColor,
                  isDark: isDark,
                  onTap: () {
                    Navigator.pop(ctx);
                    _startFocusOnTask(task, isDark);
                  },
                ),
                _optionTile(
                  icon: Icons.today_rounded,
                  label: 'Keep for Tomorrow',
                  color: AppColors.warning,
                  isDark: isDark,
                  onTap: () {
                    Navigator.pop(ctx);
                    final tomorrow = DateTime.now()
                        .add(const Duration(days: 1));
                    _moveTaskToDate(task, tomorrow);
                  },
                ),
                _optionTile(
                  icon: Icons.check_circle_rounded,
                  label: 'Mark as Done',
                  color: AppColors.success,
                  isDark: isDark,
                  onTap: () {
                    Navigator.pop(ctx);
                    _toggleTask(task);
                  },
                ),
              ],
              if (task.isDone)
                _optionTile(
                  icon: Icons.replay_rounded,
                  label: 'Mark as Not Done',
                  color: AppColors.primary,
                  isDark: isDark,
                  onTap: () {
                    Navigator.pop(ctx);
                    _toggleTask(task);
                  },
                ),
              _optionTile(
                icon: Icons.delete_outline_rounded,
                label: 'Delete Task',
                color: AppColors.error,
                isDark: isDark,
                onTap: () {
                  Navigator.pop(ctx);
                  _deleteTask(task);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _optionTile({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
      title: Text(label,
          style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black87)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _priorityOption(String label, int value, int current,
      ValueChanged<int> onTap, bool isDark) {
    final isActive = current == value;
    final col = _priorityColor(value);
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? col.withValues(alpha: 0.12)
                : isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color:
                  isActive ? col.withValues(alpha: 0.4) : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? col : Colors.grey[500],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEditTaskDialog(Task task) {
    final titleController = TextEditingController(text: task.title);
    final descController = TextEditingController(text: task.description ?? '');
    int priority = task.priority;
    int estimated = task.estimatedPomodoros;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                  20, 12, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(2))),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text('Edit Task',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : Colors.black87)),
                        ),
                        GestureDetector(
                          onTap: () {
                            DatabaseService.deleteTask(task.id);
                            Navigator.pop(ctx);
                            _loadTasks();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.delete_outline_rounded,
                                size: 18, color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Task title',
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.grey.withValues(alpha: 0.08),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 1.5)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Description (optional)',
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.grey.withValues(alpha: 0.08),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 1.5)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Priority',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.grey[400]
                                : Colors.grey[600])),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _priorityOption('None', 0, priority,
                            (v) => setSheetState(() => priority = v), isDark),
                        const SizedBox(width: 6),
                        _priorityOption('Low', 1, priority,
                            (v) => setSheetState(() => priority = v), isDark),
                        const SizedBox(width: 6),
                        _priorityOption('Medium', 2, priority,
                            (v) => setSheetState(() => priority = v), isDark),
                        const SizedBox(width: 6),
                        _priorityOption('High', 3, priority,
                            (v) => setSheetState(() => priority = v), isDark),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Estimated Pomodoros',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.grey[400]
                                : Colors.grey[600])),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (estimated > 1) {
                              setSheetState(() => estimated--);
                            }
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.remove,
                                size: 18, color: AppColors.error),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '$estimated',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () {
                            setSheetState(() => estimated++);
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.add,
                                size: 18, color: AppColors.success),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ...List.generate(3, (i) {
                          final val = i + 1;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: GestureDetector(
                              onTap: () =>
                                  setSheetState(() => estimated = val),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: estimated == val
                                      ? AppColors.primary
                                          .withValues(alpha: 0.12)
                                      : isDark
                                          ? Colors.white
                                              .withValues(alpha: 0.05)
                                          : Colors.grey
                                              .withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$val',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: estimated == val
                                        ? AppColors.primary
                                        : Colors.grey[500],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          final newTitle = titleController.text.trim();
                          if (newTitle.isEmpty) return;
                          task.title = newTitle;
                          task.description =
                              descController.text.trim().isEmpty
                                  ? null
                                  : descController.text.trim();
                          task.priority = priority;
                          task.estimatedPomodoros = estimated;
                          DatabaseService.updateTask(task);
                          Navigator.pop(ctx);
                          _loadTasks();
                        },
                        style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14)),
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final List<_ConfettiParticle> _particles = [];

  _ConfettiPainter({required this.progress}) {
    final random = Random(42);
    for (int i = 0; i < 60; i++) {
      _particles.add(_ConfettiParticle(
        x: random.nextDouble(),
        y: random.nextDouble() * 0.3 - 0.3 * progress,
        color: [
          AppColors.primary,
          AppColors.success,
          AppColors.warning,
          AppColors.accent,
          const Color(0xFF00BCD4),
          const Color(0xFFE91E63),
        ][random.nextInt(6)],
        size: 3.0 + random.nextDouble() * 5,
        rotation: random.nextDouble() * 360,
        speed: 0.3 + random.nextDouble() * 0.7,
        wobble: random.nextDouble() * 2 - 1,
      ));
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final paint = Paint()..color = p.color.withValues(alpha: 0.8);
      final x = p.x * size.width + sin(progress * pi * 2 * p.speed + p.wobble) * 30;
      final y = (p.y + progress * 1.2) * size.height;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate((p.rotation + progress * 360 * p.speed) * pi / 180);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
            const Radius.circular(1)),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _ConfettiParticle {
  final double x, y;
  final Color color;
  final double size, rotation, speed, wobble;

  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.color,
    required this.size,
    required this.rotation,
    required this.speed,
    required this.wobble,
  });
}
