import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:flutter_colorpicker/material_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TemasPage extends StatefulWidget {
  @override
  _TemasPageState createState() => _TemasPageState();
}


class _TemasPageState extends State<TemasPage> {
  List<String> temasNombre;
  List<ThemeData> temasTema;
  int value;
  bool dark;
  SharedPreferences prefs;
  Color pickerColor;
  Color originalColor;
  bool originalDark;

  @override
  void initState() {
    super.initState();
    loadThemes();
  }

  void loadThemes() async {
    prefs = await SharedPreferences.getInstance();

    String temaJson = prefs.getString('temaPrincipal');
    if (temaJson == null) {
      pickerColor = Colors.black;
    } else {
      Map<dynamic, dynamic> json = jsonDecode(temaJson);
      pickerColor = Color.fromRGBO(json['red'], json['green'], json['blue'], 1);
    }
    originalColor = originalColor;
    
    dark = prefs.getString('brightness') == Brightness.dark.toString() ? true : false;
    originalDark = dark;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: EdgeInsets.all(0.0),
      actions: <Widget>[
        GestureDetector(
          onTap: () => setState(() => dark = !dark),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Checkbox(
                value: dark,
                onChanged: (bool value) => setState(() => dark = !dark),
              ),
              Text('Tema Oscuro')
            ],
          ),
        ),
        Divider(),
        FlatButton(
          child: Text('Cancelar', style: Theme.of(context).textTheme.button,),

          onPressed: () {
            Map<int, Color> swatch = {
              50:Color.fromRGBO(originalColor.red, originalColor.green, originalColor.blue, .1),
              100:Color.fromRGBO(originalColor.red, originalColor.green, originalColor.blue, .2),
              200:Color.fromRGBO(originalColor.red, originalColor.green, originalColor.blue, .3),
              300:Color.fromRGBO(originalColor.red, originalColor.green, originalColor.blue, .4),
              400:Color.fromRGBO(originalColor.red, originalColor.green, originalColor.blue, .5),
              500:Color.fromRGBO(originalColor.red, originalColor.green, originalColor.blue, .6),
              600:Color.fromRGBO(originalColor.red, originalColor.green, originalColor.blue, .7),
              700:Color.fromRGBO(originalColor.red, originalColor.green, originalColor.blue, .8),
              800:Color.fromRGBO(originalColor.red, originalColor.green, originalColor.blue, .9),
              900:Color.fromRGBO(originalColor.red, originalColor.green, originalColor.blue, 1),
            };

            DynamicTheme.of(context).setThemeData(ThemeData(
              primarySwatch: MaterialColor(originalColor.value, swatch),
              fontFamily: prefs.getString('fuente') ?? 'Merriweather',
              brightness: originalDark ? Brightness.dark : Brightness.light,
              accentColor: originalDark ? pickerColor : null,
              scaffoldBackgroundColor: originalDark ? Colors.black : null,
              cardColor: originalDark ? Color.fromRGBO(33, 33, 33, 1) : null
            ));
            setState(() {});
            Navigator.of(context).pop();
          },
        ),
        FlatButton(
          child: Text('Guardar', style: Theme.of(context).textTheme.button,),
          onPressed: () {

            Map<int, Color> swatch = {
              50:Color.fromRGBO(pickerColor.red, pickerColor.green, pickerColor.blue, .1),
              100:Color.fromRGBO(pickerColor.red, pickerColor.green, pickerColor.blue, .2),
              200:Color.fromRGBO(pickerColor.red, pickerColor.green, pickerColor.blue, .3),
              300:Color.fromRGBO(pickerColor.red, pickerColor.green, pickerColor.blue, .4),
              400:Color.fromRGBO(pickerColor.red, pickerColor.green, pickerColor.blue, .5),
              500:Color.fromRGBO(pickerColor.red, pickerColor.green, pickerColor.blue, .6),
              600:Color.fromRGBO(pickerColor.red, pickerColor.green, pickerColor.blue, .7),
              700:Color.fromRGBO(pickerColor.red, pickerColor.green, pickerColor.blue, .8),
              800:Color.fromRGBO(pickerColor.red, pickerColor.green, pickerColor.blue, .9),
              900:Color.fromRGBO(pickerColor.red, pickerColor.green, pickerColor.blue, 1),
            };

            prefs.setString('temaPrincipal', jsonEncode({'red': pickerColor.red,'green': pickerColor.green,'blue': pickerColor.blue,'value': pickerColor.value}));
            prefs.setString('brightness', dark ? Brightness.dark.toString() : Brightness.light.toString());

            DynamicTheme.of(context).setThemeData(ThemeData(
              primarySwatch: MaterialColor(pickerColor.value, swatch),
              fontFamily: prefs.getString('fuente') ?? 'Merriweather',
              brightness: dark ? Brightness.dark : Brightness.light,
              accentColor: dark ? pickerColor : null,
              scaffoldBackgroundColor: dark ? Colors.black : null,
              cardColor: dark ? Color.fromRGBO(33, 33, 33, 1) : null
            ));
            setState(() {});
            Navigator.of(context).pop();
          },
        ),
      ],
      content: MaterialPicker(
        pickerColor: pickerColor,
        onColorChanged: (Color color) => setState(() => pickerColor = color),
      )
    );
  }
}