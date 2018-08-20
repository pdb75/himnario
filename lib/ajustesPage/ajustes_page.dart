import 'package:flutter/material.dart';

import './components/tema_page.dart';

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
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            leading: Icon(Icons.color_lens),
            title: Text('Tema'),
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) => TemasPage(),
                );
            },
          ),
        ],
      ),
    );
  }
}