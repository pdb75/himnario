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
import 'package:threading/threading.dart';

import './components/boton_voz.dart';
import './components/estructura_himno.dart';

class HimnoPage extends StatefulWidget {

  HimnoPage({this.numero, this.titulo});
  
  final int numero;
  final String titulo;

  @override
  _HimnoPageState createState() => _HimnoPageState();
}

class _HimnoPageState extends State<HimnoPage> with TickerProviderStateMixin {
  Animation<double> switchMode;
  AnimationController switchModeController;
  AnimationController cancionDuracion;
  List<AudioPlayer> audioVoces;
  List<String> stringVoces;
  List<bool> voces;
  List<Parrafo> estrofas;
  List<File> archivos;
  bool dragging;
  double draggingProgress;
  bool modoVoces;
  bool start;
  double currentProgress;
  double nextProgress;
  Duration currentDuration;
  int totalDuration;
  bool vozDisponible;
  bool cargando;
  bool favorito;
  double initfontSize;
  double fontSize;
  double initposition;
  bool descargado;
  int max;
  Database db;
  HttpClient cliente;
  SharedPreferences prefs;

  @override
  void initState() {
    max = 0;
    super.initState();
    Screen.keepOn(true);
    cliente = HttpClient();
    descargado = false;
    cargando = true;
    archivos = List<File>(4);
    stringVoces = ['Soprano', 'Tenor', 'ContraAlto', 'Bajo'];
    audioVoces = [AudioPlayer(),AudioPlayer(),AudioPlayer(),AudioPlayer()];
    modoVoces = false;
    start = false;
    vozDisponible = false;
    dragging = false;
    favorito = false;
    initfontSize = 16.0;
    fontSize = initfontSize;
    currentDuration = Duration();
    switchModeController = AnimationController(duration: Duration(milliseconds: 200), vsync: this);
    switchMode = CurvedAnimation(parent: switchModeController, curve: Curves.easeInOut);
    switchMode..addListener(() {
      setState(() {});
    });
    voces = [true, true, true, true];
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
        await audioVoces[i].resume();
        await audioVoces[i].stop();
      }
      audioVoces[0].positionHandler = (Duration duration) {
        setState(() {
          currentProgress = duration.inMilliseconds / totalDuration;
          currentDuration = duration;
        });
      };
      audioVoces[0].completionHandler = () {
        setState(() {
          start = false;
          currentProgress = 0.0;
        });
      };

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
      for (String linea in parrafo['parrafo'].split('\n')) {
        if (linea.length > max) max = linea.length;
      }
    }
    initfontSize = (MediaQuery.of(context).size.width - 30)/max + 8;
    fontSize = (MediaQuery.of(context).size.width - 30)/max + 8;


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
    List<bool> done = [false, false, false, false];
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
        await audioVoces[i].resume();
        await audioVoces[i].stop();
      }
      audioVoces[0].positionHandler = (Duration duration) {
        setState(() {
          currentProgress = duration.inMilliseconds / totalDuration;
          currentDuration = duration;
        });
      };
      audioVoces[0].completionHandler = () {
        setState(() {
          start = false;
          currentProgress = 0.0;
        });
      };

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
    Thread(() async => audioVoces[0].resume()).start();
    Thread(() async => audioVoces[1].resume()).start();
    Thread(() async => audioVoces[2].resume()).start();
    Thread(() async => audioVoces[3].resume()).start();
    // audioVoces[0].resume();
    // audioVoces[1].resume();
    // audioVoces[2].resume();
    // audioVoces[3].resume();
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
    for (int i = 0; i < audioVoces.length; ++i) {
      await audioVoces[i].pause();
      await audioVoces[i].seek(Duration(milliseconds: (progress * totalDuration).floor()));
    }
    resumeVoces();
  }

  void onTapDown(TapDownDetails details) async {
    if(details.globalPosition.dx < 15.0)
      setState(() {currentProgress = 0.0;});
    else if (details.globalPosition.dx >= 15.0 &&
    details.globalPosition.dx < MediaQuery.of(context).size.width - 15.0)
      setState(() {
        currentProgress = (details.globalPosition.dx) / (MediaQuery.of(context).size.width); 
      });
    else setState(() {currentProgress = 1.0;});
    vocesSeek(currentProgress);
  }

  void swithModes() async {
    modoVoces = !modoVoces;
    if(switchMode.value == 1.0) {
      await switchModeController.reverse();
      setState(() {
        start = false;
        currentProgress = 0.0;
        for (int i = 0; i < audioVoces.length; ++i) {
          voces[i] = true;
          audioVoces[i].stop();
        }
      });
    }
    else {
      await switchModeController.forward();
    }
  }

  void pauseSingleVoice(int index) {
    audioVoces[index].setVolume(0.0);
    setState(() {
      voces[index] = false;
    });
  }

  void resumeSingleVoice(int index) {
    audioVoces[index].setVolume(1.0);
    setState(() {
      voces[index] = true;
    });
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

    print(MediaQuery.of(context).size.width);

    bool smallDevice = MediaQuery.of(context).size.width < 400;
    // bool smallDevice = false;

    List<Widget> controlesLayout = !smallDevice ? [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          BotonVoz(
            voz: 'Soprano',
            activo: voces[0],
            onPressed: () {
              if(voces[0])
                pauseSingleVoice(0);
              else
                resumeSingleVoice(0);
            },
          ),
          BotonVoz(
            voz: 'Tenor',
            activo: voces[1],
            onPressed: () {
              if(voces[1])
                pauseSingleVoice(1);
              else
                resumeSingleVoice(1);
            },
          ),
          BotonVoz(
            voz: 'Contra Alto',
            activo: voces[2],
            onPressed: () {
              if(voces[2])
                pauseSingleVoice(2);
              else
                resumeSingleVoice(2);
            },
          ),
          BotonVoz(
            voz: 'Bajo',
            activo: voces[3],
            onPressed: () {
              if(voces[3])
                pauseSingleVoice(3);
              else
                resumeSingleVoice(3);
            },
          ),
        ],
      )
    ] : [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          BotonVoz(
            voz: '   Soprano  ',
            activo: voces[0],
            onPressed: () {
              if(voces[0])
                pauseSingleVoice(0);
              else
                resumeSingleVoice(0);
            },
          ),
          BotonVoz(
            voz: '    Tenor    ',
            activo: voces[1],
            onPressed: () {
              if(voces[1])
                pauseSingleVoice(1);
              else
                resumeSingleVoice(1);
            },
          ),
        ],
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          BotonVoz(
            voz: 'Contra Alto',
            activo: voces[2],
            onPressed: () {
              if(voces[2])
                pauseSingleVoice(2);
              else
                resumeSingleVoice(2);
            },
          ),
          BotonVoz(
            voz: '     Bajo     ',
            activo: voces[3],
            onPressed: () {
              if(voces[3])
                pauseSingleVoice(3);
              else
                resumeSingleVoice(3);
            },
          ),
        ],
      ),
    ];

    List<Widget> buttonLayout = [
      Slider(
        onChangeStart: (double nextProgress) {
          setState(() {
            draggingProgress = nextProgress;
            dragging = true;
          });
        },
        onChanged: (double nextProgress) {
          setState(() => draggingProgress = nextProgress);
        },
        onChangeEnd: (double nextProgress) {
          setState(() {
            currentProgress = nextProgress;
            dragging = false;
          });
          vocesSeek(currentProgress);
        },
        value: dragging ? draggingProgress : currentProgress,
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
              icon: Icon(Icons.fast_rewind),
            ),
            onPressed: () {},
          ),
          start ? RawMaterialButton(
            shape: CircleBorder(),
            child: IconButton(
              onPressed: pauseVoces,
              icon: Icon(Icons.pause),
            ),
            onPressed: () {},
          ) : 
          RawMaterialButton(
            shape: CircleBorder(),
            child: IconButton(
              onPressed: !cargando ? () {
                resumeVoces();
              } : null,
              icon: Icon(Icons.play_arrow),
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
              icon: Icon(Icons.fast_forward)
            ),
            onPressed: () {},
          ),
        ]
      )
    ];

    for (Widget widget in buttonLayout)
      controlesLayout.add(widget);

    if(prefs != null)
    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          vozDisponible ? IconButton(
            onPressed: toggleDescargado,
            icon: descargado ? Icon(Icons.delete,) : Icon(Icons.get_app,),
          ) : Container(),
          IconButton(
            onPressed: toggleFavorito,
            icon: favorito ? Icon(Icons.star,) : Icon(Icons.star_border,),
          )
        ],
        title: Tooltip(
          message: '${widget.numero} - ${widget.titulo}',
          child: Container(
            width: double.infinity,
            child: Text('${widget.numero} - ${widget.titulo}'),
          ),
        )
      ),
      body: GestureDetector(
        onScaleUpdate: (ScaleUpdateDetails details) {
          double newFontSize = initfontSize*details.scale;
          setState(() => fontSize = newFontSize < 10.0 ? 10.0 : newFontSize);
        },
        onScaleEnd: (ScaleEndDetails details) {
          initfontSize = fontSize;
        },
        child: Stack(
          children: <Widget>[
            (estrofas.isNotEmpty ? ListView.builder(
              padding: EdgeInsets.only(bottom: 70.0 + switchMode.value * 130),
              itemCount: 1,
              itemBuilder: (BuildContext context, int index) =>
                HimnoText(
                  estrofas: estrofas,
                  fontSize: fontSize,
                  alignment: prefs.getString('alignment'),
                )
            ) :
            Center(child: CircularProgressIndicator(),)),
            Align(
              alignment: FractionalOffset.bottomCenter,
              child: FractionalTranslation(
                translation: Offset(0.0, 1.0 - switchMode.value),
                child: Card(
                  margin: EdgeInsets.all(0.0),
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
                      child: CircularProgressIndicator(),
                    ),
                  )
                ),
              )
            )
          ],
        ),
      ),
      floatingActionButton: vozDisponible ? Padding(
        padding: EdgeInsets.only(bottom: smallDevice ? switchMode.value * 175 : switchMode.value * 130),
        child: FloatingActionButton(
          backgroundColor: modoVoces ? Colors.red : Theme.of(context).accentColor,
          onPressed: swithModes,
          child: Stack(
            children: <Widget>[
              Transform.scale(
                scale: 1.0 - switchMode.value,
                child: Icon(Icons.play_arrow, size: 40.0,),
              ),
              Transform.scale(
                scale: 0.0 + switchMode.value,
                child: Icon(Icons.redo, size: 40.0,),
              ),
            ],
          )
        )
      ) : null
    ); else return Scaffold(appBar: AppBar(),);
  }
}