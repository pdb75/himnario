import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'package:sqflite/sqflite.dart';

import '../models/himnos.dart';
import '../components/scroller.dart';
import '../components/corosScroller.dart';

enum BuscadorType{
  Himnos,
  Coros,
  Todos
}

class Buscador extends StatefulWidget {

  Buscador({this.id, this.subtema = false, this.type = BuscadorType.Todos});

  final int id;
  final bool subtema;
  final BuscadorType type;

  @override
  _BuscadorState createState() => _BuscadorState();
}

class _BuscadorState extends State<Buscador> {
  List<Himno> himnos;
  bool cargando;
  String path;
  Database db; 

  @override
  void initState() {
    super.initState();
    cargando = true;
    himnos = List<Himno>();
    path = '';
    initDB();
  }

  Future<Null> initDB([bool refresh = true]) async {
    String databasesPath = (await getApplicationDocumentsDirectory()).path;
    path = databasesPath + "/himnos.db";
    db = await openReadOnlyDatabase(path);

    if (refresh) {
      List<Himno> himnostemp = List<Himno>();
      List<Map<String,dynamic>> data = await executeQuery('select himnos.id, himnos.titulo, himnos.transpose from himnos${widget.type == BuscadorType.Coros ? ' where id > 517' : widget.type == BuscadorType.Himnos ? ' where id <= 517' : ''} order by himnos.id ASC');
      List<Map<String,dynamic>> favoritosQuery = await executeQuery('select * from favoritos');
      List<int> favoritos = List<int>();

      for(dynamic favorito in favoritosQuery) {
        favoritos.add(favorito['himno_id']);
      }

      List<Map<String,dynamic>> descargasQuery = await executeQuery('select * from descargados');
      List<int> descargas = List<int>();

      for(dynamic descarga in descargasQuery) {
        descargas.add(descarga['himno_id']);
      }

      for(dynamic himno in data) {
        himnostemp.add(Himno(
          numero: himno['id'],
          titulo: himno['titulo'],
          transpose: himno['transpose'],
          descargado: descargas.contains(himno['id']),
          favorito: favoritos.contains(himno['id']),
        ));
      }
      
      setState(() {
        himnos = himnostemp;
        cargando = false;
      });
    }
    return null;
  }

  Future<Null> fetchHimnos(String query) async {
    setState(() => cargando = true);
    // print(widget.type);
    List<Himno> himnostemp = List<Himno>();
    String queryTitulo = '';
    String queryParrafo = '';
    List<String> palabras = query.split(' ');
    for (String palabra in palabras) {
      palabra = palabra.replaceAll('á', 'a');
      palabra = palabra.replaceAll('é', 'e');
      palabra = palabra.replaceAll('í', 'i');
      palabra = palabra.replaceAll('ó', 'o');
      palabra = palabra.replaceAll('ú', 'u');
      if(queryTitulo.isEmpty)
        queryTitulo += "REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(himnos.id || ' ' || himnos.titulo,'á','a'), 'é','e'),'í','i'),'ó','o'),'ú','u') like '%$palabra%'";
      else queryTitulo += " and REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(himnos.id || ' ' || himnos.titulo,'á','a'), 'é','e'),'í','i'),'ó','o'),'ú','u') like '%$palabra%'";

      if(queryParrafo.isEmpty)
        queryParrafo += " REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(parrafo,'á','a'), 'é','e'),'í','i'),'ó','o'),'ú','u') like '%$palabra%'";
      else queryParrafo += " and REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(parrafo,'á','a'), 'é','e'),'í','i'),'ó','o'),'ú','u') like '%$palabra%'";
    }
    
    List<Map<String,dynamic>> data = await db.rawQuery("select himnos.id, himnos.titulo, himnos.transpose from himnos join parrafos on parrafos.himno_id = himnos.id where${widget.type == BuscadorType.Coros ? ' himnos.id > 517 and' : widget.type == BuscadorType.Himnos ? ' himnos.id <= 517 and' : ''} ($queryTitulo or $queryParrafo) group by himnos.id order by himnos.id ASC");

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
      himnostemp.add(Himno(
        numero: himno['id'],
        titulo: himno['titulo'],
        transpose: himno['transpose'],
        descargado: descargas.contains(himno['id']),
        favorito: favoritos.contains(himno['id']),
      ));
    }
    himnos = himnostemp;
    setState(() => cargando = false);
    return null;
  }

  Future<List<Map<String, dynamic>>> executeQuery(String query) async {
    List<Map<String, dynamic>> result = List<Map<String, dynamic>>();
    try {
      if (!db.isOpen) {
        db = await openReadOnlyDatabase(path);
      }
      result = await db.rawQuery(query);
    } catch(e) {
      print(e);
    }
    return result;
  }

  @override
  void dispose() async {
    super.dispose();
    await db.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          onChanged: fetchHimnos,
          style: TextStyle(
            color: Theme.of(context).textTheme.title.color,
            fontFamily: Theme.of(context).textTheme.title.fontFamily,
            fontSize: 20.0,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Theme.of(context).canvasColor
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(4.0),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 100),
            curve: Curves.easeInOutSine,
            height: cargando ? 4.0 : 0.0,
            child: LinearProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryIconTheme.color == Colors.black ? Colors.black : Theme.of(context).primaryColor),
              backgroundColor: Colors.white,
            ),
          ),
        ),
      ),
      body: widget.type == BuscadorType.Himnos ? Scroller(
        cargando: cargando,
        himnos: himnos,
        buscador: true,
        initDB: initDB,
        mensaje: 'No se han encontrado coincidencias',
      ) : CorosScroller(
        cargando: cargando,
        himnos: himnos,
        initDB: initDB,
        buscador: true,
        mensaje: 'No se han encontrado coincidencias',
      )
    );
  }
}