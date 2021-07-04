import 'package:flutter/material.dart';
import 'package:flutter_application_2/pages/drawer.dart';

class ContactsPage extends StatelessWidget {
  static String id = 'contacts_page';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Add contacts'),
        ),
        drawer: myDrawer(),
        body: Center(
            child: ElevatedButton.icon(
                onPressed: () {
                  print("QR");
                },
                icon: Icon(Icons.qr_code),
                label: Text("Add contact"))));
  }
}
