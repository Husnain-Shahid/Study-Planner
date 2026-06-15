import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/gemini_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/models.dart';

class FlashcardsScreen extends StatefulWidget {
  const FlashcardsScreen({super.key});

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  String? _selectedSubjectId;

  void _showAddCard({String? subjectId}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddCardSheet(subjectId: subjectId ?? _selectedSubjectId),
    );
  }

  void _showAiGenerate() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AiGenerateSheet(subjectId: _selectedSubjectId),
    );
  }

  void _startReview(List<FlashCard> cards) {
    if (cards.isEmpty) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => _ReviewScreen(cards: cards)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcards'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome_rounded),
            tooltip: 'AI Generate',
            onPressed: _showAiGenerate,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCard(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Card', style: TextStyle(fontFamily: 'Poppins', color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          // Subject filter
          StreamBuilder<List<SubjectModel>>(
            stream: FirestoreService.watchSubjects(),
            builder: (context, snap) {
              final subjects = snap.data ?? [];
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    _FilterPill(label: 'All', selected: _selectedSubjectId == null, onTap: () => setState(() => _selectedSubjectId = null)),
                    ...subjects.map((s) => _FilterPill(
                      label: '${s.icon} ${s.name}',
                      selected: _selectedSubjectId == s.id,
                      color: s.color,
                      onTap: () => setState(() => _selectedSubjectId = s.id),
                    )),
                  ],
                ),
              );
            },
          ),

          Expanded(
            child: StreamBuilder<List<FlashCard>>(
              stream: FirestoreService.watchFlashcards(subjectId: _selectedSubjectId),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }
                final cards = snap.data ?? [];
                final dueCards = cards.where((c) => c.isDue).toList();

                if (cards.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🃏', style: TextStyle(fontSize: 64)),
                        const SizedBox(height: 16),
                        Text('No flashcards yet', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text('Create cards or use AI to generate them', style: TextStyle(fontFamily: 'Poppins', color: Colors.grey.shade500)),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _showAiGenerate,
                          icon: const Icon(Icons.auto_awesome_rounded),
                          label: const Text('Generate with AI'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  children: [
                    // Review button
                    if (dueCards.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [AppColors.primary.withOpacity(0.8), AppColors.accent.withOpacity(0.8)]),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Text('🔔', style: TextStyle(fontSize: 32)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${dueCards.length} cards due for review!', style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: Colors.white)),
                                  const Text('Review now to strengthen memory', style: TextStyle(fontFamily: 'Poppins', color: Colors.white70, fontSize: 12)),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              ),
                              onPressed: () => _startReview(dueCards),
                              child: const Text('Review', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(),

                    Text('${cards.length} cards total', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey.shade500)),
                    const SizedBox(height: 12),

                    ...cards.asMap().entries.map((e) => _CardTile(
                      card: e.value,
                      onDelete: () => FirestoreService.deleteFlashcard(e.value.id),
                    ).animate().fadeIn(delay: Duration(milliseconds: e.key * 50))),
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

class _CardTile extends StatelessWidget {
  final FlashCard card;
  final VoidCallback onDelete;

  const _CardTile({required this.card, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Dismissible(
      key: Key(card.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: AppColors.error.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: card.isDue ? AppColors.primary.withOpacity(0.3) : Colors.grey.withOpacity(0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Q', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 11)),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(card.front, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13))),
                if (card.isDue) const Icon(Icons.notification_important_rounded, color: AppColors.primary, size: 16),
              ],
            ),
            const Divider(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                  child: const Text('A', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: AppColors.accent, fontSize: 11)),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(card.back, style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey.shade600))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Review Screen ──────────────────────────────────────────────────────────────
class _ReviewScreen extends StatefulWidget {
  final List<FlashCard> cards;
  const _ReviewScreen({required this.cards});

  @override
  State<_ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<_ReviewScreen> with SingleTickerProviderStateMixin {
  int _current = 0;
  bool _showBack = false;
  bool _done = false;
  late AnimationController _flipCtrl;
  late Animation<double> _flipAnim;

  @override
  void initState() {
    super.initState();
    _flipCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _flipAnim = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    super.dispose();
  }

  void _flip() {
    if (_showBack) {
      _flipCtrl.reverse();
    } else {
      _flipCtrl.forward();
    }
    setState(() => _showBack = !_showBack);
  }

  Future<void> _rate(String difficulty) async {
    // Spaced repetition: easy=good, hard=bad
    final card = widget.cards[_current];
    double ef = card.easeFactor;
    int interval = card.interval;

    if (difficulty == 'easy') {
      ef = (ef + 0.1).clamp(1.3, 2.5);
      interval = (interval * ef).round().clamp(1, 365);
    } else if (difficulty == 'hard') {
      ef = (ef - 0.15).clamp(1.3, 2.5);
      interval = 1;
    } else {
      // medium
      interval = (interval * ef).round().clamp(1, 365);
    }

    await FirestoreService.updateFlashcard(card.id, {
      'easeFactor': ef,
      'interval': interval,
      'nextReview': DateTime.now().add(Duration(days: interval)).toIso8601String(),
    });

    if (_current < widget.cards.length - 1) {
      _flipCtrl.reset();
      setState(() {
        _current++;
        _showBack = false;
      });
    } else {
      setState(() => _done = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_done) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 72)).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
              const SizedBox(height: 20),
              Text('Session Complete!', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text('Reviewed ${widget.cards.length} cards', style: TextStyle(fontFamily: 'Poppins', color: Colors.grey.shade500)),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      );
    }

    final card = widget.cards[_current];
    final progress = (_current + 1) / widget.cards.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('${_current + 1} / ${widget.cards.length}'),
        leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(value: progress, color: AppColors.primary, backgroundColor: Colors.grey.withOpacity(0.2), minHeight: 4),
          Expanded(
            child: GestureDetector(
              onTap: _flip,
              child: AnimatedBuilder(
                animation: _flipAnim,
                builder: (_, child) {
                  final angle = _flipAnim.value * pi;
                  final isFront = angle < pi / 2;
                  return Transform(
                    transform: Matrix4.rotationY(angle),
                    alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isFront
                                ? [AppColors.primary.withOpacity(0.8), AppColors.primaryDark]
                                : [AppColors.accent.withOpacity(0.8), const Color(0xFF008A6E)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: (isFront ? AppColors.primary : AppColors.accent).withOpacity(0.3),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Transform(
                          transform: Matrix4.rotationY(isFront ? 0 : pi),
                          alignment: Alignment.center,
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  isFront ? 'QUESTION' : 'ANSWER',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 2,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  isFront ? card.front : card.back,
                                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white, height: 1.5),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 32),
                                if (isFront)
                                  Text(
                                    'Tap to reveal answer',
                                    style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.white.withOpacity(0.6)),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          if (_showBack)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  Text('How well did you know this?', style: TextStyle(fontFamily: 'Poppins', color: Colors.grey.shade500, fontSize: 13)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, padding: const EdgeInsets.symmetric(vertical: 14)),
                        onPressed: () => _rate('hard'),
                        child: const Text('Hard', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                      )),
                      const SizedBox(width: 8),
                      Expanded(child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning, padding: const EdgeInsets.symmetric(vertical: 14)),
                        onPressed: () => _rate('medium'),
                        child: const Text('Okay', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                      )),
                      const SizedBox(width: 8),
                      Expanded(child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, padding: const EdgeInsets.symmetric(vertical: 14)),
                        onPressed: () => _rate('easy'),
                        child: const Text('Easy', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                      )),
                    ],
                  ),
                ],
              ).animate().slideY(begin: 1, end: 0, duration: 300.ms),
            ),
        ],
      ),
    );
  }
}

// ── Add Card Sheet ─────────────────────────────────────────────────────────────
class _AddCardSheet extends StatefulWidget {
  final String? subjectId;
  const _AddCardSheet({this.subjectId});

  @override
  State<_AddCardSheet> createState() => _AddCardSheetState();
}

class _AddCardSheetState extends State<_AddCardSheet> {
  final _frontCtrl = TextEditingController();
  final _backCtrl = TextEditingController();
  String? _subjectId;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _subjectId = widget.subjectId;
  }

  @override
  void dispose() {
    _frontCtrl.dispose();
    _backCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_frontCtrl.text.trim().isEmpty || _backCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    final card = FlashCard(
      id: const Uuid().v4(),
      subjectId: _subjectId ?? '',
      front: _frontCtrl.text.trim(),
      back: _backCtrl.text.trim(),
      nextReview: DateTime.now(),
    );
    await FirestoreService.addFlashcard(card);
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
            Text('Add Flashcard', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 20),
            TextField(
              controller: _frontCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Question / Front', hintText: 'What is...?'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _backCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Answer / Back', hintText: 'The answer is...'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Add Card'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── AI Generate Sheet ──────────────────────────────────────────────────────────
class _AiGenerateSheet extends StatefulWidget {
  final String? subjectId;
  const _AiGenerateSheet({this.subjectId});

  @override
  State<_AiGenerateSheet> createState() => _AiGenerateSheetState();
}

class _AiGenerateSheetState extends State<_AiGenerateSheet> {
  final _noteCtrl = TextEditingController();
  int _count = 10;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    if (_noteCtrl.text.trim().isEmpty) return;
    setState(() { _loading = true; _error = null; });
    try {
      final cards = await GeminiService.generateFlashcards(_noteCtrl.text.trim(), count: _count);
      final flashcards = cards.map((c) => FlashCard(
        id: const Uuid().v4(),
        subjectId: widget.subjectId ?? '',
        front: c['front'] ?? '',
        back: c['back'] ?? '',
        nextReview: DateTime.now(),
      )).toList();
      await FirestoreService.addFlashcards(flashcards);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Generated ${flashcards.length} flashcards!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); _loading = false; });
    }
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
            Row(
              children: [
                const Text('🤖', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Text('AI Flashcard Generator', style: Theme.of(context).textTheme.headlineSmall),
              ],
            ),
            const SizedBox(height: 6),
            Text('Paste your notes and AI will create flashcards', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.grey.shade500)),
            const SizedBox(height: 20),
            TextField(
              controller: _noteCtrl,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Paste your notes here',
                hintText: 'Paste any study material, textbook content, or topic description...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            Text('Number of cards', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Row(
              children: [5, 10, 15, 20].map((n) => Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _count = n),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _count == n ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _count == n ? AppColors.primary : Colors.grey.withOpacity(0.3)),
                    ),
                    child: Text('$n', textAlign: TextAlign.center,
                        style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: _count == n ? Colors.white : Colors.grey.shade600)),
                  ),
                ),
              )).toList(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Text(_error!, style: const TextStyle(color: AppColors.error, fontFamily: 'Poppins', fontSize: 13)),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _generate,
                icon: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.auto_awesome_rounded),
                label: Text(_loading ? 'Generating...' : 'Generate $_count Cards'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterPill({required this.label, required this.selected, this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? c : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: selected ? Colors.white : Colors.grey.shade600)),
      ),
    );
  }
}

extension on Brightness {
  static Brightness get dark => Brightness.dark;
}

