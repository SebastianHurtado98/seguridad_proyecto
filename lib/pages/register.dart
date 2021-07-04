import 'package:flutter/material.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_2/pages/received.dart';
import 'package:rsa_encrypt/rsa_encrypt.dart';
import 'package:pointycastle/api.dart' as crypto;
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

Future<crypto.AsymmetricKeyPair<crypto.PublicKey, crypto.PrivateKey>>
    getKeyPair() {
  var helper = RsaKeyHelper();
  return helper.computeRSAKeyPair(helper.getSecureRandom());
}

class RegisterPage extends StatelessWidget {
  static String id = 'register_page';
  String username = "what";
  String password = "ever";

  saveData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('username', username);
    prefs.setString('password', password);
    final RsaKeyHelper helper = new RsaKeyHelper();

    crypto.AsymmetricKeyPair keyPair = await getKeyPair();
    final privateKey =
        helper.encodePrivateKeyToPemPKCS1(keyPair.privateKey as RSAPrivateKey);
    final publicKey =
        helper.encodePublicKeyToPemPKCS1(keyPair.publicKey as RSAPublicKey);

    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path;
    String pathPrivate = '$path/assets/private.pem';
    String pathPublic = '$path/assets/public.pem';

    bool pathPrivateExists = await File(pathPrivate).exists();
    bool pathPublicExists = await File(pathPublic).exists();

    if (pathPrivateExists) {
      File(pathPrivate).writeAsString('$privateKey');
    } else {
      new File(pathPrivate).create(recursive: true).then((File privateFile) {
        privateFile.writeAsString('$privateKey');
      });
    }

    if (pathPublicExists) {
      File(pathPublic).writeAsString('$publicKey');
    } else {
      new File(pathPublic).create(recursive: true).then((File publicFile) {
        publicFile.writeAsString('$publicKey');
      });
    }

    // Regiter in firebase (should be replaced with QR)
    print(publicKey);
    FirebaseFirestore.instance
        .collection('usuarios')
        .add({'username': username, 'key': publicKey});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Register'),
        ),
        body: Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 15.0,
            ),
            _userTextField(),
            SizedBox(
              height: 15.0,
            ),
            _passwordTextField(),
            SizedBox(
              height: 20.0,
            ),
            _bottonRegister(context),
          ],
        )));
  }

  Widget _userTextField() {
    return StreamBuilder(
        builder: (BuildContext context, AsyncSnapshot snapshot) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 20.0),
        child: TextField(
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            icon: Icon(Icons.person),
            hintText: 'Usuario',
            labelText: 'Usuario',
          ),
          onChanged: (value) {
            username = value;
          },
        ),
      );
    });
  }

  Widget _passwordTextField() {
    return StreamBuilder(
        builder: (BuildContext context, AsyncSnapshot snapshot) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 20.0),
        child: TextField(
          keyboardType: TextInputType.emailAddress,
          obscureText: true,
          decoration: InputDecoration(
            icon: Icon(Icons.lock),
            hintText: '*******',
            labelText: 'Contraseña',
          ),
          onChanged: (value) {
            password = value;
          },
        ),
      );
    });
  }

  Widget _bottonRegister(context) {
    return StreamBuilder(
        builder: (BuildContext context, AsyncSnapshot snapshot) {
      return ElevatedButton(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 80.0, vertical: 15.0),
          child: Text('Register',
              style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)),
        ),
        style: ButtonStyle(
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ))),
        onPressed: () {
          saveData();
          Navigator.pushNamed(context, ReceivedPage.id);
        },
      );
    });
  }
}
