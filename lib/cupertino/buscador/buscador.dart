import 'package:Himnario/cupertino/models/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import 'package:scoped_model/scoped_model.dart';
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
    path = '';
    himnos = List<Himno>();
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
    print(widget.type);
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
    
    List<Map<String,dynamic>> data = await executeQuery("select himnos.id, himnos.titulo, himnos.transpose from himnos join parrafos on parrafos.himno_id = himnos.id where${widget.type == BuscadorType.Coros ? ' himnos.id > 517 and' : widget.type == BuscadorType.Himnos ? ' himnos.id <= 517 and' : ''} ($queryTitulo or $queryParrafo) group by himnos.id order by himnos.id ASC");
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
    final TemaModel tema = ScopedModel.of<TemaModel>(context);
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        actionsForegroundColor: tema.mainColorContrast,
        backgroundColor: tema.mainColor,
        middle: CupertinoTextField(
          autofocus: true,
          onChanged: fetchHimnos,
          cursorColor: Colors.black,
          style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
            fontFamily: ScopedModel.of<TemaModel>(context).font,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50.0),
            color: Colors.white
          ),
          suffix: cargando ? CupertinoActivityIndicator() : null,
        )
      ),
      child: widget.type == BuscadorType.Himnos ? ScopedModel<TemaModel>(
        model: tema,
        child: Scroller(
          cargando: cargando,
          himnos: himnos,
          buscador: true,
          initDB: initDB,
          iPhoneX: MediaQuery.of(context).size.width >= 812.0 || MediaQuery.of(context).size.height >= 812.0,
          mensaje: 'No se han encontrado coincidencias',
        ),
      ) : ScopedModel<TemaModel>(
        model: tema,
        child: CorosScroller(
          cargando: cargando,
          himnos: himnos,
          buscador: true,
          initDB: initDB,
          iPhoneX: MediaQuery.of(context).size.width >= 812.0 || MediaQuery.of(context).size.height >= 812.0,
          mensaje: 'No se han encontrado coincidencias',
        ),
      ),
    );
  }
}