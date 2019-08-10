import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:screen/screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import './components/bodyCoro.dart';
import '../models/himnos.dart';
import './components/boton_voz.dart';
import './components/estructura_Coro.dart';
import './components/slider.dart';

class CoroPage extends StatefulWidget {

  CoroPage({this.numero, this.titulo, this.transpose});
  
  final int numero;
  final String titulo;
  final int transpose;

  @override
  _CoroPageState createState() => _CoroPageState();
}

class _CoroPageState extends State<CoroPage> with SingleTickerProviderStateMixin {
  AnimationController fontController;
  List<Parrafo> estrofas;
  int transpose;
  int totalDuration;
  bool acordesDisponible;
  bool cargando;
  bool favorito;
  bool acordes;
  bool transposeMode;
  double initfontSize;
  double initposition;
  bool descargado;
  int max;
  Database db;
  SharedPreferences prefs;

  @override
  void initState() {
    print(widget.transpose);
    max = 0;
    transpose = widget.transpose;
    super.initState();
    Screen.keepOn(true);
    acordes = false;
    descargado = false;
    cargando = true;
    transposeMode = false;
    acordesDisponible = false;
    favorito = false;
    initfontSize = 16.0;
    fontController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
      lowerBound: 0.1,
      upperBound: 1.0
    )..addListener(() => setState(() {}));
    estrofas = List<Parrafo>();
    getHimno();
  }

  Future<Database> initDB() async {
    String databasesPath = (await getApplicationDocumentsDirectory()).path;
    String path = databasesPath + "/himnos.db";
    db = await openDatabase(path);
    return db;
  }

  Future<Null> getHimno() async {
    prefs = await SharedPreferences.getInstance();
    String databasesPath = (await getApplicationDocumentsDirectory()).path;
    String path = databasesPath + "/himnos.db";
    db = await openDatabase(path);

    List<Map<String,dynamic>> parrafos = await db.rawQuery('select * from parrafos where himno_id = ${widget.numero}');
    estrofas = Parrafo.fromJson(parrafos);

    for (Parrafo parrafo in estrofas) {
      acordesDisponible = parrafo.acordes != null && parrafo.acordes.split('\n')[0] != '' && parrafo.acordes != '';
      print(acordesDisponible);
      if (acordesDisponible) {
        parrafo.acordes = Acordes.transpose(transpose, parrafo.acordes.split('\n')).join('\n');
      }
      for (String linea in parrafo.parrafo.split('\n')) {
        if (linea.length > max) max = linea.length;
      }
    }
    initfontSize = (MediaQuery.of(context).size.width - 30)/max + 8;

    List<Map<String,dynamic>> favoritosQuery = await db.rawQuery('select * from favoritos where himno_id = ${widget.numero}');
    List<Map<String,dynamic>> descargadoQuery = await db.rawQuery('select * from descargados where himno_id = ${widget.numero}');

    setState(() {
      favorito = favoritosQuery.isNotEmpty;
      descargado = descargadoQuery.isNotEmpty;
      totalDuration = descargadoQuery.isNotEmpty ? descargadoQuery[0]['duracion'] : 0;
    });
    await db.close();
    return null;
  }

  @override
  void dispose() async {
    super.dispose();
    Screen.keepOn(false);
  }

  void toggleFavorito() {
    initDB()
      .then((db) async {
        await db.transaction((action) async {
          if(favorito) {
            await action.rawDelete('delete from favoritos where himno_id = ${widget.numero}');
          } else {
            await action.rawInsert('insert into favoritos values (${widget.numero})');
          }
        });
        await db.close();
        setState(() => favorito = !favorito);
      });
  }

  void applyTranspose(int value) async {
    transpose = transpose + value;
    for (Parrafo parrafo in estrofas) {
      parrafo.acordes = Acordes.transpose(value, parrafo.acordes.split('\n')).join('\n');
    }
    initDB().then((db) async {
      await db.rawQuery('update himnos set transpose = ${transpose%12} where id = ${widget.numero}');
      await db.close();
    });
    setState(() {});
  }
  @override
  Widget build(BuildContext context) {

    if(prefs != null)
    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          IconButton(
            onPressed: toggleFavorito,
            icon: favorito ? Icon(Icons.star,) : Icon(Icons.star_border,),
          ),
          PopupMenuButton(
            onSelected: (int e) {
              switch (e) {
                case 0:
                  setState(() => acordes = !acordes);
                  if (fontController.value == 1.0) {
                    fontController.animateTo(
                      0.0,
                      curve: Curves.fastOutSlowIn
                    );
                    if (transposeMode)
                      setState(() => transposeMode = !transposeMode);
                  }
                  else fontController.animateTo(
                    1.0,
                    curve: Curves.linearToEaseOut
                  );
                  break;
                case 1:
                  if (!transposeMode) 
                    if (fontController.value == 0.1)
                    fontController.animateTo(
                      1.0,
                      curve: Curves.linearToEaseOut
                    );
                  setState(() => transposeMode = !transposeMode);
                  break;
                case 2:
                  applyTranspose(-transpose);
                  break;
                case 3:
                  String currentNotation = prefs.getString('notation') ?? 'latina';
                  prefs.setString('notation', currentNotation == 'latina' ? 'americana' : 'latina');
                  if (!transposeMode) 
                    if (fontController.value == 0.1)
                    fontController.animateTo(
                      1.0,
                      curve: Curves.linearToEaseOut
                    );
                  setState(() {});
                  break;
                default:
              }

            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
              PopupMenuItem(
                value: 0,
                enabled: acordesDisponible,
                child: ListTile(
                  leading: Icon(Icons.music_note),
                  title: Text(
                    (fontController.value == 1 ? 'Ocultar' : 'Mostrar') + ' Acordes',
                    style: Theme.of(context).textTheme.subhead.copyWith(
                      color: acordesDisponible ? Theme.of(context).textTheme.subhead.color : Colors.grey
                    ),
                  ),
                )
              ),
              PopupMenuItem(
                value: 1,
                enabled: acordesDisponible,
                child: ListTile(
                  leading: Icon(Icons.unfold_more),
                  title: Text(
                    'Transponer', 
                    style: Theme.of(context).textTheme.subhead.copyWith(
                      color: acordesDisponible ? Theme.of(context).textTheme.subhead.color : Colors.grey
                    ),
                  ),
                )
              ),
              PopupMenuItem(
                value: 2,
                enabled: acordesDisponible,
                child: ListTile(
                  leading: Icon(Icons.undo),
                  title: Text(
                    'Tono Original',
                    style: Theme.of(context).textTheme.subhead.copyWith(
                      color: acordesDisponible ? Theme.of(context).textTheme.subhead.color : Colors.grey
                    ),
                  ),
                )
              ),
              PopupMenuItem(
                value: 3,
                enabled: acordesDisponible,
                child: ListTile(
                  leading: Image.asset(
                    'assets/notation.png',
                    color: acordesDisponible ? Colors.grey[600] : Colors.grey[300],
                    width: 20.0,
                  ),
                  title: Text(
                    'Notación ' + (prefs.getString('notation') == null || prefs.getString('notation') == 'latina' ? 'americana' : 'latina'),
                    style: Theme.of(context).textTheme.subhead.copyWith(
                      color: acordesDisponible ? Theme.of(context).textTheme.subhead.color : Colors.grey
                    ),
                  ),
                )
              ),
            ],
          )
        ],
        title: Tooltip(
          message: widget.titulo,
          child: Container(
            width: double.infinity,
            child: Text(widget.titulo),
          ),
        )
      ),
      body: Stack(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(bottom: transposeMode ? 40.0 : 0.0),
            child: BodyCoro(
              alignment: prefs.getString('alignment'),
              estrofas: estrofas,
              initfontSize: initfontSize,
              acordes: acordes,
              animation: fontController.value,
              notation: prefs.getString('notation') ?? 'latino',
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              curve: Curves.fastOutSlowIn,
              height: transposeMode ? 60 : 0.0,
              width: double.infinity,
              decoration: BoxDecoration(
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    blurRadius: 20.0,
                    // spreadRadius: 1.0,
                    offset: Offset(0.0, 18.0)
                  )
                ],
                color: Theme.of(context).scaffoldBackgroundColor
              ),
              child: ButtonBar(
                alignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  FlatButton.icon(
                    icon: Icon(Icons.arrow_drop_down),
                    label: Text('Bajar Tono'),
                    onPressed: () => applyTranspose(-1),
                  ),
                  FlatButton.icon(
                    icon: Icon(Icons.arrow_drop_up),
                    label: Text('Subir Tono'),
                    onPressed: () => applyTranspose(1),
                  ),
                  OutlineButton(
                    child: Text('Ok'),
                    onPressed: () => setState(() => transposeMode = !transposeMode),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    ); else return Scaffold(appBar: AppBar(),);
  }
}