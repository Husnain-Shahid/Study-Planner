import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/models.dart';

class ExamsScreen extends StatefulWidget {
  const ExamsScreen({super.key});

  @override
  State<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends State<ExamsScreen> {
  void _showAddExam() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddExamSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exam Countdown')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddExam,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Exam', style: TextStyle(fontFamily: 'Poppins', color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: StreamBuilder<List<ExamModel>>(
        stream: FirestoreService.watchExams(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          final exams = snap.data ?? [];
          final upcoming = exams.where((e) => !e.isPast).toList();
          final past = exams.where((e) => e.isPast).toList();

          if (exams.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('📝', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  Text('No exams scheduled', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text('Add your upcoming exams to track countdown', style: TextStyle(fontFamily: 'Poppins', color: Colors.grey.shade500)),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            children: [
              if (upcoming.isNotEmpty) ...[
                Text('Upcoming', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                ...upcoming.asMap().entries.map((e) => _ExamCard(
                  exam: e.value,
                  onDelete: () => FirestoreService.deleteExam(e.value.id),
                ).animate().fadeIn(delay: Duration(milliseconds: e.key * 80)).slideY(begin: 0.1, end: 0)),
              ],
              if (past.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text('Past Exams', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                ...past.map((e) => _ExamCard(
                  exam: e,
                  onDelete: () => FirestoreService.deleteExam(e.id),
                  isPast: true,
                )),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ExamCard extends StatelessWidget {
  final ExamModel exam;
  final VoidCallback onDelete;
  final bool isPast;

  const _ExamCard({required this.exam, required this.onDelete, this.isPast = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isPast ? Colors.grey : exam.urgencyColor;

    return Dismissible(
      key: Key(exam.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.red),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            // Days circle
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.3), width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isPast ? 'Done' : '${exam.daysLeft}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: isPast ? 14 : 22,
                      color: color,
                    ),
                  ),
                  if (!isPast)
                    Text(
                      exam.daysLeft == 1 ? 'day' : 'days',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: color),
                    ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(exam.name,
                      style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 15,
                          color: isPast ? Colors.grey : null),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: Color(exam.subjectColor), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(exam.subjectName, style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.event_rounded, size: 13, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(DateFormat('EEEE, MMM d, yyyy').format(exam.examDate),
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.grey.shade500)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Urgency bar
                  if (!isPast) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: exam.daysLeft > 90 ? 1 : (exam.daysLeft / 90).clamp(0, 1),
                        backgroundColor: color.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation(color),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Importance badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                exam.importance.toUpperCase(),
                style: TextStyle(fontFamily: 'Poppins', fontSize: 9, fontWeight: FontWeight.w700, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddExamSheet extends StatefulWidget {
  const _AddExamSheet();

  @override
  State<_AddExamSheet> createState() => _AddExamSheetState();
}

class _AddExamSheetState extends State<_AddExamSheet> {
  final _nameCtrl = TextEditingController();
  DateTime _examDate = DateTime.now().add(const Duration(days: 14));
  String _importance = 'high';
  String? _subjectId;
  String _subjectName = 'General';
  int _subjectColor = 0xFF6C63FF;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _examDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => _examDate = picked);
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    final exam = ExamModel(
      id: const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      subjectId: _subjectId ?? '',
      subjectName: _subjectName,
      subjectColor: _subjectColor,
      examDate: _examDate,
      importance: _importance,
    );
    await FirestoreService.addExam(exam);
    if (mounted) Navigator.pop(context);
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
            Text('Add Exam', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 20),

            TextField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Exam name', prefixIcon: Icon(Icons.assignment_outlined)),
            ),

            const SizedBox(height: 16),

            StreamBuilder<List<SubjectModel>>(
              stream: FirestoreService.watchSubjects(),
              builder: (context, snap) {
                final subjects = snap.data ?? [];
                return DropdownButtonFormField<String>(
                  value: _subjectId,
                  decoration: const InputDecoration(labelText: 'Subject', prefixIcon: Icon(Icons.book_outlined)),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('General', style: TextStyle(fontFamily: 'Poppins'))),
                    ...subjects.map((s) => DropdownMenuItem(
                      value: s.id,
                      child: Row(children: [Text(s.icon), const SizedBox(width: 8), Text(s.name, style: const TextStyle(fontFamily: 'Poppins'))]),
                    )),
                  ],
                  onChanged: (id) {
                    final s = subjects.firstWhere((s) => s.id == id, orElse: () => subjects.first);
                    setState(() {
                      _subjectId = id;
                      _subjectName = id == null ? 'General' : s.name;
                      _subjectColor = id == null ? 0xFF6C63FF : s.colorValue;
                    });
                  },
                );
              },
            ),

            const SizedBox(height: 16),

            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.15)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 20, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Text('Exam date: ${DateFormat('EEE, MMM d, yyyy').format(_examDate)}', style: const TextStyle(fontFamily: 'Poppins', fontSize: 14)),
                    const Spacer(),
                    const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Text('Importance', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Row(
              children: ['high', 'medium', 'low'].map((p) {
                final labels = {'high': '🔴 High', 'medium': '🟡 Medium', 'low': '🟢 Low'};
                final colors = {'high': AppColors.error, 'medium': AppColors.warning, 'low': AppColors.success};
                final c = colors[p]!;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _importance = p),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _importance == p ? c.withOpacity(0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _importance == p ? c : Colors.grey.withOpacity(0.3)),
                      ),
                      child: Text(labels[p]!, textAlign: TextAlign.center,
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600, color: _importance == p ? c : Colors.grey.shade600)),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Add Exam'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}


