import 'package:flutter/material.dart';
import 'dart:async';
import 'package:sqflite/sqflite.dart';

import '../models/himnos.dart';
import '../himnoPage/himno.dart';
import '../buscador/buscador.dart';

class TemaPage extends StatefulWidget {
  int id;
  bool subtema;
  String tema;

  TemaPage({this.id, this.subtema = false, this.tema});
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
    cargando = true;
    himnos = List<Himno>();
    initDB();
  }

  Future<Null> initDB() async {
    String databasesPath = await getDatabasesPath();
    String path = databasesPath + "/himnos.db";
    db = await openReadOnlyDatabase(path);

    await fetchHimnos();
    return null;
  }

  Future<Null> fetchHimnos() async {
    setState(() => cargando = true);
    if (widget.id == 0) {
      List<Map<String,dynamic>> data = await db.rawQuery('select himnos.id, himnos.titulo from himnos order by himnos.id ASC');
      himnos = Himno.fromJson(data);
    } else {
      List<Map<String,dynamic>> data;
      if(widget.subtema) {
        data = await db.rawQuery('select himnos.id, himnos.titulo from himnos join sub_tema_himnos on sub_tema_himnos.himno_id = himnos.id where sub_tema_himnos.sub_tema_id = ${widget.id} order by himnos.id ASC');
      } else {
        data = await db.rawQuery('select himnos.id, himnos.titulo from himnos join tema_himnos on himnos.id = tema_himnos.himno_id where tema_himnos.tema_id = ${widget.id} order by himnos.id ASC');
      }
      himnos = Himno.fromJson(data);
    }

    setState(() => cargando = false);
    return null;
  }

  @override
  void dispose(){
    super.dispose();
    db.close();
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
      body: cargando ? 
      Center(child: CircularProgressIndicator(),)
      : ListView.builder(
          itemCount: himnos.length,
          itemBuilder: (BuildContext context, int index) =>
            ListTile(
              onTap: () async {
                await db.close();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (BuildContext context) => HimnoPage(numero: himnos[index].numero, titulo: himnos[index].titulo,)) );
              },
              title: Text('${himnos[index].numero} - ${himnos[index].titulo}'),
            )
        ),
    );
  }
}