import 'package:flutter/material.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:screen/screen.dart';

import './components/boton_voz.dart';
import './components/estructura_himno.dart';

class HimnoPage extends StatefulWidget {
  int numero;
  String titulo;

  HimnoPage({this.numero, this.titulo});

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
  Database db;

  @override
  void initState() {
    super.initState();
    Screen.keepOn(true);
    cargando = true;
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
    http.get('http://104.131.104.212:8085/himno/${widget.numero}/Soprano/disponible')
      .then((res) {
        if(res.body == 'si')
          setState(() => vozDisponible = true);
        else
          setState(() => vozDisponible = false);
      });
  }

  Future<Null> getHimno() async {
    String databasesPath = await getDatabasesPath();
    String path = databasesPath + "/himnos.db";
    db = await openDatabase(path);

    List<Map<String,dynamic>> parrafos = await db.rawQuery('select * from parrafos where himno_id = ${widget.numero}');

    List<Map<String,dynamic>> favoritosQuery = await db.rawQuery('select * from favoritos where himno_id = ${widget.numero}');

    setState(() {
      favorito = favoritosQuery.isNotEmpty;
      estrofas = Parrafo.fromJson(parrafos);
    });

    return null;
  }



  Future<Null> initVoces() async {
    setState(() => cargando = true);
    for (int i = 0; i < audioVoces.length; ++i) {
      await audioVoces[i].play('http://104.131.104.212:8085/himno/${widget.numero}/${stringVoces[i]}');
      await audioVoces[i].stop();
    }
    audioVoces[0].durationHandler = (Duration duration) => totalDuration = duration.inMilliseconds;
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
    setState(() => cargando = false);
    return null;
  }

  void resumeVoces() {
    audioVoces[0].resume();
    audioVoces[1].resume();
    audioVoces[2].resume();
    audioVoces[3].resume();
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
  void dispose() {
    super.dispose();
    for (int i = 0; i < audioVoces.length; ++i) {
      audioVoces[i].release();
    }
    Screen.keepOn(false);
    db.close();
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
      for (int i = 0; i < audioVoces.length; ++i) {
        await audioVoces[i].release();
      }
      setState(() {
        start = false;
        cargando = true;
        currentProgress = 0.0;
        for (int i = 0; i < audioVoces.length; ++i) {
          voces[i] = true;
        }
      });
    }
    else {
      await switchModeController.forward();
      await initVoces();
    }
  }

  void pauseSingleVoice(int index) {
    audioVoces[index].setVolume(0.0);
    setState(() {
      voces[index] = !voces[index];
    });
  }

  void resumeSingleVoice(int index) {
    audioVoces[index].setVolume(1.0);
    setState(() {
      voces[index] = !voces[index];
    });
  }

  void toggleFavorito() async {
    await db.transaction((action) async {
      if(favorito) {
        await action.rawDelete('delete from favoritos where himno_id = ${widget.numero}');
      } else {
        await action.rawInsert('insert into favoritos values (${widget.numero})');
      }
    });
    setState(() => favorito = !favorito);

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          IconButton(
            onPressed: toggleFavorito,
            icon: favorito ? Icon(Icons.star,) : Icon(Icons.star_border,),
          )
        ],
        title: Text('${widget.numero} - ${widget.titulo}'),
      ),
      body: GestureDetector(
        onHorizontalDragDown: (DragDownDetails details) {
          initposition = details.globalPosition.dx;
        },

        onHorizontalDragUpdate: (DragUpdateDetails details) {
          setState(() => fontSize = initfontSize + (details.globalPosition.dx - initposition)*0.1);
        },

        onHorizontalDragEnd: (DragEndDetails details) {
          initfontSize = fontSize;
        },
        child: Stack(
          children: <Widget>[
            (estrofas.isNotEmpty ? ListView.builder(
              padding: EdgeInsets.only(bottom: 70.0 + switchMode.value * 130),
              itemCount: estrofas.length,
              itemBuilder: (BuildContext context, int index) =>
                (estrofas[index].coro ? 
                Coro(coro: estrofas[index].parrafo, fontSize: fontSize,) :
                Estrofa(numero: estrofas[index].orden, estrofa: estrofas[index].parrafo,fontSize: fontSize,))
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
                      children: <Widget>[
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
                        ),
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
                                onPressed: !cargando ? resumeVoces : null,
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
                          ],
                        )
                      ],
                    )
                  ) : Container(
                    height: 140.0,
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
        padding: EdgeInsets.only(bottom: switchMode.value * 130),
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
    );
  }
}