import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';


class PDFViewer extends StatefulWidget {
  final String url;
  final int sem;
  final String subjectCode;
  final String typeKey;
  final int uniqueID;
  final String title;

  PDFViewer({
    required this.url,
    required this.sem,
    required this.subjectCode,
    required this.typeKey,
    this.uniqueID,
    this.title,
  });

  @override
  _PDFViewerState createState() => _PDFViewerState();
}

class _PDFViewerState extends State<PDFViewer> {
  bool isLoading = true;
  late PdfDocument document;

  @override
  void initState() {
    super.initState();
    loadDocument();
  }

  Future<void> loadDocument() async {
    try {
      String url = widget.url;
      final fileID = widget.uniqueID;
      String dir = (await getApplicationDocumentsDirectory()).path;
      String path =
          '$dir/${widget.sem}_${widget.subjectCode}_${widget.typeKey[0]}_${fileID}_${widget.title}';
      File file = File(path);

      if (await file.exists()) {
        document = await PdfDocument.openFile(file.path);
      } else {
        var request = await HttpClient().getUrl(Uri.parse(url));
        var response = await request.close();
        var bytes = await consolidateHttpClientResponseBytes(response);
        await file.writeAsBytes(bytes);
        document = await PdfDocument.openFile(file.path);
      }

      setState(() {
        isLoading = false;
      }); // Update UI
    } catch (err) {
      print("Error loading PDF: $err");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Document"),
      ),
      body: isLoading
          ? Center(
        child: CircularProgressIndicator(),
      )
          : PDFView(
        document: document,
        lazyLoad: false, // Optional: set lazyLoad to false for faster loading
      ),
    );
  }
}
