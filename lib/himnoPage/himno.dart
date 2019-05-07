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

import './components/bodyHimno.dart';
import './components/boton_voz.dart';
import '../models/himnos.dart';
import './components/slider.dart';

class HimnoPage extends StatefulWidget {

  HimnoPage({this.numero, this.titulo});
  
  final int numero;
  final String titulo;

  @override
  _HimnoPageState createState() => _HimnoPageState();
}

class _HimnoPageState extends State<HimnoPage> with TickerProviderStateMixin {
  AnimationController switchModeController;
  AnimationController cancionDuracion;
  StreamSubscription positionSubscription;
  StreamSubscription completeSubscription;
  List<AudioPlayer> audioVoces;
  List<String> stringVoces;
  int currentVoice;
  List<Parrafo> estrofas;
  List<File> archivos;
  bool modoVoces;
  bool start;
  double currentProgress;
  Duration currentDuration;
  int totalDuration;
  bool vozDisponible;
  bool cargando;
  bool favorito;
  bool acordes;
  double initfontSize;
  double initposition;
  bool descargado;
  int max;
  int doneCount;
  Database db;
  HttpClient cliente;
  SharedPreferences prefs;

  @override
  void initState() {
    max = 0;
    super.initState();
    Screen.keepOn(true);
    acordes = false;
    cliente = HttpClient();
    descargado = false;
    cargando = true;
    archivos = List<File>(5);
    stringVoces = ['Soprano', 'Tenor', 'ContraAlto', 'Bajo', 'Todos'];
    audioVoces = [AudioPlayer(),AudioPlayer(),AudioPlayer(),AudioPlayer(),AudioPlayer()];
    modoVoces = false;
    start = false;
    vozDisponible = false;
    favorito = false;
    initfontSize = 16.0;
    currentDuration = Duration();
    switchModeController = AnimationController(
      duration: Duration(milliseconds: 200), 
      vsync: this
    )..addListener(() {
      setState(() {});
    });
    doneCount = 0;
    currentVoice = 4;
    estrofas = List<Parrafo>();
    currentProgress = 0.0;
    getHimno();
  }

  Future<Database> initDB() async {
    String databasesPath = (await getApplicationDocumentsDirectory()).path;
    String path = databasesPath + "/himnos.db";
    db = await openDatabase(path);
    return db;
  }

  void deleteVocesFiles() async {
    String path = (await getApplicationDocumentsDirectory()).path;
    for (int i = 0; i < audioVoces.length; ++i) {
      try {File(path + '/${widget.numero}-${stringVoces[i]}.mp3').delete();}
      catch (e) {print(e);}
    }
  }

  Future<Null> initVocesDownloaded() async {
    setState(() {
      cargando = true;
      vozDisponible = true;
    });
    String path = (await getApplicationDocumentsDirectory()).path;
    if(cliente != null) 
      for (int i = 0; i < audioVoces.length; ++i) {
        int success = await audioVoces[i].setUrl(path + '/${widget.numero}-${stringVoces[i]}.mp3', isLocal: true);
        while(success != 1) {
          HttpClient cliente = HttpClient();
          HttpClientRequest request = await cliente.getUrl(Uri.parse('http://104.131.104.212:8085/himno/${widget.numero}/${stringVoces[i]}'));
          HttpClientResponse response = await request.close();
          Uint8List bytes = await consolidateHttpClientResponseBytes(response);
          File archivo = File(path + '/${widget.numero}-${stringVoces[i]}.mp3');
          await archivo.writeAsBytes(bytes);
          success = await audioVoces[i].setUrl(path + '/${widget.numero}-${stringVoces[i]}.mp3', isLocal: true);
        }
        await audioVoces[i].setReleaseMode(ReleaseMode.STOP);
      }
      positionSubscription = audioVoces[4].onAudioPositionChanged.listen((Duration duration) {
        setState(() {
          currentProgress = duration.inMilliseconds / totalDuration;
          currentDuration = duration;
        });
      });
      completeSubscription = audioVoces[4].onPlayerCompletion.listen((_) {
        setState(() {
          start = false;
          currentProgress = 0.0;
        });
      });
    if(cliente != null) {
      setState(() => cargando = false);
    } else if(archivos[0] == null && !descargado)
        deleteVocesFiles();
    return null;
  }

  Future<Null> getHimno() async {
    prefs = await SharedPreferences.getInstance();
    String databasesPath = (await getApplicationDocumentsDirectory()).path;
    String path = databasesPath + "/himnos.db";
    db = await openDatabase(path);

    List<Map<String,dynamic>> parrafos = await db.rawQuery('select * from parrafos where himno_id = ${widget.numero}');

    for (Map<String,dynamic> parrafo in parrafos) {
      acordes = parrafo['acordes'] != null;
      for (String linea in parrafo['parrafo'].split('\n')) {
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
      estrofas = Parrafo.fromJson(parrafos);
    });

    if (descargadoQuery.isEmpty) {
      http.get('http://104.131.104.212:8085/himno/${widget.numero}/Soprano/disponible')
      .then((res) {
        if(res.body == 'si') {
          initVoces();
          setState(() => vozDisponible = true);
        }
        else
          setState(() => vozDisponible = false);
      });
    } else initVocesDownloaded();
    await db.close();
    return null;
  }

  Future<Null> initVoces() async {
    setState(() => cargando = true);
    String path = (await getApplicationDocumentsDirectory()).path;
    List<bool> done = [false, false, false, false, false];
    cliente.getUrl(Uri.parse('http://104.131.104.212:8085/himno/${widget.numero}/Soprano/duracion'))
      .then((request) => request.close())
      .then((response) => consolidateHttpClientResponseBytes(response))
      .then((bytes) async {
        totalDuration = (double.parse(Utf8Decoder().convert(bytes))*1000).ceil();
      });
    for(int i = 0; i < audioVoces.length; ++i) {
      cliente.getUrl(Uri.parse('http://104.131.104.212:8085/himno/${widget.numero}/${stringVoces[i]}'))
        .then((request) => request.close())
        .then((response) => consolidateHttpClientResponseBytes(response))
        .then((bytes) async {
          archivos[i] = File(path + '/${widget.numero}-${stringVoces[i]}.mp3');
          await archivos[i].writeAsBytes(bytes);
          done[i] = true;
          if (mounted)
            setState(() => ++doneCount);
        });
    }

    while(done.contains(false)) {
      await Future.delayed(Duration(milliseconds: 200));
    }

    if(cliente != null) 
      for (int i = 0; i < audioVoces.length; ++i) {
        int success = await audioVoces[i].setUrl(path + '/${widget.numero}-${stringVoces[i]}.mp3', isLocal: true);
        while(success != 1) {
          success = await audioVoces[i].setUrl(path + '/${widget.numero}-${stringVoces[i]}.mp3', isLocal: true);
        }
        await audioVoces[i].setReleaseMode(ReleaseMode.STOP);
      }
      positionSubscription = audioVoces[4].onAudioPositionChanged.listen((Duration duration) {
        setState(() {
          currentProgress = duration.inMilliseconds / totalDuration;
          currentDuration = duration;
        });
      });
      completeSubscription = audioVoces[4].onPlayerCompletion.listen((_) {
        setState(() {
          start = false;
          currentProgress = 0.0;
        });
      });

    if(cliente != null) {
      setState(() => cargando = false);
    } else {
      for (int i = 0; i < audioVoces.length; ++i) {
        audioVoces[i].release();
        if(archivos[i] != null && !descargado) 
          if(archivos[i].existsSync())
            archivos[i].deleteSync();
      }
    }
    return null;
  }

  void resumeVoces() {
    print(currentVoice);
    audioVoces[currentVoice].seek(Duration(milliseconds: (currentProgress * totalDuration).floor()));
    audioVoces[currentVoice].resume();
    setState(() => start = true);
  }

  void stopVoces() {
    setState(() {
      start = false;
      currentProgress = 0.0;
    });
    for (int i = 0; i < audioVoces.length; ++i) {
      audioVoces[i].pause();
      audioVoces[i].seek(Duration(milliseconds: 0));
    }
  }

  @override
  void dispose() async {
    super.dispose();
    switchModeController.dispose();
    Screen.keepOn(false);
    cliente = null;
    if(vozDisponible) {
      if(archivos[0] == null && !descargado)
        deleteVocesFiles();
      for (int i = 0; i < audioVoces.length; ++i) {
        audioVoces[i].release();
        if(archivos[i] != null && !descargado) 
          if(archivos[i].existsSync())
            archivos[i].deleteSync();
      }
    }
  }

  void pauseVoces() {
    setState(() => start = false);
    for (int i = 0; i < audioVoces.length; ++i) {
      audioVoces[i].pause();
    }
  }

  void vocesSeek(double progress) async {
    setState(() => currentProgress = progress);
    await audioVoces[currentVoice].pause();
    await audioVoces[currentVoice].seek(Duration(milliseconds: (progress * totalDuration).floor()));
    if (start)
      resumeVoces();
  }

  void swithModes() async {
    modoVoces = !modoVoces;
    if(switchModeController.value == 1.0) {
      await switchModeController.animateTo(
        0.0,
        curve: Curves.fastOutSlowIn
      );
      setState(() {
        start = false;
        currentProgress = 0.0;
        audioVoces[currentVoice].stop();
        currentVoice = 4;
      });
    }
    else {
      await switchModeController.animateTo(
        1.0,
        curve: Curves.fastOutSlowIn
      );
    }
  }

  void toggleVoice(int index) async {
    cancelSubscription();
    if (start) {
      await audioVoces[currentVoice].pause();
    }
    if (currentVoice == 4) {
      positionSubscription = audioVoces[index].onAudioPositionChanged.listen((Duration duration) {
        setState(() {
          currentProgress = duration.inMilliseconds / totalDuration;
          currentDuration = duration;
        });
      });
      completeSubscription = audioVoces[index].onPlayerCompletion.listen((_) {
        setState(() {
          start = false;
          currentProgress = 0.0;
        });
      });
    } else if (currentVoice == index) {
      positionSubscription = audioVoces[4].onAudioPositionChanged.listen((Duration duration) {
        setState(() {
          currentProgress = duration.inMilliseconds / totalDuration;
          currentDuration = duration;
        });
      });
      completeSubscription = audioVoces[4].onPlayerCompletion.listen((_) {
        setState(() {
          start = false;
          currentProgress = 0.0;
        });
      });
    } else {
      positionSubscription = audioVoces[index].onAudioPositionChanged.listen((Duration duration) {
        setState(() {
          currentProgress = duration.inMilliseconds / totalDuration;
          currentDuration = duration;
        });
      });
      completeSubscription = audioVoces[index].onPlayerCompletion.listen((_) {
        setState(() {
          start = false;
          currentProgress = 0.0;
        });
      });
    }
    currentVoice = currentVoice == index ? 4 : index;
    if (start) {
      resumeVoces();
    }
    setState(() {});
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

  void cancelSubscription() {
    positionSubscription.cancel();
    completeSubscription.cancel();
  }

  void toggleDescargado() {
    initDB()
      .then((db) async {
        await db.transaction((action) async {
          if(descargado) {
            await action.rawDelete('delete from descargados where himno_id = ${widget.numero}');
          } else {
            await action.rawInsert('insert into descargados values (${widget.numero}, $totalDuration)');
          }
        });
        await db.close();
        setState(() => descargado = !descargado);
      });
  }

  @override
  Widget build(BuildContext context) {

    bool smallDevice = true;

    List<Widget> controlesLayout = !smallDevice ? [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          BotonVoz(
            voz: 'Soprano',
            activo: currentVoice == 0 || currentVoice == 4,
            onPressed: () => toggleVoice(0),
          ),
          BotonVoz(
            voz: 'Tenor',
            activo: currentVoice == 1 || currentVoice == 4,
            onPressed: () => toggleVoice(1),
          ),
          BotonVoz(
            voz: 'Contra Alto',
            activo: currentVoice == 2 || currentVoice == 4,
            onPressed: () => toggleVoice(2),
          ),
          BotonVoz(
            voz: 'Bajo',
            activo: currentVoice == 3 || currentVoice == 4,
            onPressed: () => toggleVoice(3),
          ),
        ],
      )
    ] : [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          BotonVoz(
            voz: '   Soprano  ',
            activo: currentVoice == 0 || currentVoice == 4,
            onPressed: () => toggleVoice(0),
          ),
          BotonVoz(
            voz: '    Tenor    ',
            activo: currentVoice == 1 || currentVoice == 4,
            onPressed: () => toggleVoice(1),
          ),
        ],
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          BotonVoz(
            voz: 'Contra Alto',
            activo: currentVoice == 2 || currentVoice == 4,
            onPressed: () => toggleVoice(2),
          ),
          BotonVoz(
            voz: '     Bajo     ',
            activo: currentVoice == 3 || currentVoice == 4,
            onPressed: () => toggleVoice(3),
          ),
        ],
      ),
    ];

    List<Widget> buttonLayout = [
      VoicesProgressBar(
        currentProgress: currentProgress,
        duration: totalDuration,
        onDragStart: cancelSubscription,
        smalldevice: smallDevice,
        onSelected: (double progress) {
          positionSubscription = audioVoces[currentVoice].onAudioPositionChanged.listen((Duration duration) {
            setState(() {
              currentProgress = duration.inMilliseconds / totalDuration;
              currentDuration = duration;
            });
          });
          completeSubscription = audioVoces[currentVoice].onPlayerCompletion.listen((_) {
            setState(() {
              start = false;
              currentProgress = 0.0;
            });
          });
          print(progress);
          setState(() => currentProgress = progress);
          vocesSeek(progress);
        },
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          RawMaterialButton(
            shape: CircleBorder(),
            child: IconButton(
              onPressed: () {
                double newProgress = currentProgress - 0.1;
                if(newProgress <= 0.0)
                  vocesSeek(0.0);
                else vocesSeek(currentProgress - 0.1);
              },
              icon: Icon(
                Icons.fast_rewind,
                color: CupertinoTheme.of(context).textTheme.textStyle.color,
              ),
            ),
            onPressed: () {},
          ),
          start ? RawMaterialButton(
            shape: CircleBorder(),
            child: IconButton(
              onPressed: pauseVoces,
              icon: Icon(
                Icons.pause,
                color: CupertinoTheme.of(context).textTheme.textStyle.color,
              ),
            ),
            onPressed: () {},
          ) : 
          RawMaterialButton(
            shape: CircleBorder(),
            child: IconButton(
              onPressed: !cargando ? () {
                resumeVoces();
              } : null,
              icon: Icon(
                Icons.play_arrow,
                color: CupertinoTheme.of(context).textTheme.textStyle.color,
              ),
            ),
            onPressed: () {},
          ),
          RawMaterialButton(
            shape: CircleBorder(),
            child: IconButton(
              onPressed: () {
                double newProgress = currentProgress + 0.1;
                if(newProgress >= 1.0)
                  vocesSeek(1.0);
                else vocesSeek(currentProgress + 0.1);
              },
              icon: Icon(
                Icons.fast_forward,
                color: CupertinoTheme.of(context).textTheme.textStyle.color,
              )
            ),
            onPressed: () {},
          ),
        ]
      )
    ];

    for (Widget widget in buttonLayout)
      controlesLayout.add(widget);

    if(prefs != null)
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        transitionBetweenRoutes: true,
        middle: Text('${widget.numero} - ${widget.titulo}'),
        trailing: Transform.translate(
          offset: Offset(20.0, 0.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              CupertinoButton(
                onPressed: toggleFavorito,
                padding: EdgeInsets.only(bottom: 2.0),
                child: favorito ? Icon(Icons.star, size: 30.0,) : Icon(Icons.star_border, size: 30.0,),
              ),
              vozDisponible ? CupertinoButton(
                onPressed: () {
                  showCupertinoModalPopup(
                    context: context,
                    builder: (BuildContext context) => CupertinoActionSheet(
                      cancelButton: CupertinoActionSheetAction(
                        isDestructiveAction: true,
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Cancelar'),
                      ),
                      actions: <Widget>[
                        CupertinoActionSheetAction(
                          isDestructiveAction: descargado,
                          onPressed: () {
                            toggleDescargado();
                            Navigator.of(context).pop();
                          },
                          child: Text(descargado ? 'Eliminar' : 'Descargar'),
                        ),
                        CupertinoActionSheetAction(
                          onPressed: () {
                            swithModes();
                            Navigator.of(context).pop();
                          },
                          child: Text(modoVoces ? 'Ocultar Voces' : 'Mostrar Voces'),
                        ),
                      ],
                    )
                  );
                },
                padding: EdgeInsets.only(bottom: 2.0),
                child: Icon(Icons.more_vert, size: 30.0,),
              ) : Container(),
            ],
          ),
        )
      ),
      // appBar: AppBar(
      //   actions: <Widget>[
      //     vozDisponible ? IconButton(
      //       onPressed: toggleDescargado,
      //       icon: descargado ? Icon(Icons.delete,) : Icon(Icons.get_app,),
      //     ) : Container(),
      //     IconButton(
      //       onPressed: toggleFavorito,
      //       icon: favorito ? Icon(Icons.star,) : Icon(Icons.star_border,),
      //     ),
      //     // PopupMenuButton(
      //     //   onSelected: (dynamic value) {
      //     //     switch (value) {
      //     //       case 0:
      //     //         toggleDescargado();
      //     //         break;
      //     //       default:
      //     //     }
      //     //   },            
      //     //   icon: Icon(Icons.more_vert),
      //     //   itemBuilder: (BuildContext context) => <PopupMenuEntry>[
      //     //     PopupMenuItem(
      //     //       value: 0,
      //     //       enabled: vozDisponible,
      //     //       child: Row(
      //     //         mainAxisAlignment: MainAxisAlignment.spaceAround,
      //     //         children: <Widget>[
      //     //           descargado ? Icon(Icons.delete,) : Icon(Icons.get_app,),
      //     //           Text(descargado ? 'Eliminar' : 'Descargar')
      //     //         ],
      //     //       ),
      //     //     )
      //     //   ],
      //     // )
      //   ],
      //   title: Tooltip(
      //     message: '${widget.numero} - ${widget.titulo}',
      //     child: Container(
      //       width: double.infinity,
      //       child: Text('${widget.numero} - ${widget.titulo}'),
      //     ),
      //   ),
      //   bottom: PreferredSize(
      //     preferredSize: Size.fromHeight(4.0),
      //     child: Container()
      //   ),
      // ),
      child: Stack(
        children: <Widget>[
          BodyHimno(
            alignment: prefs.getString('alignment'),
            estrofas: estrofas,
            initfontSize: initfontSize,
          ),
          Align(
            alignment: FractionalOffset.bottomCenter,
            child: FractionalTranslation(
              translation: Offset(0.0, 1.0 - switchModeController.value),
              child: Card(
                margin: EdgeInsets.all(0.0),
                color: CupertinoTheme.of(context).scaffoldBackgroundColor,
                elevation: 10.0,
                child: !cargando ? Padding(
                  padding: EdgeInsets.symmetric(vertical: 5.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: controlesLayout
                  )
                ) : Container(
                  height: smallDevice ? 185.0 : 140.0,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.0),
                      child: CupertinoActivityIndicator(
                        animating: true,
                        radius: 20.0,
                      ),
                    ),
                  ),
                )
              ),
            )
          )
        ],
      ),
      // floatingActionButton: vozDisponible ? Padding(
      //   padding: EdgeInsets.only(bottom: smallDevice ? switchModeController.value * 175 : switchModeController.value * 130),
      //   child: FloatingActionButton(
      //     key: UniqueKey(),
      //     backgroundColor: modoVoces ? Colors.red : Theme.of(context).accentColor,
      //     onPressed: swithModes,
      //     child: Stack(
      //       children: <Widget>[
      //         Transform.scale(
      //           scale: 1.0 - switchModeController.value,
      //           child: Icon(Icons.play_arrow, size: 40.0),
      //         ),
      //         Transform.scale(
      //           scale: 0.0 + switchModeController.value,
      //           child: Icon(Icons.redo, size: 40.0),
      //         ),
      //       ],
      //     )
      //   )
      // ) : null
    ); else return CupertinoPageScaffold(child: Container(),);

    // bool smallDevice = MediaQuery.of(context).size.width < 400;

    // List<Widget> controlesLayout = !smallDevice ? [
    //   Row(
    //     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    //     children: <Widget>[
    //       BotonVoz(
    //         voz: 'Soprano',
    //         activo: currentVoice == 0 || currentVoice == 4,
    //         onPressed: () => toggleVoice(0),
    //       ),
    //       BotonVoz(
    //         voz: 'Tenor',
    //         activo: currentVoice == 1 || currentVoice == 4,
    //         onPressed: () => toggleVoice(1),
    //       ),
    //       BotonVoz(
    //         voz: 'Contra Alto',
    //         activo: currentVoice == 2 || currentVoice == 4,
    //         onPressed: () => toggleVoice(2),
    //       ),
    //       BotonVoz(
    //         voz: 'Bajo',
    //         activo: currentVoice == 3 || currentVoice == 4,
    //         onPressed: () => toggleVoice(3),
    //       ),
    //     ],
    //   )
    // ] : [
    //   Row(
    //     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    //     children: <Widget>[
    //       BotonVoz(
    //         voz: '   Soprano  ',
    //         activo: currentVoice == 0 || currentVoice == 4,
    //         onPressed: () => toggleVoice(0),
    //       ),
    //       BotonVoz(
    //         voz: '    Tenor    ',
    //         activo: currentVoice == 1 || currentVoice == 4,
    //         onPressed: () => toggleVoice(1),
    //       ),
    //     ],
    //   ),
    //   Row(
    //     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    //     children: <Widget>[
    //       BotonVoz(
    //         voz: 'Contra Alto',
    //         activo: currentVoice == 2 || currentVoice == 4,
    //         onPressed: () => toggleVoice(2),
    //       ),
    //       BotonVoz(
    //         voz: '     Bajo     ',
    //         activo: currentVoice == 3 || currentVoice == 4,
    //         onPressed: () => toggleVoice(3),
    //       ),
    //     ],
    //   ),
    // ];

    // List<Widget> buttonLayout = [
    //   VoicesProgressBar(
    //     currentProgress: currentProgress,
    //     duration: totalDuration,
    //     onDragStart: cancelSubscription,
    //     smalldevice: smallDevice,
    //     onSelected: (double progress) {
    //       positionSubscription = audioVoces[currentVoice].onAudioPositionChanged.listen((Duration duration) {
    //         setState(() {
    //           currentProgress = duration.inMilliseconds / totalDuration;
    //           currentDuration = duration;
    //         });
    //       });
    //       completeSubscription = audioVoces[currentVoice].onPlayerCompletion.listen((_) {
    //         setState(() {
    //           start = false;
    //           currentProgress = 0.0;
    //         });
    //       });
    //       print(progress);
    //       setState(() => currentProgress = progress);
    //       vocesSeek(progress);
    //     },
    //   ),
    //   Row(
    //     mainAxisAlignment: MainAxisAlignment.center,
    //     children: <Widget>[
    //       RawMaterialButton(
    //         shape: CircleBorder(),
    //         child: IconButton(
    //           onPressed: () {
    //             double newProgress = currentProgress - 0.1;
    //             if(newProgress <= 0.0)
    //               vocesSeek(0.0);
    //             else vocesSeek(currentProgress - 0.1);
    //           },
    //           icon: Icon(Icons.fast_rewind),
    //         ),
    //         onPressed: () {},
    //       ),
    //       start ? RawMaterialButton(
    //         shape: CircleBorder(),
    //         child: IconButton(
    //           onPressed: pauseVoces,
    //           icon: Icon(Icons.pause),
    //         ),
    //         onPressed: () {},
    //       ) : 
    //       RawMaterialButton(
    //         shape: CircleBorder(),
    //         child: IconButton(
    //           onPressed: !cargando ? () {
    //             resumeVoces();
    //           } : null,
    //           icon: Icon(Icons.play_arrow),
    //         ),
    //         onPressed: () {},
    //       ),
    //       RawMaterialButton(
    //         shape: CircleBorder(),
    //         child: IconButton(
    //           onPressed: () {
    //             double newProgress = currentProgress + 0.1;
    //             if(newProgress >= 1.0)
    //               vocesSeek(1.0);
    //             else vocesSeek(currentProgress + 0.1);
    //           },
    //           icon: Icon(Icons.fast_forward)
    //         ),
    //         onPressed: () {},
    //       ),
    //     ]
    //   )
    // ];

    // for (Widget widget in buttonLayout)
    //   controlesLayout.add(widget);

    // if(prefs != null)
    // return Scaffold(
    //   appBar: AppBar(
    //     actions: <Widget>[
    //       vozDisponible ? IconButton(
    //         onPressed: toggleDescargado,
    //         icon: descargado ? Icon(Icons.delete,) : Icon(Icons.get_app,),
    //       ) : Container(),
    //       IconButton(
    //         onPressed: toggleFavorito,
    //         icon: favorito ? Icon(Icons.star,) : Icon(Icons.star_border,),
    //       ),
    //       // PopupMenuButton(
    //       //   onSelected: (dynamic value) {
    //       //     switch (value) {
    //       //       case 0:
    //       //         toggleDescargado();
    //       //         break;
    //       //       default:
    //       //     }
    //       //   },            
    //       //   icon: Icon(Icons.more_vert),
    //       //   itemBuilder: (BuildContext context) => <PopupMenuEntry>[
    //       //     PopupMenuItem(
    //       //       value: 0,
    //       //       enabled: vozDisponible,
    //       //       child: Row(
    //       //         mainAxisAlignment: MainAxisAlignment.spaceAround,
    //       //         children: <Widget>[
    //       //           descargado ? Icon(Icons.delete,) : Icon(Icons.get_app,),
    //       //           Text(descargado ? 'Eliminar' : 'Descargar')
    //       //         ],
    //       //       ),
    //       //     )
    //       //   ],
    //       // )
    //     ],
    //     title: Tooltip(
    //       message: '${widget.numero} - ${widget.titulo}',
    //       child: Container(
    //         width: double.infinity,
    //         child: Text('${widget.numero} - ${widget.titulo}'),
    //       ),
    //     ),
    //     bottom: PreferredSize(
    //       preferredSize: Size.fromHeight(4.0),
    //       child: Container()
    //     ),
    //   ),
    //   body: Stack(
    //     children: <Widget>[
    //       BodyHimno(
    //         alignment: prefs.getString('alignment'),
    //         estrofas: estrofas,
    //         initfontSize: initfontSize,
    //       ),
    //       Align(
    //         alignment: FractionalOffset.bottomCenter,
    //         child: FractionalTranslation(
    //           translation: Offset(0.0, 1.0 - switchModeController.value),
    //           child: Card(
    //             margin: EdgeInsets.all(0.0),
    //             elevation: 10.0,
    //             child: !cargando ? Padding(
    //               padding: EdgeInsets.symmetric(vertical: 5.0),
    //               child: Column(
    //                 mainAxisAlignment: MainAxisAlignment.start,
    //                 mainAxisSize: MainAxisSize.min,
    //                 children: controlesLayout
    //               )
    //             ) : Container(
    //               height: smallDevice ? 185.0 : 140.0,
    //               child: Center(
    //                 child: Padding(
    //                   padding: EdgeInsets.symmetric(horizontal: 20.0),
    //                   child: LinearProgressIndicator(value: 0.25*doneCount,),
    //                 ),
    //               ),
    //             )
    //           ),
    //         )
    //       )
    //     ],
    //   ),
    //   floatingActionButton: vozDisponible ? Padding(
    //     padding: EdgeInsets.only(bottom: smallDevice ? switchModeController.value * 175 : switchModeController.value * 130),
    //     child: FloatingActionButton(
    //       key: UniqueKey(),
    //       backgroundColor: modoVoces ? Colors.red : Theme.of(context).accentColor,
    //       onPressed: swithModes,
    //       child: Stack(
    //         children: <Widget>[
    //           Transform.scale(
    //             scale: 1.0 - switchModeController.value,
    //             child: Icon(Icons.play_arrow, size: 40.0),
    //           ),
    //           Transform.scale(
    //             scale: 0.0 + switchModeController.value,
    //             child: Icon(Icons.redo, size: 40.0),
    //           ),
    //         ],
    //       )
    //     )
    //   ) : null
    // ); else return Scaffold(appBar: AppBar(),);
  }
}