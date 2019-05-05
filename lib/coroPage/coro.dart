import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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
  // AnimationController switchModeController;
  // AnimationController cancionDuracion;
  // StreamSubscription positionSubscription;
  // StreamSubscription completeSubscription;
  // List<AudioPlayer> audioVoces;
  // List<String> stringVoces;
  // int currentVoice;
  List<Parrafo> estrofas;
  // List<File> archivos;
  // bool modoVoces;
  // bool start;
  // double currentProgress;
  // Duration currentDuration;
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
  // int doneCount;
  Database db;
  // HttpClient cliente;
  SharedPreferences prefs;

  @override
  void initState() {
    print(widget.transpose);
    max = 0;
    transpose = widget.transpose;
    super.initState();
    Screen.keepOn(true);
    acordes = false;
    // cliente = HttpClient();
    descargado = false;
    cargando = true;
    transposeMode = false;
    // archivos = List<File>(5);
    // stringVoces = ['Soprano', 'Tenor', 'ContraAlto', 'Bajo', 'Todos'];
    // audioVoces = [AudioPlayer(),AudioPlayer(),AudioPlayer(),AudioPlayer(),AudioPlayer()];
    // modoVoces = false;
    // start = false;
    acordesDisponible = false;
    favorito = false;
    initfontSize = 16.0;
    fontController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
      lowerBound: 0.1,
      upperBound: 1.0
    )..addListener(() => setState(() {}));
    // currentDuration = Duration();
    // switchModeController = AnimationController(duration: Duration(milliseconds: 200), vsync: this);
    // switchMode = CurvedAnimation(parent: switchModeController, curve: Curves.easeInOut);
    // switchMode..addListener(() {
    //   setState(() {});
    // });
    // doneCount = 0;
    // currentVoice = 4;
    estrofas = List<Parrafo>();
    // currentProgress = 0.0;
    getHimno();
  }

  Future<Database> initDB() async {
    String databasesPath = (await getApplicationDocumentsDirectory()).path;
    String path = databasesPath + "/himnos.db";
    db = await openDatabase(path);
    return db;
  }

  // void deleteVocesFiles() async {
  //   String path = (await getApplicationDocumentsDirectory()).path;
  //   for (int i = 0; i < audioVoces.length; ++i) {
  //     try {File(path + '/${widget.numero}-${stringVoces[i]}.mp3').delete();}
  //     catch (e) {print(e);}
  //   }
  // }

  // Future<Null> initVocesDownloaded() async {
  //   setState(() {
  //     cargando = true;
  //     vozDisponible = true;
  //   });
  //   String path = (await getApplicationDocumentsDirectory()).path;
  //   if(cliente != null) 
  //     for (int i = 0; i < audioVoces.length; ++i) {
  //       int success = await audioVoces[i].setUrl(path + '/${widget.numero}-${stringVoces[i]}.mp3', isLocal: true);
  //       while(success != 1) {
  //         HttpClient cliente = HttpClient();
  //         HttpClientRequest request = await cliente.getUrl(Uri.parse('http://104.131.104.212:8085/himno/${widget.numero}/${stringVoces[i]}'));
  //         HttpClientResponse response = await request.close();
  //         Uint8List bytes = await consolidateHttpClientResponseBytes(response);
  //         File archivo = File(path + '/${widget.numero}-${stringVoces[i]}.mp3');
  //         await archivo.writeAsBytes(bytes);
  //         success = await audioVoces[i].setUrl(path + '/${widget.numero}-${stringVoces[i]}.mp3', isLocal: true);
  //       }
  //       await audioVoces[i].setReleaseMode(ReleaseMode.STOP);
  //     }
  //     positionSubscription = audioVoces[4].onAudioPositionChanged.listen((Duration duration) {
  //       setState(() {
  //         currentProgress = duration.inMilliseconds / totalDuration;
  //         currentDuration = duration;
  //       });
  //     });
  //     completeSubscription = audioVoces[4].onPlayerCompletion.listen((_) {
  //       setState(() {
  //         start = false;
  //         currentProgress = 0.0;
  //       });
  //     });
  //   if(cliente != null) {
  //     setState(() => cargando = false);
  //   } else if(archivos[0] == null && !descargado)
  //       deleteVocesFiles();
  //   return null;
  // }

  Future<Null> getHimno() async {
    prefs = await SharedPreferences.getInstance();
    String databasesPath = (await getApplicationDocumentsDirectory()).path;
    String path = databasesPath + "/himnos.db";
    db = await openDatabase(path);

    List<Map<String,dynamic>> parrafos = await db.rawQuery('select * from parrafos where himno_id = ${widget.numero}');
    estrofas = Parrafo.fromJson(parrafos);

    for (Parrafo parrafo in estrofas) {
      acordesDisponible = parrafo.acordes != null && parrafo.acordes != '';
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

    // if (descargadoQuery.isEmpty) {
    //   http.get('http://104.131.104.212:8085/himno/${widget.numero}/Soprano/disponible')
    //   .then((res) {
    //     if(res.body == 'si') {
    //       initVoces();
    //       setState(() => vozDisponible = true);
    //     }
    //     else
    //       setState(() => vozDisponible = false);
    //   });
    // } else initVocesDownloaded();
    await db.close();
    return null;
  }

  // Future<Null> initVoces() async {
  //   setState(() => cargando = true);
  //   String path = (await getApplicationDocumentsDirectory()).path;
  //   List<bool> done = [false, false, false, false, false];
  //   cliente.getUrl(Uri.parse('http://104.131.104.212:8085/himno/${widget.numero}/Soprano/duracion'))
  //     .then((request) => request.close())
  //     .then((response) => consolidateHttpClientResponseBytes(response))
  //     .then((bytes) async {
  //       totalDuration = (double.parse(Utf8Decoder().convert(bytes))*1000).ceil();
  //     });
  //   for(int i = 0; i < audioVoces.length; ++i) {
  //     cliente.getUrl(Uri.parse('http://104.131.104.212:8085/himno/${widget.numero}/${stringVoces[i]}'))
  //       .then((request) => request.close())
  //       .then((response) => consolidateHttpClientResponseBytes(response))
  //       .then((bytes) async {
  //         archivos[i] = File(path + '/${widget.numero}-${stringVoces[i]}.mp3');
  //         await archivos[i].writeAsBytes(bytes);
  //         done[i] = true;
  //         if (mounted)
  //           setState(() => ++doneCount);
  //       });
  //   }

  //   while(done.contains(false)) {
  //     await Future.delayed(Duration(milliseconds: 200));
  //   }

  //   if(cliente != null) 
  //     for (int i = 0; i < audioVoces.length; ++i) {
  //       int success = await audioVoces[i].setUrl(path + '/${widget.numero}-${stringVoces[i]}.mp3', isLocal: true);
  //       while(success != 1) {
  //         success = await audioVoces[i].setUrl(path + '/${widget.numero}-${stringVoces[i]}.mp3', isLocal: true);
  //       }
  //       await audioVoces[i].setReleaseMode(ReleaseMode.STOP);
  //     }
  //     positionSubscription = audioVoces[4].onAudioPositionChanged.listen((Duration duration) {
  //       setState(() {
  //         currentProgress = duration.inMilliseconds / totalDuration;
  //         currentDuration = duration;
  //       });
  //     });
  //     completeSubscription = audioVoces[4].onPlayerCompletion.listen((_) {
  //       setState(() {
  //         start = false;
  //         currentProgress = 0.0;
  //       });
  //     });

  //   if(cliente != null) {
  //     setState(() => cargando = false);
  //   } else {
  //     for (int i = 0; i < audioVoces.length; ++i) {
  //       audioVoces[i].release();
  //       if(archivos[i] != null && !descargado) 
  //         if(archivos[i].existsSync())
  //           archivos[i].deleteSync();
  //     }
  //   }
  //   return null;
  // }

  // void resumeVoces() {
  //   print(currentVoice);
  //   audioVoces[currentVoice].seek(Duration(milliseconds: (currentProgress * totalDuration).floor()));
  //   audioVoces[currentVoice].resume();
  //   setState(() => start = true);
  // }

  // void stopVoces() {
  //   setState(() {
  //     start = false;
  //     currentProgress = 0.0;
  //   });
  //   for (int i = 0; i < audioVoces.length; ++i) {
  //     audioVoces[i].pause();
  //     audioVoces[i].seek(Duration(milliseconds: 0));
  //   }
  // }

  @override
  void dispose() async {
    super.dispose();
    // switchModeController.dispose();
    Screen.keepOn(false);
    // cliente = null;
    // if(vozDisponible) {
    //   if(archivos[0] == null && !descargado)
    //     deleteVocesFiles();
    //   for (int i = 0; i < audioVoces.length; ++i) {
    //     audioVoces[i].release();
    //     if(archivos[i] != null && !descargado) 
    //       if(archivos[i].existsSync())
    //         archivos[i].deleteSync();
    //   }
    // }
  }

  // void pauseVoces() {
  //   setState(() => start = false);
  //   for (int i = 0; i < audioVoces.length; ++i) {
  //     audioVoces[i].pause();
  //   }
  // }

  // void vocesSeek(double progress) async {
  //   setState(() => currentProgress = progress);
  //   await audioVoces[currentVoice].pause();
  //   await audioVoces[currentVoice].seek(Duration(milliseconds: (progress * totalDuration).floor()));
  //   if (start)
  //     resumeVoces();
  // }

  // void swithModes() async {
  //   modoVoces = !modoVoces;
  //   if(switchMode.value == 1.0) {
  //     await switchModeController.reverse();
  //     setState(() {
  //       start = false;
  //       currentProgress = 0.0;
  //       audioVoces[currentVoice].stop();
  //       currentVoice = 4;
  //     });
  //   }
  //   else {
  //     await switchModeController.forward();
  //   }
  // }

  // void toggleVoice(int index) async {
  //   cancelSubscription();
  //   if (start) {
  //     await audioVoces[currentVoice].pause();
  //   }
  //   if (currentVoice == 4) {
  //     positionSubscription = audioVoces[index].onAudioPositionChanged.listen((Duration duration) {
  //       setState(() {
  //         currentProgress = duration.inMilliseconds / totalDuration;
  //         currentDuration = duration;
  //       });
  //     });
  //     completeSubscription = audioVoces[index].onPlayerCompletion.listen((_) {
  //       setState(() {
  //         start = false;
  //         currentProgress = 0.0;
  //       });
  //     });
  //   } else if (currentVoice == index) {
  //     positionSubscription = audioVoces[4].onAudioPositionChanged.listen((Duration duration) {
  //       setState(() {
  //         currentProgress = duration.inMilliseconds / totalDuration;
  //         currentDuration = duration;
  //       });
  //     });
  //     completeSubscription = audioVoces[4].onPlayerCompletion.listen((_) {
  //       setState(() {
  //         start = false;
  //         currentProgress = 0.0;
  //       });
  //     });
  //   } else {
  //     positionSubscription = audioVoces[index].onAudioPositionChanged.listen((Duration duration) {
  //       setState(() {
  //         currentProgress = duration.inMilliseconds / totalDuration;
  //         currentDuration = duration;
  //       });
  //     });
  //     completeSubscription = audioVoces[index].onPlayerCompletion.listen((_) {
  //       setState(() {
  //         start = false;
  //         currentProgress = 0.0;
  //       });
  //     });
  //   }
  //   currentVoice = currentVoice == index ? 4 : index;
  //   if (start) {
  //     resumeVoces();
  //   }
  //   setState(() {});
  // }

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
    // print(transpose%12);
    for (Parrafo parrafo in estrofas)
      parrafo.acordes = Acordes.transpose(value, parrafo.acordes.split('\n')).join('\n');
    initDB().then((db) async {
      await db.rawQuery('update himnos set transpose = ${transpose%12} where id = ${widget.numero}');
      await db.close();
    });
    setState(() {});
  }

  // void cancelSubscription() {
  //   positionSubscription.cancel();
  //   completeSubscription.cancel();
  // }

  // void toggleDescargado() {
  //   initDB()
  //     .then((db) async {
  //       await db.transaction((action) async {
  //         if(descargado) {
  //           await action.rawDelete('delete from descargados where himno_id = ${widget.numero}');
  //         } else {
  //           await action.rawInsert('insert into descargados values (${widget.numero}, $totalDuration)');
  //         }
  //       });
  //       await db.close();
  //       setState(() => descargado = !descargado);
  //     });
  // }

  @override
  Widget build(BuildContext context) {

    if(prefs != null)
    return Stack(
      children: <Widget>[
        CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            middle: Text(widget.titulo),
            trailing: Transform.translate(
              offset: Offset(20.0, 0.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  CupertinoButton(
                    onPressed: toggleFavorito,
                    padding: EdgeInsets.only(bottom: 4.0),
                    child: favorito ? Icon(Icons.star, size: 30.0,) : Icon(Icons.star_border, size: 30.0,),
                  ),
                  CupertinoButton(
                    onPressed: () {
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
                                Navigator.of(context).pop();
                              },
                              child: Text((fontController.value == 1 ? 'Ocultar' : 'Mostrar') + ' Acordes'),
                            ),
                            CupertinoActionSheetAction(
                              onPressed: () {
                                if (!transposeMode) 
                                  if (fontController.value == 0.1)
                                  fontController.animateTo(
                                    1.0,
                                    curve: Curves.linearToEaseOut
                                  );
                                setState(() => transposeMode = !transposeMode);
                                Navigator.of(context).pop();
                              },
                              child: Text('Transponer'),
                            ),
                            CupertinoActionSheetAction(
                              onPressed: () {
                                applyTranspose(-transpose);
                                Navigator.of(context).pop();
                              },
                              child: Text('Tono Original'),
                            ),
                          ],
                        )
                      );
                    },
                    padding: EdgeInsets.only(bottom: 4.0),
                    child: Icon(Icons.more_vert, size: 30.0,),
                  ),
                ],
              ),
            )
          ),
          // appBar: AppBar(
          //   actions: <Widget>[
          //     IconButton(
          //       onPressed: toggleFavorito,
          //       icon: favorito ? Icon(Icons.star,) : Icon(Icons.star_border,),
          //     ),
          //     PopupMenuButton(
          //       onSelected: (int e) {
          //         switch (e) {
          //           case 0:
          //             setState(() => acordes = !acordes);
          //             if (fontController.value == 1.0) {
          //               fontController.animateTo(
          //                 0.0,
          //                 curve: Curves.fastOutSlowIn
          //               );
          //               if (transposeMode)
          //                 setState(() => transposeMode = !transposeMode);
          //             }
          //             else fontController.animateTo(
          //               1.0,
          //               curve: Curves.linearToEaseOut
          //             );
          //             break;
          //           case 1:
          //             if (!transposeMode) 
          //               if (fontController.value == 0.1)
          //               fontController.animateTo(
          //                 1.0,
          //                 curve: Curves.linearToEaseOut
          //               );
          //             setState(() => transposeMode = !transposeMode);
          //             break;
          //           case 2:
          //             applyTranspose(-transpose);
          //             break;
          //           default:
          //         }

          //       },
          //       itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
          //         PopupMenuItem(
          //           value: 0,
          //           enabled: acordesDisponible,
          //           child: ListTile(
          //             leading: Icon(Icons.music_note),
          //             title: Text((fontController.value == 1 ? 'Ocultar' : 'Mostrar') + ' Acordes'),
          //           )
          //         ),
          //         PopupMenuItem(
          //           value: 1,
          //           enabled: acordesDisponible,
          //           child: ListTile(
          //             leading: Icon(Icons.unfold_more),
          //             title: Text('Transponer'),
          //           )
          //         ),
          //         PopupMenuItem(
          //           value: 2,
          //           enabled: acordesDisponible,
          //           child: ListTile(
          //             leading: Icon(Icons.undo),
          //             title: Text('Tono Original'),
          //           )
          //         ),
          //       ],
          //     )
          //   ],
          //   title: Tooltip(
          //     message: widget.titulo,
          //     child: Container(
          //       width: double.infinity,
          //       child: Text(widget.titulo),
          //     ),
          //   )
          // ),
          child: Stack(
            children: <Widget>[
              BodyCoro(
                alignment: prefs.getString('alignment'),
                estrofas: estrofas,
                initfontSize: initfontSize,
                acordes: acordes,
                animation: fontController.value,
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
                        offset: Offset(0.0, 18.0)
                      )
                    ],
                    color: Theme.of(context).scaffoldBackgroundColor
                  ),
                  child: ButtonBar(
                    alignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      CupertinoButton(
                        padding: EdgeInsets.only(bottom: 4.0),
                        child: Row(
                          children: <Widget>[
                            Icon(Icons.arrow_drop_down),
                            Text('Bajar Tono')
                          ],
                        ),
                        onPressed: () => applyTranspose(-1),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.only(bottom: 4.0),
                        child: Row(
                          children: <Widget>[
                            Icon(Icons.arrow_drop_up),
                            Text('Subir Tono')
                          ],
                        ),
                        onPressed: () => applyTranspose(1),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.only(bottom: 4.0),
                        child: Text('Ok'),
                        onPressed: () => setState(() => transposeMode = !transposeMode),
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
        // Positioned(
        //   right: 0.0,
        //   top: 68.0,
        //   child: Container(
        //     color: Theme.of(context).scaffoldBackgroundColor,
        //     child: Column(
        //       mainAxisSize: MainAxisSize.min,
        //       children: <Widget>[
        //         CupertinoButton(
        //           onPressed: () {
        //             setState(() => acordes = !acordes);
        //             if (fontController.value == 1.0) {
        //               fontController.animateTo(
        //                 0.0,
        //                 curve: Curves.fastOutSlowIn
        //               );
        //               if (transposeMode)
        //                 setState(() => transposeMode = !transposeMode);
        //             }
        //             else fontController.animateTo(
        //               1.0,
        //               curve: Curves.linearToEaseOut
        //             );
        //           },
        //           child: Row(
        //             children: [
        //               Icon(Icons.music_note),
        //               Text((fontController.value == 1 ? 'Ocultar' : 'Mostrar') + ' Acordes'),
        //             ]
        //           ),
        //         ),
        //         CupertinoButton(
        //           onPressed: () {
        //             if (!transposeMode) 
        //               if (fontController.value == 0.1)
        //               fontController.animateTo(
        //                 1.0,
        //                 curve: Curves.linearToEaseOut
        //               );
        //             setState(() => transposeMode = !transposeMode);
        //           },
        //           child: Row(
        //             children: [
        //               Icon(Icons.music_note),
        //               Text((fontController.value == 1 ? 'Ocultar' : 'Mostrar') + ' Acordes'),
        //             ]
        //           ),
        //         ),
        //         CupertinoButton(
        //           onPressed: () {},
        //           child: Row(
        //             children: [
        //               Icon(Icons.music_note),
        //               Text((fontController.value == 1 ? 'Ocultar' : 'Mostrar') + ' Acordes'),
        //             ]
        //           ),
        //         ),
        //       ],
        //     ),
        //   ),
        // )
      ]
    ); else return CupertinoPageScaffold(navigationBar: CupertinoNavigationBar(), child: Container(),);
    // return Scaffold(
    //   appBar: AppBar(
    //     actions: <Widget>[
    //       IconButton(
    //         onPressed: toggleFavorito,
    //         icon: favorito ? Icon(Icons.star,) : Icon(Icons.star_border,),
    //       ),
    //       PopupMenuButton(
    //         onSelected: (int e) {
    //           switch (e) {
    //             case 0:
    //               setState(() => acordes = !acordes);
    //               if (fontController.value == 1.0) {
    //                 fontController.animateTo(
    //                   0.0,
    //                   curve: Curves.fastOutSlowIn
    //                 );
    //                 if (transposeMode)
    //                   setState(() => transposeMode = !transposeMode);
    //               }
    //               else fontController.animateTo(
    //                 1.0,
    //                 curve: Curves.linearToEaseOut
    //               );
    //               break;
    //             case 1:
    //               if (!transposeMode) 
    //                 if (fontController.value == 0.1)
    //                 fontController.animateTo(
    //                   1.0,
    //                   curve: Curves.linearToEaseOut
    //                 );
    //               setState(() => transposeMode = !transposeMode);
    //               break;
    //             case 2:
    //               applyTranspose(-transpose);
    //               break;
    //             default:
    //           }

    //         },
    //         itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
    //           PopupMenuItem(
    //             value: 0,
    //             enabled: acordesDisponible,
    //             child: ListTile(
    //               leading: Icon(Icons.music_note),
    //               title: Text((fontController.value == 1 ? 'Ocultar' : 'Mostrar') + ' Acordes'),
    //             )
    //           ),
    //           PopupMenuItem(
    //             value: 1,
    //             enabled: acordesDisponible,
    //             child: ListTile(
    //               leading: Icon(Icons.unfold_more),
    //               title: Text('Transponer'),
    //             )
    //           ),
    //           PopupMenuItem(
    //             value: 2,
    //             enabled: acordesDisponible,
    //             child: ListTile(
    //               leading: Icon(Icons.undo),
    //               title: Text('Tono Original'),
    //             )
    //           ),
    //         ],
    //       )
    //     ],
    //     title: Tooltip(
    //       message: widget.titulo,
    //       child: Container(
    //         width: double.infinity,
    //         child: Text(widget.titulo),
    //       ),
    //     )
    //   ),
    //   body: Stack(
    //     children: <Widget>[
    //       BodyCoro(
    //         alignment: prefs.getString('alignment'),
    //         estrofas: estrofas,
    //         initfontSize: initfontSize,
    //         acordes: acordes,
    //         animation: fontController.value,
    //       ),
    //       Align(
    //         alignment: Alignment.bottomCenter,
    //         child: AnimatedContainer(
    //           duration: Duration(milliseconds: 200),
    //           curve: Curves.fastOutSlowIn,
    //           height: transposeMode ? 60 : 0.0,
    //           width: double.infinity,
    //           decoration: BoxDecoration(
    //             boxShadow: <BoxShadow>[
    //               BoxShadow(
    //                 blurRadius: 20.0,
    //                 offset: Offset(0.0, 18.0)
    //               )
    //             ],
    //             color: Theme.of(context).scaffoldBackgroundColor
    //           ),
    //           child: ButtonBar(
    //             alignment: MainAxisAlignment.spaceEvenly,
    //             children: <Widget>[
    //               FlatButton.icon(
    //                 icon: Icon(Icons.arrow_drop_down),
    //                 label: Text('Bajar Tono'),
    //                 onPressed: () => applyTranspose(-1),
    //               ),
    //               FlatButton.icon(
    //                 icon: Icon(Icons.arrow_drop_up),
    //                 label: Text('Subir Tono'),
    //                 onPressed: () => applyTranspose(1),
    //               ),
    //               OutlineButton(
    //                 child: Text('Ok'),
    //                 onPressed: () => setState(() => transposeMode = !transposeMode),
    //               )
    //             ],
    //           ),
    //         ),
    //       )
    //     ],
    //   ),
    // ); else return Scaffold(appBar: AppBar(),);
  }
}