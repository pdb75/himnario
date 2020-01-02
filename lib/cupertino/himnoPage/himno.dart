import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:Himnario/cupertino/models/tema.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:scoped_model/scoped_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:screen/screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:photo_view/photo_view.dart';

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
  double initfontSizeProtrait;
  double initfontSizeLandscape;
  double initposition;
  bool descargado;
  int max;
  int doneCount;
  Database db;
  HttpClient cliente;
  SharedPreferences prefs;

  String tema;
  int temaId;
  String subTema;

  // Sheet variables
  bool sheet;
  bool sheetAvailable;
  File sheetFile;
  PhotoViewController sheetController;
  Orientation currentOrientation;
  
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
    initfontSizeProtrait = 16.0;
    initfontSizeLandscape = 16.0;
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

    
    // Sheet init
    sheet = false;
    sheetAvailable = false;
    sheetFile = File('/');
    sheetController = PhotoViewController();
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
        if(aux.existsSync())
          aux.delete();
      }
      catch (e) {print(e);}
    }
  }

  Future<Null> initVocesDownloaded() async {
    setState(() {
      cargando = true;
      vozDisponible = true;
    });
    String path = (await getApplicationDocumentsDirectory()).path;
    if(cliente != null && mounted) 
      for (int i = 0; i < audioVoces.length; ++i) {
        int success = -1;
        try {
          success = await audioVoces[i].setUrl(path + '/${widget.numero}-${stringVoces[i]}.mp3', isLocal: true);
        } catch(e) {
          print(e);
        }
        while(success != 1) {
          http.Response res = await http.get('http://104.131.104.212:8085/himno/${widget.numero}/Soprano/disponible');
          if(res.body == 'no') {
            setState(() => vozDisponible = false);
            return null;
          }
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
    if(cliente != null && mounted) {
      setState(() => cargando = false);
    } else if(archivos[0] == null && !descargado)
        deleteVocesFiles();
    return null;
  }

  Future<Null> checkPartitura(String path) async {
    File aux = File(path + '/${widget.numero}.jpg');
    if (descargado) {
      if (await aux.exists()) {
        if (mounted) setState(() => sheetAvailable = true);
      } else {
        http.Response res = await http.get('http://104.131.104.212:8085/partitura/${widget.numero}/disponible');
        if (res.statusCode == 200) {
          if (mounted) setState(() => sheetAvailable = true);
          http.Response image = await http.get('http://104.131.104.212:8085/partitura/${widget.numero}');
          await aux.writeAsBytes(image.bodyBytes);
        }
      }
    }
    else {
      http.Response res = await http.get('http://104.131.104.212:8085/partitura/${widget.numero}/disponible');
      if (res.statusCode == 200) {
        if (mounted) setState(() => sheetAvailable = true);
        http.Response image = await http.get('http://104.131.104.212:8085/partitura/${widget.numero}');
        await aux.writeAsBytes(image.bodyBytes);
      }
    }
    setState(() => sheetFile = aux);
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

    if (MediaQuery.of(context).orientation == Orientation.portrait) {
      initfontSizeProtrait = (MediaQuery.of(context).size.width - 30)/max + 8;
      initfontSizeLandscape = (MediaQuery.of(context).size.height - 30)/max + 8;
    } else {
      initfontSizeProtrait = (MediaQuery.of(context).size.height - 30)/max + 8;
      initfontSizeLandscape = (MediaQuery.of(context).size.width - 30)/max + 8;
    }

    List<Map<String,dynamic>> favoritosQuery = await db.rawQuery('select * from favoritos where himno_id = ${widget.numero}');
    List<Map<String,dynamic>> descargadoQuery = await db.rawQuery('select * from descargados where himno_id = ${widget.numero}');
    // List<Map<String,dynamic>> temaQuery = await db.rawQuery('select temas.tema, temas.id from tema_himnos join temas on temas.id = tema_himnos.tema_id where tema_himnos.himno_id = ${widget.numero}');
    // List<dynamic> subTemaQuery = await db.rawQuery('select sub_temas.id, sub_temas.sub_tema from sub_tema_himnos join sub_temas on sub_temas.id = sub_tema_himnos.sub_tema_id where sub_tema_himnos.himno_id = ${widget.numero}');
    setState(() {
      favorito = favoritosQuery.isNotEmpty;
      descargado = descargadoQuery.isNotEmpty;
      totalDuration = descargadoQuery.isNotEmpty ? descargadoQuery[0]['duracion'] : 0;
      estrofas = Parrafo.fromJson(parrafos);
      tema = '';
      subTema = '';
      temaId = 1;
      // tema = temaQuery == null || temaQuery.isEmpty ? '' : temaQuery[0]['tema'];
      // subTema = subTemaQuery == null || subTemaQuery.isEmpty ? '' : subTemaQuery[0]['sub_tema'];
      // temaId = subTemaQuery.isNotEmpty ? subTemaQuery[0]['id'] : temaQuery[0]['id'];
    });

    if (descargadoQuery.isEmpty && mounted) {
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
    checkPartitura(databasesPath);
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

    if(cliente != null && mounted) 
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

    if(cliente != null && mounted) {
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
      if (sheetFile.existsSync() && !descargado)
        sheetFile.deleteSync();
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

    bool smallDevice = MediaQuery.of(context).orientation == Orientation.portrait;

    List<Widget> controlesLayout = !smallDevice ? [
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
    ] : [
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
                color: ScopedModel.of<TemaModel>(context).getScaffoldTextColor(),
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
                color: ScopedModel.of<TemaModel>(context).getScaffoldTextColor(),
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
                if(newProgress >= 1.0)
                  vocesSeek(1.0);
                else vocesSeek(currentProgress + 0.1);
              },
              icon: Icon(
                Icons.fast_forward,
                color: ScopedModel.of<TemaModel>(context).getScaffoldTextColor(),
              )
            ),
            onPressed: () {},
          ),
        ]
      )
    ];

    for (Widget widget in buttonLayout)
      controlesLayout.add(widget);

    List<Widget> modalButtons = [
      CupertinoActionSheetAction(
        isDestructiveAction: descargado,
        onPressed: () {
          toggleDescargado();
          Navigator.of(context).pop();
        },
        child: Text(descargado ? 'Eliminar' : 'Descargar'),
      ),
    ];

    if(vozDisponible) {
      modalButtons.add(CupertinoActionSheetAction(
        onPressed: () {
          swithModes();
          Navigator.of(context).pop();
        },
        child: Text(modoVoces ? 'Ocultar Voces' : 'Mostrar Voces'),
      ));
    }

    if(sheetAvailable) {
      modalButtons.add(CupertinoActionSheetAction(
        onPressed: () {
          setState(() => sheet = !sheet);
          Navigator.of(context).pop();
        },
        child: Text(sheet ? 'Ocultar Partitura' : 'Mostrar Partitura'),
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
          style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
            color: ScopedModel.of<TemaModel>(context).getTabTextColor(),
            fontFamily: ScopedModel.of<TemaModel>(context).font
          ),
        ),
        trailing: prefs != null ? Transform.translate(
          offset: Offset(20.0, 0.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              CupertinoButton(
                onPressed: toggleFavorito,
                padding: EdgeInsets.only(bottom: 2.0),
                child: favorito ? Icon(Icons.star, size: 30.0,) : Icon(Icons.star_border, size: 30.0,),
              ),
              CupertinoButton(
                disabledColor: Colors.black.withOpacity(0.5),
                onPressed: vozDisponible || sheetAvailable ? () {
                  showCupertinoModalPopup(
                    context: context,
                    builder: (BuildContext context) => CupertinoActionSheet(
                      cancelButton: CupertinoActionSheetAction(
                        isDestructiveAction: true,
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Cancelar'),
                      ),
                      actions: modalButtons,
                    )
                  );
                } : null,
                padding: EdgeInsets.only(bottom: 2.0),
                child: Icon(Icons.more_vert, size: 30.0,),
              ),
            ],
          ),
        ) : null
      ),
      child: prefs != null ? Stack(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(bottom: switchModeController.value * (smallDevice ? 185.0 : 140.0)),
            child: BodyHimno(
              alignment: prefs.getString('alignment'),
              estrofas: estrofas,
              initfontSizeProtrait: initfontSizeProtrait,
              initfontSizeLandscape: initfontSizeLandscape,
              tema: tema,
              subTema: subTema,
              temaId: temaId
            ),
          ),

          Opacity(
            opacity: sheet ? 1.0 : 0.0,
            child: AnimatedContainer(
              curve: sheet ? Curves.fastLinearToSlowEaseIn : Curves.fastOutSlowIn,
              duration: Duration(milliseconds: 500),
              transform: Matrix4.skew(
                sheet ? 0.0 : -1.0, 
                sheet ? 0.0 : -1.0
              ),
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
                  return currentOrientation == null ? Container() : PhotoView(
                    controller: sheetController,
                    imageProvider: FileImage(sheetFile),
                    basePosition: Alignment.topCenter,
                    initialScale: orientation == Orientation.portrait ? PhotoViewComputedScale.contained : PhotoViewComputedScale.covered,
                    loadingChild: Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          CupertinoActivityIndicator(),
                          SizedBox(height: 20.0,),
                          Text(descargado ? 'Cargando partitura' : 'Descargando partitura', style: TextStyle(
                              color: Colors.black,
                            ),
                            textScaleFactor: 1.2,
                          )
                        ],
                      ),
                    ),
                    backgroundDecoration: BoxDecoration(
                      color: Colors.white
                    )
                  );
                },
              )
            ),
          ),
          
          Align(
            alignment: FractionalOffset.bottomCenter,
            child: FractionalTranslation(
              translation: Offset(0.0, 1.0 - switchModeController.value),
              child: Card(
                margin: EdgeInsets.all(0.0),
                color: ScopedModel.of<TemaModel>(context).getScaffoldBackgroundColor(),
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
      ) : Container(),
    );
  }
}