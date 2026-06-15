import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/models/models.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;
  static String get uid => FirebaseAuth.instance.currentUser!.uid;

  // ── Refs ──────────────────────────────────────────────────────────────────
  static DocumentReference get userRef => _db.collection('users').doc(uid);
  static CollectionReference get subjectsRef => userRef.collection('subjects');
  static CollectionReference get sessionsRef => userRef.collection('sessions');
  static CollectionReference get tasksRef => userRef.collection('tasks');
  static CollectionReference get notesRef => userRef.collection('notes');
  static CollectionReference get flashcardsRef => userRef.collection('flashcards');
  static CollectionReference get examsRef => userRef.collection('exams');
  static CollectionReference get quizResultsRef => userRef.collection('quizResults');
  static CollectionReference get aiChatsRef => userRef.collection('aiChats');
  static CollectionReference get badgesRef => userRef.collection('badges');
  static CollectionReference get usersCollection => _db.collection('users');

  // ── User ──────────────────────────────────────────────────────────────────
  static Future<void> createUser(UserModel user) async {
    await userRef.set(user.toMap());
  }

  static Future<UserModel?> getUser() async {
    final doc = await userRef.get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  static Stream<UserModel?> watchUser() {
    return userRef.snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  static Future<void> updateUser(Map<String, dynamic> data) async {
    await userRef.update(data);
  }

  // ── XP & Streak ───────────────────────────────────────────────────────────
  static Future<void> addXp(int amount) async {
    await userRef.update({
      'xp': FieldValue.increment(amount),
      'weeklyXp': FieldValue.increment(amount),
    });
    final user = await getUser();
    if (user != null) {
      final newLevel = (user.xp ~/ 100) + 1;
      if (newLevel != user.level) {
        await userRef.update({'level': newLevel});
      }
    }
  }

  static Future<void> updateStreak() async {
    final user = await getUser();
    if (user == null) return;
    final today = DateTime.now();
    final lastSession = await sessionsRef
        .orderBy('date', descending: true)
        .limit(2)
        .get();
    if (lastSession.docs.length >= 2) {
      final prevDate = (lastSession.docs[1].data() as Map)['date'] as Timestamp;
      final diff = today.difference(prevDate.toDate()).inDays;
      if (diff == 1) {
        await userRef.update({'streak': FieldValue.increment(1)});
      } else if (diff > 1) {
        await userRef.update({'streak': 1});
      }
    } else {
      await userRef.update({'streak': 1});
    }
  }

  // ── Subjects ──────────────────────────────────────────────────────────────
  static Stream<List<SubjectModel>> watchSubjects() {
    return subjectsRef
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((s) => s.docs.map((d) => SubjectModel.fromFirestore(d)).toList());
  }

  static Future<String> addSubject(SubjectModel subject) async {
    final ref = await subjectsRef.add(subject.toMap());
    return ref.id;
  }

  static Future<void> updateSubject(String id, Map<String, dynamic> data) async {
    await subjectsRef.doc(id).update(data);
  }

  static Future<void> deleteSubject(String id) async {
    await subjectsRef.doc(id).delete();
  }

  // ── Sessions ──────────────────────────────────────────────────────────────
  static Stream<List<StudySession>> watchSessions({DateTime? date}) {
    Query query = sessionsRef.orderBy('date', descending: true);
    if (date != null) {
      final start = DateTime(date.year, date.month, date.day);
      final end = start.add(const Duration(days: 1));
      query = query
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThan: Timestamp.fromDate(end));
    }
    return query.snapshots().map((s) => s.docs.map((d) => StudySession.fromFirestore(d)).toList());
  }

  static Future<List<StudySession>> getSessionsForRange(DateTime start, DateTime end) async {
    final snap = await sessionsRef
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .get();
    return snap.docs.map((d) => StudySession.fromFirestore(d)).toList();
  }

  static Future<String> addSession(StudySession session) async {
    final ref = await sessionsRef.add(session.toMap());
    await addXp(session.xpEarned);
    await updateStreak();
    return ref.id;
  }

  static Future<void> deleteSession(String id) async {
    await sessionsRef.doc(id).delete();
  }

  // ── Tasks ─────────────────────────────────────────────────────────────────
  static Stream<List<TaskModel>> watchTasks() {
    return tasksRef
        .orderBy('dueDate', descending: false)
        .snapshots()
        .map((s) => s.docs.map((d) => TaskModel.fromFirestore(d)).toList());
  }

  static Future<String> addTask(TaskModel task) async {
    final ref = await tasksRef.add(task.toMap());
    return ref.id;
  }

  static Future<void> completeTask(String id) async {
    await tasksRef.doc(id).update({
      'completed': true,
      'completedAt': Timestamp.fromDate(DateTime.now()),
    });
    await addXp(5);
    await checkBadges();
  }

  static Future<void> deleteTask(String id) async {
    await tasksRef.doc(id).delete();
  }

  // ── Notes ─────────────────────────────────────────────────────────────────
  static Stream<List<NoteModel>> watchNotes({String? subjectId}) {
    Query query = notesRef.orderBy('updatedAt', descending: true);
    if (subjectId != null) query = query.where('subjectId', isEqualTo: subjectId);
    return query.snapshots().map((s) => s.docs.map((d) => NoteModel.fromFirestore(d)).toList());
  }

  static Future<String> addNote(NoteModel note) async {
    final ref = await notesRef.add(note.toMap());
    return ref.id;
  }

  static Future<void> updateNote(String id, Map<String, dynamic> data) async {
    await notesRef.doc(id).update({...data, 'updatedAt': Timestamp.fromDate(DateTime.now())});
  }

  static Future<void> deleteNote(String id) async {
    await notesRef.doc(id).delete();
  }

  // ── Flashcards ────────────────────────────────────────────────────────────
  static Stream<List<FlashCard>> watchFlashcards({String? subjectId}) {
    Query query = flashcardsRef;
    if (subjectId != null) query = query.where('subjectId', isEqualTo: subjectId);
    return query.snapshots().map((s) => s.docs.map((d) => FlashCard.fromFirestore(d)).toList());
  }

  static Future<void> addFlashcard(FlashCard card) async {
    await flashcardsRef.add(card.toMap());
  }

  static Future<void> addFlashcards(List<FlashCard> cards) async {
    final batch = _db.batch();
    for (final card in cards) {
      batch.set(flashcardsRef.doc(), card.toMap());
    }
    await batch.commit();
  }

  static Future<void> updateFlashcard(String id, Map<String, dynamic> data) async {
    await flashcardsRef.doc(id).update(data);
  }

  static Future<void> deleteFlashcard(String id) async {
    await flashcardsRef.doc(id).delete();
  }

  // ── Exams ─────────────────────────────────────────────────────────────────
  static Stream<List<ExamModel>> watchExams() {
    return examsRef
        .orderBy('examDate', descending: false)
        .snapshots()
        .map((s) => s.docs.map((d) => ExamModel.fromFirestore(d)).toList());
  }

  static Future<String> addExam(ExamModel exam) async {
    final ref = await examsRef.add(exam.toMap());
    return ref.id;
  }

  static Future<void> deleteExam(String id) async {
    await examsRef.doc(id).delete();
  }

  // ── Quiz Results ──────────────────────────────────────────────────────────
  static Future<void> saveQuizResult({
    required String topic,
    required int score,
    required int total,
    required List<String> weakTopics,
  }) async {
    await quizResultsRef.add({
      'topic': topic,
      'score': score,
      'total': total,
      'weakTopics': weakTopics,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
    await addXp(20);
    await checkBadges();
  }

  static Future<List<Map<String, dynamic>>> getQuizResults() async {
    final snap = await quizResultsRef.orderBy('createdAt', descending: true).limit(20).get();
    return snap.docs.map((d) => d.data() as Map<String, dynamic>).toList();
  }

  // ── AI Chat ───────────────────────────────────────────────────────────────
  static Future<void> saveChatMessages(String chatId, List<ChatMessage> messages) async {
    await aiChatsRef.doc(chatId).set({
      'messages': messages.map((m) => m.toMap()).toList(),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    }, SetOptions(merge: true));
  }

  static Future<List<ChatMessage>> getChatHistory(String chatId) async {
    final doc = await aiChatsRef.doc(chatId).get();
    if (!doc.exists) return [];
    final data = doc.data() as Map<String, dynamic>;
    final msgs = data['messages'] as List<dynamic>? ?? [];
    return msgs.map((m) => ChatMessage.fromMap(m as Map<String, dynamic>)).toList();
  }

  // ── Badges ────────────────────────────────────────────────────────────────
  static Future<List<String>> getUnlockedBadgeIds() async {
    final snap = await badgesRef.get();
    return snap.docs.map((d) => d.id).toList();
  }

  static Future<bool> unlockBadge(String badgeId) async {
    final existing = await badgesRef.doc(badgeId).get();
    if (existing.exists) return false;
    await badgesRef.doc(badgeId).set({'unlockedAt': Timestamp.fromDate(DateTime.now())});
    return true;
  }

  static Future<void> checkBadges() async {
    final user = await getUser();
    if (user == null) return;

    if (user.xp >= 100) await unlockBadge('xp_100');
    if (user.xp >= 500) await unlockBadge('xp_500');
    if (user.streak >= 7) await unlockBadge('streak_7');
    if (user.streak >= 30) await unlockBadge('streak_30');

    final sessions = await sessionsRef.limit(1).get();
    if (sessions.docs.isNotEmpty) await unlockBadge('first_session');

    final quizzes = await quizResultsRef.limit(1).get();
    if (quizzes.docs.isNotEmpty) await unlockBadge('first_quiz');

    final notes = await notesRef.count().get();
    if ((notes.count ?? 0) >= 10) await unlockBadge('note_taker');

    final cards = await flashcardsRef.count().get();
    if ((cards.count ?? 0) >= 50) await unlockBadge('flashcard_pro');

    final hour = DateTime.now().hour;
    if (hour >= 0 && hour < 4) await unlockBadge('night_owl');
    if (hour >= 5 && hour < 7) await unlockBadge('early_bird');
  }

  // ── Leaderboard ───────────────────────────────────────────────────────────
  static Stream<List<UserModel>> watchLeaderboard() {
    return usersCollection
        .orderBy('weeklyXp', descending: true)
        .limit(20)
        .snapshots()
        .map((s) => s.docs.map((d) => UserModel.fromFirestore(d)).toList());
  }

  // ── Analytics ─────────────────────────────────────────────────────────────
  static Future<Map<String, double>> getHoursPerSubjectLast7Days() async {
    final start = DateTime.now().subtract(const Duration(days: 7));
    final sessions = await getSessionsForRange(start, DateTime.now());
    final Map<String, double> result = {};
    for (final s in sessions) {
      result[s.subjectName] = (result[s.subjectName] ?? 0) + s.durationMins / 60;
    }
    return result;
  }

  static Future<Map<int, double>> getDailyHoursLast7Days() async {
    final Map<int, double> result = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0};
    final start = DateTime.now().subtract(const Duration(days: 6));
    final sessions = await getSessionsForRange(start, DateTime.now());
    for (final s in sessions) {
      final diff = DateTime.now().difference(s.date).inDays;
      if (diff >= 0 && diff < 7) {
        result[6 - diff] = (result[6 - diff] ?? 0) + s.durationMins / 60;
      }
    }
    return result;
  }
}
