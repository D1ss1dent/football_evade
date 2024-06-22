import 'package:flutter/material.dart';
import 'package:football_evade/menu_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(
    home: MenuScreen(),
    debugShowCheckedModeBanner: false,
  ));
}
