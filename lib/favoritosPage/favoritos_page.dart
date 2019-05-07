import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/himnos.dart';
import '../components/scroller.dart';

class FavoritosPage extends StatefulWidget {
  @override
  _FavoritosPageState createState() => _FavoritosPageState();
}

class _FavoritosPageState extends State<FavoritosPage> {
  List<Himno> himnos;
  Database db;
  bool cargando;

  @override
  void initState() {
    super.initState();
    himnos = List<Himno>();
    cargando = true;
    initDB();
  }

  void initDB([bool refresh = true]) async {
    setState(() => cargando = true);
    himnos = List<Himno>();
    String path = (await getApplicationDocumentsDirectory()).path;
    db = await openDatabase(path + '/himnos.db');
    List<Map<String,dynamic>> data = await db.rawQuery('select * from himnos join favoritos on favoritos.himno_id = himnos.id order by himnos.id ASC');
    List<Map<String,dynamic>> descargadosQuery = await db.rawQuery('select * from descargados');
    List<int> descargados = List<int>();
    for(dynamic descargado in descargadosQuery)
      descargados.add(descargado['himno_id']);
    for(dynamic himno in data) {
      himnos.add(Himno(
        numero: himno['id'],
        titulo: himno['titulo'],
        transpose: himno['transpose'],
        descargado: descargados.contains(himno['id']),
        favorito: true
      ));
    }
    await db.close();
    setState(() => cargando = false);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Favoritos'),
      ),
      // appBar: AppBar(
      //   title: Text('Favoritos'),
      //   bottom: PreferredSize(
      //     preferredSize: Size.fromHeight(4.0),
      //     child: AnimatedContainer(
      //       duration: Duration(milliseconds: 100),
      //       curve: Curves.easeInOutSine,
      //       height: cargando ? 4.0 : 0.0,
      //       child: LinearProgressIndicator(),
      //     ),
      //   ),
      // ),
      child: Scroller(
        himnos: himnos,
        cargando: cargando,
        initDB: initDB,
        iPhoneX: MediaQuery.of(context).size.width >= 812.0 || MediaQuery.of(context).size.height >= 812.0,
        mensaje: 'No has agregando ningún himno\n a tu lista de favoritos',
      )
    );
  }
}