import 'package:flutter/material.dart';
import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import './himnos/himnos.dart';

void main() async {
  List<ThemeData> temasTema = [
      ThemeData(
        primarySwatch: Colors.deepPurple,
        indicatorColor: Colors.white,
      ),
      ThemeData(
        accentColor: Colors.deepPurpleAccent,
        indicatorColor: Colors.white,
        primaryColorDark: Colors.deepPurple,
        primaryColor: Colors.deepPurple,
        brightness: Brightness.dark
      ),
      ThemeData(
        primarySwatch: Colors.blue,
        indicatorColor: Colors.white,
      ),
      ThemeData(
        accentColor: Colors.blueAccent,
        indicatorColor: Colors.white,
        primaryColorDark: Colors.blue,
        primaryColor: Colors.blue,
        brightness: Brightness.dark
      ),
      ThemeData(
        primarySwatch: Colors.orange,
        indicatorColor: Colors.black
      ),
      ThemeData(
        accentColor: Colors.orangeAccent,
        indicatorColor: Colors.black,
        primaryColorDark: Colors.orange,
        primaryColor: Colors.orange,
        brightness: Brightness.dark
      ),
      ThemeData(
        primarySwatch: Colors.green,
        indicatorColor: Colors.white,
      ),
      ThemeData(
        accentColor: Colors.greenAccent,
        indicatorColor: Colors.white,
        primaryColorDark: Colors.green,
        primaryColor: Colors.green,
        brightness: Brightness.dark
      ),
      ThemeData(
        primarySwatch: Colors.pink,
        indicatorColor: Colors.white
      ),
      ThemeData(
        accentColor: Colors.pinkAccent,
        indicatorColor: Colors.white,
        primaryColorDark: Colors.pink,
        primaryColor: Colors.pink,
        brightness: Brightness.dark
      ),
      ThemeData(
        primarySwatch: Colors.red,
        indicatorColor: Colors.white
      ),
      ThemeData(
        accentColor: Colors.redAccent,
        indicatorColor: Colors.white,
        primaryColorDark: Colors.red,
        primaryColor: Colors.red,
        brightness: Brightness.dark
      ),
      ThemeData(
        primarySwatch: Colors.brown,
        indicatorColor: Colors.white
      ),
      ThemeData(
        accentColor: Colors.brown,
        indicatorColor: Colors.white,
        primaryColorDark: Colors.brown,
        primaryColor: Colors.brown,
        brightness: Brightness.dark
      )
    ];
  ThemeData tema;
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String color = prefs.getString('tema');
  String brightness = prefs.getString('brightness');
  
  for(ThemeData x in temasTema)
    if(x.primaryColor.toString() == color && x.brightness.toString() == brightness) {
      tema = ThemeData(
        accentColor: x.accentColor,
        indicatorColor: x.indicatorColor,
        primaryColorDark: x.primaryColorDark,
        primaryColor: x.primaryColor,
        brightness: x.brightness,
        fontFamily: prefs.getString('fuente') ?? 'Roboto'
      );
      break;
    }
  if (tema == null)
    tema = ThemeData(
      primarySwatch: Colors.deepPurple,
      indicatorColor: Colors.white,
      fontFamily: prefs.getString('fuente') ?? 'Roboto'
    );


  runApp(MyApp(tema: tema));
}
class MyApp extends StatelessWidget {

  MyApp({this.tema});

  final ThemeData tema;

  @override
  Widget build(BuildContext context) {
    return DynamicTheme(
      data: (Brightness brightness) => tema,
      themedWidgetBuilder: (BuildContext context, ThemeData theme) =>
        MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Himnos y Cánticos del Evangelio',
        theme: theme,
        home: HimnosPage(),
      )
    );
  }
}