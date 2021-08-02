import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_application_2/pages/login.dart';
import 'package:flutter_application_2/pages/register.dart';
import 'package:flutter_application_2/pages/received.dart';
import 'package:flutter_application_2/pages/send.dart';
import 'package:flutter_application_2/pages/contacts.dart';
import 'package:flutter_application_2/pages/pdf_viewer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MaterialApp(title: 'E Send', initialRoute: LoginPage.id, routes: {
    LoginPage.id: (context) => LoginPage(),
    RegisterPage.id: (context) => RegisterPage(),
    ReceivedPage.id: (context) => ReceivedPage(),
    SendPage.id: (context) => SendPage(),
    ContactsPage.id: (context) => ContactsPage(),
    PdfViewerPage.id: (context) => PdfViewerPage(),
  }));
}
