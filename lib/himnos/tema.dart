import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'package:sqflite/sqflite.dart';

import '../models/himnos.dart';
import '../himnoPage/himno.dart';
import '../buscador/buscador.dart';
import '../components/scroller.dart';

class TemaPage extends StatefulWidget {

  TemaPage({this.id, this.subtema = false, this.tema});
  
  final int id;
  final bool subtema;
  final String tema;
  
  @override
  _TemaPageState createState() => _TemaPageState();
}

class _TemaPageState extends State<TemaPage> {
  List<Himno> himnos;
  bool cargando;
  Database db;

  @override
  void initState() {
    super.initState();
    himnos = List<Himno>();
    cargando = true;
    initDB();
  }

  Future<Null> initDB() async {
    String databasesPath = (await getApplicationDocumentsDirectory()).path;
    String path = databasesPath + "/himnos.db";
    db = await openReadOnlyDatabase(path);

    await fetchHimnos();
    return null;
  }

  Future<Null> fetchHimnos() async {
    setState(() => cargando = true);
    himnos = List<Himno>();
    List<Map<String,dynamic>> data;
    if (widget.id == 0) {
      data = await db.rawQuery('select himnos.id, himnos.titulo from himnos order by himnos.id ASC');
    } else {
      if(widget.subtema) {
        data = await db.rawQuery('select himnos.id, himnos.titulo from himnos join sub_tema_himnos on sub_tema_himnos.himno_id = himnos.id where sub_tema_himnos.sub_tema_id = ${widget.id} order by himnos.id ASC');
      } else {
        data = await db.rawQuery('select himnos.id, himnos.titulo from himnos join tema_himnos on himnos.id = tema_himnos.himno_id where tema_himnos.tema_id = ${widget.id} order by himnos.id ASC');
      }
    }
    List<Map<String,dynamic>> favoritosQuery = await db.rawQuery('select * from favoritos');
    List<int> favoritos = List<int>();
    for(dynamic favorito in favoritosQuery) {
      favoritos.add(favorito['himno_id']);
    }
    List<Map<String,dynamic>> descargasQuery = await db.rawQuery('select * from descargados');
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
    return null;
  }

  @override
  void dispose(){
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tema),
        actions: <Widget>[
          IconButton(
            onPressed: () async {
              await db.close();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (BuildContext context) => Buscador(id: widget.id, subtema:widget.subtema))
              );
            },
            icon: Icon(Icons.search),
          ),
        ],
      ),
      body: Scroller(
        himnos: himnos,
        cargando: cargando,
        initDB: initDB
      )
    );
  }
}