import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/himnos.dart';
import '../components/scroller.dart';

class DescargadosPage extends StatefulWidget {
  @override
  _DescargadosPageState createState() => _DescargadosPageState();
}

class _DescargadosPageState extends State<DescargadosPage> {
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

  void initDB() async {
    setState(() => cargando = true);
    himnos = List<Himno>();
    String path = (await getApplicationDocumentsDirectory()).path;
    db = await openDatabase(path + '/himnos.db');
    List<Map<String,dynamic>> data = await db.rawQuery('select * from himnos join descargados on descargados.himno_id = himnos.id order by himnos.id ASC');
    List<Map<String,dynamic>> favoritosQuery = await db.rawQuery('select * from favoritos');
    List<int> favoritos = List<int>();
    for(dynamic favorito in favoritosQuery)
      favoritos.add(favorito['himno_id']);
    for(dynamic himno in data) {
      himnos.add(Himno(
        numero: himno['id'],
        titulo: himno['titulo'],
        descargado: true,
        favorito: favoritos.contains(himno['id'])
      ));
    }
    await db.close();
    setState(() => cargando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Himnos Descargados'),
      ),
      body: Scroller(
        himnos: himnos,
        cargando: cargando,
        initDB: initDB,
        mensaje: 'No has descargado ningún himno\n para escuchar la melodia sin conexión'
      )
    );
  }
}