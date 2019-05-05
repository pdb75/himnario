import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/himnos.dart';
import '../components/scroller.dart';

class DisponiblesPage extends StatefulWidget {
  @override
  _DisponiblesPageState createState() => _DisponiblesPageState();
}

class _DisponiblesPageState extends State<DisponiblesPage> {
  List<Himno> himnos;
  bool cargando;
  Database db;

  @override
  void initState() {
    super.initState();
    initDB();
    himnos = List<Himno>();
    cargando = true;
  }

  void initDB([bool refresh = true]) async {
    setState(() => cargando = true);
    String path = (await getApplicationDocumentsDirectory()).path;
    himnos = List<Himno>();
    http.Response res = await http.get('http://104.131.104.212:8085/disponibles');
    openDatabase(path + '/himnos.db')
      .then((dbOpened) async {
        db = dbOpened;
        List<Map<String,dynamic>> data = await dbOpened.rawQuery("select himnos.id, himnos.titulo from himnos where himnos.id in ${(res.body.replaceFirst('[', '(')).replaceFirst(']', ')')} group by himnos.id order by himnos.id ASC");
        List<Map<String,dynamic>> favoritosQuery = await dbOpened.rawQuery('select * from favoritos');
        List<int> favoritos = List<int>();
        for(dynamic favorito in favoritosQuery) {
          favoritos.add(favorito['himno_id']);
        }
        List<Map<String,dynamic>> descargasQuery = await dbOpened.rawQuery('select * from descargados');
        List<int> descargas = List<int>();
        for(dynamic descarga in descargasQuery) {
          descargas.add(descarga['himno_id']);
        }
        for(dynamic himno in data) {
          himnos.add(Himno(
            numero: himno['id'],
            titulo: himno['titulo'],
            descargado: descargas.contains(himno['id']),
            favorito: favoritos.contains(himno['id']),
          ));
        }
        await db.close();
        setState(() => cargando = false);
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Voces Disponibles'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(4.0),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 100),
            curve: Curves.easeInOutSine,
            height: cargando ? 4.0 : 0.0,
            child: LinearProgressIndicator(),
          ),
        ),
      ),
      body: Scroller(
        himnos: himnos,
        cargando: cargando,
        initDB: initDB
      )
    );
  }
}