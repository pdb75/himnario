import 'package:Himnario/db/db.dart';
import 'package:Himnario/helpers/isAndroid.dart';
import 'package:Himnario/models/himnos.dart';
import 'package:Himnario/models/tema.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:scoped_model/scoped_model.dart';
import 'package:screen/screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import './components/bodyCoro.dart';

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
  List<Parrafo> estrofas = [];
  int transpose;
  int totalDuration;
  bool acordesDisponible = false;
  bool cargando = true;
  bool favorito = false;
  bool acordes = false;
  bool transposeMode = false;
  double initFontSizePortrait = 16.0;
  double initFontSizeLandscape = 16.0;
  bool descargado = false;
  int max = 0;
  SharedPreferences prefs;

  // autoScroll Variables
  ScrollController scrollController = ScrollController();
  bool scrollMode = false;
  bool autoScroll = false;
  int autoScrollRate = 0;

  @override
  void initState() {
    super.initState();

    print(widget.transpose);
    transpose = widget.transpose;

    fontController = AnimationController(vsync: this, duration: Duration(milliseconds: 500), lowerBound: 0.1, upperBound: 1.0)
      ..addListener(() => setState(() {}));

    getHimno();
    Screen.keepOn(true);
  }

  Future<Null> getHimno() async {
    prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> parrafos = await DB.rawQuery('select * from parrafos where himno_id = ${widget.numero}');
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

    if (MediaQuery.of(context).orientation == Orientation.portrait) {
      initFontSizePortrait = (MediaQuery.of(context).size.width - 30) / max + 8;
      initFontSizeLandscape = (MediaQuery.of(context).size.height - 30) / max + 8;
    } else {
      initFontSizePortrait = (MediaQuery.of(context).size.height - 30) / max + 8;
      initFontSizeLandscape = (MediaQuery.of(context).size.width - 30) / max + 8;
    }

    List<Map<String, dynamic>> favoritosQuery = await DB.rawQuery('select * from favoritos where himno_id = ${widget.numero}');
    List<Map<String, dynamic>> descargadoQuery = await DB.rawQuery('select * from descargados where himno_id = ${widget.numero}');

    setState(() {
      favorito = favoritosQuery.isNotEmpty;
      descargado = descargadoQuery.isNotEmpty;
      totalDuration = descargadoQuery.isNotEmpty ? descargadoQuery[0]['duracion'] : 0;
    });
    return null;
  }

  @override
  void dispose() async {
    super.dispose();
    Screen.keepOn(false);
  }

  void toggleFavorito() async {
    if (favorito) {
      await DB.rawDelete('delete from favoritos where himno_id = ${widget.numero}');
    } else {
      await DB.rawInsert('insert into favoritos values (${widget.numero})');
    }

    setState(() => favorito = !favorito);
  }

  void applyTranspose(int value) async {
    transpose = transpose + value;
    for (Parrafo parrafo in estrofas) {
      parrafo.acordes = Acordes.transpose(value, parrafo.acordes.split('\n')).join('\n');
    }

    await DB.rawQuery('update himnos set transpose = ${transpose % 12} where id = ${widget.numero}');

    setState(() {});
  }

  void stopScroll() => scrollController.animateTo(scrollController.offset, curve: Curves.linear, duration: Duration(milliseconds: 1));

  Widget materialLayout(BuildContext context) {
    if (prefs != null) {
      return Scaffold(
        appBar: AppBar(
            actions: <Widget>[
              IconButton(
                onPressed: toggleFavorito,
                icon: favorito
                    ? Icon(
                        Icons.star,
                      )
                    : Icon(
                        Icons.star_border,
                      ),
              ),
              PopupMenuButton(
                onSelected: (int e) {
                  switch (e) {
                    case 0:
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
                      break;
                    case 1:
                      if (!transposeMode) if (fontController.value == 0.1) fontController.animateTo(1.0, curve: Curves.linearToEaseOut);
                      if (scrollMode) {
                        stopScroll();
                        autoScroll = false;
                        scrollMode = false;
                      }
                      setState(() => transposeMode = !transposeMode);
                      break;
                    case 2:
                      applyTranspose(-transpose);
                      break;
                    case 3:
                      String currentNotation = prefs.getString('notation') ?? 'latina';
                      prefs.setString('notation', currentNotation == 'latina' ? 'americana' : 'latina');
                      if (!transposeMode) if (fontController.value == 0.1) fontController.animateTo(1.0, curve: Curves.linearToEaseOut);
                      setState(() {});
                      break;
                    case 4:
                      if (!scrollMode) if (fontController.value == 0.1) fontController.animateTo(1.0, curve: Curves.linearToEaseOut);
                      if (transposeMode) {
                        transposeMode = false;
                      }
                      setState(() => scrollMode = !scrollMode);
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
                          style: Theme.of(context)
                              .textTheme
                              .subhead
                              .copyWith(color: acordesDisponible ? Theme.of(context).textTheme.subhead.color : Colors.grey),
                        ),
                      )),
                  PopupMenuItem(
                      value: 1,
                      enabled: acordesDisponible,
                      child: ListTile(
                        leading: Icon(Icons.unfold_more),
                        title: Text(
                          'Transponer',
                          style: Theme.of(context)
                              .textTheme
                              .subhead
                              .copyWith(color: acordesDisponible ? Theme.of(context).textTheme.subhead.color : Colors.grey),
                        ),
                      )),
                  PopupMenuItem(
                      value: 2,
                      enabled: acordesDisponible,
                      child: ListTile(
                        leading: Icon(Icons.undo),
                        title: Text(
                          'Tono Original',
                          style: Theme.of(context)
                              .textTheme
                              .subhead
                              .copyWith(color: acordesDisponible ? Theme.of(context).textTheme.subhead.color : Colors.grey),
                        ),
                      )),
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
                          style: Theme.of(context)
                              .textTheme
                              .subhead
                              .copyWith(color: acordesDisponible ? Theme.of(context).textTheme.subhead.color : Colors.grey),
                        ),
                      )),
                  PopupMenuItem(
                      value: 4,
                      enabled: acordesDisponible && scrollController.position.maxScrollExtent > 0.0,
                      child: ListTile(
                        leading: Icon(Icons.expand_more),
                        title: Text(
                          'Scroll Automático',
                          style: Theme.of(context).textTheme.subhead.copyWith(
                              color: acordesDisponible && scrollController.position.maxScrollExtent > 0.0
                                  ? Theme.of(context).textTheme.subhead.color
                                  : Colors.grey),
                        ),
                      )),
                ],
              )
            ],
            title: Tooltip(
              message: widget.titulo,
              child: Container(
                width: double.infinity,
                child: Text(
                  widget.titulo,
                  textScaleFactor: 0.9,
                ),
              ),
            )),
        body: Stack(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(bottom: transposeMode || scrollMode ? 40.0 : 0.0),
              child: BodyCoro(
                scrollController: scrollController,
                stopScroll: () {
                  stopScroll();
                  setState(() => autoScroll = false);
                },
                alignment: prefs.getString('alignment'),
                estrofas: estrofas,
                initFontSizePortrait: initFontSizePortrait,
                initFontSizeLandscape: initFontSizeLandscape,
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
                decoration: BoxDecoration(boxShadow: <BoxShadow>[
                  BoxShadow(
                      blurRadius: 20.0,
                      // spreadRadius: 1.0,
                      offset: Offset(0.0, 18.0))
                ], color: Theme.of(context).scaffoldBackgroundColor),
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
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                curve: Curves.fastOutSlowIn,
                height: scrollMode ? 60 : 0.0,
                width: double.infinity,
                decoration: BoxDecoration(boxShadow: <BoxShadow>[
                  BoxShadow(
                      blurRadius: 20.0,
                      // spreadRadius: 1.0,
                      offset: Offset(0.0, 18.0))
                ], color: Theme.of(context).scaffoldBackgroundColor),
                child: ButtonBar(
                  alignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    FlatButton(
                      child: Icon(Icons.fast_rewind),
                      onPressed: () {
                        autoScrollRate = autoScrollRate > 0 ? autoScrollRate - 1 : 0;
                        scrollController.animateTo(scrollController.position.maxScrollExtent,
                            curve: Curves.linear,
                            duration: Duration(
                                seconds: ((scrollController.position.maxScrollExtent - scrollController.offset) / (5 + 5 * autoScrollRate)).floor()));
                        setState(() => autoScroll = true);
                      },
                    ),
                    FlatButton(
                      child: Row(
                        children: <Widget>[
                          Icon(autoScroll ? Icons.pause : Icons.play_arrow),
                          Text('${autoScrollRate + 1}x'),
                        ],
                      ),
                      onPressed: () {
                        if (autoScroll) {
                          stopScroll();
                        } else {
                          scrollController.animateTo(scrollController.position.maxScrollExtent,
                              curve: Curves.linear,
                              duration: Duration(
                                  seconds:
                                      ((scrollController.position.maxScrollExtent - scrollController.offset) / (5 + 5 * autoScrollRate)).floor()));
                        }
                        setState(() => autoScroll = !autoScroll);
                      },
                    ),
                    FlatButton(
                      child: Icon(Icons.fast_forward),
                      onPressed: () {
                        ++autoScrollRate;
                        scrollController.animateTo(scrollController.position.maxScrollExtent,
                            curve: Curves.linear,
                            duration: Duration(
                                seconds: ((scrollController.position.maxScrollExtent - scrollController.offset) / (5 + 5 * autoScrollRate)).floor()));
                        setState(() => autoScroll = true);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(),
      );
    }
  }

  Widget cupertinoLayout(BuildContext context) {
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
                      initFontSizePortrait: initFontSizePortrait,
                      initFontSizeLandscape: initFontSizeLandscape,
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

  @override
  Widget build(BuildContext context) {
    return isAndroid() ? materialLayout(context) : cupertinoLayout(context);
  }
}