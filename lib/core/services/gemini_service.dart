import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/models/models.dart';

class GeminiService {
  // ⚠️ Replace with your key from https://aistudio.google.com
  static String apiKey = 'Your_Gemini_API_Key';
  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent';

  static Future<String> _generate(String prompt, {String? systemPrompt}) async {
    final body = {
      'contents': [
        if (systemPrompt != null)
          {
            'role': 'user',
            'parts': [
              {'text': systemPrompt}
            ]
          },
        {
          'role': 'user',
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.7,
        'topK': 40,
        'topP': 0.95,
        'maxOutputTokens': 2048,
      },
    };

    try {
      final uri = Uri.parse('$_baseUrl?key=$apiKey');
      print('DEBUG: Gemini _generate -> POST ${uri.toString()} (prompt length: ${prompt.length})');
      final response = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body))
          .timeout(const Duration(seconds: 20));

      print('DEBUG: Gemini response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        try {
          return data['candidates'][0]['content']['parts'][0]['text'] as String;
        } catch (e) {
          print('ERROR: Unexpected Gemini response format: ${response.body}');
          throw Exception('Unexpected Gemini response format');
        }
      } else if (response.statusCode == 429) {
        print('ERROR: Gemini rate limit: ${response.body}');
        throw Exception('Rate limit reached. Please wait a moment and try again.');
      } else {
        print('ERROR: Gemini API error ${response.statusCode}: ${response.body}');
        throw Exception('Gemini API error: ${response.statusCode} - ${response.body}');
      }
    } on TimeoutException catch (_) {
      throw Exception('Request to Gemini timed out. Please try again.');
    } on Exception catch (e) {
      print('ERROR: Gemini _generate exception: $e');
      rethrow;
    }
  }

  // ── AI Chat ────────────────────────────────────────────────────────────────
  static Future<String> chat(
    List<ChatMessage> history,
    String newMessage, {
    String? subjectContext,
  }) async {
    final systemPrompt = '''You are StudyBot, an intelligent study assistant for students. 
You help with academic questions, explain concepts clearly, and provide study guidance.
${subjectContext != null ? 'Current subject context: $subjectContext' : ''}
Keep responses helpful, accurate, and encouraging. Format with markdown when helpful.''';

    // Build conversation history
    final contents = <Map<String, dynamic>>[];

    // Add system context as first user message
    contents.add({
      'role': 'user',
      'parts': [
        {'text': systemPrompt}
      ]
    });

    // Add history (last 10 messages to stay within token limit)
    final recentHistory = history.length > 10 ? history.sublist(history.length - 10) : history;
    for (final msg in recentHistory) {
      contents.add({
        'role': msg.isUser ? 'user' : 'model',
        'parts': [
          {'text': msg.content}
        ]
      });
    }

    // Add new message
    contents.add({
      'role': 'user',
      'parts': [
        {'text': newMessage}
      ]
    });

    final body = {
      'contents': contents,
      'generationConfig': {
        'temperature': 0.8,
        'maxOutputTokens': 1024,
      },
    };

    try {
      final uri = Uri.parse('$_baseUrl?key=$apiKey');
      print('DEBUG: Gemini chat -> POST ${uri.toString()} (history items: ${history.length})');
      final response = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body))
          .timeout(const Duration(seconds: 20));

      print('DEBUG: Gemini chat response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        try {
          return data['candidates'][0]['content']['parts'][0]['text'] as String;
        } catch (e) {
          print('ERROR: Unexpected Gemini chat response: ${response.body}');
          throw Exception('Unexpected Gemini response format');
        }
      } else if (response.statusCode == 429) {
        print('ERROR: Gemini chat rate limit: ${response.body}');
        throw Exception('Rate limit reached. Please wait 1 minute and try again.');
      } else {
        print('ERROR: Gemini chat API error ${response.statusCode}: ${response.body}');
        throw Exception('Failed to get response. Please try again.');
      }
    } on TimeoutException catch (_) {
      throw Exception('Request to Gemini timed out. Please try again.');
    } on Exception catch (e) {
      print('ERROR: Gemini chat exception: $e');
      rethrow;
    }
  }

  // ── Quiz Generator ─────────────────────────────────────────────────────────
  static Future<List<QuizQuestion>> generateQuiz(
    String topic, {
    int count = 10,
    String difficulty = 'medium',
  }) async {
    final prompt = '''Generate $count multiple choice questions about: "$topic"
Difficulty: $difficulty

Return ONLY valid JSON in this exact format, no markdown, no extra text:
{
  "questions": [
    {
      "question": "Question text here?",
      "options": ["Option A", "Option B", "Option C", "Option D"],
      "correct": 0,
      "explanation": "Brief explanation of the correct answer"
    }
  ]
}

The "correct" field is the index (0-3) of the correct option.
Make questions educational, clear, and accurate.''';

    final raw = await _generate(prompt);

    // Clean response - remove markdown code blocks if present
    String cleaned = raw.trim();
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.replaceAll(RegExp(r'```json?\n?'), '').replaceAll('```', '').trim();
    }

    final json = jsonDecode(cleaned) as Map<String, dynamic>;
    final questions = json['questions'] as List<dynamic>;
    return questions.map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>)).toList();
  }

  // ── AI Summarizer ──────────────────────────────────────────────────────────
  static Future<String> summarize(String text, {bool simple = false}) async {
    final prompt = simple
        ? '''Explain this text in very simple terms that a student can understand easily.
Use bullet points and simple language. Text: "$text"'''
        : '''Summarize this text into key bullet points for a student.
Focus on the most important concepts. Keep it concise and clear.
Text: "$text"''';

    return await _generate(prompt);
  }

  // ── Flashcard Generator ────────────────────────────────────────────────────
  static Future<List<Map<String, String>>> generateFlashcards(
    String noteText, {
    String subjectId = '',
    int count = 10,
  }) async {
    final prompt = '''Create $count flashcards from this study material:
"$noteText"

Return ONLY valid JSON, no markdown:
{
  "flashcards": [
    {"front": "Question or term", "back": "Answer or definition"}
  ]
}''';

    final raw = await _generate(prompt);
    String cleaned = raw.trim();
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.replaceAll(RegExp(r'```json?\n?'), '').replaceAll('```', '').trim();
    }

    final json = jsonDecode(cleaned) as Map<String, dynamic>;
    final cards = json['flashcards'] as List<dynamic>;
    return cards.map((c) {
      final card = c as Map<String, dynamic>;
      return {'front': card['front'] as String, 'back': card['back'] as String};
    }).toList();
  }

  // ── Smart Study Planner ───────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> generateStudyPlan({
    required List<String> exams,
    required List<String> weakSubjects,
    required int availableHoursPerDay,
    required int daysUntilExam,
  }) async {
    final prompt = '''Create a personalized study schedule for a student.

Exams: ${exams.join(', ')}
Weak subjects: ${weakSubjects.join(', ')}
Available hours per day: $availableHoursPerDay
Days until exam: $daysUntilExam

Return ONLY valid JSON:
{
  "plan": [
    {
      "day": 1,
      "sessions": [
        {"subject": "Math", "topic": "Algebra", "hours": 2, "priority": "high"}
      ]
    }
  ],
  "tips": ["Tip 1", "Tip 2"]
}''';

    final raw = await _generate(prompt);
    String cleaned = raw.trim();
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.replaceAll(RegExp(r'```json?\n?'), '').replaceAll('```', '').trim();
    }

    final json = jsonDecode(cleaned) as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(json['plan'] as List);
  }

  // ── Study Tips ─────────────────────────────────────────────────────────────
  static Future<List<String>> generateStudyTips({
    required Map<String, double> subjectHours,
    required List<String> weakTopics,
    required int streak,
    required int xp,
  }) async {
    final prompt = '''Give 5 personalized study tips for this student:
- Study hours by subject: ${subjectHours.entries.map((e) => '${e.key}: ${e.value.toStringAsFixed(1)}h').join(', ')}
- Weak topics: ${weakTopics.join(', ')}
- Current streak: $streak days
- Total XP: $xp

Return ONLY valid JSON:
{
  "tips": [
    "Specific actionable tip 1",
    "Specific actionable tip 2",
    "Specific actionable tip 3",
    "Specific actionable tip 4",
    "Specific actionable tip 5"
  ]
}''';

    final raw = await _generate(prompt);
    String cleaned = raw.trim();
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.replaceAll(RegExp(r'```json?\n?'), '').replaceAll('```', '').trim();
    }

    final json = jsonDecode(cleaned) as Map<String, dynamic>;
    return List<String>.from(json['tips'] as List);
  }
}

