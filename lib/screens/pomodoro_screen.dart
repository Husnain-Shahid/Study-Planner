import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/models.dart';
import 'package:uuid/uuid.dart';

enum _TimerMode { work, shortBreak, longBreak }

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> with TickerProviderStateMixin {
  static const _workMins = 25;
  static const _shortBreakMins = 5;
  static const _longBreakMins = 15;

  _TimerMode _mode = _TimerMode.work;
  Timer? _timer;
  int _secondsLeft = _workMins * 60;
  int _totalSeconds = _workMins * 60;
  bool _running = false;
  int _pomodorosCompleted = 0;
  String? _selectedSubjectId;
  String? _selectedSubjectName;
  int _selectedSubjectColor = 0xFF6C63FF;
  DateTime? _sessionStart;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startStop() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
    } else {
      if (_sessionStart == null) _sessionStart = DateTime.now();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_secondsLeft > 0) {
          setState(() => _secondsLeft--);
        } else {
          _timer?.cancel();
          setState(() => _running = false);
          _onComplete();
        }
      });
      setState(() => _running = true);
    }
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _secondsLeft = _totalSeconds;
      _sessionStart = null;
    });
  }

  Future<void> _onComplete() async {
    if (_mode == _TimerMode.work && _selectedSubjectId != null) {
      _pomodorosCompleted++;
      final now = DateTime.now();
      final start = _sessionStart ?? now.subtract(Duration(seconds: _totalSeconds));
      final session = StudySession(
        id: const Uuid().v4(),
        subjectId: _selectedSubjectId!,
        subjectName: _selectedSubjectName ?? 'Study',
        subjectColor: _selectedSubjectColor,
        date: now,
        startTime: start,
        endTime: now,
        durationMins: _workMins,
        type: 'pomodoro',
        xpEarned: 10,
      );
      await FirestoreService.addSession(session);
    }

    _sessionStart = null;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _mode == _TimerMode.work ? '🎉 Pomodoro complete! +10 XP' : '✅ Break time over!',
            style: const TextStyle(fontFamily: 'Poppins'),
          ),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _switchMode(_TimerMode mode) {
    _timer?.cancel();
    final mins = mode == _TimerMode.work
        ? _workMins
        : mode == _TimerMode.shortBreak
        ? _shortBreakMins
        : _longBreakMins;
    setState(() {
      _mode = mode;
      _running = false;
      _totalSeconds = mins * 60;
      _secondsLeft = _totalSeconds;
      _sessionStart = null;
    });
  }

  String get _timeString {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get _progress => 1 - (_secondsLeft / _totalSeconds);

  Color get _modeColor => _mode == _TimerMode.work
      ? AppColors.primary
      : _mode == _TimerMode.shortBreak
      ? AppColors.success
      : AppColors.accent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Pomodoro Timer')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Mode tabs
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  _ModeTab(label: 'Focus', selected: _mode == _TimerMode.work, color: AppColors.primary, onTap: () => _switchMode(_TimerMode.work)),
                  _ModeTab(label: 'Short Break', selected: _mode == _TimerMode.shortBreak, color: AppColors.success, onTap: () => _switchMode(_TimerMode.shortBreak)),
                  _ModeTab(label: 'Long Break', selected: _mode == _TimerMode.longBreak, color: AppColors.accent, onTap: () => _switchMode(_TimerMode.longBreak)),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Circular timer
            AnimatedBuilder(
              animation: _pulseController,
              builder: (_, child) {
                return Transform.scale(
                  scale: _running ? 1 + _pulseController.value * 0.02 : 1,
                  child: child,
                );
              },
              child: SizedBox(
                width: 260,
                height: 260,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background circle
                    SizedBox(
                      width: 260,
                      height: 260,
                      child: CircularProgressIndicator(
                        value: 1,
                        strokeWidth: 12,
                        valueColor: AlwaysStoppedAnimation(_modeColor.withValues(alpha: 0.1)),
                      ),
                    ),
                    // Progress circle
                    SizedBox(
                      width: 260,
                      height: 260,
                      child: CircularProgressIndicator(
                        value: _progress,
                        strokeWidth: 12,
                        strokeCap: StrokeCap.round,
                        valueColor: AlwaysStoppedAnimation(_modeColor),
                      ),
                    ),
                    // Time display
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _timeString,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 52,
                            fontWeight: FontWeight.w700,
                            color: _modeColor,
                          ),
                        ),
                        Text(
                          _mode == _TimerMode.work ? 'Focus Time' : 'Break Time',
                          style: TextStyle(fontFamily: 'Poppins', color: Colors.grey.shade500, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Pomodoros done
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < _pomodorosCompleted % 4
                      ? _modeColor
                      : _modeColor.withValues(alpha: 0.2),
                ),
              )),
            ),

            const SizedBox(height: 8),
            Text(
              '$_pomodorosCompleted pomodoro${_pomodorosCompleted != 1 ? 's' : ''} today',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey.shade500),
            ),

            const SizedBox(height: 32),

            // Subject selector
            StreamBuilder<List<SubjectModel>>(
              stream: FirestoreService.watchSubjects(),
              builder: (context, snap) {
                final subjects = snap.data ?? [];
                return DropdownButtonFormField<String>(
                  value: _selectedSubjectId,
                  decoration: const InputDecoration(
                    labelText: 'Study subject (optional)',
                    prefixIcon: Icon(Icons.book_rounded),
                  ),
                  items: subjects.map((s) => DropdownMenuItem(
                    value: s.id,
                    child: Row(
                      children: [
                        Text(s.icon),
                        const SizedBox(width: 8),
                        Text(s.name, style: const TextStyle(fontFamily: 'Poppins')),
                      ],
                    ),
                  )).toList(),
                  onChanged: (id) {
                    final subject = subjects.firstWhere((s) => s.id == id);
                    setState(() {
                      _selectedSubjectId = id;
                      _selectedSubjectName = subject.name;
                      _selectedSubjectColor = subject.colorValue;
                    });
                  },
                );
              },
            ),

            const SizedBox(height: 32),

            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.outlined(
                  onPressed: _reset,
                  icon: const Icon(Icons.refresh_rounded),
                  iconSize: 28,
                  style: IconButton.styleFrom(
                    minimumSize: const Size(52, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(width: 20),

                // Play/Pause
                GestureDetector(
                  onTap: _startStop,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _modeColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: _modeColor.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      _running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),

                const SizedBox(width: 20),

                IconButton.outlined(
                  onPressed: () => _switchMode(
                    _mode == _TimerMode.work ? _TimerMode.shortBreak : _TimerMode.work,
                  ),
                  icon: const Icon(Icons.skip_next_rounded),
                  iconSize: 28,
                  style: IconButton.styleFrom(
                    minimumSize: const Size(52, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // XP info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Text('⚡', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('+10 XP per completed Pomodoro', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13)),
                        Text('Session logged automatically', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _ModeTab({required this.label, required this.selected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : Colors.grey.shade500,
            ),
          ),
        ),
      ),
    );
  }
}
