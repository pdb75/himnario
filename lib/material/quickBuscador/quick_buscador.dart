import 'dart:async';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../himnoPage/components/estructura_himno.dart';
import '../models/himnos.dart';
import '../himnoPage/himno.dart';

class QuickBuscador extends StatefulWidget {
  @override
  _QuickBuscadorState createState() => _QuickBuscadorState();
}

class _QuickBuscadorState extends State<QuickBuscador> {
  bool done;
  bool cargando;
  String path;
  Database db;
  Himno himno;
  List<Parrafo> estrofas;
  int max;
  double fontSize;
  SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    path = '';
    max = 0;
    fontSize = 16.0;
    done = false;
    cargando = true;
    estrofas = List<Parrafo>();
    himno = Himno(titulo: 'Ingrese un número', numero: -1);
    initDB();
  }

  Future<Null> initDB() async {
    prefs = await SharedPreferences.getInstance();
    String databasesPath = (await getApplicationDocumentsDirectory()).path;
    path = databasesPath + "/himnos.db";
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
      List<Map<String,dynamic>> himnoQuery = await executeQuery('select himnos.id, himnos.titulo from himnos where himnos.id = $query');
      if (himnoQuery.isEmpty || int.parse(query) > 517)
        setState(() {
          estrofas = List<Parrafo>();
          himno = Himno(titulo: 'No Encontrado', numero: -2);
          cargando = false;
        });
      else {
        List<Map<String,dynamic>> parrafos = await executeQuery('select * from parrafos where himno_id = $query');
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
            suffix: Container(
              width: MediaQuery.of(context).size.width - 200,
              child: Text(
                himno.titulo ?? '',
                textAlign: TextAlign.end,
                style: TextStyle(
                  color: Theme.of(context).textTheme.title.color,
                  fontFamily: Theme.of(context).textTheme.title.fontFamily,
                  fontSize: 20.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          ),
          style: TextStyle(
            color: Theme.of(context).textTheme.title.color,
            fontFamily: Theme.of(context).textTheme.title.fontFamily,
            fontSize: 20.0,
            fontWeight: FontWeight.w500,
          ),
          onSubmitted: himno.numero != -1 && himno.numero > 517 ? (String query) {
              setState(() => done = !done);
            } : null,
          onChanged: onChanged,
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
        estrofas.isNotEmpty ? GestureDetector(
          onTap: () => setState(() => done = !done),
          child: Container(
            height: double.infinity,
            width: double.infinity,
            color: Colors.transparent,
            child: Column(
              children: <Widget>[
                HimnoText(
                  estrofas: estrofas,
                  fontSize: fontSize,
                  alignment: prefs.getString('alignment'),
                )
              ],
            ),
          ),
        ) : himno.numero == -2 ? Center(child: Text('Himno no encontrado', textAlign: TextAlign.center,),) 
      : Center(child: Text('Ingrese el número del himno', textAlign: TextAlign.center,
      textScaleFactor: 1.5,),) :
      Container()),
    );
  }
}