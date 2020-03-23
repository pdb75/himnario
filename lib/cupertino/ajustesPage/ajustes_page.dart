import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Himnario/api/api.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

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
  int downloaded;

  @override
  void initState() {
    downloaded = -1;
    super.initState();
    loadThemes();
    checkPartituras().then((ready) {
      if (ready) {
        setState(() => downloaded = 517);
      } else {
        setState(() => downloaded = -1);
      }
    });
  }

  void loadThemes() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {});
  }

  Future<bool> checkPartituras() async {
    setState(() => downloaded = -2);
    String path = (await getApplicationDocumentsDirectory()).path;
    for (int i = 1; i <= 517; ++i) {
      File aux = File(path + '/$i.jpg');
      if (!(await aux.exists())) {
        return false;
      }
    }
    return true;
  }

  void downloadPartituras() async {
    String path = (await getApplicationDocumentsDirectory()).path;
    setState(() => downloaded = 0);
    for (int i = 1; i <= 517; ++i) {
      File aux = File(path + '/$i.jpg');
      if (!(await aux.exists())) {
        http.Response res = await http.get(SheetsApi.sheetAvailable(i));
        if (res.statusCode == 200) {
          http.get(SheetsApi.getSheet(i)).then((image) async {
            await aux.writeAsBytes(image.bodyBytes);
            if (mounted) setState(() => downloaded += 1);
          });
        }
      } else {
        if (mounted) setState(() => downloaded += 1);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final TemaModel tema = ScopedModel.of<TemaModel>(context, rebuildOnChange: true);

    List<Widget> botonDescarga = [
      Expanded(
        child: Container(),
      ),
      downloaded == -2 || (downloaded < 517 && downloaded > -1)
          ? SizedBox(height: 24, width: 24, child: CupertinoActivityIndicator())
          : Icon(
              downloaded < 517 ? Icons.cloud_download : Icons.cloud_done,
              color: tema.getScaffoldTextColor(),
            ),
      SizedBox(
        width: 10.0,
      ),
      Text((downloaded < 517 && downloaded > -1) ? 'Descargando partituras' : downloaded <= -1 ? 'Descargar todas las partituras' : 'Partituras ya descargadas',
          style: CupertinoTheme.of(context)
              .textTheme
              .textStyle
              .copyWith(color: tema.getScaffoldTextColor(), fontFamily: ScopedModel.of<TemaModel>(context, rebuildOnChange: true).font)),
    ];

    if (downloaded < 517 && downloaded != -1 && downloaded != -2) {
      botonDescarga.addAll([
        Padding(
          padding: EdgeInsets.only(left: 20.0),
          child: SizedBox(
            height: 20,
            width: 20,
            child: Stack(
              children: <Widget>[
                // CircularProgressIndicator(
                //   strokeWidth: 1.5,
                //   value: downloaded / 517,
                //   valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
                // ),
                Align(
                    alignment: Alignment.bottomCenter,
                    child: LinearProgressIndicator(
                      value: downloaded / 517,
                      backgroundColor: Colors.grey[400],
                      valueColor: AlwaysStoppedAnimation<Color>(tema.getScaffoldTextColor()),
                    )),
                Align(
                  alignment: Alignment.topCenter,
                  child: Text('${(downloaded / 517 * 100).floor()}%',
                      textScaleFactor: 0.5,
                      style: CupertinoTheme.of(context)
                          .textTheme
                          .textStyle
                          .copyWith(color: tema.getScaffoldTextColor(), fontFamily: ScopedModel.of<TemaModel>(context, rebuildOnChange: true).font)),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Container(),
        ),
      ]);
    } else {
      botonDescarga.add(
        Expanded(
          child: Container(),
        ),
      );
    }

    return CupertinoPageScaffold(
      backgroundColor: tema.getScaffoldBackgroundColor(),
      navigationBar: CupertinoNavigationBar(
        actionsForegroundColor: tema.getTabTextColor(),
        backgroundColor: tema.getTabBackgroundColor(),
        middle: Text(
          'Ajustes',
          style: CupertinoTheme.of(context)
              .textTheme
              .textStyle
              .copyWith(color: tema.getTabTextColor(), fontFamily: ScopedModel.of<TemaModel>(context, rebuildOnChange: true).font),
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
                      ));
            },
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Container(),
                ),
                Icon(
                  Icons.color_lens,
                  color: tema.getScaffoldTextColor(),
                ),
                SizedBox(
                  width: 10.0,
                ),
                Text('Colores',
                    style: CupertinoTheme.of(context)
                        .textTheme
                        .textStyle
                        .copyWith(color: tema.getScaffoldTextColor(), fontFamily: ScopedModel.of<TemaModel>(context, rebuildOnChange: true).font)),
                Expanded(
                  child: Container(),
                ),
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
                      ));
            },
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Container(),
                ),
                Icon(
                  Icons.text_fields,
                  color: tema.getScaffoldTextColor(),
                ),
                SizedBox(
                  width: 10.0,
                ),
                Text('Fuente',
                    style: CupertinoTheme.of(context)
                        .textTheme
                        .textStyle
                        .copyWith(color: tema.getScaffoldTextColor(), fontFamily: ScopedModel.of<TemaModel>(context, rebuildOnChange: true).font)),
                Expanded(
                  child: Container(),
                ),
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
                      ));
            },
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Container(),
                ),
                Icon(
                  Icons.format_align_center,
                  color: tema.getScaffoldTextColor(),
                ),
                SizedBox(
                  width: 10.0,
                ),
                Text('Alineación',
                    style: CupertinoTheme.of(context)
                        .textTheme
                        .textStyle
                        .copyWith(color: tema.getScaffoldTextColor(), fontFamily: ScopedModel.of<TemaModel>(context, rebuildOnChange: true).font)),
                Expanded(
                  child: Container(),
                ),
              ],
            ),
          ),
          CupertinoButton(
            onPressed: downloaded < 517 ? downloadPartituras : null,
            child: Row(children: botonDescarga),
          ),
        ],
      ),
    );
  }
}
