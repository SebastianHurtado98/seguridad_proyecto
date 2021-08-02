import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:rsa_encrypt/rsa_encrypt.dart';
import 'package:pointycastle/api.dart' as crypto;
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:flutter_application_2/pages/drawer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import 'package:aes_crypt/aes_crypt.dart';

class SendPage extends StatefulWidget {
  static String id = 'send_page';
  @override
  _SendPageState createState() => _SendPageState();
}

class _SendPageState extends State<SendPage> {
  String contact_username = "Elegir contacto";
  String pdf_name = "Choose file";
  String pdf_cache_location = "location";

  List<String> get_contacts() {
    /* hacer funcionar el async
    final prefs = await SharedPreferences.getInstance();
    final contacts = prefs.getStringList('contacts') ?? <String>[];
    */
    return ['Elegir contacto', 'fmejia', 'shurtado98'];
  }

  Future<bool> choose_pdf() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(withData: true);

    if (result != null) {
      PlatformFile file = result.files.first;
      final directory = await getApplicationDocumentsDirectory();
      final path = directory.path;

      CollectionReference _collectionRef =
          FirebaseFirestore.instance.collection('usuarios');
      final prefs = await SharedPreferences.getInstance();

      QuerySnapshot querySnapshot = await _collectionRef.get();

      // Existe una mejor manera de hacer esto:
      // Deberìa salir de local y no de la base de datos

      /*

      String friendsPemKey = "notyet";


      final allData = querySnapshot.docs
          .map((e) => {
                "name": (e.data() as dynamic)['username'],
                "key": (e.data() as dynamic)['key']
              })
          .where((element) => element["name"] == contact_username)
          .toList();
      friendsPemKey = allData[0]['key'];

      final privPem = await File(pathPrivate).readAsString();

      final RsaKeyHelper helper = new RsaKeyHelper();
      RSAPrivateKey privKey = helper.parsePrivateKeyFromPem(privPem);
      RSAPublicKey friendsKey = helper.parsePublicKeyFromPem(friendsPemKey);
      */

      print("LOCATION SELECTED");
      print(file.path);

      setState(() {
        pdf_name = file.name;
        pdf_cache_location = file.path as String;
      });
      return true;
    } else {
      return false;
    }
  }

  send_message() async {
    Directory appDocDirectory = await getApplicationDocumentsDirectory();
    var crypt = AesCrypt('password');
    crypt.setOverwriteMode(AesCryptOwMode.on);

    var output = crypt.encryptFileSync(
        pdf_cache_location, appDocDirectory.path + '/' + pdf_name + '.aes');

    File sent_file = File(appDocDirectory.path + '/' + pdf_name + '.aes');

    FirebaseStorage storage = FirebaseStorage.instance;
    Reference ref = storage.ref().child(pdf_name + '.aes');
    UploadTask uploadTask = ref.putFile(sent_file);
    uploadTask.then((res) {
      print(res.ref.getDownloadURL());
    });

    print(output);

    String pathPrivate = appDocDirectory.path + '/assets/private.pem';
    String pathPublic =
        appDocDirectory.path + '/assets/' + contact_username + '.pem';

    final privPem = await File(pathPrivate).readAsString();
    final friendsPemKey = await File(pathPublic).readAsString();

    final RsaKeyHelper helper = new RsaKeyHelper();
    RSAPrivateKey privKey = helper.parsePrivateKeyFromPem(privPem);
    RSAPublicKey friendsKey = helper.parsePublicKeyFromPem(friendsPemKey);

    FirebaseFirestore.instance.collection('documentos').add({
      'receptor': contact_username,
      'pdf_name': pdf_name,
      'aes_key': encrypt("password", friendsKey)
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Send a document'),
        ),
        drawer: myDrawer(),
        body: Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          DropdownButton<String>(
            value: contact_username,
            icon: const Icon(Icons.arrow_downward),
            iconSize: 24,
            elevation: 16,
            style: const TextStyle(color: Colors.lightBlue),
            underline: Container(
              height: 2,
              color: Colors.lightBlueAccent,
            ),
            onChanged: (String? newValue) {
              setState(() {
                contact_username = newValue!;
              });
            },
            items: get_contacts().map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
          ElevatedButton.icon(
              onPressed: () {
                choose_pdf();
              },
              icon: Icon(Icons.file_copy),
              label: Text(pdf_name)),
          ElevatedButton.icon(
              onPressed: () {
                send_message();
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (BuildContext context) => super.widget));
              },
              icon: Icon(Icons.send),
              label: Text("Send"))
        ])));
  }
}
