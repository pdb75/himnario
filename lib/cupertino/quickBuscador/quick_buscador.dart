import 'dart:async';

import 'package:Himnario/cupertino/models/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../models/himnos.dart';
import '../himnoPage/components/estructura_himno.dart';
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
  String path;

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
    CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        actionsForegroundColor: ScopedModel.of<TemaModel>(context).mainColorContrast,
        backgroundColor: ScopedModel.of<TemaModel>(context).mainColor,
        middle: Padding(
          padding: EdgeInsets.only(right: 0.0),
          child: CupertinoTextField(
            autofocus: true,
            keyboardType: TextInputType.number,
            cursorColor: Colors.black,
            style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
              fontFamily: ScopedModel.of<TemaModel>(context).font,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50.0),
              color: Colors.white
            ),
            suffix: Container(
              width: MediaQuery.of(context).size.width - 200,
              margin: EdgeInsets.only(right: 6.0),
              child: Text(
                himno.titulo ?? '',
                softWrap: false,
                textAlign: TextAlign.end,
                style: TextStyle(
                  color: CupertinoTheme.of(context).textTheme.textStyle.color,
                  fontFamily: ScopedModel.of<TemaModel>(context).font,
                  fontSize: 20.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            onSubmitted: himno.numero != -1 && himno.numero > 517 ? (String query) {
              setState(() => done = !done);
            } : null,
            onChanged: onChanged,
          ),
        )
      ),
      child: SafeArea(
        child: (!cargando ? 
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
          ) : himno.numero == -2 ? Center(
            child: Text(
              'Himno no encontrado', 
              textAlign: TextAlign.center,
              style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                fontFamily: ScopedModel.of<TemaModel>(context).font
              )
            ),
          ) 
        : Center(child: Text(
          'Ingrese el número del himno', 
          textAlign: TextAlign.center,
          style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
            fontFamily: ScopedModel.of<TemaModel>(context).font
          ),
          textScaleFactor: 1.5,
        ),) :
        Container())
      ),
    );
  }
}