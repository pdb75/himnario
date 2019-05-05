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
  List<ThemeData> temasTema;
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
        fontFamily: prefs.getString('fuente') ?? 'Roboto',
        scaffoldBackgroundColor: Colors.white
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
        fontFamily: prefs.getString('fuente') ?? 'Roboto',
        scaffoldBackgroundColor: Colors.white
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
        fontFamily: prefs.getString('fuente') ?? 'Roboto',
        scaffoldBackgroundColor: Colors.white
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
        fontFamily: prefs.getString('fuente') ?? 'Roboto',
        scaffoldBackgroundColor: Colors.white
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
        fontFamily: prefs.getString('fuente') ?? 'Roboto',
        scaffoldBackgroundColor: Colors.white
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
        fontFamily: prefs.getString('fuente') ?? 'Roboto',
        scaffoldBackgroundColor: Colors.white
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
        fontFamily: prefs.getString('fuente') ?? 'Roboto',
        scaffoldBackgroundColor: Colors.white
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
                builder: (BuildContext context) => CupertinoPicker.builder(
                  backgroundColor: CupertinoTheme.of(context).scaffoldBackgroundColor,
                  itemExtent: 20.0,
                  onSelectedItemChanged: (int i) => print(i),
                  childCount: temasTema.length,
                  itemBuilder: (BuildContext context, int i) => Text(temasNombre[i]),
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