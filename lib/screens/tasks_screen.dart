import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/models.dart';
import '../../core/widgets/app_bottom_nav.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  String _filter = 'all'; // all | today | pending | completed
  final int _selectedIndex = 1; // Tasks index

  // --- Logic ---

  void _showAddTask() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddTaskSheet(),
    );
  }

  void _onNavItemTapped(int index) {
    if (index == _selectedIndex) return;
    switch (index) {
      case 0: Navigator.pushReplacementNamed(context, '/dashboard'); break;
      case 2: Navigator.pushReplacementNamed(context, '/ai-quiz'); break;
      case 3: Navigator.pushReplacementNamed(context, '/analytics'); break;
    }
  }

  List<TaskModel> _applyFilter(List<TaskModel> tasks) {
    switch (_filter) {
      case 'today':
        final today = DateTime.now();
        return tasks.where((t) =>
        t.dueDate.year == today.year &&
            t.dueDate.month == today.month &&
            t.dueDate.day == today.day
        ).toList();
      case 'pending':
        return tasks.where((t) => !t.completed).toList();
      case 'completed':
        return tasks.where((t) => t.completed).toList();
      default:
        return tasks;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 24)
        ),
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.smart_toy_rounded),
            onPressed: () => Navigator.pushNamed(context, '/ai'),
            tooltip: 'Study AI Assistant',
          ),
          const SizedBox(width: 8),
        ],
      ),

      // Central FAB now handles adding tasks
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTask,
        backgroundColor: AppColors.primary,
        shape: const CircleBorder(),
        elevation: 8,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
        tooltip: 'Add New Task',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: AppBottomNavBar(
        selectedIndex: _selectedIndex,
        onTap: _onNavItemTapped,
      ),

      body: Column(
        children: [
          // Filters Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                _FilterChip(label: 'All', value: 'all', selected: _filter, onTap: (v) => setState(() => _filter = v)),
                _FilterChip(label: 'Today', value: 'today', selected: _filter, onTap: (v) => setState(() => _filter = v)),
                _FilterChip(label: 'Pending', value: 'pending', selected: _filter, onTap: (v) => setState(() => _filter = v)),
                _FilterChip(label: 'Completed', value: 'completed', selected: _filter, onTap: (v) => setState(() => _filter = v)),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<List<TaskModel>>(
              stream: FirestoreService.watchTasks(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                final all = snap.data ?? [];
                final tasks = _applyFilter(all);

                if (tasks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('📝', style: TextStyle(fontSize: 64)),
                        const SizedBox(height: 16),
                        Text(all.isEmpty ? 'No tasks yet' : 'No tasks in this filter',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text('Tap the + button to get started',
                            style: TextStyle(fontFamily: 'Poppins', color: Colors.grey.shade500)),
                      ],
                    ),
                  );
                }

                // Sort: overdue first, then priority, then date
                tasks.sort((a, b) {
                  if (a.isOverdue && !b.isOverdue) return -1;
                  if (!a.isOverdue && b.isOverdue) return 1;
                  final pOrder = {'high': 0, 'medium': 1, 'low': 2};
                  final pComp = (pOrder[a.priority] ?? 1).compareTo(pOrder[b.priority] ?? 1);
                  if (pComp != 0) return pComp;
                  return a.dueDate.compareTo(b.dueDate);
                });

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 120), // Padding for FAB clearance
                  itemCount: tasks.length,
                  itemBuilder: (_, i) => _TaskTile(task: tasks[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- Task List Item Widget ---

class _TaskTile extends StatelessWidget {
  final TaskModel task;
  const _TaskTile({required this.task});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => FirestoreService.deleteTask(task.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: task.isOverdue
                ? AppColors.error.withOpacity(0.3)
                : task.completed
                ? Colors.grey.withOpacity(0.1)
                : task.priorityColor.withOpacity(0.2),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: task.completed ? null : () => FirestoreService.completeTask(task.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: task.completed ? AppColors.success : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: task.completed ? AppColors.success : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: task.completed
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      decoration: task.completed ? TextDecoration.lineThrough : null,
                      color: task.completed ? Colors.grey : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.book_outlined, size: 12, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(task.subjectName, style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.grey.shade500)),
                      const SizedBox(width: 10),
                      Icon(Icons.calendar_today_outlined, size: 12, color: task.isOverdue ? AppColors.error : Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM d').format(task.dueDate),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: task.isOverdue ? AppColors.error : Colors.grey.shade500,
                          fontWeight: task.isOverdue ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: task.priorityColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                task.priority[0].toUpperCase() + task.priority.substring(1),
                style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w600, color: task.priorityColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Bottom Sheet Widget ---

class _AddTaskSheet extends StatefulWidget {
  const _AddTaskSheet();

  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  final _titleCtrl = TextEditingController();
  String _priority = 'medium';
  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));
  String? _subjectId;
  String _subjectName = 'General';
  bool _loading = false;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);

    final task = TaskModel(
      id: const Uuid().v4(),
      title: _titleCtrl.text.trim(),
      subjectId: _subjectId ?? '',
      subjectName: _subjectName,
      dueDate: _dueDate,
      priority: _priority,
      createdAt: DateTime.now(),
    );

    await FirestoreService.addTask(task);
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('New Task', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: _titleCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'What needs to be done?', prefixIcon: Icon(Icons.edit_note_rounded)),
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<SubjectModel>>(
              stream: FirestoreService.watchSubjects(),
              builder: (context, snap) {
                final subjects = snap.data ?? [];
                return DropdownButtonFormField<String>(
                  value: _subjectId,
                  decoration: const InputDecoration(labelText: 'Assign to Subject', prefixIcon: Icon(Icons.book_outlined)),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('General')),
                    ...subjects.map((s) => DropdownMenuItem(
                      value: s.id,
                      child: Text(s.name),
                    )),
                  ],
                  onChanged: (id) {
                    setState(() {
                      _subjectId = id;
                      _subjectName = id == null ? 'General' : subjects.firstWhere((s) => s.id == id).name;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 20, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Text('Due: ${DateFormat('EEE, MMM d').format(_dueDate)}', style: const TextStyle(fontWeight: FontWeight.w500)),
                    const Spacer(),
                    const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Priority', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 12),
            Row(
              children: ['high', 'medium', 'low'].map((p) {
                final colors = {'high': AppColors.error, 'medium': AppColors.warning, 'low': AppColors.success};
                final c = colors[p]!;
                final isSelected = _priority == p;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _priority = p),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? c.withOpacity(0.15) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isSelected ? c : Colors.grey.withOpacity(0.2)),
                      ),
                      child: Text(
                        p[0].toUpperCase() + p.substring(1),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.w600, color: isSelected ? c : Colors.grey),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Task', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Filter Chip ---

class _FilterChip extends StatelessWidget {
  final String label, value, selected;
  final ValueChanged<String> onTap;
  const _FilterChip({required this.label, required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade600
            )
        ),
      ),
    );
  }
}