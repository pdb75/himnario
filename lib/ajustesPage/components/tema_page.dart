import 'package:flutter/material.dart';
import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TemasPage extends StatefulWidget {
  @override
  _TemasPageState createState() => _TemasPageState();
}


class _TemasPageState extends State<TemasPage> {
  List<String> temasNombre;
  List<ThemeData> temasTema;
  int value;
  SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    loadThemes();
  }

  void loadThemes() async {
    prefs = await SharedPreferences.getInstance();
    temasNombre = ['Morado', 'Morado Dark', 'Azul', 'Azul Dark', 'Naranjo', 'Naranjo Dark', 'Verde', 'Verde Dark', 'Rosa', 'Rosa Dark', 'Rojo', 'Rojo Dark', 'Cafe', 'Cafe Dark'];
    temasTema = [
      ThemeData(
        primarySwatch: Colors.deepPurple,
        indicatorColor: Colors.white,
        fontFamily: prefs.getString('fuente') ?? 'Roboto'
      ),
      ThemeData(
        accentColor: Colors.deepPurpleAccent,
        indicatorColor: Colors.white,
        primaryColorDark: Colors.deepPurple,
        primaryColor: Colors.deepPurple,
        brightness: Brightness.dark,
        fontFamily: prefs.getString('fuente') ?? 'Roboto'
      ),
      ThemeData(
        primarySwatch: Colors.blue,
        indicatorColor: Colors.white,
        fontFamily: prefs.getString('fuente') ?? 'Roboto'
      ),
      ThemeData(
        accentColor: Colors.blueAccent,
        indicatorColor: Colors.white,
        primaryColorDark: Colors.blue,
        primaryColor: Colors.blue,
        brightness: Brightness.dark,
        fontFamily: prefs.getString('fuente') ?? 'Roboto'
      ),
      ThemeData(
        primarySwatch: Colors.orange,
        indicatorColor: Colors.black,
        fontFamily: prefs.getString('fuente') ?? 'Roboto'
      ),
      ThemeData(
        accentColor: Colors.orangeAccent,
        indicatorColor: Colors.black,
        primaryColorDark: Colors.orange,
        primaryColor: Colors.orange,
        brightness: Brightness.dark,
        fontFamily: prefs.getString('fuente') ?? 'Roboto'
      ),
      ThemeData(
        primarySwatch: Colors.green,
        indicatorColor: Colors.white,
        fontFamily: prefs.getString('fuente') ?? 'Roboto'
      ),
      ThemeData(
        accentColor: Colors.greenAccent,
        indicatorColor: Colors.white,
        primaryColorDark: Colors.green,
        primaryColor: Colors.green,
        brightness: Brightness.dark,
        fontFamily: prefs.getString('fuente') ?? 'Roboto'
      ),
      ThemeData(
        primarySwatch: Colors.pink,
        indicatorColor: Colors.white,
        fontFamily: prefs.getString('fuente') ?? 'Roboto'
      ),
      ThemeData(
        accentColor: Colors.pinkAccent,
        indicatorColor: Colors.white,
        primaryColorDark: Colors.pink,
        primaryColor: Colors.pink,
        brightness: Brightness.dark,
        fontFamily: prefs.getString('fuente') ?? 'Roboto'
      ),
      ThemeData(
        primarySwatch: Colors.red,
        indicatorColor: Colors.white,
        fontFamily: prefs.getString('fuente') ?? 'Roboto'
      ),
      ThemeData(
        accentColor: Colors.redAccent,
        indicatorColor: Colors.white,
        primaryColorDark: Colors.red,
        primaryColor: Colors.red,
        brightness: Brightness.dark,
        fontFamily: prefs.getString('fuente') ?? 'Roboto'
      ),
      ThemeData(
        primarySwatch: Colors.brown,
        indicatorColor: Colors.white,
        fontFamily: prefs.getString('fuente') ?? 'Roboto'
      ),
      ThemeData(
        accentColor: Colors.brown,
        indicatorColor: Colors.white,
        primaryColorDark: Colors.brown,
        primaryColor: Colors.brown,
        brightness: Brightness.dark,
        fontFamily: prefs.getString('fuente') ?? 'Roboto'
      )
    ];
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> botones = List<Widget>();
    if(temasTema != null)
    for(int i = 0; i < temasTema.length; ++i) {
      if (Theme.of(context).primaryColor == temasTema[i].primaryColor && value == null && Theme.of(context).brightness == temasTema[i].brightness)
        value = i;
      botones.add(
        InkWell(
          onTap: () {
            prefs.setString('tema', temasTema[i].primaryColor.toString());
            prefs.setString('brightness', temasTema[i].brightness.toString());
            DynamicTheme.of(context).setThemeData(temasTema[i]);
            setState(() => value = i);
          },
          child: Row(
            children: <Widget>[
              Radio(
                onChanged: (int e) {
                  prefs.setString('tema', temasTema[i].primaryColor.toString());
                  prefs.setString('brightness', temasTema[i].brightness.toString());
                  DynamicTheme.of(context).setThemeData(temasTema[i]);
                  setState(() => value = e);
                },
                groupValue: value,
                value: i,
              ),
              Text(temasNombre[i])
            ],
          ),
        )
      );
    }
    return SimpleDialog(
      title: Text('Seleccionar Colores'),
      children: botones
    );
  }
}