import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:flutter_colorpicker/material_picker.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/tema.dart';

class TemasPage extends StatefulWidget {
  @override
  _TemasPageState createState() => _TemasPageState();
}

class _TemasPageState extends State<TemasPage> {
  List<String> temasNombre;
  List<ThemeData> temasTema;
  int value;
  bool dark;
  bool originalDark;
  SharedPreferences prefs;
  Color originalColor;
  Color pickerColor;

  @override
  void initState() {
    super.initState();
    loadThemes();
  }

  void loadThemes() async {
    prefs = await SharedPreferences.getInstance();
    dark = prefs.getString('brightness') == Brightness.dark.toString() ? true : false;
    originalDark = dark;
    pickerColor = ScopedModel.of<TemaModel>(context).mainColor;
    originalColor = pickerColor;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      actions: <Widget>[
        Column(
          children: <Widget>[
            CupertinoButton(
                onPressed: () => setState(() {
                      dark = !dark;
                      Brightness brightness = dark ? Brightness.dark : Brightness.light;
                      ScopedModel.of<TemaModel>(context).setBrightness(brightness);
                    }),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.only(right: 10.0),
                          child: Icon(
                            CupertinoIcons.brightness,
                            color: WidgetsBinding.instance.window.platformBrightness == Brightness.dark ? Colors.white : Colors.black,
                          ),
                        ),
                        Text('Tema Oscuro',
                            style:
                                TextStyle(color: WidgetsBinding.instance.window.platformBrightness == Brightness.dark ? Colors.white : Colors.black)),
                      ],
                    ),
                    IgnorePointer(
                      child: CupertinoSwitch(
                        onChanged: (e) => e,
                        value: dark ?? false,
                      ),
                    )
                  ],
                )),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                FlatButton(
                  child: Text('Cancelar',
                      style: TextStyle(color: WidgetsBinding.instance.window.platformBrightness == Brightness.dark ? Colors.white : Colors.black)),
                  onPressed: () {
                    ScopedModel.of<TemaModel>(context).setMainColor(originalColor);
                    ScopedModel.of<TemaModel>(context).setBrightness(originalDark ? Brightness.dark : Brightness.light);
                    Navigator.of(context).pop();
                  },
                ),
                FlatButton(
                  child: Text(
                    'Guardar',
                    style: TextStyle(color: WidgetsBinding.instance.window.platformBrightness == Brightness.dark ? Colors.white : Colors.black),
                  ),
                  onPressed: () {
                    Brightness brightness = dark ? Brightness.dark : Brightness.light;
                    ScopedModel.of<TemaModel>(context).setMainColor(pickerColor);
                    ScopedModel.of<TemaModel>(context).setBrightness(brightness);

                    prefs.setInt('mainColor', pickerColor.value);
                    prefs.setString('brightness', brightness.toString());
                    print((pickerColor.red * 0.299 + pickerColor.green * 0.587 + pickerColor.blue * 0.114));

                    setState(() {});
                    Navigator.of(context).pop();
                  },
                ),
              ],
            )
          ],
        )
      ],
      content: Container(
        height: 440.0,
        child: MaterialPicker(
          pickerColor: pickerColor,
          onColorChanged: (Color color) => setState(() {
            pickerColor = color;
            ScopedModel.of<TemaModel>(context).setMainColor(color);
          }),
        ),
      ),
    );
  }
}
