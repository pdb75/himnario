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

  @override
  void initState() {
    super.initState();
    loadThemes();
  }

  void loadThemes() async {
    prefs = await SharedPreferences.getInstance();
    dark = prefs.getString('brightness') == Brightness.dark.toString() ? true : false;
    pickerColor = Theme.of(context).primaryColor;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // titlePadding: EdgeInsets.all(0.0),
      // title: Row(
      //   children: <Widget>[
      //     Checkbox(
      //       activeColor: Theme.of(context).primaryColor,
      //       checkColor: Theme.of(context).primaryIconTheme.color,
      //       value: dark,
      //       onChanged: (e) => setState(() => dark = e),
      //     ),
      //     Text('Tema Oscuro', style: Theme.of(context).textTheme.button,)
      //   ],
      // ),
      contentPadding: EdgeInsets.all(0.0),
      actions: <Widget>[
        FlatButton(
          child: Text('Cancelar', style: Theme.of(context).textTheme.button,),
          onPressed: () => Navigator.of(context).pop(),
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

            prefs.setString('tema', jsonEncode({'red': pickerColor.red,'green': pickerColor.green,'blue': pickerColor.blue,'value': pickerColor.value}));
            // prefs.setString('brightness', dark ? Brightness.dark.toString() : Brightness.light.toString());

            DynamicTheme.of(context).setThemeData(ThemeData(
              primarySwatch: MaterialColor(pickerColor.value, swatch),
              fontFamily: prefs.getString('fuente') ?? 'Roboto',
              // brightness: dark ? Brightness.dark : Brightness.light
            ));
            setState(() {});
            Navigator.of(context).pop();
          },
        ),
      ],
      content: MaterialPicker(
        pickerColor: pickerColor,
        onColorChanged: (Color color) => setState(() => pickerColor = color),
      ),
    );
  }
}