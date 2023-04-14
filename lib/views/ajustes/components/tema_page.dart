import 'dart:convert';

import 'package:Himnario/helpers/isAndroid.dart';
import 'package:Himnario/models/tema.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:flutter_colorpicker/material_picker.dart';
import 'package:scoped_model/scoped_model.dart';
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

    if (isAndroid()) {
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
    } else {
      dark = prefs.getString('brightness') == Brightness.dark.toString() ? true : false;
      originalDark = dark;
      pickerColor = ScopedModel.of<TemaModel>(context).mainColor;
      originalColor = pickerColor;
    }

    setState(() {});
  }

  Widget materialLayout(BuildContext context) {
    List<Widget> _buttons = List<Widget>();
    if (MediaQuery.of(context).size.width > 400)
      _buttons.addAll(
        [
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
            child: Text(
              'Cancelar',
              style: Theme.of(context).textTheme.button,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          FlatButton(
            child: Text(
              'Guardar',
              style: Theme.of(context).textTheme.button,
            ),
            onPressed: () {
              Map<int, Color> swatch = {
                50: Color.fromRGBO(pickerColor.red, pickerColor.green, pickerColor.blue, .1),
                100: Color.fromRGBO(pickerColor.red, pickerColor.green, pickerColor.blue, .2),
                200: Color.fromRGBO(pickerColor.red, pickerColor.green, pickerColor.blue, .3),
                300: Color.fromRGBO(pickerColor.red, pickerColor.green, pickerColor.blue, .4),
                400: Color.fromRGBO(pickerColor.red, pickerColor.green, pickerColor.blue, .5),
                500: Color.fromRGBO(pickerColor.red, pickerColor.green, pickerColor.blue, .6),
                600: Color.fromRGBO(pickerColor.red, pickerColor.green, pickerColor.blue, .7),
                700: Color.fromRGBO(pickerColor.red, pickerColor.green, pickerColor.blue, .8),
                800: Color.fromRGBO(pickerColor.red, pickerColor.green, pickerColor.blue, .9),
                900: Color.fromRGBO(pickerColor.red, pickerColor.green, pickerColor.blue, 1),
              };

              prefs.setString('temaPrincipal',
                  jsonEncode({'red': pickerColor.red, 'green': pickerColor.green, 'blue': pickerColor.blue, 'value': pickerColor.value}));
              prefs.setString('brightness', dark ? Brightness.dark.toString() : Brightness.light.toString());

              DynamicTheme.of(context).setThemeData(ThemeData(
                  primarySwatch: MaterialColor(pickerColor.value, swatch),
                  fontFamily: prefs.getString('fuente') ?? 'Merriweather',
                  brightness: dark ? Brightness.dark : Brightness.light,
                  accentColor: dark ? pickerColor : null,
                  scaffoldBackgroundColor: dark ? Colors.black : null,
                  cardColor: dark ? Color.fromRGBO(33, 33, 33, 1) : null));
              setState(() {});
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    else
      _buttons.add(
        Container(
          margin: EdgeInsets.only(right: MediaQuery.of(context).size.width / 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              GestureDetector(
                  onTap: () => setState(() => dark = !dark),
                  child: SizedBox(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Checkbox(
                          value: dark,
                          onChanged: (bool value) => setState(() => dark = !dark),
                        ),
                        Text('Tema Oscuro'),
                      ],
                    ),
                  )),
              Container(
                margin: EdgeInsets.only(left: 20.0),
                child: FlatButton(
                  child: Text(
                    'Cancelar',
                    style: Theme.of(context).textTheme.button,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Container(
                margin: EdgeInsets.only(left: 20.0),
                child: FlatButton(
                  child: Text(
                    'Guardar',
                    style: Theme.of(context).textTheme.button,
                  ),
                  onPressed: () {
                    Map<int, Color> swatch = {
                      50: Color.fromRGBO(pickerColor.red, pickerColor.green, pickerColor.blue, .1),
                      100: Color.fromRGBO(pickerColor.red, pickerColor.green, pickerColor.blue, .2),
                      200: Color.fromRGBO(pickerColor.red, pickerColor.green, pickerColor.blue, .3),
                      300: Color.fromRGBO(pickerColor.red, pickerColor.green, pickerColor.blue, .4),
                      400: Color.fromRGBO(pickerColor.red, pickerColor.green, pickerColor.blue, .5),
                      500: Color.fromRGBO(pickerColor.red, pickerColor.green, pickerColor.blue, .6),
                      600: Color.fromRGBO(pickerColor.red, pickerColor.green, pickerColor.blue, .7),
                      700: Color.fromRGBO(pickerColor.red, pickerColor.green, pickerColor.blue, .8),
                      800: Color.fromRGBO(pickerColor.red, pickerColor.green, pickerColor.blue, .9),
                      900: Color.fromRGBO(pickerColor.red, pickerColor.green, pickerColor.blue, 1),
                    };

                    prefs.setString('temaPrincipal',
                        jsonEncode({'red': pickerColor.red, 'green': pickerColor.green, 'blue': pickerColor.blue, 'value': pickerColor.value}));
                    prefs.setString('brightness', dark ? Brightness.dark.toString() : Brightness.light.toString());

                    DynamicTheme.of(context).setThemeData(ThemeData(
                        primarySwatch: MaterialColor(pickerColor.value, swatch),
                        fontFamily: prefs.getString('fuente') ?? 'Merriweather',
                        brightness: dark ? Brightness.dark : Brightness.light,
                        accentColor: dark ? pickerColor : null,
                        scaffoldBackgroundColor: dark ? Colors.black : null,
                        cardColor: dark ? Color.fromRGBO(33, 33, 33, 1) : null));
                    setState(() {});
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        ),
      );
    return AlertDialog(
      contentPadding: EdgeInsets.all(0.0),
      actions: _buttons,
      content: MaterialPicker(
        pickerColor: pickerColor,
        onColorChanged: (Color color) => setState(() => pickerColor = color),
      ),
    );
  }

  Widget cupertinoLayout(BuildContext context) {
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

  @override
  Widget build(BuildContext context) {
    return isAndroid() ? materialLayout(context) : cupertinoLayout(context);
  }
}
