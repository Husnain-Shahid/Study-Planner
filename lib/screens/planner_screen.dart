// ─── PLANNER SCREEN ───────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/models.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  DateTime _focused = DateTime.now();
  DateTime _selected = DateTime.now();

  void _showAddSession() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddSessionSheet(selectedDate: _selected),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('Study Planner')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSession,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Session', style: TextStyle(fontFamily: 'Poppins', color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          // Calendar
          Container(
            color: isDark ? AppColors.darkSurface : Colors.white,
            child: TableCalendar(
              firstDay: DateTime.utc(2020),
              lastDay: DateTime.utc(2030),
              focusedDay: _focused,
              selectedDayPredicate: (d) => isSameDay(d, _selected),
              calendarFormat: CalendarFormat.month,
              startingDayOfWeek: StartingDayOfWeek.monday,
              onDaySelected: (sel, foc) => setState(() { _selected = sel; _focused = foc; }),
              onPageChanged: (foc) => setState(() => _focused = foc),
              calendarStyle: CalendarStyle(
                selectedDecoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                todayDecoration: BoxDecoration(color: AppColors.primary.withOpacity(0.3), shape: BoxShape.circle),
                selectedTextStyle: const TextStyle(color: Colors.white, fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                todayTextStyle: const TextStyle(color: AppColors.primary, fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                defaultTextStyle: TextStyle(fontFamily: 'Poppins', color: isDark ? Colors.white70 : Colors.black87),
                weekendTextStyle: TextStyle(fontFamily: 'Poppins', color: isDark ? Colors.white54 : Colors.grey.shade500),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 16),
                leftChevronIcon: const Icon(Icons.chevron_left_rounded, color: AppColors.primary),
                rightChevronIcon: const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey.shade500),
                weekendStyle: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey.shade400),
              ),
            ),
          ),

          const Divider(height: 1),

          // Sessions for selected day
          Expanded(
            child: StreamBuilder<List<StudySession>>(
              stream: FirestoreService.watchSessions(date: _selected),
              builder: (context, snap) {
                final sessions = snap.data ?? [];

                if (sessions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('📅', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text(
                          DateFormat('EEEE, MMMM d').format(_selected),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text('No sessions planned', style: TextStyle(fontFamily: 'Poppins', color: Colors.grey.shade500, fontSize: 13)),
                      ],
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  children: [
                    Text(DateFormat('EEEE, MMMM d').format(_selected), style: Theme.of(context).textTheme.titleMedium),
                    Text('${sessions.length} session${sessions.length != 1 ? 's' : ''}', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey.shade500)),
                    const SizedBox(height: 12),
                    ...sessions.asMap().entries.map((e) {
                      final s = e.value;
                      return Dismissible(
                        key: Key(s.id),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => FirestoreService.deleteSession(s.id),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
                          child: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                        ),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border(left: BorderSide(color: Color(s.subjectColor), width: 4)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s.subjectName, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 15)),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${DateFormat('h:mm a').format(s.startTime)} – ${DateFormat('h:mm a').format(s.endTime)}',
                                      style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Color(s.subjectColor).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('${s.durationMins}m', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 13, color: Color(s.subjectColor))),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: Duration(milliseconds: e.key * 60)).slideX(begin: 0.05, end: 0),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AddSessionSheet extends StatefulWidget {
  final DateTime selectedDate;
  const _AddSessionSheet({required this.selectedDate});

  @override
  State<_AddSessionSheet> createState() => _AddSessionSheetState();
}

class _AddSessionSheetState extends State<_AddSessionSheet> {
  String? _subjectId;
  String _subjectName = '';
  int _subjectColor = 0xFF6C63FF;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  bool _loading = false;

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(context: context, initialTime: isStart ? _startTime : _endTime);
    if (picked != null) setState(() => isStart ? _startTime = picked : _endTime = picked);
  }

  Future<void> _save() async {
    if (_subjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a subject')));
      return;
    }
    setState(() => _loading = true);
    final date = widget.selectedDate;
    final start = DateTime(date.year, date.month, date.day, _startTime.hour, _startTime.minute);
    final end = DateTime(date.year, date.month, date.day, _endTime.hour, _endTime.minute);
    if (end.isBefore(start)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('End time must be after start time')));
      setState(() => _loading = false);
      return;
    }
    final durationMins = end.difference(start).inMinutes;
    final session = StudySession(
      id: const Uuid().v4(),
      subjectId: _subjectId!,
      subjectName: _subjectName,
      subjectColor: _subjectColor,
      date: date,
      startTime: start,
      endTime: end,
      durationMins: durationMins,
      type: 'manual',
      xpEarned: (durationMins / 25).round() * 5,
    );
    await FirestoreService.addSession(session);
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
            Text('Add Study Session', style: Theme.of(context).textTheme.headlineSmall),
            Text('${DateFormat('EEEE, MMM d').format(widget.selectedDate)}', style: TextStyle(fontFamily: 'Poppins', color: Colors.grey.shade500, fontSize: 13)),
            const SizedBox(height: 20),
            StreamBuilder<List<SubjectModel>>(
              stream: FirestoreService.watchSubjects(),
              builder: (context, snap) {
                final subjects = snap.data ?? [];
                return DropdownButtonFormField<String>(
                  value: _subjectId,
                  decoration: const InputDecoration(labelText: 'Subject *', prefixIcon: Icon(Icons.book_outlined)),
                  items: subjects.map((s) => DropdownMenuItem(
                    value: s.id,
                    child: Row(children: [Text(s.icon), const SizedBox(width: 8), Text(s.name, style: const TextStyle(fontFamily: 'Poppins'))]),
                  )).toList(),
                  onChanged: (id) {
                    final s = subjects.firstWhere((s) => s.id == id);
                    setState(() { _subjectId = id; _subjectName = s.name; _subjectColor = s.colorValue; });
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: GestureDetector(
                  onTap: () => _pickTime(true),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Start', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.grey.shade500)),
                        const SizedBox(height: 4),
                        Text(_startTime.format(context), style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 16)),
                      ],
                    ),
                  ),
                )),
                const SizedBox(width: 12),
                Expanded(child: GestureDetector(
                  onTap: () => _pickTime(false),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('End', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.grey.shade500)),
                        const SizedBox(height: 4),
                        Text(_endTime.format(context), style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 16)),
                      ],
                    ),
                  ),
                )),
              ],
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Add Session'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─── GAMIFICATION SCREEN ──────────────────────────────────────────────────────
class GamificationScreen extends StatelessWidget {
  const GamificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: FutureBuilder<List<String>>(
        future: FirestoreService.getUnlockedBadgeIds(),
        builder: (context, snap) {
          final unlocked = snap.data ?? [];
          final allBadges = BadgeModel.getAllBadges();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            children: [
              // XP & Level header
              StreamBuilder<UserModel?>(
                stream: FirestoreService.watchUser(),
                builder: (context, userSnap) {
                  final user = userSnap.data;
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Text('Level ${user?.level ?? 1}', style: const TextStyle(fontFamily: 'Poppins', fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white)),
                        Text(user?.levelTitle ?? 'Beginner', style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, color: Colors.white70)),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(children: [
                              Text('${user?.xp ?? 0}', style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 20, color: Colors.white)),
                              const Text('Total XP', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.white60)),
                            ]),
                            Column(children: [
                              Text('${user?.streak ?? 0}d', style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 20, color: Colors.white)),
                              const Text('Streak', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.white60)),
                            ]),
                            Column(children: [
                              Text('${unlocked.length}', style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 20, color: Colors.white)),
                              const Text('Badges', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.white60)),
                            ]),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),
              Text('Badges', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.6, crossAxisSpacing: 12, mainAxisSpacing: 12),
                itemCount: allBadges.length,
                itemBuilder: (_, i) {
                  final badge = allBadges[i];
                  final isUnlocked = unlocked.contains(badge.id);
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isUnlocked
                          ? AppColors.warning.withOpacity(0.1)
                          : isDark ? AppColors.darkCard : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isUnlocked ? AppColors.warning.withOpacity(0.4) : Colors.grey.withOpacity(0.15),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(isUnlocked ? badge.emoji : '🔒', style: const TextStyle(fontSize: 22)),
                            const Spacer(),
                            if (isUnlocked) const Icon(Icons.check_circle_rounded, color: AppColors.warning, size: 16),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(badge.title, style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12, color: isUnlocked ? null : Colors.grey.shade400)),
                        Text(badge.description, style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: Colors.grey.shade500, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ).animate().fadeIn(delay: Duration(milliseconds: i * 50));
                },
              ),

              const SizedBox(height: 24),
              Text('Leaderboard', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),

              StreamBuilder<List<UserModel>>(
                stream: FirestoreService.watchLeaderboard(),
                builder: (context, snap) {
                  final users = snap.data ?? [];
                  if (users.isEmpty) return const Center(child: Text('No data yet', style: TextStyle(fontFamily: 'Poppins')));
                  return Column(
                    children: users.asMap().entries.map((e) {
                      final u = e.value;
                      final rank = e.key + 1;
                      final isDark = Theme.of(context).brightness == Brightness.dark;
                      final medals = {1: '🥇', 2: '🥈', 3: '🥉'};
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: rank <= 3 ? AppColors.warning.withOpacity(0.08) : isDark ? AppColors.darkCard : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: rank <= 3 ? AppColors.warning.withOpacity(0.2) : Colors.grey.withOpacity(0.1)),
                        ),
                        child: Row(
                          children: [
                            Text(medals[rank] ?? '#$rank', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: rank <= 3 ? 20 : 14)),
                            const SizedBox(width: 12),
                            CircleAvatar(
                              radius: 18,
                              backgroundImage: u.avatarUrl != null ? NetworkImage(u.avatarUrl!) : null,
                              backgroundColor: AppColors.primary.withOpacity(0.2),
                              child: u.avatarUrl == null ? Text(u.name[0], style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontFamily: 'Poppins', fontSize: 12)) : null,
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(u.name, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14))),
                            Text('${u.weeklyXp} XP', style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: AppColors.warning, fontSize: 13)),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── GROUPS SCREEN ────────────────────────────────────────────────────────────
class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Study Groups')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('👥', style: TextStyle(fontSize: 72)),
            const SizedBox(height: 20),
            Text('Study Groups', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Create or join study groups with friends. Share notes, set goals, and study together.',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Poppins', color: Colors.grey.shade500, height: 1.5),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create Group'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.group_add_rounded),
              label: const Text('Join with Code', style: TextStyle(fontFamily: 'Poppins')),
            ),
          ],
        ),
      ),
    );
  }
}

