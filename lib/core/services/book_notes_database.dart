import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class BookNoteItem {
  final String? id;
  final String title;
  final String content;
  final String bookTitle;
  final String dateAdded;
  final String? pdfPath;

  BookNoteItem({this.id, required this.title, required this.content, required this.bookTitle, required this.dateAdded, this.pdfPath});

  Map<String, dynamic> toMap() => {
    'id': id, 'title': title, 'content': content, 'bookTitle': bookTitle, 'dateAdded': dateAdded, 'pdfPath': pdfPath,
  };

  factory BookNoteItem.fromMap(Map<String, dynamic> map) => BookNoteItem(
    id: map['id']?.toString(),
    title: map['title'] ?? '',
    content: map['content'] ?? '',
    bookTitle: map['bookTitle'] ?? '',
    dateAdded: map['dateAdded'] ?? '',
    pdfPath: map['pdfPath'],
  );
}

class BookNotesDatabase {
  static Database? _db;
  static Future<Database> get db async => _db ??= await _init();

  static Future<Database> _init() async {
    final path = join(await getDatabasesPath(), 'book_notes_v2.db');
    return await openDatabase(path, version: 1, onCreate: (db, v) async {
      await db.execute('CREATE TABLE notes(id INTEGER PRIMARY KEY, title TEXT, content TEXT, bookTitle TEXT, dateAdded TEXT, pdfPath TEXT)');
    });
  }

  static Future<int> insert(BookNoteItem n) async => (await db).insert('notes', n.toMap());
  static Future<List<BookNoteItem>> getAll() async {
    final maps = await (await db).query('notes', orderBy: 'id DESC');
    return maps.map((m) => BookNoteItem.fromMap(m)).toList();
  }
  static Future<int> delete(String id) async => (await db).delete('notes', where: 'id = ?', whereArgs: [id]);
}