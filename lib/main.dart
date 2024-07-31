import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'Login.dart';
import 'RouteGenerator.dart';
import 'dart:io';

final ThemeData temaIOS = ThemeData(
  primaryColor: const Color(0xff075E54),
  colorScheme: const ColorScheme.light(
    primary: Color(0xff075E54),
    secondary: Color(0xff25D366),
  ),
);

final ThemeData temaPadrao = ThemeData(
  primaryColor: const Color(0xff075E54),
  colorScheme: const ColorScheme.light(
    primary: Color(0xff075E54),
    secondary: Color(0xff25D366),
  ),
);


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(MaterialApp(
    home: Login(),
    theme: Platform.isIOS ? temaIOS : temaPadrao,
    initialRoute: "/",
    onGenerateRoute: RouteGenerator.generateRoute,
    debugShowCheckedModeBanner: false,
  ));
}

