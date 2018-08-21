import 'package:flutter/material.dart';
import 'dart:async';
import 'package:sqflite/sqflite.dart';

import '../models/himnos.dart';
import '../himnoPage/himno.dart';

class Buscador extends StatefulWidget {

  Buscador({this.id, this.subtema = false});

  final int id;
  final bool subtema;

  @override
  _BuscadorState createState() => _BuscadorState();
}

class _BuscadorState extends State<Buscador> {
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
    List<Map<String,dynamic>> data = await db.rawQuery('select himnos.id, himnos.titulo from himnos order by himnos.id ASC');
    setState(() {
      himnos = Himno.fromJson(data);
      cargando = false;
    });
    return null;
  }

  Future<Null> fetchHimnos(String query) async {
    setState(() => cargando = true);
    // List<Map<String,dynamic>> data = await db.rawQuery("select himnos.id, himnos.titulo from himnos where himnos.id || ' ' || himnos.titulo like '%$query%'");
    List<Map<String,dynamic>> data = await db.rawQuery("select himnos.id, himnos.titulo from himnos join parrafos on parrafos.himno_id = himnos.id where himnos.id || ' ' || himnos.titulo like '%$query%' or parrafos.parrafo like '%$query%' group by himnos.id order by himnos.id ASC");
    himnos = Himno.fromJson(data);
    setState(() => cargando = false);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          onChanged: fetchHimnos,
          decoration: InputDecoration(
            // border: OutlineInputBorder(
            //   borderRadius: BorderRadius.circular(10.0),
            // ),
            filled: true,
            fillColor: Theme.of(context).canvasColor
          ),
        ),
      ),
      body: cargando ? 
      Center(
        child: CircularProgressIndicator(),
      ) : 
      ListView.builder(
        itemCount: himnos.length,
        itemBuilder: (BuildContext context, int index) => 
        ListTile(
          onTap: () async {
            await db.close();
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (BuildContext context) => HimnoPage(numero: himnos[index].numero, titulo: himnos[index].titulo,)));
            Navigator.pop(context);
          },
          title: Text('${himnos[index].numero} - ${himnos[index].titulo}'),
        ),
      )
    );
  }
}