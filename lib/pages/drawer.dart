import 'package:flutter/material.dart';
import 'package:flutter_application_2/pages/received.dart';
import 'package:flutter_application_2/pages/send.dart';
import 'package:flutter_application_2/pages/contacts.dart';

class myDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          Container(
            height: 125.0,
            child: DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.blue,
                ),
                child: Text('Menu',
                    style: TextStyle(color: Colors.white, fontSize: 24))),
          ),
          ListTile(
            title: Text('Recibidos', style: TextStyle(fontSize: 20)),
            onTap: () {
              Navigator.pushNamed(context, ReceivedPage.id);
            },
          ),
          ListTile(
            title: Text('Enviar', style: TextStyle(fontSize: 20)),
            onTap: () {
              Navigator.pushNamed(context, SendPage.id);
            },
          ),
          ListTile(
            title: Text('Añadir contacto', style: TextStyle(fontSize: 20)),
            onTap: () {
              Navigator.pushNamed(context, ContactsPage.id);
            },
          ),
        ],
      ),
    );
  }
}
