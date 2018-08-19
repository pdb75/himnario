import 'package:flutter/material.dart';

import './himnos/himnos.dart';

void main() {
  MaterialPageRoute.debugEnableFadingRoutes = true;
  runApp(MyApp());
}

// Map<String, MaterialColor> colores = {
//   'Morado': Colors.deepPurple,
//   'Azul': Colors.blue,
//   'Celeste': Colors.lightBlue,
//   'Amber': Colors.amber,
//   'Cafe': Colors.brown,
//   'Cyan': Colors.cyan,
//   'Naranjo': Colors.deepOrange,
//   'Verde': Colors.green,
//   'Verde Claro': Colors.lightGreen,
//   'Gris': Colors.grey,
//   'Indigo': Colors.indigo,
//   'Lima': Colors.lime,
//   'Rosado': Colors.pink,
//   'Rojo': Colors.red,
//   'Amarillo': Colors.yellow
// };

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {  
    return MaterialApp(
      title: 'Himnos y Cánticos del Evangelio',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: HimnosPage(),
    );
  }
}