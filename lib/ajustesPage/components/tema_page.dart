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

  @override
  void initState() {
    super.initState();
    temasNombre = ['Morado', 'Morado Dark', 'Azul', 'Azul Dark', 'Naranjo', 'Naranjo Dark', 'Verde', 'Verde Dark', 'Rosa', 'Rosa Dark', 'Rojo', 'Rojo Dark', 'Cafe', 'Cafe Dark'];
    temasTema = [
      ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      ThemeData(
        accentColor: Colors.deepPurpleAccent,
        indicatorColor: Colors.black,
        primaryColorDark: Colors.deepPurple,
        primaryColor: Colors.deepPurple,
        brightness: Brightness.dark
      ),
      ThemeData(
        primarySwatch: Colors.blue,
      ),
      ThemeData(
        accentColor: Colors.blueAccent,
        indicatorColor: Colors.black,
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
        indicatorColor: Colors.black
      ),
      ThemeData(
        accentColor: Colors.greenAccent,
        indicatorColor: Colors.black,
        primaryColorDark: Colors.green,
        primaryColor: Colors.green,
        brightness: Brightness.dark
      ),
      ThemeData(
        primarySwatch: Colors.pink,
        indicatorColor: Colors.black
      ),
      ThemeData(
        accentColor: Colors.pinkAccent,
        indicatorColor: Colors.black,
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
        indicatorColor: Colors.black,
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
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> botones = List<Widget>();
    for(int i = 0; i < temasTema.length; ++i) {
      if (Theme.of(context).primaryColor == temasTema[i].primaryColor && value == null && Theme.of(context).brightness == temasTema[i].brightness) {
        print(temasTema[i].brightness.toString());
        value = i;
      }
      botones.add(
        InkWell(
          onTap: () {
            SharedPreferences.getInstance()
              .then((prefs) {
                prefs.setString('tema', temasTema[i].primaryColor.toString());
                prefs.setString('brightness', temasTema[i].brightness.toString());
              });
            DynamicTheme.of(context).setThemeData(temasTema[i]);
            setState(() => value = i);
          },
          child: Row(
            children: <Widget>[
              Radio(
                onChanged: (int e) {
                  SharedPreferences.getInstance()
                    .then((prefs) {
                      prefs.setString('tema', temasTema[i].primaryColor.toString());
                      prefs.setString('brightness', temasTema[i].brightness.toString());
                    });
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
      title: Text('Seleccionar Tema'),
      children: botones
    );
  }
}