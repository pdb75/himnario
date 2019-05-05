import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

import './components/tema_page.dart';
import './components/fuente_page.dart';
import './components/alineacion_page.dart';

class AjustesPage extends StatefulWidget {
  @override
  _AjustesPageState createState() => _AjustesPageState();
}

class _AjustesPageState extends State<AjustesPage> {
  List<String> temasNombre;
  List<CupertinoThemeData> temasTema;
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
      CupertinoThemeData(
        primaryColor: Colors.deepPurple,
      ),
      CupertinoThemeData(
        primaryColor: Colors.deepPurple,
        brightness: Brightness.dark,
      ),
      CupertinoThemeData(
        primaryColor: Colors.blue,
      ),
      CupertinoThemeData(
        primaryColor: Colors.blue,
        brightness: Brightness.dark,
      ),
      CupertinoThemeData(
        primaryColor: Colors.orange,
      ),
      CupertinoThemeData(
        primaryColor: Colors.orange,
        brightness: Brightness.dark,
      ),
      CupertinoThemeData(
        primaryColor: Colors.green,
      ),
      CupertinoThemeData(
        primaryColor: Colors.green,
        brightness: Brightness.dark,
      ),
      CupertinoThemeData(
        primaryColor: Colors.pink,
      ),
      CupertinoThemeData(
        primaryColor: Colors.pink,
        brightness: Brightness.dark,
      ),
      CupertinoThemeData(
        primaryColor: Colors.red,
      ),
      CupertinoThemeData(
        primaryColor: Colors.red,
        brightness: Brightness.dark,
      ),
      CupertinoThemeData(
        primaryColor: Colors.brown,
      ),
      CupertinoThemeData(
        primaryColor: Colors.brown,
        brightness: Brightness.dark,
      )
    ];
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Ajustes'),
      ),
      // appBar: AppBar(
      //   title: Text('Ajustes'),
      //   bottom: PreferredSize(
      //     preferredSize: Size.fromHeight(4.0),
      //     child: Container()
      //   ),
      // ),
      child: ListView(
        children: <Widget>[
          CupertinoButton(
            onPressed: () {
              print(CupertinoTheme.of(context).textTheme.textStyle.fontFamily);
              showCupertinoModalPopup(
                context: context,
                builder: (BuildContext context) => Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    height: 150.0,
                    child: CupertinoPicker.builder(
                      useMagnifier: true,
                      magnification: 1.5,
                      backgroundColor: CupertinoTheme.of(context).scaffoldBackgroundColor,
                      itemExtent: 30.0,
                      onSelectedItemChanged: (int i) {
                        prefs.setString('tema', temasTema[i].primaryColor.toString());
                        prefs.setString('brightness', temasTema[i].brightness.toString());
                        // DynamicTheme.of(context).setThemeData(temasTema[i]);
                      },
                      childCount: temasTema.length,
                      itemBuilder: (BuildContext context, int i) => Text(temasNombre[i]),
                    )
                  )
                )
              );
            },
            child: Row(
              children: <Widget>[
                Expanded(child: Container(),),
                Icon(Icons.color_lens),
                SizedBox(width: 10.0,),
                Text('Colores'),
                Expanded(child: Container(),),
              ],
            ),
          ),
          CupertinoButton(
            onPressed: () {

            },
            child: Row(
              children: <Widget>[
                Expanded(child: Container(),),
                Icon(Icons.text_fields),
                SizedBox(width: 10.0,),
                Text('Fuente'),
                Expanded(child: Container(),),
              ],
            ),
          ),
          CupertinoButton(
            onPressed: () {

            },
            child: Row(
              children: <Widget>[
                Expanded(child: Container(),),
                Icon(Icons.format_align_center),
                SizedBox(width: 10.0,),
                Text('Alineación'),
                Expanded(child: Container(),),
              ],
            ),
          ),
          // ListTile(
          //   leading: Icon(Icons.color_lens),
          //   title: Text('Colores'),
          //   onTap: () {
          //     showDialog(
          //       context: context,
          //       builder: (BuildContext context) => TemasPage(),
          //       );
          //   },
          // ),
          // ListTile(
          //   leading: Icon(Icons.text_fields),
          //   title: Text('Fuente'),
          //   onTap: () {
          //     showDialog(
          //       context: context,
          //       builder: (BuildContext context) => FuentesPage(),
          //       );
          //   },
          // ),
          // ListTile(
          //   leading: Icon(Icons.format_align_center),
          //   title: Text('Alineación'),
          //   onTap: () {
          //     showDialog(
          //       context: context,
          //       builder: (BuildContext context) => AlineacionesPage(),
          //       );
          //   },
          // ),
        ],
      ),
    );
  }
}