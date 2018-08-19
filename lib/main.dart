import 'package:flutter/material.dart';

import './himnos/himnos.dart';

void main() {
  MaterialPageRoute.debugEnableFadingRoutes = true;
  runApp(MyApp());
}

Map<String, ThemeData> colores = {
  'Morado': ThemeData(
    primarySwatch: Colors.deepPurple
  )
};

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {  
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Himnos y Cánticos del Evangelio',
      theme: colores['Morado'],
      home: HimnosPage(),
    );
  }
}