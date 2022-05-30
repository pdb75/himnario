import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FuentesPage extends StatefulWidget {
  @override
  _FuentesPageState createState() => _FuentesPageState();
}

class _FuentesPageState extends State<FuentesPage> {
  List<String> fuentes;
  int value;

  @override
  void initState() {
    super.initState();
    fuentes = ['Josefin Sans', 'Lato', 'Merriweather', 'Montserrat', 'Open Sans', 'Poppins', 'Roboto', 'Roboto Mono', 'Rubik', 'Source Sans Pro'];
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> botones = List<Widget>();
    for (int i = 0; i < fuentes.length; ++i) {
      if (Theme.of(context).textTheme.title.fontFamily == fuentes[i]) {
        value = i;
      }
      botones.add(InkWell(
        onTap: () {
          SharedPreferences.getInstance().then((prefs) {
            prefs.setString('fuente', fuentes[i]);
            ThemeData tema;
            String temaJson = prefs.getString('temaPrincipal');

            if (temaJson == null)
              tema = ThemeData(
                primarySwatch: MaterialColor(Colors.black.value, {
                  50: Color.fromRGBO(Colors.black.red, Colors.black.green, Colors.black.blue, .1),
                  100: Color.fromRGBO(Colors.black.red, Colors.black.green, Colors.black.blue, .2),
                  200: Color.fromRGBO(Colors.black.red, Colors.black.green, Colors.black.blue, .3),
                  300: Color.fromRGBO(Colors.black.red, Colors.black.green, Colors.black.blue, .4),
                  400: Color.fromRGBO(Colors.black.red, Colors.black.green, Colors.black.blue, .5),
                  500: Color.fromRGBO(Colors.black.red, Colors.black.green, Colors.black.blue, .6),
                  600: Color.fromRGBO(Colors.black.red, Colors.black.green, Colors.black.blue, .7),
                  700: Color.fromRGBO(Colors.black.red, Colors.black.green, Colors.black.blue, .8),
                  800: Color.fromRGBO(Colors.black.red, Colors.black.green, Colors.black.blue, .9),
                  900: Color.fromRGBO(Colors.black.red, Colors.black.green, Colors.black.blue, 1),
                }),
                fontFamily: fuentes[i],
              );
            else {
              Map<dynamic, dynamic> json = jsonDecode(temaJson);
              tema = ThemeData(
                primarySwatch: MaterialColor(
                  json['value'],
                  {
                    50: Color.fromRGBO(json['red'], json['green'], json['blue'], .1),
                    100: Color.fromRGBO(json['red'], json['green'], json['blue'], .2),
                    200: Color.fromRGBO(json['red'], json['green'], json['blue'], .3),
                    300: Color.fromRGBO(json['red'], json['green'], json['blue'], .4),
                    400: Color.fromRGBO(json['red'], json['green'], json['blue'], .5),
                    500: Color.fromRGBO(json['red'], json['green'], json['blue'], .6),
                    600: Color.fromRGBO(json['red'], json['green'], json['blue'], .7),
                    700: Color.fromRGBO(json['red'], json['green'], json['blue'], .8),
                    800: Color.fromRGBO(json['red'], json['green'], json['blue'], .9),
                    900: Color.fromRGBO(json['red'], json['green'], json['blue'], 1),
                  },
                ),
                fontFamily: fuentes[i],
              );
            }
            DynamicTheme.of(context).setThemeData(tema);
          });
          setState(() => value = i);
        },
        child: Row(
          children: <Widget>[
            Radio(
              onChanged: (int e) {
                SharedPreferences.getInstance().then((prefs) {
                  prefs.setString('fuente', fuentes[i]);
                  ThemeData tema;
                  String temaJson = prefs.getString('temaPrincipal');

                  if (temaJson == null)
                    tema = ThemeData(
                      primarySwatch: MaterialColor(Colors.black.value, {
                        50: Color.fromRGBO(Colors.black.red, Colors.black.green, Colors.black.blue, .1),
                        100: Color.fromRGBO(Colors.black.red, Colors.black.green, Colors.black.blue, .2),
                        200: Color.fromRGBO(Colors.black.red, Colors.black.green, Colors.black.blue, .3),
                        300: Color.fromRGBO(Colors.black.red, Colors.black.green, Colors.black.blue, .4),
                        400: Color.fromRGBO(Colors.black.red, Colors.black.green, Colors.black.blue, .5),
                        500: Color.fromRGBO(Colors.black.red, Colors.black.green, Colors.black.blue, .6),
                        600: Color.fromRGBO(Colors.black.red, Colors.black.green, Colors.black.blue, .7),
                        700: Color.fromRGBO(Colors.black.red, Colors.black.green, Colors.black.blue, .8),
                        800: Color.fromRGBO(Colors.black.red, Colors.black.green, Colors.black.blue, .9),
                        900: Color.fromRGBO(Colors.black.red, Colors.black.green, Colors.black.blue, 1),
                      }),
                      fontFamily: fuentes[i],
                    );
                  else {
                    Map<dynamic, dynamic> json = jsonDecode(temaJson);
                    tema = ThemeData(
                      primarySwatch: MaterialColor(
                        json['value'],
                        {
                          50: Color.fromRGBO(json['red'], json['green'], json['blue'], .1),
                          100: Color.fromRGBO(json['red'], json['green'], json['blue'], .2),
                          200: Color.fromRGBO(json['red'], json['green'], json['blue'], .3),
                          300: Color.fromRGBO(json['red'], json['green'], json['blue'], .4),
                          400: Color.fromRGBO(json['red'], json['green'], json['blue'], .5),
                          500: Color.fromRGBO(json['red'], json['green'], json['blue'], .6),
                          600: Color.fromRGBO(json['red'], json['green'], json['blue'], .7),
                          700: Color.fromRGBO(json['red'], json['green'], json['blue'], .8),
                          800: Color.fromRGBO(json['red'], json['green'], json['blue'], .9),
                          900: Color.fromRGBO(json['red'], json['green'], json['blue'], 1),
                        },
                      ),
                      fontFamily: fuentes[i],
                    );
                  }
                  DynamicTheme.of(context).setThemeData(tema);
                });
                setState(() => value = e);
              },
              groupValue: value,
              value: i,
            ),
            Text(
              fuentes[i],
              style: TextStyle(fontFamily: fuentes[i]),
            )
          ],
        ),
      ));
    }
    return SimpleDialog(title: Text('Seleccionar Fuente'), children: botones);
  }
}
