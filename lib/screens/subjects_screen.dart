import 'package:flutter/material.dart';
import '../core/services/firestore_service.dart';
import '../core/models/models.dart';
import '../core/theme/app_theme.dart';

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({super.key});

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<SubjectModel> _localSubjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubjectsFromFirebase();
  }

  Future<void> _loadSubjectsFromFirebase() async {
    try {
      // Initial load from Firebase
      FirestoreService.watchSubjects().listen((subjects) {
        if (mounted) {
          setState(() {
            _localSubjects = subjects;
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      print('Error loading subjects: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddSubjectSheet() {
    final titleController = TextEditingController();
    final iconController = TextEditingController(text: '📚');
    double targetHours = 10;
    Color selectedColor = AppColors.subjectColors[0];
    bool isSaving = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? AppColors.darkSurface 
                      : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Add New Subject',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: titleController,
                        enabled: !isSaving,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Subject Name',
                          hintText: 'e.g. Mathematics, Physics',
                          prefixIcon: Icon(Icons.book_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: iconController,
                        enabled: !isSaving,
                        decoration: const InputDecoration(
                          labelText: 'Icon (Emoji)',
                          hintText: 'Enter an emoji',
                          prefixIcon: Icon(Icons.emoji_emotions_outlined),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Weekly Target Hours: ${targetHours.round()}h',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
                      ),
                      Slider(
                        value: targetHours,
                        min: 1,
                        max: 40,
                        activeColor: AppColors.primary,
                        onChanged: isSaving ? null : (value) => setSheetState(() => targetHours = value),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Theme Color',
                        style: TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 45,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: AppColors.subjectColors.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final color = AppColors.subjectColors[index];
                            final isSelected = selectedColor == color;
                            return GestureDetector(
                              onTap: isSaving ? null : () => setSheetState(() => selectedColor = color),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? Colors.black87 : Colors.transparent,
                                    width: 2.5,
                                  ),
                                  boxShadow: [
                                    if (isSelected) BoxShadow(color: color.withOpacity(0.4), blurRadius: 8)
                                  ],
                                ),
                                child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                           onPressed: isSaving ? null : () async {
                             final name = titleController.text.trim();
                             if (name.isEmpty) {
                               ScaffoldMessenger.of(context).showSnackBar(
                                 const SnackBar(content: Text('Subject name cannot be empty'), backgroundColor: Colors.orange),
                               );
                               return;
                             }

                             setSheetState(() => isSaving = true);

                             try {
                               final newSubject = SubjectModel(
                                 id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
                                 name: name,
                                 colorValue: selectedColor.value,
                                 icon: iconController.text.trim(),
                                 targetHours: targetHours,
                                 createdAt: DateTime.now(),
                               );

                               // 🚀 Add to local list immediately for instant feedback
                               if (mounted) {
                                 setState(() {
                                   _localSubjects.add(newSubject);
                                 });
                               }

                               // 📤 Upload to Firebase in background
                               final subjectId = await FirestoreService.addSubject(newSubject);
                               print('DEBUG: Subject uploaded with ID: $subjectId');

                               if (mounted) {
                                 // Update the temporary ID to actual Firebase ID
                                 setState(() {
                                   final index = _localSubjects.indexWhere((s) => s.id == newSubject.id);
                                   if (index >= 0) {
                                     _localSubjects[index] = SubjectModel(
                                       id: subjectId,
                                       name: newSubject.name,
                                       colorValue: newSubject.colorValue,
                                       icon: newSubject.icon,
                                       targetHours: newSubject.targetHours,
                                       createdAt: newSubject.createdAt,
                                     );
                                   }
                                 });

                                 ScaffoldMessenger.of(context).showSnackBar(
                                   SnackBar(content: Text('Subject "$name" added successfully!'), backgroundColor: Colors.green),
                                 );
                                 Navigator.pop(sheetContext);
                               }
                             } catch (e) {
                               if (mounted) {
                                 setSheetState(() => isSaving = false);
                                 final errorMsg = e.toString().replaceAll('Exception: ', '');
                                 print('DEBUG: Subject add error: $errorMsg');

                                 // Remove from local list on error
                                 setState(() {
                                   _localSubjects.removeWhere((s) => s.name == name);
                                 });

                                 ScaffoldMessenger.of(context).showSnackBar(
                                   SnackBar(
                                     content: Text('Error adding subject: $errorMsg'),
                                     backgroundColor: Colors.red,
                                     duration: const Duration(seconds: 4),
                                   ),
                                 );
                               }
                             }
                           },
                           child: isSaving
                               ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                               : const Text('Create Subject'),
                         ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Subjects'),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/analytics'),
            icon: const Icon(Icons.bar_chart_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddSubjectSheet,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Subject', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
       body: Column(
         children: [
           Padding(
             padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
             child: TextField(
               controller: _searchController,
               onChanged: (_) => setState(() {}),
               decoration: InputDecoration(
                 hintText: 'Search subjects...',
                 prefixIcon: const Icon(Icons.search_rounded),
                 suffixIcon: _searchController.text.isNotEmpty
                     ? IconButton(icon: const Icon(Icons.close), onPressed: () { _searchController.clear(); setState(() {}); })
                     : null,
               ),
             ),
           ),
           Expanded(
             child: _isLoading
                 ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                 : _buildSubjectsList(),
           ),
         ],
       ),
     );
   }

    Widget _buildSubjectsList() {
      final query = _searchController.text.toLowerCase();
      final subjects = _localSubjects.where((s) => s.name.toLowerCase().contains(query)).toList();

      if (subjects.isEmpty) {
        return _buildEmptyState(_localSubjects.isEmpty);
      }

      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
        itemCount: subjects.length,
        itemBuilder: (context, index) => SubjectTile(
          subject: subjects[index],
          onDelete: () {
            setState(() {
              _localSubjects.removeWhere((s) => s.id == subjects[index].id);
            });
            FirestoreService.deleteSubject(subjects[index].id);
          },
        ),
      );
    }

    Widget _buildEmptyState(bool isTotalEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(isTotalEmpty ? '📚' : '🔍', style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              isTotalEmpty ? 'No subjects added yet' : 'No matches found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              isTotalEmpty ? 'Tap the button below to add your first course' : 'Try searching for something else',
              style: TextStyle(color: Colors.grey.shade500, fontFamily: 'Poppins'),
            ),
          ],
        ),
      );
    }
}

class SubjectTile extends StatelessWidget {
  final SubjectModel subject;
  final VoidCallback? onDelete;
  const SubjectTile({super.key, required this.subject, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = Color(subject.colorValue);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // Future: Subject details
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(child: Text(subject.icon, style: const TextStyle(fontSize: 24))),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subject.name,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                            ),
                            Text(
                              'Goal: ${subject.targetHours.round()}h / week',
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontFamily: 'Poppins'),
                            ),
                          ],
                        ),
                      ),
                       IconButton(
                         icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                         onPressed: () => _confirmDelete(context, subject, onDelete),
                       ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, SubjectModel subject, VoidCallback? onDelete) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Subject?'),
        content: Text('Are you sure you want to delete ${subject.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              onDelete?.call();
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
