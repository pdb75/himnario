import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:Himnario/helpers/isAndroid.dart';
import 'package:Himnario/helpers/smallDevice.dart';
import 'package:Himnario/models/himnos.dart';
import 'package:Himnario/models/tema.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:scoped_model/scoped_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:screen/screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:photo_view/photo_view.dart';

import './components/bodyHimno.dart';
import 'components/botonVoz.dart';
import './components/slider.dart';

import 'package:Himnario/api/api.dart';

class HimnoPage extends StatefulWidget {
  final int numero;
  final String titulo;

  HimnoPage({this.numero, this.titulo});

  @override
  _HimnoPageState createState() => _HimnoPageState();
}

class _HimnoPageState extends State<HimnoPage> with SingleTickerProviderStateMixin {
  // Voices Variables
  AnimationController switchModeController;
  StreamSubscription positionSubscription;
  StreamSubscription completeSubscription;
  PhotoViewScaleStateController scaleController;
  List<AudioPlayer> audioVoces;
  List<String> stringVoces;
  int currentVoice;
  bool modoVoces;
  bool start;
  double currentProgress;
  Duration currentDuration;
  int totalDuration;
  bool vozDisponible;
  bool cargando;
  bool descargado;
  int max;
  int doneCount;
  HttpClient cliente;

  // Lyrics Variables
  List<Parrafo> estrofas;
  List<File> archivos;
  bool favorito;
  bool acordes;
  double initFontSizePortrait;
  double initFontSizeLandscape;
  double initposition;
  Database db;
  String tema;
  int temaId;
  String subTema;

  SharedPreferences prefs;

  // Sheet variables
  bool sheet;
  bool sheetReady;
  bool sheetAvailable;
  File sheetFile;
  PhotoViewController sheetController;
  Orientation currentOrientation;

  @override
  void initState() {
    max = 0;
    Screen.keepOn(true);
    acordes = false;
    cliente = HttpClient();
    descargado = false;
    cargando = true;
    archivos = List<File>(5);
    stringVoces = ['Soprano', 'Tenor', 'ContraAlto', 'Bajo', 'Todos'];
    audioVoces = [AudioPlayer(), AudioPlayer(), AudioPlayer(), AudioPlayer(), AudioPlayer()];
    modoVoces = false;
    start = false;
    vozDisponible = false;
    favorito = false;
    initFontSizePortrait = 16.0;
    initFontSizeLandscape = 16.0;
    currentDuration = Duration();
    switchModeController = AnimationController(duration: Duration(milliseconds: 200), vsync: this)
      ..addListener(() {
        setState(() {});
      });
    scaleController = PhotoViewScaleStateController()
      ..addIgnorableListener(() {
        if (scaleController.scaleState == PhotoViewScaleState.covering) {
          scaleController.scaleState = PhotoViewScaleState.originalSize;
        }
      });
    doneCount = 0;
    currentVoice = 4;
    estrofas = List<Parrafo>();
    currentProgress = 0.0;
    tema = subTema = '';
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(statusBarBrightness: Brightness.light, statusBarIconBrightness: Brightness.light));
    getHimno();

    // Sheet init
    sheet = false;
    sheetAvailable = false;
    sheetFile = File('/a.jpg');
    sheetController = PhotoViewController();
    sheetReady = false;

    super.initState();
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
      try {
        File aux = File(path + '/${widget.numero}-${stringVoces[i]}.mp3');
        if (aux.existsSync()) aux.delete();
      } catch (e) {
        print(e);
      }
    }
  }

  Future<Null> initVocesDownloaded() async {
    setState(() {
      cargando = true;
      vozDisponible = true;
    });

    String path = (await getApplicationDocumentsDirectory()).path;
    if (cliente != null && mounted)
      for (int i = 0; i < audioVoces.length; ++i) {
        int success = -1;

        if (File(path + '/${widget.numero}-${stringVoces[i]}.mp3').existsSync()) {
          success = await audioVoces[i].setUrl(path + '/${widget.numero}-${stringVoces[i]}.mp3', isLocal: true);
        }

        while (success != 1) {
          http.Response res = await http.get(VoicesApi.voiceAvailable(widget.numero));
          if (res.statusCode == 404) {
            return null;
          }
          HttpClient cliente = HttpClient();
          HttpClientRequest request = await cliente.getUrl(Uri.parse(VoicesApi.getVoice(widget.numero, stringVoces[i])));
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

    if (cliente != null && mounted) {
      setState(() => cargando = false);
    } else if (archivos[0] == null && !descargado) deleteVocesFiles();
    return null;
  }

  Future<Null> checkPartitura(String path) async {
    File aux = File(path + '/${widget.numero}.jpg');
    if (descargado || await aux.exists()) {
      if (await aux.exists()) {
        if (mounted) setState(() => sheetAvailable = true);
      } else {
        http.Response res = await http.get(SheetsApi.sheetAvailable(widget.numero));
        if (res.statusCode == 200) {
          if (mounted) setState(() => sheetAvailable = true);
          http.Response image = await http.get(SheetsApi.getSheet(widget.numero));
          await aux.writeAsBytes(image.bodyBytes);
        }
      }
    } else {
      http.Response res = await http.get(SheetsApi.sheetAvailable(widget.numero));
      print(res.statusCode);
      if (res.statusCode == 200) {
        if (mounted) setState(() => sheetAvailable = true);
        http.Response image = await http.get(SheetsApi.getSheet(widget.numero));
        await aux.writeAsBytes(image.bodyBytes);
      }
    }
    if (mounted)
      setState(() {
        sheetFile = aux;
        sheetReady = aux.existsSync();
      });
    return null;
  }

  Future<Null> getHimno() async {
    prefs = await SharedPreferences.getInstance();
    String databasesPath = (await getApplicationDocumentsDirectory()).path;
    String path = databasesPath + "/himnos.db";
    db = await openDatabase(path);

    List<Map<String, dynamic>> parrafos = await db.rawQuery('select * from parrafos where himno_id = ${widget.numero}');

    for (Map<String, dynamic> parrafo in parrafos) {
      acordes = parrafo['acordes'] != null;
      for (String linea in parrafo['parrafo'].split('\n')) {
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

    List<Map<String, dynamic>> favoritosQuery = await db.rawQuery('select * from favoritos where himno_id = ${widget.numero}');
    List<Map<String, dynamic>> descargadoQuery = await db.rawQuery('select * from descargados where himno_id = ${widget.numero}');
    // List<Map<String,dynamic>> temaQuery = await db.rawQuery('select temas.tema, temas.id from tema_himnos join temas on temas.id = tema_himnos.tema_id where tema_himnos.himno_id = ${widget.numero}');
    // List<dynamic> subTemaQuery = await db.rawQuery('select sub_temas.id, sub_temas.sub_tema from sub_tema_himnos join sub_temas on sub_temas.id = sub_tema_himnos.sub_tema_id where sub_tema_himnos.himno_id = ${widget.numero}');
    setState(() {
      favorito = favoritosQuery.isNotEmpty;
      descargado = descargadoQuery.isNotEmpty;
      totalDuration = descargadoQuery.isNotEmpty ? descargadoQuery[0]['duracion'] : 0;
      estrofas = Parrafo.fromJson(parrafos);
      // tema = temaQuery == null || temaQuery.isEmpty ? '' : temaQuery[0]['tema'];
      // subTema = subTemaQuery.isNotEmpty ? subTemaQuery[0]['sub_tema'] : '';
      // temaId = subTemaQuery.isNotEmpty ? subTemaQuery[0]['id'] : temaQuery[0]['id'];
      tema = '';
      subTema = '';
      temaId = 1;
    });

    if (descargadoQuery.isEmpty && mounted) {
      http.get(VoicesApi.voiceAvailable(widget.numero)).then((res) {
        if (res.statusCode == 200) {
          initVoces();
          setState(() => vozDisponible = true);
        } else
          setState(() => vozDisponible = false);
      }).catchError((onError) => print(onError));
    } else
      initVocesDownloaded();
    checkPartitura(databasesPath);
    await db.close();
    return null;
  }

  Future<Null> initVoces() async {
    setState(() => cargando = true);
    String path = (await getApplicationDocumentsDirectory()).path;
    List<bool> done = [false, false, false, false, false];
    cliente
        .getUrl(Uri.parse(VoicesApi.getVoiceDuration(widget.numero, 'Soprano')))
        .then((request) => request.close())
        .then((response) => consolidateHttpClientResponseBytes(response))
        .then((bytes) async {
      totalDuration = (double.parse(Utf8Decoder().convert(bytes)) * 1000).ceil();
    });
    for (int i = 0; i < audioVoces.length; ++i) {
      cliente
          .getUrl(Uri.parse(VoicesApi.getVoice(widget.numero, stringVoces[i])))
          .then((request) => request.close())
          .then((response) => consolidateHttpClientResponseBytes(response))
          .then((bytes) async {
        archivos[i] = File(path + '/${widget.numero}-${stringVoces[i]}.mp3');
        await archivos[i].writeAsBytes(bytes);
        done[i] = true;
        if (mounted) setState(() => ++doneCount);
      });
    }

    while (done.contains(false)) {
      await Future.delayed(Duration(milliseconds: 200));
    }

    if (cliente != null && mounted)
      for (int i = 0; i < audioVoces.length; ++i) {
        int success = await audioVoces[i].setUrl(path + '/${widget.numero}-${stringVoces[i]}.mp3', isLocal: true);
        while (success != 1) {
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

    if (cliente != null && mounted) {
      setState(() => cargando = false);
    } else {
      for (int i = 0; i < audioVoces.length; ++i) {
        audioVoces[i].release();
        if (archivos[i] != null && !descargado) if (archivos[i].existsSync()) archivos[i].deleteSync();
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
    sheetController.dispose();
    switchModeController.dispose();
    Screen.keepOn(false);
    cliente = null;
    if (vozDisponible) {
      if (archivos[0] == null && !descargado) deleteVocesFiles();
      if (sheetFile.existsSync() && !descargado) sheetFile.deleteSync();
      for (int i = 0; i < audioVoces.length; ++i) {
        audioVoces[i].release();
        if (archivos[i] != null && !descargado) if (archivos[i].existsSync()) archivos[i].deleteSync();
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
    if (start) resumeVoces();
  }

  void switchModes() async {
    modoVoces = !modoVoces;
    if (switchModeController.value == 1.0) {
      await switchModeController.animateTo(0.0, curve: Curves.fastOutSlowIn);
      setState(() {
        start = false;
        currentProgress = 0.0;
        audioVoces[currentVoice].stop();
        currentVoice = 4;
      });
    } else {
      await switchModeController.animateTo(1.0, curve: Curves.fastOutSlowIn);
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

  void cancelSubscription() {
    positionSubscription.cancel();
    completeSubscription.cancel();
  }

  void toggleDescargado() {
    initDB().then((db) async {
      await db.transaction((action) async {
        if (descargado) {
          await action.rawDelete('delete from descargados where himno_id = ${widget.numero}');
        } else {
          await action.rawInsert('insert into descargados values (${widget.numero}, $totalDuration)');
        }
      });
      await db.close();
      setState(() => descargado = !descargado);
    });
  }

  Widget materialLayout() {
    List<Widget> controlesLayout = !smallDevice(context)
        ? [
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
          ]
        : [
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
      Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
        RawMaterialButton(
          shape: CircleBorder(),
          child: IconButton(
            onPressed: () {
              double newProgress = currentProgress - 0.1;
              if (newProgress <= 0.0)
                vocesSeek(0.0);
              else
                vocesSeek(currentProgress - 0.1);
            },
            icon: Icon(Icons.fast_rewind),
          ),
          onPressed: () {},
        ),
        start
            ? RawMaterialButton(
                shape: CircleBorder(),
                child: IconButton(
                  onPressed: pauseVoces,
                  icon: Icon(Icons.pause),
                ),
                onPressed: () {},
              )
            : RawMaterialButton(
                shape: CircleBorder(),
                child: IconButton(
                  onPressed: !cargando
                      ? () {
                          resumeVoces();
                        }
                      : null,
                  icon: Icon(Icons.play_arrow),
                ),
                onPressed: () {},
              ),
        RawMaterialButton(
          shape: CircleBorder(),
          child: IconButton(
              onPressed: () {
                double newProgress = currentProgress + 0.1;
                if (newProgress >= 1.0)
                  vocesSeek(1.0);
                else
                  vocesSeek(currentProgress + 0.1);
              },
              icon: Icon(Icons.fast_forward)),
          onPressed: () {},
        ),
      ])
    ];

    for (Widget widget in buttonLayout) controlesLayout.add(widget);

    if (prefs != null)
      return Scaffold(
          appBar: AppBar(
            actions: <Widget>[
              vozDisponible || sheetAvailable
                  ? IconButton(
                      onPressed: toggleDescargado,
                      icon: descargado
                          ? Icon(
                              Icons.delete,
                            )
                          : Icon(
                              Icons.get_app,
                            ),
                    )
                  : Container(),

              // Activar modo partituras
              sheetAvailable
                  ? IconButton(
                      onPressed: () {
                        // Future.delayed(Duration(milliseconds: 500)).then((_) => sheetController.reset());
                        setState(() => sheet = !sheet);
                      },
                      icon: Icon(Icons.music_note),
                    )
                  : Container(),

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
            ],
            title: Tooltip(
              message: '${widget.numero} - ${widget.titulo}',
              child: Container(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.titulo}',
                      textScaleFactor: 0.9,
                    ),
                    Text(
                      '${widget.numero}',
                      textScaleFactor: 0.8,
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),
            bottom: PreferredSize(preferredSize: Size.fromHeight(4.0), child: Container()),
          ),
          body: Stack(
            children: <Widget>[
              BodyHimno(
                alignment: prefs.getString('alignment'),
                estrofas: estrofas,
                initFontSizePortrait: initFontSizePortrait,
                initFontSizeLandscape: initFontSizeLandscape,
                switchValue: switchModeController.value,
                tema: tema,
                subTema: subTema,
                temaId: temaId,
              ),

              // Partitura de Himno

              // IgnorePointer(
              //   child: AnimatedOpacity(
              //     duration: Duration(milliseconds: sheetDragging || sheetOutDragging ? 1 : 500),
              //     curve: Curves.easeInOutSine,
              //     opacity: sheet && sheetOutDragging ? draggingOut(0.8) : draggingIn(0.8),
              //     child: Container(
              //       color: Colors.black,
              //     ),
              //   ),
              // ),

              // GestureDetector(
              //   onHorizontalDragStart: (DragStartDetails details) {
              //     setState(() {
              //        sheetDragging = true;
              //        initSheetOffset = details.globalPosition.dx;
              //     });
              //   },
              //   onHorizontalDragUpdate: (DragUpdateDetails details) {
              //     setState(() {
              //       sheetOffset = (initSheetOffset - details.globalPosition.dx);
              //       sheet = details.delta.dx < -4;
              //     });
              //   },
              //   onHorizontalDragEnd: (DragEndDetails details) {
              //     setState(() {
              //        sheetDragging = false;
              //        sheet = sheet ? true : sheetOffset > MediaQuery.of(context).size.width/4;
              //        sheetOffset = 0.0;
              //        initSheetOffset = 0.0;
              //     });
              //   },
              //   child: Align(
              //     alignment: Alignment.centerRight,
              //     child: Container(
              //       height: double.infinity,
              //       width: MediaQuery.of(context).orientation == Orientation.portrait ? 40.0 : 50,
              //       color: Colors.transparent,
              //     ),
              //   ),
              // ),
              WillPopScope(
                onWillPop: () async {
                  bool goBack = true;
                  if (sheet) {
                    setState(() => sheet = !sheet);
                    goBack = false;
                  }
                  return goBack;
                },
                child: AnimatedContainer(
                    curve: sheet ? Curves.fastLinearToSlowEaseIn : Curves.fastOutSlowIn,
                    duration: Duration(milliseconds: sheet ? 500 : 1500),
                    transform: Matrix4.translationValues(sheet ? 0.0 : 5000, 0.0, 0.0),
                    height: MediaQuery.of(context).size.height - (modoVoces ? 200 : 0),
                    child: OrientationBuilder(
                      builder: (BuildContext context, Orientation orientation) {
                        if (currentOrientation == null) {
                          currentOrientation = orientation;
                        }
                        if (currentOrientation != orientation) {
                          currentOrientation = null;
                          sheetController = PhotoViewController();
                          sheet = false;
                        }
                        return currentOrientation == null
                            ? Container()
                            : !sheetReady
                                ? Container(
                                    width: double.infinity,
                                    height: double.infinity,
                                    color: Colors.white,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: <Widget>[
                                        CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                        ),
                                        SizedBox(
                                          height: 20.0,
                                        ),
                                        Text(
                                          descargado ? 'Cargando partitura' : 'Descargando partitura',
                                          style: TextStyle(
                                            color: Colors.black,
                                          ),
                                          textScaleFactor: 1.2,
                                        )
                                      ],
                                    ),
                                  )
                                : PhotoView(
                                    controller: sheetController,
                                    imageProvider: FileImage(sheetFile),
                                    basePosition: Alignment.topCenter,
                                    scaleStateController: scaleController,
                                    initialScale:
                                        orientation == Orientation.portrait ? PhotoViewComputedScale.contained : PhotoViewComputedScale.covered,
                                    loadingChild: Container(
                                      width: double.infinity,
                                      height: double.infinity,
                                      color: Colors.white,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: <Widget>[
                                          CircularProgressIndicator(
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                          ),
                                          SizedBox(
                                            height: 20.0,
                                          ),
                                          Text(
                                            descargado ? 'Cargando partitura' : 'Descargando partitura',
                                            style: TextStyle(
                                              color: Colors.black,
                                            ),
                                            textScaleFactor: 1.2,
                                          )
                                        ],
                                      ),
                                    ),
                                    backgroundDecoration: BoxDecoration(color: Colors.white));
                      },
                    )),
              ),
              // GestureDetector(
              //   onHorizontalDragStart: !sheet ? null : (DragStartDetails details) {
              //     setState(() {
              //        sheetOutDragging = true;
              //        initSheetOffset = details.globalPosition.dx;
              //     });
              //   },
              //   onHorizontalDragUpdate: (DragUpdateDetails details) {
              //     setState(() {
              //       sheetOffset = (details.globalPosition.dx - initSheetOffset);
              //       sheet = sheetOutDragging && details.delta.dx < 4;
              //     });
              //   },
              //   onHorizontalDragEnd: (DragEndDetails details) {
              //     setState(() {
              //        sheetOutDragging = false;
              //        sheet = !sheet ? false : sheetOffset < MediaQuery.of(context).size.width/4;
              //        sheetOffset = 0.0;
              //        initSheetOffset = 0.0;
              //        if (!sheet) {
              //          sheetController.reset();
              //        }
              //     });
              //   },
              //   child: Align(
              //     alignment: Alignment.centerLeft,
              //     child: Container(
              //       height: double.infinity,
              //       width: MediaQuery.of(context).orientation == Orientation.portrait ? 40.0 : 50,
              //       color: Colors.transparent,
              //     ),
              //   ),
              // ),

              Align(
                  alignment: FractionalOffset.bottomCenter,
                  child: FractionalTranslation(
                    translation: Offset(0.0, 1.0 - switchModeController.value),
                    child: Card(
                        margin: EdgeInsets.all(0.0),
                        elevation: 10.0,
                        child: !cargando
                            ? Padding(
                                padding: EdgeInsets.symmetric(vertical: 5.0),
                                child: Column(mainAxisAlignment: MainAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: controlesLayout))
                            : Container(
                                height: smallDevice(context) ? 185.0 : 140.0,
                                child: Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 20.0),
                                    child: LinearProgressIndicator(
                                        value: 0.25 * doneCount,
                                        backgroundColor: Colors.grey[400],
                                        valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryIconTheme.color == Colors.black
                                            ? Colors.black
                                            : Theme.of(context).primaryColor)),
                                  ),
                                ),
                              )),
                  ))
            ],
          ),
          floatingActionButton: vozDisponible
              ? Padding(
                  padding: EdgeInsets.only(bottom: smallDevice(context) ? switchModeController.value * 175 : switchModeController.value * 130),
                  child: FloatingActionButton(
                      key: UniqueKey(),
                      backgroundColor: modoVoces ? Colors.redAccent : Theme.of(context).accentColor,
                      onPressed: switchModes,
                      child: Stack(
                        children: <Widget>[
                          Transform.scale(
                            scale: 1.0 - switchModeController.value,
                            child: Icon(Icons.play_arrow, size: 40.0),
                          ),
                          Transform.scale(
                            scale: 0.0 + switchModeController.value,
                            child: Icon(Icons.redo, color: Colors.white, size: 40.0),
                          ),
                        ],
                      )))
              : null);
    else
      return Scaffold(
        appBar: AppBar(),
      );
  }

  Widget cupertinoLayout() {
    List<Widget> controlesLayout = !smallDevice(context)
        ? [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                BotonVoz(
                  voz: 'Soprano',
                  activo: currentVoice == 0 || currentVoice == 4,
                  onPressed: () => toggleVoice(0),
                  mainColor: ScopedModel.of<TemaModel>(context).getAccentColor(),
                  mainColorContrast: ScopedModel.of<TemaModel>(context).getAccentColorText(),
                ),
                BotonVoz(
                  voz: 'Tenor',
                  activo: currentVoice == 1 || currentVoice == 4,
                  onPressed: () => toggleVoice(1),
                  mainColor: ScopedModel.of<TemaModel>(context).getAccentColor(),
                  mainColorContrast: ScopedModel.of<TemaModel>(context).getAccentColorText(),
                ),
                BotonVoz(
                  voz: 'Contra Alto',
                  activo: currentVoice == 2 || currentVoice == 4,
                  onPressed: () => toggleVoice(2),
                  mainColor: ScopedModel.of<TemaModel>(context).getAccentColor(),
                  mainColorContrast: ScopedModel.of<TemaModel>(context).getAccentColorText(),
                ),
                BotonVoz(
                  voz: 'Bajo',
                  activo: currentVoice == 3 || currentVoice == 4,
                  onPressed: () => toggleVoice(3),
                  mainColor: ScopedModel.of<TemaModel>(context).getAccentColor(),
                  mainColorContrast: ScopedModel.of<TemaModel>(context).getAccentColorText(),
                ),
              ],
            )
          ]
        : [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                BotonVoz(
                  voz: '   Soprano  ',
                  activo: currentVoice == 0 || currentVoice == 4,
                  onPressed: () => toggleVoice(0),
                  mainColor: ScopedModel.of<TemaModel>(context).getAccentColor(),
                  mainColorContrast: ScopedModel.of<TemaModel>(context).getAccentColorText(),
                ),
                BotonVoz(
                  voz: '    Tenor    ',
                  activo: currentVoice == 1 || currentVoice == 4,
                  onPressed: () => toggleVoice(1),
                  mainColor: ScopedModel.of<TemaModel>(context).getAccentColor(),
                  mainColorContrast: ScopedModel.of<TemaModel>(context).getAccentColorText(),
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
                  mainColor: ScopedModel.of<TemaModel>(context).getAccentColor(),
                  mainColorContrast: ScopedModel.of<TemaModel>(context).getAccentColorText(),
                ),
                BotonVoz(
                  voz: '     Bajo     ',
                  activo: currentVoice == 3 || currentVoice == 4,
                  onPressed: () => toggleVoice(3),
                  mainColor: ScopedModel.of<TemaModel>(context).getAccentColor(),
                  mainColorContrast: ScopedModel.of<TemaModel>(context).getAccentColorText(),
                ),
              ],
            ),
          ];

    List<Widget> buttonLayout = [
      VoicesProgressBar(
        brightness: ScopedModel.of<TemaModel>(context).brightness,
        currentProgress: currentProgress,
        duration: totalDuration,
        onDragStart: cancelSubscription,
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
      Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
        RawMaterialButton(
          shape: CircleBorder(),
          child: IconButton(
            onPressed: () {
              double newProgress = currentProgress - 0.1;
              if (newProgress <= 0.0)
                vocesSeek(0.0);
              else
                vocesSeek(currentProgress - 0.1);
            },
            icon: Icon(
              Icons.fast_rewind,
              color: ScopedModel.of<TemaModel>(context).getScaffoldTextColor(),
            ),
          ),
          onPressed: () {},
        ),
        start
            ? RawMaterialButton(
                shape: CircleBorder(),
                child: IconButton(
                  onPressed: pauseVoces,
                  icon: Icon(
                    Icons.pause,
                    color: ScopedModel.of<TemaModel>(context).getScaffoldTextColor(),
                  ),
                ),
                onPressed: () {},
              )
            : RawMaterialButton(
                shape: CircleBorder(),
                child: IconButton(
                  onPressed: !cargando
                      ? () {
                          resumeVoces();
                        }
                      : null,
                  icon: Icon(
                    Icons.play_arrow,
                    color: ScopedModel.of<TemaModel>(context).getScaffoldTextColor(),
                  ),
                ),
                onPressed: () {},
              ),
        RawMaterialButton(
          shape: CircleBorder(),
          child: IconButton(
              onPressed: () {
                double newProgress = currentProgress + 0.1;
                if (newProgress >= 1.0)
                  vocesSeek(1.0);
                else
                  vocesSeek(currentProgress + 0.1);
              },
              icon: Icon(
                Icons.fast_forward,
                color: ScopedModel.of<TemaModel>(context).getScaffoldTextColor(),
              )),
          onPressed: () {},
        ),
      ])
    ];

    for (Widget widget in buttonLayout) controlesLayout.add(widget);

    List<Widget> modalButtons = [
      CupertinoActionSheetAction(
        isDestructiveAction: descargado,
        onPressed: () {
          toggleDescargado();
          Navigator.of(context).pop();
        },
        child: Text(descargado ? 'Eliminar' : 'Descargar',
            style: TextStyle(color: WidgetsBinding.instance.window.platformBrightness == Brightness.dark ? Colors.white : Colors.black)),
      ),
    ];

    if (vozDisponible) {
      modalButtons.add(CupertinoActionSheetAction(
        onPressed: () {
          switchModes();
          Navigator.of(context).pop();
        },
        child: Text(modoVoces ? 'Ocultar Voces' : 'Mostrar Voces',
            style: TextStyle(color: WidgetsBinding.instance.window.platformBrightness == Brightness.dark ? Colors.white : Colors.black)),
      ));
    }

    if (sheetAvailable) {
      modalButtons.add(CupertinoActionSheetAction(
        onPressed: () {
          Future.delayed(Duration(milliseconds: 500)).then((_) => sheetController.reset());
          setState(() => sheet = !sheet);
          Navigator.of(context).pop();
        },
        child: Text(sheet ? 'Ocultar Partitura' : 'Mostrar Partitura',
            style: TextStyle(color: WidgetsBinding.instance.window.platformBrightness == Brightness.dark ? Colors.white : Colors.black)),
      ));
    }

    return CupertinoPageScaffold(
      backgroundColor: ScopedModel.of<TemaModel>(context).getScaffoldBackgroundColor(),
      navigationBar: CupertinoNavigationBar(
          transitionBetweenRoutes: true,
          actionsForegroundColor: ScopedModel.of<TemaModel>(context).getTabTextColor(),
          backgroundColor: ScopedModel.of<TemaModel>(context).getTabBackgroundColor(),
          middle: Text(
            '${widget.numero} - ${widget.titulo}',
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
                        onPressed: vozDisponible || sheetAvailable
                            ? () {
                                showCupertinoModalPopup(
                                    context: context,
                                    builder: (BuildContext context) => CupertinoActionSheet(
                                          cancelButton: CupertinoActionSheetAction(
                                            isDestructiveAction: true,
                                            onPressed: () => Navigator.of(context).pop(),
                                            child: Text('Cancelar'),
                                          ),
                                          actions: modalButtons,
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
                  padding: EdgeInsets.only(bottom: switchModeController.value * (smallDevice(context) ? 185.0 : 140.0)),
                  child: BodyHimno(
                      alignment: prefs.getString('alignment'),
                      estrofas: estrofas,
                      initFontSizePortrait: initFontSizePortrait,
                      initFontSizeLandscape: initFontSizeLandscape,
                      tema: tema,
                      subTema: subTema,
                      temaId: temaId),
                ),
                AnimatedContainer(
                    curve: sheet ? Curves.fastLinearToSlowEaseIn : Curves.fastOutSlowIn,
                    duration: Duration(milliseconds: sheet ? 500 : 1500),
                    transform: Matrix4.translationValues(sheet ? 0.0 : 5000, 0.0, 0.0),
                    height: MediaQuery.of(context).size.height - (modoVoces ? 200 : 0),
                    // transform: Matrix4.translationValues(
                    //   sheetDragging ? MediaQuery.of(context).size.width - sheetOffset :
                    //   sheetOutDragging ? sheetOffset :
                    //   sheet ? 0.0 :MediaQuery.of(context).size.width,
                    //   0.0,
                    //   0.0
                    // ),
                    child: OrientationBuilder(
                      builder: (BuildContext context, Orientation orientation) {
                        if (currentOrientation == null) {
                          currentOrientation = orientation;
                        }
                        if (currentOrientation != orientation) {
                          currentOrientation = null;
                          sheetController = PhotoViewController();
                          sheet = false;
                        }
                        return currentOrientation == null
                            ? Container()
                            : !sheetReady
                                ? Container(
                                    width: double.infinity,
                                    height: double.infinity,
                                    color: Colors.white,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: <Widget>[
                                        CupertinoActivityIndicator(),
                                        SizedBox(
                                          height: 20.0,
                                        ),
                                        Text(
                                          descargado ? 'Cargando partitura' : 'Descargando partitura',
                                          style: TextStyle(
                                            color: Colors.black,
                                          ),
                                          textScaleFactor: 1.2,
                                        )
                                      ],
                                    ),
                                  )
                                : PhotoView(
                                    controller: sheetController,
                                    imageProvider: FileImage(sheetFile),
                                    basePosition: Alignment.topCenter,
                                    scaleStateController: scaleController,
                                    initialScale:
                                        orientation == Orientation.portrait ? PhotoViewComputedScale.contained : PhotoViewComputedScale.covered,
                                    loadingChild: Container(
                                      width: double.infinity,
                                      height: double.infinity,
                                      color: Colors.white,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: <Widget>[
                                          CupertinoActivityIndicator(),
                                          SizedBox(
                                            height: 20.0,
                                          ),
                                          Text(
                                            descargado ? 'Cargando partitura' : 'Descargando partitura',
                                            style: TextStyle(
                                              color: Colors.black,
                                            ),
                                            textScaleFactor: 1.2,
                                          )
                                        ],
                                      ),
                                    ),
                                    backgroundDecoration: BoxDecoration(color: Colors.white));
                      },
                    )),
                Align(
                    alignment: FractionalOffset.bottomCenter,
                    child: FractionalTranslation(
                      translation: Offset(0.0, 1.0 - switchModeController.value),
                      child: Card(
                          margin: EdgeInsets.all(0.0),
                          color: ScopedModel.of<TemaModel>(context).getScaffoldBackgroundColor(),
                          elevation: 10.0,
                          child: !cargando
                              ? Padding(
                                  padding: EdgeInsets.symmetric(vertical: 5.0),
                                  child:
                                      Column(mainAxisAlignment: MainAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: controlesLayout))
                              : Container(
                                  height: smallDevice(context) ? 185.0 : 140.0,
                                  child: Center(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 20.0),
                                      child: CupertinoActivityIndicator(
                                        animating: true,
                                        radius: 20.0,
                                      ),
                                    ),
                                  ),
                                )),
                    ))
              ],
            )
          : Container(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return isAndroid() ? materialLayout() : cupertinoLayout();
  }
}
