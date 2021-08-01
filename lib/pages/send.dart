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
  String message_encryptedAESkey = "wrongencryptedAESkey";
  String message_iv = "wrongiv";
  String message_encrypted_pdf = "wrongencrypted_pdf";

  List<String> get_contacts() {
    /* hacer funcionar el async
    final prefs = await SharedPreferences.getInstance();
    final contacts = prefs.getStringList('contacts') ?? <String>[];
    */
    return ['Elegir contacto', 'fmejia', 'shurtado'];
  }

  Future<bool> choose_pdf() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(withData: true);

    if (result != null) {
      PlatformFile file = result.files.first;
      //delete
      print(file.path);
      Uint8List pdf = file.bytes as Uint8List;
      Uint8List source = Uint8List.fromList(
          [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]);
      final AES_key = source.toString();
      final directory = await getApplicationDocumentsDirectory();
      final path = directory.path;
      String pathPrivate = '$path/assets/private.pem';
      String pathPublic = '$path/assets/public.pem';

      String friendsPemKey = "notyet";

      CollectionReference _collectionRef =
          FirebaseFirestore.instance.collection('usuarios');
      final prefs = await SharedPreferences.getInstance();

      QuerySnapshot querySnapshot = await _collectionRef.get();

      // Existe una mejor manera de hacer esto:
      // Deberìa salir de local y no de la base de datos

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

      final encryptedAESkey = encrypt(AES_key, friendsKey);
      var crypt = AesCrypt();

      Uint8List key = source;
      Uint8List iv = source;

      crypt.setPassword('my cool password');
      crypt.setOverwriteMode(AesCryptOwMode.on);
      crypt.aesSetParams(key, iv, AesMode.cbc);
      Uint8List encrypted_pdf = crypt.aesEncrypt(source);
      /* Conectar a cloud storage.
      String path_temp = '$path/assets/temp.bin.aes';
      crypt.encryptDataToFileSync(pdf, path_temp);
      final encryptedPdf = await File(path_temp).readAsString(encoding: utf8);
      print(base64.decode(encryptedPdf));
      */
      print("PDF SENDING");
      print(source);

      setState(() {
        pdf_name = file.name;
        message_encryptedAESkey = encryptedAESkey.codeUnits.toString();
        message_iv = iv.toString();
        message_encrypted_pdf = encrypted_pdf.toString();
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
        '/data/user/0/com.shurtado.esend/cache/file_picker/sample.pdf',
        appDocDirectory.path + '/enc_file.pdf.aes');

    File sent_file = File(appDocDirectory.path + '/enc_file.pdf.aes');

    FirebaseStorage storage = FirebaseStorage.instance;
    Reference ref = storage.ref().child("enc_file.pdf.aes");
    UploadTask uploadTask = ref.putFile(sent_file);
    uploadTask.then((res) {
      print(res.ref.getDownloadURL());
    });

    print(output);
    var output2 = crypt.decryptFileSync(
        appDocDirectory.path + '/enc_file.pdf.aes',
        appDocDirectory.path + '/chanze.pdf');
    print(output2);

    FirebaseFirestore.instance.collection('documentos').add({
      'receptor': contact_username,
      'name': pdf_name,
      'ekey': message_encryptedAESkey,
      'iv': message_iv,
      'document': message_encrypted_pdf
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
