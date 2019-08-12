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
    pickerColor = ScopedModel.of<TemaModel>(context).mainColor;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      actions: <Widget>[
        FlatButton(
          child: Text('Cancelar', style: Theme.of(context).textTheme.button,),
          onPressed: () => Navigator.of(context).pop(),
        ),
        FlatButton(
          child: Text('Guardar', style: Theme.of(context).textTheme.button,),
          onPressed: () {
            ScopedModel.of<TemaModel>(context).setMainColor(pickerColor);
            prefs.setInt('mainColor', pickerColor.value);

            print((pickerColor.red*0.299 + pickerColor.green*0.587 + pickerColor.blue*0.114));

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