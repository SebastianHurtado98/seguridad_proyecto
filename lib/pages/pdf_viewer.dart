import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf_viewer_plugin/pdf_viewer_plugin.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_application_2/pages/drawer.dart';
import 'dart:io';

class PdfViewerPage extends StatefulWidget {
  static String id = 'pdf_viewer_page';
  @override
  _PdfViewerPageState createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  String path = "assets/prueba2.pdf";

  @override
  initState() {
    super.initState();
  }

  Future<String> getPath() async {
    final prefs = await SharedPreferences.getInstance();
    final directory = await getApplicationDocumentsDirectory();
    final path = prefs.getString('file_location') ??
        directory.path + "/assets/prueba2.pdf";
    print("What you are looking for");
    print(path);
    return path;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: getPath(),
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if (snapshot.hasData) {
          return Scaffold(
              appBar: AppBar(
                title: Text('Ver pdf'),
              ),
              drawer: myDrawer(),
              body: Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    Container(
                      height: 300.0,
                      child: PdfView(path: snapshot.data as dynamic),
                    ),
                    ElevatedButton.icon(
                        onPressed: () {
                          print(snapshot.data);
                          Navigator.pop(context);
                          Navigator.pushNamed(context, "pdf_viewer_page");
                        },
                        icon: Icon(Icons.save),
                        label: Text("Cargar"))
                  ])));
        } else {
          return Scaffold(
              appBar: AppBar(
                title: Text('Ver pdf'),
              ),
              drawer: myDrawer(),
              body: Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    Text("Aun no se ha cargado"),
                    ElevatedButton.icon(
                        onPressed: () {
                          print("Cargando...");
                          Navigator.pop(context);
                          Navigator.pushNamed(context, "pdf_viewer_page");
                        },
                        icon: Icon(Icons.save),
                        label: Text("Cargar"))
                  ])));
        }
      },
    );
  }
}
