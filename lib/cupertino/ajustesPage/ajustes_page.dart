import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/tema.dart';
import './components/tema_page.dart';
import './components/fuente_page.dart';
import './components/alineacion_page.dart';

class AjustesPage extends StatefulWidget {
  @override
  _AjustesPageState createState() => _AjustesPageState();
}

class _AjustesPageState extends State<AjustesPage> {
  SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    loadThemes();
  }

  void loadThemes() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final TemaModel tema = ScopedModel.of<TemaModel>(context, rebuildOnChange: true);
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        actionsForegroundColor: ScopedModel.of<TemaModel>(context, rebuildOnChange: true).mainColorContrast,
        backgroundColor: ScopedModel.of<TemaModel>(context, rebuildOnChange: true).mainColor,
        middle: Text(
          'Ajustes',
          style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
            color: ScopedModel.of<TemaModel>(context, rebuildOnChange: true).mainColorContrast,
            fontFamily: ScopedModel.of<TemaModel>(context, rebuildOnChange: true).font
          ),
        ),
      ),
      child: ListView(
        children: <Widget>[
          CupertinoButton(
            onPressed: () {
              showCupertinoDialog(
                context: context,
                builder: (BuildContext context) => ScopedModel<TemaModel>(
                  model: tema,
                  child: TemasPage(),
                )
              );
            },
            child: Row(
              children: <Widget>[
                Expanded(child: Container(),),
                Icon(Icons.color_lens),
                SizedBox(width: 10.0,),
                Text(
                  'Colores',
                  style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                    fontFamily: ScopedModel.of<TemaModel>(context, rebuildOnChange: true).font
                  )
                ),
                Expanded(child: Container(),),
              ],
            ),
          ),
          CupertinoButton(
            onPressed: () {
              showCupertinoDialog(
                context: context,
                builder: (BuildContext context) => ScopedModel<TemaModel>(
                  model: tema,
                  child: FuentesPage(),
                )
              );
            },
            child: Row(
              children: <Widget>[
                Expanded(child: Container(),),
                Icon(Icons.text_fields),
                SizedBox(width: 10.0,),
                Text('Fuente',
                  style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                    fontFamily: ScopedModel.of<TemaModel>(context, rebuildOnChange: true).font
                  )
                ),
                Expanded(child: Container(),),
              ],
            ),
          ),
          CupertinoButton(
            onPressed: () {
              showCupertinoDialog(
                context: context,
                builder: (BuildContext context) => ScopedModel<TemaModel>(
                  model: tema,
                  child: AlineacionesPage(),
                )
              );
            },
            child: Row(
              children: <Widget>[
                Expanded(child: Container(),),
                Icon(Icons.format_align_center),
                SizedBox(width: 10.0,),
                Text('Alineación',
                  style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                    fontFamily: ScopedModel.of<TemaModel>(context, rebuildOnChange: true).font
                  )
                ),
                Expanded(child: Container(),),
              ],
            ),
          ),
        ],
      ),
    );
  }
}