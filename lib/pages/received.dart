import 'package:flutter/material.dart';
import 'package:flutter_application_2/pages/drawer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rsa_encrypt/rsa_encrypt.dart';
import 'package:pointycastle/api.dart' as crypto;
import 'package:aes_crypt/aes_crypt.dart';
import 'dart:typed_data';

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
      {required this.name,
      required this.receptor,
      required this.ekey,
      required this.iv,
      required this.document});
  final String name;
  final String receptor;
  final String ekey;
  final String iv;
  final String document;
  String get_list_text() {
    return this.name + " - " + this.receptor;
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
        child: Text(document.name[0]),
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
    //String AESKey = decrypt(document.ekey, privateKey);
    Uint8List source = Uint8List.fromList(
        [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]);
    print("Decoding AES Key");
    //String encryptedAESKey = String.fromCharCodes(_get_source(document.ekey));
    //String AESKey = decrypt(encryptedAESKey, privateKey);
    print(source);

    /*/
    var crypt = AesCrypt();
    Uint8List key = Uint8List.fromList(_get_source(AESKey));
    Uint8List iv = Uint8List.fromList(_get_source(document.iv));
    crypt.aesSetParams(key, iv, AesMode.cbc);
    Uint8List encryptedData =
        Uint8List.fromList(_get_source(document.document));
    Uint8List decryptedData = crypt.aesDecrypt(encryptedData);
    */
    print("PDF RECEIVING");
    print(source);

    // Se necesita de otro paquete para usar strings como encrypted!!
    // https://pub.dev/packages/rsa_encrypt
    // Parece que esta opcion es màs versatil. Y el AES?
    // Para el caso de AES, tampoco hay mucha versatilidad con los paquetes de envio.
    // Es decir, necesitamos otro paquete para usar:
    // el pdf encriptado como string, key como string, iv como string.
    // https://pub.dev/packages/aes_crypt
    // para la presentaciòn final tendremos que resumir bien lo que hemos usado
    // y como se podria mejorar + por que los paquetes de envio no mandan texto plano.
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
              name: (e.data() as dynamic)['name'],
              receptor: (e.data() as dynamic)['receptor'],
              ekey: (e.data() as dynamic)['ekey'],
              document: (e.data() as dynamic)['document'],
              iv: (e.data() as dynamic)['iv'],
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
