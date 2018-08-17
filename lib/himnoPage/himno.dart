import 'package:flutter/material.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

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
  List<String> estrofas;
  List<String> coros;
  bool dragging;
  double draggingProgress;
  bool modoVoces;
  bool start;
  double currentProgress;
  double nextProgress;
  Duration currentDuration;
  int totalDuration;

  @override
  void initState() {
    super.initState();
    stringVoces = ['Soprano', 'Tenor', 'ContraAlto', 'Bajo'];
    audioVoces = [AudioPlayer(),AudioPlayer(),AudioPlayer(),AudioPlayer()];
    modoVoces = false;
    start = false;
    dragging = false;
    currentDuration = Duration();
    initVoces();
    switchModeController = AnimationController(duration: Duration(milliseconds: 200), vsync: this);
    switchMode = CurvedAnimation(parent: switchModeController, curve: Curves.easeInOut);
    switchMode..addListener(() {
      setState(() {});
    });
    voces = [true, true, true, true];
    estrofas = List<String>();
    coros = List<String>();
    currentProgress = 0.0;
    estrofas.add("""Lleno de angustia y temores,
en brava y oscura mar,
el hombre perdido navega,
cual barco en la tempestad.
Olas de mal le rodean,
nubes de gran pavor.
El naufragio eternal le amenaza
y su alma llena el terror.""");
    estrofas.add("""Contra las olas y el viento
batalla con ansiedad.
Valiente procura librarse del
bravo mar de impiedad.
Mas ya sus fuerzas gastadas,
rendido y sin valor,
desmayando desea un refugio,
un guía y un Salvador.""");
    estrofas.add("""Fuerte y solícito acude
Jesús, y con gran bondad
aborda la frágil barquilla,
y calma la tempestad.
Libre de todo peligro, 
salvo, seguro y en paz,
hoy con Cristo navega el marino
a eterna felicidad.""");
    coros.add("""Mira, oh turbado, tu Salvador cerca está.
Vio tu peligro y con suma bondad acude
a librarte de ruina y dolor;
domina los vientos, las nubes y el mar
y te abre el puerto del bienestar.
Su voz potente en la tempestad
trae paz, dulce paz.
Recibe a Cristo y navegarás
en calma y paz.""");
  }

  Future<Null> initVoces() async {
    for (int i = 0; i < audioVoces.length; ++i) {
      await audioVoces[i].play('http://104.131.104.212:8085/${stringVoces[i]}');
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
      audioVoces[i].stop();
    }
  }

  @override
  void dispose() {
    super.dispose();
    for (int i = 0; i < audioVoces.length; ++i) {
      audioVoces[i].release();
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
      for (int i = 0; i < audioVoces.length; ++i) {
        await audioVoces[i].release();
      }
      setState(() {
        start = false;
        currentProgress = 0.0;
        for (int i = 0; i < audioVoces.length; ++i) {
          voces[i] = true;
        }
      });
    }
    else {
      await switchModeController.forward();
      await initVoces();
      resumeVoces();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.numero} - ${widget.titulo}'),
      ),
      body: Stack(
        children: <Widget>[
          ListView(
            padding: EdgeInsets.only(bottom: 70.0 + switchMode.value * 130),
            children: <Widget>[
              Estrofa(numero: 1, estrofa: estrofas[0]),
              Coro(coro: coros[0],),
              Estrofa(numero: 2, estrofa: estrofas[1]),
              Estrofa(numero: 3, estrofa: estrofas[2]),
            ],
          ),
          Align(
            alignment: FractionalOffset.bottomCenter,
            child: FractionalTranslation(
              translation: Offset(0.0, 1.0 - switchMode.value),
              child: Card(
                margin: EdgeInsets.all(0.0),
                elevation: 10.0,
                child: Padding(
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
                      // GestureDetector(
                      //   onTapDown: onTapDown,
                      //   child: Center(
                      //     child: CustomPaint(
                      //       painter: ProgressBar(
                      //         currentProgress: currentProgress
                      //       ),
                      //       child: Container(height: 20.0),
                      //     )
                      //   ),
                      // ),
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
                              onPressed: resumeVoces,
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
                )
              ),
            )
          )
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: switchMode.value * 130),
        child: FloatingActionButton(
          backgroundColor: modoVoces ? Colors.red : Colors.blue,
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
      )
    );
  }
}

class ProgressBar extends CustomPainter {
  double currentProgress;
  ProgressBar({this.currentProgress});

  @override
  void paint(Canvas canvas, Size size) {
    double canvasCurrentProgress = 15 + (size.width - 30) * currentProgress;

    Paint totalProgress = Paint()
      ..color = Colors.grey
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(15.0, size.height/2), Offset(size.width - 15, size.height/2), totalProgress);

    Paint currenProgress = Paint()
      ..color = Colors.blue
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(15.0, size.height/2), Offset(canvasCurrentProgress, size.height/2), currenProgress);

    Paint currenProgressCircle = Paint()
      ..color = Colors.blue
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(Offset(canvasCurrentProgress, size.height/2), 10.0, currenProgressCircle);
  }

  @override
  bool shouldRepaint(ProgressBar old) {

    return true;
  }

}