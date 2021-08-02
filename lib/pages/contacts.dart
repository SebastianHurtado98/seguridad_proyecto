import 'package:flutter/material.dart';
import 'package:flutter_application_2/pages/drawer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qrscan/qrscan.dart' as scanner;
import 'dart:io';

class ContactsPage extends StatelessWidget {
  static String id = 'contacts_page';

  Future<void> saveContact() async {
    await Permission.camera.request();
    String cameraScanResult = await scanner.scan() as String;
    var data = cameraScanResult.split("#esend#");
    String contact_username = data[0];
    String contact_key = data[1];
    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path;
    String pathPublic = '$path/assets/' + contact_username + '.pem';

    bool pathPublicExists = await File(pathPublic).exists();

    if (pathPublicExists) {
      File(pathPublic).writeAsString(contact_key);
    } else {
      new File(pathPublic).create(recursive: true).then((File publicFile) {
        publicFile.writeAsString(contact_key);
      });
    }
  }

  Future<String> getData() async {
    final prefs = await SharedPreferences.getInstance();
    final saved_username = prefs.getString('username') ?? "invalid";

    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path;
    String pathPublic = '$path/assets/public.pem';
    String my_key = await File(pathPublic).readAsString();
    print(saved_username);
    print(my_key);

    return saved_username + '#esend#' + my_key;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
        future: getData(),
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          if (snapshot.hasData) {
            return Scaffold(
                appBar: AppBar(
                  title: Text('Add contacts'),
                ),
                drawer: myDrawer(),
                body: Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                      QrImage(
                        data: snapshot.data as String,
                        version: QrVersions.auto,
                        size: 200.0,
                      ),
                      ElevatedButton.icon(
                          onPressed: () {
                            saveContact();
                          },
                          icon: Icon(Icons.qr_code),
                          label: Text("Add contact"))
                    ])));
          } else {
            return Scaffold(
                appBar: AppBar(
                  title: Text('Add contacts'),
                ),
                drawer: myDrawer(),
                body: Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                      ElevatedButton.icon(
                          onPressed: () {
                            print("QR");
                          },
                          icon: Icon(Icons.qr_code),
                          label: Text("Add contact"))
                    ])));
          }
        });
  }
}
