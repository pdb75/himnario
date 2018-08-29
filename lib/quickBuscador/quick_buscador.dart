import 'dart:async';

import 'package:Himnario/himnoPage/components/estructura_himno.dart';
import 'package:Himnario/models/himnos.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../himnoPage/himno.dart';

class QuickBuscador extends StatefulWidget {
  @override
  _QuickBuscadorState createState() => _QuickBuscadorState();
}

class _QuickBuscadorState extends State<QuickBuscador> {
  bool done;
  bool cargando;
  Database db;
  Himno himno;
  List<Parrafo> estrofas;
  int max;
  double initfontSize;
  double fontSize;

  @override
  void initState() {
    super.initState();
    max = 0;
    initfontSize = 16.0;
    fontSize = initfontSize;
    done = false;
    cargando = true;
    estrofas = List<Parrafo>();
    himno = Himno(titulo: '', numero: -1);
    initDB();
  }

  Future<Null> initDB() async {
    String databasesPath = (await getApplicationDocumentsDirectory()).path;
    String path = databasesPath + "/himnos.db";
    db = await openDatabase(path);
    setState(() {
      cargando = false;
    });
    return null;
  }

  void onChanged(String query) async {
    if (query.isNotEmpty) {
      List<Map<String,dynamic>> himnoQuery = await db.rawQuery('select himnos.id, himnos.titulo from himnos where himnos.id = $query');
      if (himnoQuery.isEmpty)
        setState(() {
          estrofas = List<Parrafo>();
          himno = Himno(titulo: 'No Encontrado', numero: -1);
        });
      else {
        List<Map<String,dynamic>> parrafos = await db.rawQuery('select * from parrafos where himno_id = $query');
        for (Map<String,dynamic> parrafo in parrafos) {
          for (String linea in parrafo['parrafo'].split('\n')) {
            if (linea.length > max) max = linea.length;
          }
        }
        initfontSize = (MediaQuery.of(context).size.width - 30)/max + 8;
        fontSize = (MediaQuery.of(context).size.width - 30)/max + 8;
        setState(() {
          himno = Himno(titulo: himnoQuery[0]['titulo'], numero:himnoQuery[0]['id']);
          estrofas = Parrafo.fromJson(parrafos);
        });
      }
    } else setState(() {
        estrofas = List<Parrafo>();
        himno = Himno(titulo: 'No Encontrado', numero: -1);
      });
  }

  @override
  void dispose() async {
    super.dispose();
    await db.close();
  }

  @override
  Widget build(BuildContext context) {
    return done ? 
    HimnoPage(titulo: himno.titulo, numero: himno.numero) :
    Scaffold(
      appBar: AppBar(
        title: TextField(
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: Theme.of(context).canvasColor,
            suffixStyle: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Theme.of(context).accentColor,
              fontFamily: 'Roboto',
              fontSize: 20.0,
              fontWeight: FontWeight.w500,
            ),
            suffixText: himno.titulo ?? ''
          ),
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Theme.of(context).accentColor,
            fontFamily: 'Roboto',
            fontSize: 20.0,
            fontWeight: FontWeight.w500,
          ),
          onSubmitted: himno.numero != -1 ? (String query) {
              setState(() => done = !done);
            } : null,
          onChanged: onChanged,
        ),
        actions: <Widget>[
          IconButton(
            onPressed: himno.numero != -1 ? () {
              setState(() => done = !done);
            } : null,
            icon: Icon(Icons.check),
          )
        ],
      ),
      body: 
      (estrofas.isNotEmpty ? ListView.builder(
        itemCount: estrofas.length,
        itemBuilder: (BuildContext context, int index) =>
          (estrofas[index].coro ? 
          Coro(coro: estrofas[index].parrafo, fontSize: fontSize,) :
          Estrofa(numero: estrofas[index].orden, estrofa: estrofas[index].parrafo,fontSize: fontSize,))
      ) :
      Center(child: CircularProgressIndicator(),)),
    );
  }
}