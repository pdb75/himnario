import 'package:flutter/material.dart';

import './components/tema_page.dart';
import './components/fuente_page.dart';
import './components/alineacion_page.dart';

class AjustesPage extends StatefulWidget {
  @override
  _AjustesPageState createState() => _AjustesPageState();
}

class _AjustesPageState extends State<AjustesPage> {

  @override
  void initState(){
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ajustes'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(4.0),
          child: Container()
        ),
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            leading: Icon(Icons.color_lens),
            title: Text('Colores'),
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) => TemasPage(),
                );
            },
          ),
          ListTile(
            leading: Icon(Icons.text_fields),
            title: Text('Fuente'),
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) => FuentesPage(),
                );
            },
          ),
          ListTile(
            leading: Icon(Icons.format_align_center),
            title: Text('Alineación'),
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) => AlineacionesPage(),
                );
            },
          ),
        ],
      ),
    );
  }
}