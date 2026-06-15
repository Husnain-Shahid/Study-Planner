import 'package:flutter/material.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/models.dart';
import '../../core/widgets/app_bottom_nav.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  void _onNavItemTapped(int index) {
    setState(() => _selectedIndex = index);

    // Navigate to the respective screen
    switch (index) {
      case 0:
        // Dashboard - already here
        break;
      case 1:
        Navigator.pushNamed(context, '/tasks');
        break;
      case 2:
        Navigator.pushNamed(context, '/ai-quiz');
        break;
      case 3:
        Navigator.pushNamed(context, '/analytics');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/ai'),
        backgroundColor: AppColors.primary,
        shape: const CircleBorder(),
        elevation: 8,
        child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 24),
        tooltip: 'Study AI Assistant',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: AppBottomNavBar(
        selectedIndex: _selectedIndex,
        onTap: _onNavItemTapped,
      ),
      body: RefreshIndicator(
        onRefresh: () async => await Future.delayed(const Duration(milliseconds: 500)),
        child: CustomScrollView(
          slivers: [
            _buildAppBar(context),
            Builder(
              builder: (context) {
                final bottomInset = MediaQuery.of(context).viewPadding.bottom;
                final bottomSpace = bottomInset + 120.0; // nav + fab + safe area
                return SliverPadding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, bottomSpace),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _StatsRow(),
                      const SizedBox(height: 24),
                      _TodaySection(),
                      const SizedBox(height: 24),
                      _ExamCountdownSection(),
                      const SizedBox(height: 24),
                      _QuickActionsSection(),
                      const SizedBox(height: 24),
                      _RecentSubjectsSection(),
                    ]),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }


  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      floating: true,
      expandedHeight: 128,
      toolbarHeight: 128,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primary.withValues(alpha: 0.7),
              ],
            ),
          ),
          child: StreamBuilder<UserModel?>(
            stream: FirestoreService.watchUser(),
            builder: (context, snap) {
              final user = snap.data;
              final hour = DateTime.now().hour;
              final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';

              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 360;

                    final nameText = Text(
                      user?.name ?? 'Student',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: compact ? 21 : 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    );

                    final greetingText = Text(
                      '$greeting! 👋',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.82),
                        fontWeight: FontWeight.w600,
                      ),
                    );

                    final profileAvatar = GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/profile'),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
                        ),
                        child: CircleAvatar(
                          radius: compact ? 20 : 23,
                          backgroundImage: user?.avatarUrl != null ? NetworkImage(user!.avatarUrl!) : null,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          child: user?.avatarUrl == null
                              ? Text(
                                  (user?.name ?? 'S')[0].toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Poppins',
                                    fontSize: compact ? 15 : 17,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    );

                    final streakBadge = user != null && user.streak > 0
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🔥', style: TextStyle(fontSize: 16)),
                                const SizedBox(width: 6),
                                Text(
                                  '${user.streak}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink();

                    if (compact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          greetingText,
                          const SizedBox(height: 4),
                          nameText,
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              streakBadge,
                              if (user != null && user.streak > 0) const SizedBox(width: 12),
                              profileAvatar,
                            ],
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              greetingText,
                              nameText,
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            streakBadge,
                            if (user != null && user.streak > 0) const SizedBox(width: 12),
                            profileAvatar,
                          ],
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── Stats Row ──────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel?>(
      stream: FirestoreService.watchUser(),
      builder: (context, snap) {
        final user = snap.data;
        return Row(
          children: [
            _StatCard(label: 'Total XP', value: '${user?.xp ?? 0}', icon: '⚡', color: AppColors.warning),
            const SizedBox(width: 12),
            _StatCard(label: 'Level', value: '${user?.level ?? 1}', icon: '🏅', color: AppColors.primary),
            const SizedBox(width: 12),
            _StatCard(label: 'Streak', value: '${user?.streak ?? 0}d', icon: '🔥', color: AppColors.error),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Today's Sessions ───────────────────────────────────────────────────────────
class _TodaySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Today's Plan", style: Theme.of(context).textTheme.titleLarge),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/planner'),
              child: const Text('View all', style: TextStyle(fontFamily: 'Poppins')),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<StudySession>>(
          stream: FirestoreService.watchSessions(date: DateTime.now()),
          builder: (context, snap) {
            final sessions = snap.data ?? [];
            if (sessions.isEmpty) {
              return _EmptyCard(
                emoji: '📅',
                message: 'No sessions planned today',
                action: 'Plan a session',
                onTap: () => Navigator.pushNamed(context, '/planner'),
              );
            }
            return Column(
              children: sessions.map((s) => _SessionTile(session: s)).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _SessionTile extends StatelessWidget {
  final StudySession session;
  const _SessionTile({required this.session});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          top: BorderSide(color: Color(session.subjectColor).withValues(alpha: 0.2)),
          right: BorderSide(color: Color(session.subjectColor).withValues(alpha: 0.2)),
          bottom: BorderSide(color: Color(session.subjectColor).withValues(alpha: 0.2)),
          left: BorderSide(color: Color(session.subjectColor), width: 4),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(session.subjectName, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                Text(
                  '${DateFormat('h:mm a').format(session.startTime)} – ${DateFormat('h:mm a').format(session.endTime)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontFamily: 'Poppins'),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Color(session.subjectColor).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${session.durationMins}m',
              style: TextStyle(
                color: Color(session.subjectColor),
                fontWeight: FontWeight.w600,
                fontSize: 12,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Exam Countdown ─────────────────────────────────────────────────────────────
class _ExamCountdownSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Upcoming Exams', style: Theme.of(context).textTheme.titleLarge),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/exam'),
              child: const Text('View all', style: TextStyle(fontFamily: 'Poppins')),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<ExamModel>>(
          stream: FirestoreService.watchExams(),
          builder: (context, snap) {
            final exams = (snap.data ?? []).where((e) => !e.isPast).take(3).toList();
            if (exams.isEmpty) {
              return _EmptyCard(
                emoji: '📝',
                message: 'No upcoming exams',
                action: 'Add exam',
                onTap: () => Navigator.pushNamed(context, '/exam'),
              );
            }
            return SizedBox(
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: exams.length,
                itemBuilder: (_, i) => _ExamCard(exam: exams[i]),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ExamCard extends StatelessWidget {
  final ExamModel exam;
  const _ExamCard({required this.exam});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: exam.urgencyColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: exam.urgencyColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            exam.name,
            style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            exam.subjectName,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 10.5, fontFamily: 'Poppins'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Text(
            '${exam.daysLeft}',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 24, fontWeight: FontWeight.w700, color: exam.urgencyColor),
          ),
          Text(
            'days left',
            style: TextStyle(color: exam.urgencyColor, fontSize: 10, fontFamily: 'Poppins'),
          ),
        ],
      ),
    );
  }
}

// ── Quick Actions ──────────────────────────────────────────────────────────────
class _QuickActionsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(icon: Icons.timer_rounded, label: 'Timer', color: AppColors.primary, route: '/pomodoro'),
      _QuickAction(icon: Icons.note_add_rounded, label: 'Self Notes', color: AppColors.accent, route: '/notes'),
      _QuickAction(icon: Icons.quiz_rounded, label: 'Notes', color: AppColors.warning, route: '/book-notes'),
      _QuickAction(icon: Icons.style_rounded, label: 'Cards', color: AppColors.error, route: '/flashcards'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Row(
          children: actions.map((a) => Expanded(
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, a.route),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: a.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: a.color.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    Icon(a.icon, color: a.color, size: 24),
                    const SizedBox(height: 6),
                    Text(a.label, style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600, color: a.color)),
                  ],
                ),
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final String route;
  const _QuickAction({required this.icon, required this.label, required this.color, required this.route});
}

// ── Recent Subjects ────────────────────────────────────────────────────────────
class _RecentSubjectsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('My Subjects', style: Theme.of(context).textTheme.titleLarge),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/subjects'),
              child: const Text('Manage', style: TextStyle(fontFamily: 'Poppins')),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<SubjectModel>>(
          stream: FirestoreService.watchSubjects(),
          builder: (context, snap) {
            final subjects = snap.data ?? [];
            if (subjects.isEmpty) {
              return _EmptyCard(
                emoji: '📚',
                message: 'Add your first subject',
                action: 'Add subject',
                onTap: () => Navigator.pushNamed(context, '/subjects'),
              );
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: subjects.length,
              itemBuilder: (_, i) {
                final s = subjects[i];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: s.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: s.color.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Text(s.icon, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          s.name,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: s.color,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

// ── Empty State Card ───────────────────────────────────────────────────────────
class _EmptyCard extends StatelessWidget {
  final String emoji;
  final String message;
  final String action;
  final VoidCallback onTap;

  const _EmptyCard({required this.emoji, required this.message, required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.15), style: BorderStyle.none),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(message, style: TextStyle(fontFamily: 'Poppins', color: Colors.grey.shade500)),
            const SizedBox(height: 8),
            Text(
              '+ $action',
              style: const TextStyle(fontFamily: 'Poppins', color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

