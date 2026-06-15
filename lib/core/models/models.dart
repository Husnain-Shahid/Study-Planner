import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// ─── USER MODEL ───────────────────────────────────────────────────────────────
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role; // 'student' | 'teacher'
  final String? avatarUrl;
  final int xp;
  final int weeklyXp;
  final int streak;
  final int level;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.avatarUrl,
    this.xp = 0,
    this.weeklyXp = 0,
    this.streak = 0,
    this.level = 1,
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'student',
      avatarUrl: data['avatarUrl'],
      xp: data['xp'] ?? 0,
      weeklyXp: data['weeklyXp'] ?? 0,
      streak: data['streak'] ?? 0,
      level: data['level'] ?? 1,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'email': email,
    'role': role,
    'avatarUrl': avatarUrl,
    'xp': xp,
    'weeklyXp': weeklyXp,
    'streak': streak,
    'level': level,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  UserModel copyWith({String? name, String? avatarUrl, int? xp, int? weeklyXp, int? streak, int? level}) {
    return UserModel(
      uid: uid, email: email, role: role, createdAt: createdAt,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      xp: xp ?? this.xp,
      weeklyXp: weeklyXp ?? this.weeklyXp,
      streak: streak ?? this.streak,
      level: level ?? this.level,
    );
  }

  String get levelTitle {
    if (level < 5) return 'Beginner';
    if (level < 10) return 'Scholar';
    if (level < 20) return 'Expert';
    if (level < 30) return 'Master';
    return 'Legend';
  }
}

// ─── SUBJECT MODEL ────────────────────────────────────────────────────────────
class SubjectModel {
  final String id;
  final String name;
  final int colorValue;
  final String icon;
  final double targetHours;
  final DateTime createdAt;

  SubjectModel({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.icon,
    this.targetHours = 10,
    required this.createdAt,
  });

  Color get color => Color(colorValue);

  factory SubjectModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SubjectModel(
      id: doc.id,
      name: data['name'] ?? '',
      colorValue: data['colorValue'] ?? 0xFF6C63FF,
      icon: data['icon'] ?? '📚',
      targetHours: (data['targetHours'] ?? 10).toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'colorValue': colorValue,
    'icon': icon,
    'targetHours': targetHours,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}

// ─── STUDY SESSION MODEL ──────────────────────────────────────────────────────
class StudySession {
  final String id;
  final String subjectId;
  final String subjectName;
  final int subjectColor;
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final int durationMins;
  final String type; // 'pomodoro' | 'manual'
  final int xpEarned;

  StudySession({
    required this.id,
    required this.subjectId,
    required this.subjectName,
    required this.subjectColor,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.durationMins,
    this.type = 'manual',
    this.xpEarned = 0,
  });

  factory StudySession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StudySession(
      id: doc.id,
      subjectId: data['subjectId'] ?? '',
      subjectName: data['subjectName'] ?? '',
      subjectColor: data['subjectColor'] ?? 0xFF6C63FF,
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      startTime: (data['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endTime: (data['endTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      durationMins: data['durationMins'] ?? 0,
      type: data['type'] ?? 'manual',
      xpEarned: data['xpEarned'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'subjectId': subjectId,
    'subjectName': subjectName,
    'subjectColor': subjectColor,
    'date': Timestamp.fromDate(date),
    'startTime': Timestamp.fromDate(startTime),
    'endTime': Timestamp.fromDate(endTime),
    'durationMins': durationMins,
    'type': type,
    'xpEarned': xpEarned,
  };
}

// ─── TASK MODEL ───────────────────────────────────────────────────────────────
class TaskModel {
  final String id;
  final String title;
  final String subjectId;
  final String subjectName;
  final DateTime dueDate;
  final String priority; // 'high' | 'medium' | 'low'
  final bool completed;
  final DateTime? completedAt;
  final DateTime createdAt;

  TaskModel({
    required this.id,
    required this.title,
    required this.subjectId,
    required this.subjectName,
    required this.dueDate,
    this.priority = 'medium',
    this.completed = false,
    this.completedAt,
    required this.createdAt,
  });

  bool get isOverdue => !completed && dueDate.isBefore(DateTime.now());

  Color get priorityColor {
    switch (priority) {
      case 'high': return const Color(0xFFEF4444);
      case 'medium': return const Color(0xFFF59E0B);
      default: return const Color(0xFF22C55E);
    }
  }

  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TaskModel(
      id: doc.id,
      title: data['title'] ?? '',
      subjectId: data['subjectId'] ?? '',
      subjectName: data['subjectName'] ?? '',
      dueDate: (data['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      priority: data['priority'] ?? 'medium',
      completed: data['completed'] ?? false,
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'subjectId': subjectId,
    'subjectName': subjectName,
    'dueDate': Timestamp.fromDate(dueDate),
    'priority': priority,
    'completed': completed,
    'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  TaskModel copyWith({bool? completed, DateTime? completedAt}) {
    return TaskModel(
      id: id, title: title, subjectId: subjectId, subjectName: subjectName,
      dueDate: dueDate, priority: priority, createdAt: createdAt,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

// ─── NOTE MODEL ───────────────────────────────────────────────────────────────
class NoteModel {
  final String id;
  final String title;
  final String body;
  final String subjectId;
  final String subjectName;
  final List<String> imageUrls;
  final DateTime updatedAt;
  final DateTime createdAt;

  NoteModel({
    required this.id,
    required this.title,
    required this.body,
    required this.subjectId,
    required this.subjectName,
    this.imageUrls = const [],
    required this.updatedAt,
    required this.createdAt,
  });

  factory NoteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NoteModel(
      id: doc.id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      subjectId: data['subjectId'] ?? '',
      subjectName: data['subjectName'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'body': body,
    'subjectId': subjectId,
    'subjectName': subjectName,
    'imageUrls': imageUrls,
    'updatedAt': Timestamp.fromDate(updatedAt),
    'createdAt': Timestamp.fromDate(createdAt),
  };
}

// ─── FLASHCARD MODEL ──────────────────────────────────────────────────────────
class FlashCard {
  final String id;
  final String subjectId;
  final String front;
  final String back;
  final DateTime nextReview;
  final double easeFactor;
  final int interval; // days

  FlashCard({
    required this.id,
    required this.subjectId,
    required this.front,
    required this.back,
    required this.nextReview,
    this.easeFactor = 2.5,
    this.interval = 1,
  });

  bool get isDue => DateTime.now().isAfter(nextReview);

  factory FlashCard.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FlashCard(
      id: doc.id,
      subjectId: data['subjectId'] ?? '',
      front: data['front'] ?? '',
      back: data['back'] ?? '',
      nextReview: (data['nextReview'] as Timestamp?)?.toDate() ?? DateTime.now(),
      easeFactor: (data['easeFactor'] ?? 2.5).toDouble(),
      interval: data['interval'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() => {
    'subjectId': subjectId,
    'front': front,
    'back': back,
    'nextReview': Timestamp.fromDate(nextReview),
    'easeFactor': easeFactor,
    'interval': interval,
  };
}

// ─── EXAM MODEL ───────────────────────────────────────────────────────────────
class ExamModel {
  final String id;
  final String name;
  final String subjectId;
  final String subjectName;
  final int subjectColor;
  final DateTime examDate;
  final String importance; // 'high' | 'medium' | 'low'

  ExamModel({
    required this.id,
    required this.name,
    required this.subjectId,
    required this.subjectName,
    required this.subjectColor,
    required this.examDate,
    this.importance = 'high',
  });

  int get daysLeft => examDate.difference(DateTime.now()).inDays;
  bool get isPast => examDate.isBefore(DateTime.now());

  Color get urgencyColor {
    if (daysLeft > 30) return const Color(0xFF22C55E);
    if (daysLeft > 7) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  factory ExamModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExamModel(
      id: doc.id,
      name: data['name'] ?? '',
      subjectId: data['subjectId'] ?? '',
      subjectName: data['subjectName'] ?? '',
      subjectColor: data['subjectColor'] ?? 0xFF6C63FF,
      examDate: (data['examDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      importance: data['importance'] ?? 'high',
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'subjectId': subjectId,
    'subjectName': subjectName,
    'subjectColor': subjectColor,
    'examDate': Timestamp.fromDate(examDate),
    'importance': importance,
  };
}

// ─── QUIZ QUESTION MODEL ──────────────────────────────────────────────────────
class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctIndex: json['correct'] ?? 0,
      explanation: json['explanation'] ?? '',
    );
  }
}

// ─── CHAT MESSAGE MODEL ───────────────────────────────────────────────────────
class ChatMessage {
  final String id;
  final String role; // 'user' | 'assistant'
  final String content;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
  });

  bool get isUser => role == 'user';

  factory ChatMessage.fromMap(Map<String, dynamic> data) {
    return ChatMessage(
      id: data['id'] ?? '',
      role: data['role'] ?? 'user',
      content: data['content'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'role': role,
    'content': content,
    'timestamp': Timestamp.fromDate(timestamp),
  };
}

// ─── BADGE MODEL ──────────────────────────────────────────────────────────────
class BadgeModel {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final DateTime unlockedAt;

  BadgeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.unlockedAt,
  });

  static List<BadgeModel> getAllBadges() => [
    BadgeModel(id: 'first_session', title: 'First Step', description: 'Complete your first study session', emoji: '🎯', unlockedAt: DateTime.now()),
    BadgeModel(id: 'streak_7', title: '7-Day Streak', description: 'Study for 7 days in a row', emoji: '🔥', unlockedAt: DateTime.now()),
    BadgeModel(id: 'streak_30', title: 'Monthly Master', description: '30-day study streak', emoji: '👑', unlockedAt: DateTime.now()),
    BadgeModel(id: 'first_quiz', title: 'Quiz Taker', description: 'Complete your first AI quiz', emoji: '🧠', unlockedAt: DateTime.now()),
    BadgeModel(id: 'xp_100', title: 'Century Mark', description: 'Earn 100 XP', emoji: '💯', unlockedAt: DateTime.now()),
    BadgeModel(id: 'xp_500', title: 'XP Hunter', description: 'Earn 500 XP', emoji: '⚡', unlockedAt: DateTime.now()),
    BadgeModel(id: 'night_owl', title: 'Night Owl', description: 'Study after midnight', emoji: '🦉', unlockedAt: DateTime.now()),
    BadgeModel(id: 'early_bird', title: 'Early Bird', description: 'Study before 7 AM', emoji: '🌅', unlockedAt: DateTime.now()),
    BadgeModel(id: 'note_taker', title: 'Note Taker', description: 'Create 10 notes', emoji: '📝', unlockedAt: DateTime.now()),
    BadgeModel(id: 'flashcard_pro', title: 'Flashcard Pro', description: 'Create 50 flashcards', emoji: '🃏', unlockedAt: DateTime.now()),
  ];
}
