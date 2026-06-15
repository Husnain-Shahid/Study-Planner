import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

class PdfViewScreen extends StatelessWidget {
  final String path;
  final String title;
  const PdfViewScreen({super.key, required this.path, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: PdfViewer.file(path, params: const PdfViewerParams(maxScale: 5.0)),
    );
  }
}
