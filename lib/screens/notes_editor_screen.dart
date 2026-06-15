import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/gemini_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/models.dart';
import 'notes_screen.dart';

class NoteEditorScreen extends StatefulWidget {
  final String? noteId;
  const NoteEditorScreen({super.key, this.noteId});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  NoteModel? _note;
  String? _subjectId;
  String _subjectName = '';
  bool _saving = false;
  bool _summarizing = false;
  DateTime? _lastSaved;

  @override
  void initState() {
    super.initState();
    if (widget.noteId != null) _loadNote();
    // Auto-save every 5 seconds
    _bodyCtrl.addListener(_scheduleSave);
    _titleCtrl.addListener(_scheduleSave);
  }

  DateTime? _nextSave;
  void _scheduleSave() {
    _nextSave = DateTime.now().add(const Duration(seconds: 5));
    Future.delayed(const Duration(seconds: 5), () {
      if (_nextSave != null && DateTime.now().isAfter(_nextSave!)) {
        _save(auto: true);
      }
    });
  }

  Future<void> _loadNote() async {
    // Load existing note from stream
    final noteId = widget.noteId;
    if (noteId == null) return;
    final notes = await FirestoreService.watchNotes().first;
    final matchingNotes = notes.where((n) => n.id == noteId).toList();
    final note = matchingNotes.isNotEmpty ? matchingNotes.first : null;
    if (note != null && mounted) {
      setState(() {
        _note = note;
        _titleCtrl.text = note.title;
        _bodyCtrl.text = note.body;
        _subjectId = note.subjectId;
        _subjectName = note.subjectName;
      });
    }
  }

  Future<void> _save({bool auto = false}) async {
    if (_titleCtrl.text.isEmpty && _bodyCtrl.text.isEmpty) return;
    if (auto && _saving) return;

    setState(() => _saving = true);

    final data = {
      'title': _titleCtrl.text,
      'body': _bodyCtrl.text,
      'subjectId': _subjectId ?? '',
      'subjectName': _subjectName,
      'imageUrls': _note?.imageUrls ?? [],
    };

    if (_note != null) {
      await FirestoreService.updateNote(_note!.id, data);
    } else {
      final note = NoteModel(
        id: const Uuid().v4(),
        title: _titleCtrl.text,
        body: _bodyCtrl.text,
        subjectId: _subjectId ?? '',
        subjectName: _subjectName,
        updatedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );
      final id = await FirestoreService.addNote(note);
      setState(() => _note = note.copyWith(id: id));
    }

    setState(() { _saving = false; _lastSaved = DateTime.now(); });
  }

  Future<void> _summarize() async {
    if (_bodyCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Write some notes first!')));
      return;
    }
    setState(() => _summarizing = true);
    try {
      final summary = await GeminiService.summarize(_bodyCtrl.text);
      if (mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _SummarySheet(summary: summary),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
    setState(() => _summarizing = false);
  }

  @override
  void dispose() {
    _save(); // Save on close
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.noteId == null ? 'New Note' : 'Edit Note'),
        actions: [
          if (_summarizing)
            const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)))
          else
            IconButton(
              icon: const Icon(Icons.auto_awesome_rounded),
              tooltip: 'AI Summarize',
              onPressed: _summarize,
            ),
          IconButton(
            icon: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                : const Icon(Icons.save_rounded),
            onPressed: () => _save(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Subject picker
          StreamBuilder<List<SubjectModel>>(
            stream: FirestoreService.watchSubjects(),
            builder: (context, snap) {
              final subjects = snap.data ?? [];
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    _SubjectPill(label: 'General', selected: _subjectId == null, onTap: () => setState(() { _subjectId = null; _subjectName = ''; })),
                    ...subjects.map((s) => _SubjectPill(
                      label: '${s.icon} ${s.name}',
                      selected: _subjectId == s.id,
                      color: s.color,
                      onTap: () => setState(() { _subjectId = s.id; _subjectName = s.name; }),
                    )),
                  ],
                ),
              );
            },
          ),

          if (_lastSaved != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, size: 12, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Text('Auto-saved', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.grey.shade400)),
                ],
              ),
            ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _titleCtrl,
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      hintText: 'Note title...',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      hintStyle: TextStyle(fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.w700, color: Colors.grey.shade300),
                    ),
                  ),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _bodyCtrl,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 15, height: 1.7, color: isDark ? Colors.white.withValues(alpha: 0.87) : Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'Start writing your notes here...\n\nTip: Tap ✨ to get an AI summary of your notes!',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      hintStyle: TextStyle(fontFamily: 'Poppins', fontSize: 15, color: Colors.grey.shade300, height: 1.7),
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
}

extension on NoteModel {
  NoteModel copyWith({String? id}) => NoteModel(
    id: id ?? this.id, title: title, body: body, subjectId: subjectId,
    subjectName: subjectName, imageUrls: imageUrls, updatedAt: updatedAt, createdAt: createdAt,
  );
}

class _SubjectPill extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  const _SubjectPill({required this.label, required this.selected, this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? c.withOpacity(0.15) : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? c : Colors.transparent),
        ),
        child: Text(label, style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w500, color: selected ? c : Colors.grey.shade600)),
      ),
    );
  }
}

class _SummarySheet extends StatelessWidget {
  final String summary;
  const _SummarySheet({required this.summary});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Row(children: [
            const Text('✨', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Text('AI Summary', style: Theme.of(context).textTheme.headlineSmall),
          ]),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.15)),
            ),
            child: SingleChildScrollView(
              child: Text(summary, style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, height: 1.6)),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(fontFamily: 'Poppins')),
            ),
          ),
        ],
      ),
    );
  }
}

