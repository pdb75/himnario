import 'dart:async';

import 'package:Himnario/himnoPage/components/estructura_himno.dart';
import 'package:Himnario/models/himnos.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  double fontSize;
  SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    max = 0;
    fontSize = 16.0;
    done = false;
    cargando = true;
    estrofas = List<Parrafo>();
    himno = Himno(titulo: '', numero: -1);
    initDB();
  }

  Future<Null> initDB() async {
    prefs = await SharedPreferences.getInstance();
    String databasesPath = (await getApplicationDocumentsDirectory()).path;
    String path = databasesPath + "/himnos.db";
    db = await openDatabase(path);
    setState(() {
      cargando = false;
    });
    return null;
  }

  void onChanged(String query) async {
    max = 0;
    setState(() => cargando = true);
    if (query.isNotEmpty) {
      List<Map<String,dynamic>> himnoQuery = await db.rawQuery('select himnos.id, himnos.titulo from himnos where himnos.id = $query');
      if (himnoQuery.isEmpty)
        setState(() {
          estrofas = List<Parrafo>();
          himno = Himno(titulo: 'No Encontrado', numero: -2);
          cargando = false;
        });
      else {
        List<Map<String,dynamic>> parrafos = await db.rawQuery('select * from parrafos where himno_id = $query');
        for (Map<String,dynamic> parrafo in parrafos) {
          for (String linea in parrafo['parrafo'].split('\n')) {
            if (linea.length > max) max = linea.length;
          }
        }
        setState(() {
          himno = Himno(titulo: himnoQuery[0]['titulo'], numero:himnoQuery[0]['id']);
          estrofas = Parrafo.fromJson(parrafos);
          cargando = false;
          fontSize = (MediaQuery.of(context).size.width - 30)/max + 8;
        });
      }
    } else setState(() {
        estrofas = List<Parrafo>();
        himno = Himno(titulo: 'Ingrese un número', numero: -1);
        cargando = false;
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
              fontFamily: Theme.of(context).textTheme.title.fontFamily,
              fontSize: 20.0,
              fontWeight: FontWeight.w500,
            ),
            suffixText: himno.titulo ?? ''
          ),
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Theme.of(context).accentColor,
            fontFamily: Theme.of(context).textTheme.title.fontFamily,
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
      (!cargando ? 
        estrofas.isNotEmpty ? ListView.builder(
        itemCount: 1,
        itemBuilder: (BuildContext context, int index) =>
          HimnoText(
            estrofas: estrofas,
            fontSize: fontSize,
            alignment: prefs.getString('alignment'),
          )
      ) : himno.numero == -2 ? Center(child: Text('Himno no encontrado', textAlign: TextAlign.center,),) 
      : Center(child: Text('Ingrese el número del himno', textAlign: TextAlign.center,),) :
      Center(child: CircularProgressIndicator(),)),
    );
  }
}