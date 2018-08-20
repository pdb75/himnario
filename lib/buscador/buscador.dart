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
  List<ListTile> himnos;
  bool cargando;
  Database db;

  @override
  void initState() {
    super.initState();
    cargando = true;
    himnos = List<ListTile>();
    initDB();
  }

  Future<Null> initDB() async {
    String databasesPath = await getDatabasesPath();
    String path = databasesPath + "/himnos.db";
    db = await openReadOnlyDatabase(path);
    List<Map<String,dynamic>> data = await db.rawQuery('select himnos.id, himnos.titulo from himnos order by himnos.id ASC');
    for (Map<String,dynamic> himno in data) {
      himnos.add(ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (BuildContext context) => HimnoPage(numero: himno['id'], titulo: himno['titulo'],)) );
        },
        title: Text("${himno['id']} - ${himno['titulo']}"),
      ));
    }
    setState(() {
      cargando = false;
    });
    return null;
  }

  Future<Null> fetchHimnos(String query) async {
    setState(() {
      cargando = true;
      himnos.clear();
    });
    List<Map<String,dynamic>> data = await db.rawQuery("select himnos.id, himnos.titulo from himnos join parrafos on parrafos.himno_id = himnos.id where himnos.id || ' ' || himnos.titulo like '%$query%' or parrafos.parrafo like '%$query%' group by himnos.id order by himnos.id ASC");
    himnos.clear();      
    for (Map<String,dynamic> himno in data) {
      String tile = "${himno['id']} - ${himno['titulo']}";
      if((tile.toLowerCase()).contains(query.toLowerCase())) {
        int indexQuery = (tile.toLowerCase()).indexOf(query.toLowerCase());
        String start = tile.substring(0, indexQuery);
        String bold = tile.substring(indexQuery, indexQuery+query.length);
        String end = tile.substring(indexQuery+query.length, tile.length);

        himnos.add(ListTile(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (BuildContext context) => HimnoPage(numero: himno['id'], titulo: himno['titulo'],)) );
          },
          title: RichText(
            text: TextSpan(
              children: <TextSpan>[
                TextSpan(
                  style: Theme.of(context).textTheme.subhead,
                  text: start
                ),
                TextSpan(
                  style: Theme.of(context).textTheme.title,
                  text: bold
                ),
                TextSpan(
                  style: Theme.of(context).textTheme.subhead,
                  text: end
                ),
              ]
            ),
          ),
        ));
      } else {
        String start;
        String bold;
        String end;
        List<Map<String,dynamic>> parrafos = await db.rawQuery("select parrafo from parrafos where himno_id = ${himno['id']}");
        for(Map<String,dynamic> parrafo in parrafos) {
          if((parrafo['parrafo'].toLowerCase()).contains(query.toLowerCase())) {
            int indexQuery = (parrafo['parrafo'].toLowerCase()).indexOf(query.toLowerCase());
            start = parrafo['parrafo'].substring(0, indexQuery);
            bold = parrafo['parrafo'].substring(indexQuery, indexQuery+query.length);
            end = parrafo['parrafo'].substring(indexQuery+query.length, parrafo['parrafo'].length);
            break;
          }
        }
        himnos.add(ListTile(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (BuildContext context) => HimnoPage(numero: himno['id'], titulo: himno['titulo'],)) );
          },
          title: Text(tile),
          subtitle: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: <TextSpan>[
                TextSpan(
                  style: Theme.of(context).textTheme.caption,
                  text: start
                ),
                TextSpan(
                  style: Theme.of(context).textTheme.body1,
                  text: bold
                ),
                TextSpan(
                  style: Theme.of(context).textTheme.caption,
                  text: end
                ),
              ]
            ),
          ),
        ));
      }
    }
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
          himnos[index]
      )
    );
  }
}