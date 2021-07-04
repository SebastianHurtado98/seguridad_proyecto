import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_2/pages/received.dart';
import 'package:flutter_application_2/pages/register.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class LoginPage extends StatefulWidget {
  static String id = 'login_page';
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String email = "new";
  String password = "password";

  sendZeroProof(context) async {
    final prefs = await SharedPreferences.getInstance();
    final saved_username = prefs.getString('username') ?? "invalid";
    final saved_password = prefs.getString('password') ?? "invalid";
    //prefs.setStringList("contacts", ["fajardo", "kevin", "pancho"]);

    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path;
    String pathPublic = '$path/assets/public.pem';
    String my_key = await File(pathPublic).readAsString();

    if ((saved_username == "invalid") || (saved_password == "invalid")) {
      print("Go to register");
    } else if ((email == saved_username) && (password == saved_password)) {
      print("Success");
      Navigator.pushNamed(context, ReceivedPage.id);
    } else {
      print("Failed");
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          body: Center(
              child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Image.asset(
              'images/logo.jpg',
              height: 300.0,
            ),
          ),
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
          _bottonLogin(context),
          SizedBox(
            height: 10.0,
          ),
          _bottonRegister(context),
        ],
      ))),
    );
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
            email = value;
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

  Widget _bottonLogin(context) {
    return StreamBuilder(
        builder: (BuildContext context, AsyncSnapshot snapshot) {
      return ElevatedButton(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 80.0, vertical: 15.0),
          child: Text(
            'Login',
            style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
          ),
        ),
        style: ButtonStyle(
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ))),
        onPressed: () => {sendZeroProof(context)},
      );
    });
  }

  Widget _bottonRegister(context) {
    return StreamBuilder(
        builder: (BuildContext context, AsyncSnapshot snapshot) {
      return ElevatedButton(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 60.0, vertical: 14.0),
          child: Text(
            'Register',
            style: TextStyle(
                fontSize: 12.0,
                fontWeight: FontWeight.bold,
                color: Colors.blue),
          ),
        ),
        style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all<Color>(Colors.white),
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ))),
        onPressed: () => {Navigator.pushNamed(context, RegisterPage.id)},
      );
    });
  }
}
