import 'package:Himnario/api/api.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import './components/tema_page.dart';
import './components/fuente_page.dart';
import './components/alineacion_page.dart';
import 'package:path_provider/path_provider.dart';

class AjustesPage extends StatefulWidget {
  @override
  _AjustesPageState createState() => _AjustesPageState();
}

class _AjustesPageState extends State<AjustesPage> {
  int downloaded;

  @override
  void initState() {
    downloaded = -1;
    super.initState();
    checkPartituras().then((ready) {
      if (ready) {
        setState(() => downloaded = 517);
      } else {
        setState(() => downloaded = -1);
      }
    });
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Ajustes'),
        bottom: PreferredSize(preferredSize: Size.fromHeight(4.0), child: Container()),
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
          ListTile(
            leading: downloaded == -2 || (downloaded < 517 && downloaded > -1) ? SizedBox(
              height: 25,
              width: 25,
              child: CircularProgressIndicator(strokeWidth: 1.5,),
            ) : Icon(downloaded < 517 ? Icons.cloud_download : Icons.cloud_done),
            title: Text((downloaded < 517 && downloaded > -1) ? 'Descargando partituras' : downloaded <= -1 ? 'Descargar todas las partituras' : 'Partituras ya descargadas'),
            trailing: SizedBox(
              height: 30,
              width: 30,
              child: downloaded < 517 && downloaded != -1 && downloaded != -2
                  ? Stack(
                      children: <Widget>[
                        CircularProgressIndicator(
                          strokeWidth: 1.5,
                          value: downloaded / 517,
                          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
                        ),
                        Align(
                          alignment: Alignment.center,
                          child: Text(
                            '${(downloaded / 517 * 100).floor()}%',
                            textScaleFactor: 0.5,
                          ),
                        ),
                      ],
                    )
                  : null,
            ),
            onTap: downloaded < 517 ? downloadPartituras : null,
          ),
        ],
      ),
    );
  }
}
