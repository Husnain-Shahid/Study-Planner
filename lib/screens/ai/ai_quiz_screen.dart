import 'package:flutter/material.dart';
import '../../core/services/gemini_service.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/models.dart';
import '../../core/widgets/app_bottom_nav.dart';


enum _QuizState { input, loading, finishing, playing, result }

class AiQuizScreen extends StatefulWidget {
  const AiQuizScreen({super.key});

  @override
  State<AiQuizScreen> createState() => _AiQuizScreenState();
}

class _AiQuizScreenState extends State<AiQuizScreen> {
  _QuizState _state = _QuizState.input;
  final _topicCtrl = TextEditingController();
  int _questionCount = 10;
  String _difficulty = 'medium';
  int _selectedIndex = 2; // Quiz is at index 2

  List<QuizQuestion> _questions = [];
  int _current = 0;
  int? _selected;
  bool _answered = false;
  List<bool> _answers = [];
  String? _error;

  void _onNavItemTapped(int index) {
    if (index == 2) return; // Already on Quiz screen

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/dashboard');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/tasks');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/analytics');
        break;
    }
  }

  Future<void> _generateQuiz() async {
    if (_topicCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a topic first')),
      );
      return;
    }

    setState(() {
      _state = _QuizState.loading;
      _error = null;
    });

    try {
      final questions = await GeminiService.generateQuiz(
        _topicCtrl.text.trim(),
        count: _questionCount,
        difficulty: _difficulty,
      );
      setState(() {
        _questions = questions;
        _current = 0;
        _selected = null;
        _answered = false;
        _answers = [];
        _state = _QuizState.playing;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _state = _QuizState.input;
      });
    }
  }

  void _selectAnswer(int idx) {
    if (_answered) return;
    setState(() {
      _selected = idx;
      _answered = true;
      _answers.add(idx == _questions[_current].correctIndex);
    });
  }

  void _next() {
    if (_current < _questions.length - 1) {
      setState(() {
        _current++;
        _selected = null;
        _answered = false;
      });
    } else {
      _finishQuiz();
    }
  }

  Future<void> _finishQuiz() async {
    setState(() => _state = _QuizState.finishing);

    final score = _answers.where((a) => a).length;

    try {
      await FirestoreService.saveQuizResult(
        topic: _topicCtrl.text.trim(),
        score: score,
        total: _questions.length,
        weakTopics: [],
      );
    } catch (e) {
      debugPrint('Failed to save quiz result: $e');
      // We continue to show results even if saving fails
    }

    if (mounted) {
      setState(() => _state = _QuizState.result);
    }
  }

  void _restart() {
    setState(() {
      _state = _QuizState.input;
      _questions = [];
      _answers = [];
      _current = 0;
      _selected = null;
      _answered = false;
    });
  }

  @override
  void dispose() {
    _topicCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Quiz', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 24)),
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_state == _QuizState.playing)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${_current + 1}/${_questions.length}',
                  style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                ),
              ),
            ),
        ],
      ),
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
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: switch (_state) {
          _QuizState.input => _buildInput(),
          _QuizState.loading => _buildLoading('Generating your quiz...'),
          _QuizState.finishing => _buildLoading('Calculating results...'),
          _QuizState.playing => _buildQuiz(),
          _QuizState.result => _buildResult(),
        },
      ),
    );
  }

  Widget _buildInput() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.warning.withOpacity(0.15),
                  AppColors.primary.withOpacity(0.1)
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text('🧠', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text('Generate a Quiz',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 6),
                Text(
                  'Enter any topic and AI will create MCQs for you instantly',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.grey.shade600,
                      fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text('Topic or subject',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _topicCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText:
                  'e.g. "Photosynthesis", "French Revolution", "Algebra basics"',
            ),
          ),
          const SizedBox(height: 24),
          Text('Number of questions',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Row(
            children: [5, 10, 15, 20]
                .map((n) => Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _questionCount = n),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _questionCount == n
                                ? AppColors.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _questionCount == n
                                  ? AppColors.primary
                                  : Colors.grey.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            '$n',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              color: _questionCount == n
                                  ? Colors.white
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 24),
          Text('Difficulty', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Row(
            children: ['easy', 'medium', 'hard']
                .map((d) => Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _difficulty = d),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _difficulty == d
                                ? (d == 'easy'
                                        ? AppColors.success
                                        : d == 'medium'
                                            ? AppColors.warning
                                            : AppColors.error)
                                    .withOpacity(0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _difficulty == d
                                  ? (d == 'easy'
                                      ? AppColors.success
                                      : d == 'medium'
                                          ? AppColors.warning
                                          : AppColors.error)
                                  : Colors.grey.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            d[0].toUpperCase() + d.substring(1),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              color: _difficulty == d
                                  ? (d == 'easy'
                                      ? AppColors.success
                                      : d == 'medium'
                                          ? AppColors.warning
                                          : AppColors.error)
                                  : Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(_error!,
                  style: const TextStyle(
                      color: AppColors.error,
                      fontFamily: 'Poppins',
                      fontSize: 13)),
            ),
          ],
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _generateQuiz,
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('Generate Quiz'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.accent]),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 40),
          ),
          const SizedBox(height: 24),
          Text(message,
              style: Theme.of(context).textTheme.titleLarge),
          if (_state == _QuizState.loading) ...[
            const SizedBox(height: 8),
            Text(
              'AI is crafting $_questionCount questions on "${_topicCtrl.text}"',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.grey.shade500,
                  fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 32),
          const CircularProgressIndicator(color: AppColors.primary),
        ],
      ),
    );
  }

  Widget _buildQuiz() {
    final q = _questions[_current];
    final progress = (_current + 1) / _questions.length;

    return Column(
      children: [
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey.withOpacity(0.2),
          valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          minHeight: 4,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Question ${_current + 1}',
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        q.question,
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ...q.options.asMap().entries.map((entry) {
                  final i = entry.key;
                  final opt = entry.value;
                  final isCorrect = i == q.correctIndex;
                  final isSelected = i == _selected;

                  Color borderColor = Colors.grey.withOpacity(0.2);
                  Color bgColor = Colors.transparent;
                  Color textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

                  if (_answered) {
                    if (isCorrect) {
                      borderColor = AppColors.success;
                      bgColor = AppColors.success.withOpacity(0.1);
                      textColor = AppColors.success;
                    } else if (isSelected && !isCorrect) {
                      borderColor = AppColors.error;
                      bgColor = AppColors.error.withOpacity(0.1);
                      textColor = AppColors.error;
                    }
                  } else if (isSelected) {
                    borderColor = AppColors.primary;
                    bgColor = AppColors.primary.withOpacity(0.1);
                  }

                  final labels = ['A', 'B', 'C', 'D'];

                  return GestureDetector(
                    onTap: () => _selectAnswer(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: _answered
                                  ? (isCorrect
                                      ? AppColors.success
                                      : (isSelected
                                          ? AppColors.error
                                          : Colors.grey.withOpacity(0.15)))
                                  : (isSelected
                                      ? AppColors.primary
                                      : Colors.grey.withOpacity(0.15)),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: _answered && (isCorrect || isSelected)
                                  ? Icon(
                                      isCorrect
                                          ? Icons.check_rounded
                                          : Icons.close_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    )
                                  : Text(
                                      labels[i],
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(opt,
                                style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                    color: textColor,
                                    height: 1.4)),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                if (_answered) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            color: Colors.blue, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            q.explanation,
                            style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                color: Colors.blue,
                                height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_answered)
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _next,
                child: Text(_current < _questions.length - 1 ? 'Next Question →' : 'See Results'),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildResult() {
    final score = _answers.where((a) => a).length;
    final percent = (score / _questions.length * 100).round();
    final isPassing = percent >= 60;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Text(isPassing ? '🎉' : '📚', style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(isPassing ? 'Great job!' : 'Keep practicing!',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('Topic: ${_topicCtrl.text}',
              style: TextStyle(
                  fontFamily: 'Poppins', color: Colors.grey.shade500)),
          const SizedBox(height: 32),
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (isPassing ? AppColors.success : AppColors.warning)
                  .withOpacity(0.1),
              border: Border.all(
                color: isPassing ? AppColors.success : AppColors.warning,
                width: 4,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$percent%',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: isPassing ? AppColors.success : AppColors.warning,
                  ),
                ),
                Text(
                  '$score/${_questions.length}',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                _ResultRow(
                    label: 'Correct', value: '$score', color: AppColors.success),
                _ResultRow(
                    label: 'Incorrect',
                    value: '${_questions.length - score}',
                    color: AppColors.error),
                _ResultRow(
                    label: 'Score',
                    value: '$percent%',
                    color: AppColors.primary),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _restart,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('New Quiz',
                      style: TextStyle(fontFamily: 'Poppins')),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _current = 0;
                      _selected = null;
                      _answered = false;
                      _answers = [];
                      _state = _QuizState.playing;
                    });
                  },
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Retry',
                      style: TextStyle(fontFamily: 'Poppins')),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ResultRow(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 14)),
          Text(value,
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ],
      ),
    );
  }
}
