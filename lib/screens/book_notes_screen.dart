import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import '../core/services/book_notes_database.dart';
import 'pdf_view_screen.dart';

class BookNotesScreen extends StatefulWidget {
  const BookNotesScreen({super.key});
  @override
  State<BookNotesScreen> createState() => _BookNotesScreenState();
}

class _BookNotesScreenState extends State<BookNotesScreen> {
  List<BookNoteItem> _notes = [];

  @override
  void initState() { super.initState(); _refresh(); }

  void _refresh() async {
    final data = await BookNotesDatabase.getAll();
    setState(() => _notes = data);
  }

  void _addNote() {
    final t1 = TextEditingController(), t2 = TextEditingController(), t3 = TextEditingController();
    String? path;
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, top: 20, left: 20, right: 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: t1, decoration: const InputDecoration(labelText: 'Book Title')),
            TextField(controller: t2, decoration: const InputDecoration(labelText: 'Topic')),
            TextField(controller: t3, decoration: const InputDecoration(labelText: 'Note')),
            const SizedBox(height: 10),
            ElevatedButton.icon(icon: const Icon(Icons.upload), label: Text(path == null ? "Attach PDF" : "PDF Attached"),
                onPressed: () async {
                  final res = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
                  if (res != null) {
                    final file = File(res.files.single.path!);
                    final newPath = p.join((await getApplicationDocumentsDirectory()).path, "${DateTime.now().millisecondsSinceEpoch}.pdf");
                    await file.copy(newPath);
                    setS(() => path = newPath);
                  }
                }),
            ElevatedButton(child: const Text("Save"), onPressed: () async {
              await BookNotesDatabase.insert(BookNoteItem(title: t2.text, bookTitle: t1.text, content: t3.text, dateAdded: DateFormat('yyyy-MM-dd').format(DateTime.now()), pdfPath: path));
              Navigator.pop(context); _refresh();
            }),
            const SizedBox(height: 20),
          ]),
        )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Study Notes")),
      floatingActionButton: FloatingActionButton(onPressed: _addNote, child: const Icon(Icons.add)),
      body: ListView.builder(itemCount: _notes.length, itemBuilder: (ctx, i) => Card(
        child: ListTile(
          title: Text(_notes[i].title),
          subtitle: Text(_notes[i].bookTitle),
          trailing: _notes[i].pdfPath != null ? IconButton(icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => PdfViewScreen(path: _notes[i].pdfPath!, title: _notes[i].title)))) : null,
          onLongPress: () async { await BookNotesDatabase.delete(_notes[i].id!); _refresh(); },
        ),
      )),
    );
  }
}
