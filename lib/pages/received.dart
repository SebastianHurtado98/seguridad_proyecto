import 'package:flutter/material.dart';
import 'package:flutter_application_2/pages/drawer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_application_2/pages/pdf_viewer.dart';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rsa_encrypt/rsa_encrypt.dart';
import 'package:pointycastle/api.dart' as crypto;
import 'package:aes_crypt/aes_crypt.dart';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:aes_crypt/aes_crypt.dart';

List<int> _get_source(String str) {
  List<dynamic> init_list = jsonDecode(str);
  List<int> final_list = [];
  for (var i = 0; i < init_list.length; i++) {
    final_list.add(init_list[i] as int);
  }
  return final_list;
}

class Document {
  const Document(
      {required this.pdf_name, required this.receptor, required this.aes_key});
  final String pdf_name;
  final String receptor;
  final String aes_key;
  String get_list_text() {
    return this.pdf_name + " - " + this.receptor;
  }
}

typedef void ListChangedCallback(Document document, bool inList);

class DocumentListItem extends StatelessWidget {
  DocumentListItem({
    required this.document,
    required this.inList,
    required this.onListChanged,
  }) : super(key: ObjectKey(document));

  final Document document;
  final bool inList;
  final ListChangedCallback onListChanged;

  Color _getColor(BuildContext context) {
    return inList ? Colors.black54 : Theme.of(context).primaryColor;
  }

  TextStyle? _getTextStyle(BuildContext context) {
    if (!inList) return null;

    return TextStyle(
      color: Colors.black54,
      decoration: TextDecoration.lineThrough,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        onListChanged(document, inList);
      },
      leading: CircleAvatar(
        backgroundColor: _getColor(context),
        child: Text(document.pdf_name[0]),
      ),
      title: Text(document.get_list_text(), style: _getTextStyle(context)),
    );
  }
}

class DocumentList extends StatefulWidget {
  DocumentList({Key? key, required this.documents}) : super(key: key);

  final List<Document> documents;

  @override
  _DocumentListState createState() => _DocumentListState();
}

class _DocumentListState extends State<DocumentList> {
  Set<Document> _downloadList = Set<Document>();
  final db = FirebaseFirestore.instance;

  void _handleListChanged(Document document, bool inList) {
    setState(() {
      if (!inList)
        _downloadList.add(document);
      else
        _downloadList.remove(document);
    });
  }

  void _decryptDocument(Document document) async {
    final RsaKeyHelper helper = new RsaKeyHelper();
    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path;
    String pathPrivate = '$path/assets/private.pem';
    String pathPublic = '$path/assets/public.pem';
    final publicPem = await File(pathPublic).readAsString();
    final privatePem = await File(pathPrivate).readAsString();

    RSAPrivateKey privateKey = helper.parsePrivateKeyFromPem(privatePem);
    String aesKey = decrypt(document.aes_key, privateKey);
    print("AES KEY");
    print(aesKey);

    FirebaseStorage storage = FirebaseStorage.instance;

    Directory appDocDir = await getApplicationDocumentsDirectory();
    File downloadToFile =
        File(appDocDir.path + "/" + document.pdf_name + '.aes');

    print("path of downloaded");
    print(downloadToFile.path);

    await storage.ref(document.pdf_name + '.aes').writeToFile(downloadToFile);

    print("saved file");

    var crypt = AesCrypt(aesKey);
    crypt.setOverwriteMode(AesCryptOwMode.on);

    var output = crypt.decryptFileSync(
        appDocDir.path + '/' + document.pdf_name + '.aes',
        appDocDir.path + '/esend_' + document.pdf_name);
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(
        'file_location', appDocDir.path + '/esend_' + document.pdf_name);
    print(output);
    // Guardar el output en local!!!
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Recent documents'),
        ),
        drawer: myDrawer(),
        body: Column(children: [
          Expanded(
              child: ListView(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            children: widget.documents.map((Document document) {
              return DocumentListItem(
                document: document,
                inList: _downloadList.contains(document),
                onListChanged: _handleListChanged,
              );
            }).toList(),
          )),
          Container(
              margin: const EdgeInsets.only(bottom: 40.0),
              child: ElevatedButton.icon(
                  onPressed: () {
                    _downloadList.forEach((d) => _decryptDocument(d));
                    Navigator.pushNamed(context, PdfViewerPage.id);
                  },
                  icon: Icon(Icons.download),
                  label: Text("Download")))
        ]));
  }
}

class ReceivedPage extends StatefulWidget {
  static String id = 'received_page';
  @override
  _ReceivedPageState createState() => _ReceivedPageState();
}

class _ReceivedPageState extends State<ReceivedPage> {
  CollectionReference _collectionRef =
      FirebaseFirestore.instance.collection('documentos');

  Future<List<Document>> getData() async {
    // Get docs from collection reference
    final prefs = await SharedPreferences.getInstance();
    final saved_username = prefs.getString('username');

    QuerySnapshot querySnapshot = await _collectionRef.get();

    // Get data from docs and convert map to List
    final allData = querySnapshot.docs
        .map((e) => new Document(
              pdf_name: (e.data() as dynamic)['pdf_name'],
              receptor: (e.data() as dynamic)['receptor'],
              aes_key: (e.data() as dynamic)['aes_key'],
            ))
        .where((element) => element.receptor == saved_username)
        .toList();

    return allData;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Document>>(
      future: getData(),
      builder: (BuildContext context, AsyncSnapshot<List<Document>> snapshot) {
        if (snapshot.hasData) {
          return DocumentList(
            documents: (snapshot.data as dynamic),
          );
        } else {
          return DocumentList(
            documents: [],
          );
        }
      },
    );
  }
}
