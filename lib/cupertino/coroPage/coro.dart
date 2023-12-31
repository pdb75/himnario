import 'package:Himnario/cupertino/models/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:screen/screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import './components/bodyCoro.dart';
import '../models/himnos.dart';

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
  double initfontSizeProtrait;
  double initfontSizeLandscape;
  double initposition;
  bool descargado;
  int max;
  Database db;
  SharedPreferences prefs;

  // autoScroll Variables
  ScrollController scrollController;
  bool scrollMode;
  bool autoScroll;
  int autoScrollRate;

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
    initfontSizeProtrait = 16.0;
    initfontSizeLandscape = 16.0;
    fontController = AnimationController(vsync: this, duration: Duration(milliseconds: 500), lowerBound: 0.1, upperBound: 1.0)
      ..addListener(() => setState(() {}));
    estrofas = List<Parrafo>();
    getHimno();

    scrollController = ScrollController();
    autoScroll = false;
    scrollMode = false;
    autoScrollRate = 0;
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

    List<Map<String, dynamic>> parrafos = await db.rawQuery('select * from parrafos where himno_id = ${widget.numero}');
    estrofas = Parrafo.fromJson(parrafos);

    for (Parrafo parrafo in estrofas) {
      acordesDisponible = parrafo.acordes != null && parrafo.acordes.split('\n')[0] != '' && parrafo.acordes != '';
      if (acordesDisponible) {
        parrafo.acordes = Acordes.transpose(transpose, parrafo.acordes.split('\n')).join('\n');
      }
      for (String linea in parrafo.parrafo.split('\n')) {
        if (linea.length > max) max = linea.length;
      }
    }

    if (MediaQuery.of(context).orientation == Orientation.portrait) {
      initfontSizeProtrait = (MediaQuery.of(context).size.width - 30) / max + 8;
      initfontSizeLandscape = (MediaQuery.of(context).size.height - 30) / max + 8;
    } else {
      initfontSizeProtrait = (MediaQuery.of(context).size.height - 30) / max + 8;
      initfontSizeLandscape = (MediaQuery.of(context).size.width - 30) / max + 8;
    }

    List<Map<String, dynamic>> favoritosQuery = await db.rawQuery('select * from favoritos where himno_id = ${widget.numero}');
    List<Map<String, dynamic>> descargadoQuery = await db.rawQuery('select * from descargados where himno_id = ${widget.numero}');

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
    initDB().then((db) async {
      await db.transaction((action) async {
        if (favorito) {
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
    for (Parrafo parrafo in estrofas) parrafo.acordes = Acordes.transpose(value, parrafo.acordes.split('\n')).join('\n');
    initDB().then((db) async {
      await db.rawQuery('update himnos set transpose = ${transpose % 12} where id = ${widget.numero}');
      await db.close();
    });
    setState(() {});
  }

  void stopScroll() => scrollController.animateTo(scrollController.offset, curve: Curves.linear, duration: Duration(milliseconds: 1));

  @override
  Widget build(BuildContext context) {
    return Stack(children: <Widget>[
      CupertinoPageScaffold(
        backgroundColor: ScopedModel.of<TemaModel>(context).getScaffoldBackgroundColor(),
        navigationBar: CupertinoNavigationBar(
            actionsForegroundColor: ScopedModel.of<TemaModel>(context).getTabTextColor(),
            backgroundColor: ScopedModel.of<TemaModel>(context).getTabBackgroundColor(),
            middle: Text(
              widget.titulo,
              style: CupertinoTheme.of(context)
                  .textTheme
                  .textStyle
                  .copyWith(color: ScopedModel.of<TemaModel>(context).getTabTextColor(), fontFamily: ScopedModel.of<TemaModel>(context).font),
            ),
            trailing: prefs != null
                ? Transform.translate(
                    offset: Offset(20.0, 0.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        CupertinoButton(
                          onPressed: toggleFavorito,
                          padding: EdgeInsets.only(bottom: 2.0),
                          child: favorito
                              ? Icon(
                                  Icons.star,
                                  size: 30.0,
                                )
                              : Icon(
                                  Icons.star_border,
                                  size: 30.0,
                                ),
                        ),
                        CupertinoButton(
                          disabledColor: Colors.black.withOpacity(0.5),
                          onPressed: acordesDisponible
                              ? () {
                                  showCupertinoModalPopup(
                                      context: context,
                                      builder: (BuildContext context) => CupertinoActionSheet(
                                            // title: Text('Menu'),
                                            cancelButton: CupertinoActionSheetAction(
                                              isDestructiveAction: true,
                                              onPressed: () => Navigator.of(context).pop(),
                                              child: Text('Cancelar'),
                                            ),
                                            actions: <Widget>[
                                              CupertinoActionSheetAction(
                                                onPressed: () {
                                                  acordes = !acordes;
                                                  if (fontController.value == 1.0) {
                                                    fontController.animateTo(0.0, curve: Curves.fastOutSlowIn);
                                                    if (transposeMode) transposeMode = false;
                                                    if (scrollMode) {
                                                      stopScroll();
                                                      autoScroll = false;
                                                      scrollMode = false;
                                                    }
                                                    setState(() {});
                                                  } else
                                                    fontController.animateTo(1.0, curve: Curves.linearToEaseOut);
                                                  Navigator.of(context).pop();
                                                },
                                                child: Text((fontController.value == 1 ? 'Ocultar' : 'Mostrar') + ' Acordes',
                                                    style: TextStyle(
                                                        color: WidgetsBinding.instance.window.platformBrightness == Brightness.dark
                                                            ? Colors.white
                                                            : Colors.black)),
                                              ),
                                              CupertinoActionSheetAction(
                                                onPressed: () {
                                                  if (!transposeMode) if (fontController.value == 0.1)
                                                    fontController.animateTo(1.0, curve: Curves.linearToEaseOut);
                                                  if (scrollMode) {
                                                    stopScroll();
                                                    autoScroll = false;
                                                    scrollMode = false;
                                                  }
                                                  setState(() => transposeMode = !transposeMode);
                                                  Navigator.of(context).pop();
                                                },
                                                child: Text('Transponer',
                                                    style: TextStyle(
                                                        color: WidgetsBinding.instance.window.platformBrightness == Brightness.dark
                                                            ? Colors.white
                                                            : Colors.black)),
                                              ),
                                              CupertinoActionSheetAction(
                                                onPressed: () {
                                                  applyTranspose(-transpose);
                                                  Navigator.of(context).pop();
                                                },
                                                child: Text('Tono Original',
                                                    style: TextStyle(
                                                        color: WidgetsBinding.instance.window.platformBrightness == Brightness.dark
                                                            ? Colors.white
                                                            : Colors.black)),
                                              ),
                                              CupertinoActionSheetAction(
                                                onPressed: () {
                                                  String currentNotation = prefs.getString('notation') ?? 'latina';
                                                  prefs.setString('notation', currentNotation == 'latina' ? 'americana' : 'latina');
                                                  if (!transposeMode) if (fontController.value == 0.1)
                                                    fontController.animateTo(1.0, curve: Curves.linearToEaseOut);
                                                  setState(() {});
                                                  Navigator.of(context).pop();
                                                },
                                                child: Text(
                                                    'Notación ' +
                                                        (prefs.getString('notation') == null || prefs.getString('notation') == 'latina'
                                                            ? 'americana'
                                                            : 'latina'),
                                                    style: TextStyle(
                                                        color: WidgetsBinding.instance.window.platformBrightness == Brightness.dark
                                                            ? Colors.white
                                                            : Colors.black)),
                                              ),
                                              CupertinoActionSheetAction(
                                                onPressed: scrollController.position.maxScrollExtent > 0.0
                                                    ? () {
                                                        if (!scrollMode) if (fontController.value == 0.1)
                                                          fontController.animateTo(1.0, curve: Curves.linearToEaseOut);
                                                        if (transposeMode) {
                                                          transposeMode = false;
                                                        }
                                                        setState(() => scrollMode = !scrollMode);
                                                        Navigator.of(context).pop();
                                                      }
                                                    : () {},
                                                child: Text('Scroll Automático',
                                                    style: TextStyle(
                                                        color: WidgetsBinding.instance.window.platformBrightness == Brightness.dark
                                                            ? Colors.white
                                                            : Colors.black)),
                                              ),
                                            ],
                                          ));
                                }
                              : null,
                          padding: EdgeInsets.only(bottom: 2.0),
                          child: Icon(
                            Icons.more_vert,
                            size: 30.0,
                          ),
                        ),
                      ],
                    ),
                  )
                : null),
        child: prefs != null
            ? Stack(
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(bottom: transposeMode ? 40.0 : 0.0),
                    child: BodyCoro(
                      scrollController: scrollController,
                      stopScroll: () {
                        stopScroll();
                        setState(() => autoScroll = false);
                      },
                      alignment: prefs.getString('alignment'),
                      estrofas: estrofas,
                      initfontSizeProtrait: initfontSizeProtrait,
                      initfontSizeLandscape: initfontSizeLandscape,
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
                          boxShadow: <BoxShadow>[BoxShadow(blurRadius: 20.0, offset: Offset(0.0, 18.0))],
                          color: ScopedModel.of<TemaModel>(context).getScaffoldBackgroundColor()),
                      child: ButtonBar(
                        alignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          CupertinoButton(
                            padding: EdgeInsets.only(bottom: 4.0),
                            child: Row(
                              children: <Widget>[
                                Icon(
                                  Icons.arrow_drop_down,
                                  color: ScopedModel.of<TemaModel>(context).getTabTextColor(),
                                ),
                                Text(
                                  'Bajar Tono',
                                  style: DefaultTextStyle.of(context).style.copyWith(
                                      color: ScopedModel.of<TemaModel>(context).getTabTextColor(),
                                      fontFamily: ScopedModel.of<TemaModel>(context).font),
                                )
                              ],
                            ),
                            onPressed: () => applyTranspose(-1),
                          ),
                          CupertinoButton(
                            padding: EdgeInsets.only(bottom: 4.0),
                            child: Row(
                              children: <Widget>[
                                Icon(
                                  Icons.arrow_drop_up,
                                  color: ScopedModel.of<TemaModel>(context).getTabTextColor(),
                                ),
                                Text('Subir Tono',
                                    style: DefaultTextStyle.of(context).style.copyWith(
                                        color: ScopedModel.of<TemaModel>(context).getScaffoldTextColor(),
                                        fontFamily: ScopedModel.of<TemaModel>(context).font))
                              ],
                            ),
                            onPressed: () => applyTranspose(1),
                          ),
                          CupertinoButton(
                            padding: EdgeInsets.only(bottom: 4.0),
                            child: Text(
                              'Ok',
                              style: DefaultTextStyle.of(context).style.copyWith(
                                  color: ScopedModel.of<TemaModel>(context).getTabTextColor(), fontFamily: ScopedModel.of<TemaModel>(context).font),
                            ),
                            onPressed: () => setState(() => transposeMode = !transposeMode),
                          )
                        ],
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      curve: Curves.fastOutSlowIn,
                      height: scrollMode ? 60 : 0.0,
                      width: double.infinity,
                      decoration: BoxDecoration(
                          boxShadow: <BoxShadow>[BoxShadow(blurRadius: 20.0, offset: Offset(0.0, 18.0))],
                          color: ScopedModel.of<TemaModel>(context).getScaffoldBackgroundColor()),
                      child: ButtonBar(
                        alignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          FlatButton(
                            child: Icon(Icons.fast_rewind, color: ScopedModel.of<TemaModel>(context).getTabTextColor()),
                            onPressed: () {
                              autoScrollRate = autoScrollRate > 0 ? autoScrollRate - 1 : 0;
                              scrollController.animateTo(scrollController.position.maxScrollExtent,
                                  curve: Curves.linear,
                                  duration: Duration(
                                      seconds: ((scrollController.position.maxScrollExtent - scrollController.offset) / (5 + 5 * autoScrollRate))
                                          .floor()));
                              setState(() => autoScroll = true);
                            },
                          ),
                          FlatButton(
                            child: Row(
                              children: <Widget>[
                                Icon(
                                  autoScroll ? Icons.pause : Icons.play_arrow,
                                  color: ScopedModel.of<TemaModel>(context).getTabTextColor(),
                                ),
                                Text(
                                  '${autoScrollRate + 1}x',
                                  style: CupertinoTheme.of(context)
                                      .textTheme
                                      .textStyle
                                      .copyWith(color: ScopedModel.of<TemaModel>(context).getTabTextColor()),
                                ),
                              ],
                            ),
                            onPressed: () {
                              if (autoScroll) {
                                stopScroll();
                              } else {
                                scrollController.animateTo(scrollController.position.maxScrollExtent,
                                    curve: Curves.linear,
                                    duration: Duration(
                                        seconds: ((scrollController.position.maxScrollExtent - scrollController.offset) / (5 + 5 * autoScrollRate))
                                            .floor()));
                              }
                              setState(() => autoScroll = !autoScroll);
                            },
                          ),
                          FlatButton(
                            child: Icon(
                              Icons.fast_forward,
                              color: ScopedModel.of<TemaModel>(context).getTabTextColor(),
                            ),
                            onPressed: () {
                              ++autoScrollRate;
                              scrollController.animateTo(scrollController.position.maxScrollExtent,
                                  curve: Curves.linear,
                                  duration: Duration(
                                      seconds: ((scrollController.position.maxScrollExtent - scrollController.offset) / (5 + 5 * autoScrollRate))
                                          .floor()));
                              setState(() => autoScroll = true);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Container(),
      ),
    ]);
  }
}
