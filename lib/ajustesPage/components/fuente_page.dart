import 'package:flutter/material.dart';
import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FuentesPage extends StatefulWidget {
  @override
  _FuentesPageState createState() => _FuentesPageState();
}


class _FuentesPageState extends State<FuentesPage> {
  List<String> temasNombre;
  List<ThemeData> temasTema;
  List<String> fuentes;
  int value;

  @override
  void initState() {
    super.initState();
    fuentes = ['Josefin Sans', 'Lato', 'Merriweather', 'Montserrat', 'Open Sans', 'Poppins', 'Raleway', 'Roboto', 'Roboto Mono', 'Rubik', 'Source Sans Pro'];
    temasNombre = ['Morado', 'Morado Dark', 'Azul', 'Azul Dark', 'Naranjo', 'Naranjo Dark', 'Verde', 'Verde Dark', 'Rosa', 'Rosa Dark', 'Rojo', 'Rojo Dark', 'Cafe', 'Cafe Dark'];
    temasTema = [
      ThemeData(
        primarySwatch: Colors.deepPurple,
        indicatorColor: Colors.white
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
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> botones = List<Widget>();
    for(int i = 0; i < fuentes.length; ++i) {
      if (Theme.of(context).textTheme.title.fontFamily == fuentes[i]) {
        value = i;
      }
      botones.add(
        InkWell(
          onTap: () {
            SharedPreferences.getInstance()
              .then((prefs) => prefs.setString('fuente', fuentes[i]));
            DynamicTheme.of(context).setThemeData(
              ThemeData(
                accentColor: Theme.of(context).accentColor,
                indicatorColor: Theme.of(context).indicatorColor,
                primaryColorDark: Theme.of(context).primaryColorDark,
                primaryColor: Theme.of(context).primaryColor,
                brightness: Theme.of(context).brightness,
                fontFamily: fuentes[i]
              )
            );
            setState(() => value = i);
          },
          child: Row(
            children: <Widget>[
              Radio(
                onChanged: (int e) {
                  SharedPreferences.getInstance()
                    .then((prefs) => prefs.setString('fuente', fuentes[i]));
                  DynamicTheme.of(context).setThemeData(
                    ThemeData(
                      accentColor: Theme.of(context).accentColor,
                      indicatorColor: Theme.of(context).indicatorColor,
                      primaryColorDark: Theme.of(context).primaryColorDark,
                      primaryColor: Theme.of(context).primaryColor,
                      brightness: Theme.of(context).brightness,
                      fontFamily: fuentes[i]
                    )
                  );
                  setState(() => value = e);
                },
                groupValue: value,
                value: i,
              ),
              Text(
                fuentes[i],
                style: TextStyle(
                  fontFamily: fuentes[i]
                ),
                )
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