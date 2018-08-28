import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'package:sqflite/sqflite.dart';

import '../models/himnos.dart';
import '../himnoPage/himno.dart';
import '../buscador/buscador.dart';

class TemaPage extends StatefulWidget {
  int id;
  bool subtema;
  String tema;

  TemaPage({this.id, this.subtema = false, this.tema});
  @override
  _TemaPageState createState() => _TemaPageState();
}

class _TemaPageState extends State<TemaPage> {
  List<Himno> himnos;
  bool cargando;
  bool dragging;
  double scrollPosition;
  ScrollController scrollController;
  Database db;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController(initialScrollOffset: 0.0);
    himnos = List<Himno>();
    scrollController.addListener((){
      double maxScrollPosition = MediaQuery.of(context).size.height - 130.0;
      !dragging && setState(() => scrollPosition = 15.0 + ((scrollController.offset/scrollController.position.maxScrollExtent)*(maxScrollPosition)));
    });
    cargando = true;
    scrollPosition = 105.0 - 90.0;
    dragging = false;
    initDB();
  }

  Future<Null> initDB() async {
    String databasesPath = (await getApplicationDocumentsDirectory()).path;
    String path = databasesPath + "/himnos.db";
    db = await openReadOnlyDatabase(path);

    await fetchHimnos();
    return null;
  }

  Future<Null> fetchHimnos() async {
    setState(() => cargando = true);
    himnos = List<Himno>();
    List<Map<String,dynamic>> data;
    if (widget.id == 0) {
      data = await db.rawQuery('select himnos.id, himnos.titulo from himnos order by himnos.id ASC');
    } else {
      if(widget.subtema) {
        data = await db.rawQuery('select himnos.id, himnos.titulo from himnos join sub_tema_himnos on sub_tema_himnos.himno_id = himnos.id where sub_tema_himnos.sub_tema_id = ${widget.id} order by himnos.id ASC');
      } else {
        data = await db.rawQuery('select himnos.id, himnos.titulo from himnos join tema_himnos on himnos.id = tema_himnos.himno_id where tema_himnos.tema_id = ${widget.id} order by himnos.id ASC');
      }
    }
    List<Map<String,dynamic>> favoritosQuery = await db.rawQuery('select * from favoritos');
    List<int> favoritos = List<int>();
    for(dynamic favorito in favoritosQuery) {
      favoritos.add(favorito['himno_id']);
    }
    List<Map<String,dynamic>> descargasQuery = await db.rawQuery('select * from descargados');
    List<int> descargas = List<int>();
    for(dynamic descarga in descargasQuery) {
      descargas.add(descarga['himno_id']);
    }
    for(dynamic himno in data) {
      himnos.add(Himno(
        numero: himno['id'],
        titulo: himno['titulo'],
        descargado: descargas.contains(himno['id']),
        favorito: favoritos.contains(himno['id']),
      ));
    }
    setState(() => cargando = false);
    return null;
  }

  @override
  void dispose(){
    super.dispose();
    db.close();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tema),
        actions: <Widget>[
          IconButton(
            onPressed: () async {
              await db.close();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (BuildContext context) => Buscador(id: widget.id, subtema:widget.subtema))
              );
            },
            icon: Icon(Icons.search),
          ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          cargando ? 
          Center(child: CircularProgressIndicator(),)
          : ListView.builder(
            controller: scrollController,
              itemCount: himnos.length,
              itemBuilder: (BuildContext context, int index) =>
                ListTile(
                onTap: () async {
                  print(context.size.height);
                  await db.close();
                  await Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (BuildContext context) => HimnoPage(numero: himnos[index].numero, titulo: himnos[index].titulo,)));
                  initDB();
                  scrollPosition = 105.0 - 90.0;
                },
                leading: himnos[index].favorito ? Icon(Icons.star, color: Theme.of(context).accentColor,) : null,
                title: Row(
                  children: <Widget>[
                    Text('${himnos[index].numero} - ${himnos[index].titulo}'),
                    himnos[index].descargado ? Container(
                      width: 20.0,
                      height: 20.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).accentColor,
                      ),
                      margin: EdgeInsets.only(bottom: 20.0, left: 2.0),
                      child: Icon(Icons.get_app,size: 15.0, color: Theme.of(context).indicatorColor,)
                    ) : Icon(Icons.get_app, size: 0.0,),
                  ],
                ),
              ),
            ),
            himnos.length*60.0 > MediaQuery.of(context).size.height ?
            Align(
              alignment: FractionalOffset.centerRight,
              child: GestureDetector(
                onVerticalDragStart: (DragStartDetails details) {
                  double position;
                  if(details.globalPosition.dy > MediaQuery.of(context).size.height - 25.0)
                    position = MediaQuery.of(context).size.height - 115.0;
                  else if (details.globalPosition.dy < 105)
                    position = 105.0 - 90.0;
                  else 
                    position = details.globalPosition.dy - 90;
                  setState(() {
                    scrollPosition = position;
                    dragging = true;
                  });
                  scrollController.jumpTo(((scrollController.position.maxScrollExtent*((position-15)/(MediaQuery.of(context).size.height-130.0)))/56).floor()*56.0);
                },
                onVerticalDragUpdate: (DragUpdateDetails details) {
                  double position;
                  if(details.globalPosition.dy > MediaQuery.of(context).size.height - 25.0)
                    position = MediaQuery.of(context).size.height - 115.0;
                  else if (details.globalPosition.dy < 105)
                    position = 105.0 - 90.0;
                  else 
                    position = details.globalPosition.dy - 90;
                  setState(() {
                    scrollPosition = position;
                    dragging = true;
                  });
                  scrollController.jumpTo(((scrollController.position.maxScrollExtent*((position-15)/(MediaQuery.of(context).size.height-130.0)))/56).floor()*56.0);
                },
                onVerticalDragEnd: (DragEndDetails details) {
                  setState(() {
                    dragging = false;
                  });
                },
                child: Container(
                  height: double.infinity,
                  width: 40.0,
                  child: CustomPaint(
                    painter: SideScroller(
                      position: scrollPosition,
                      context: context,
                      dragging: dragging  
                    ),
                  ),
                )
              )
            ) : Container()
        ],
      )
      
    );
  }
}

class SideScroller extends CustomPainter {
  final double position;
  bool dragging;
  Paint scrollBar;

  SideScroller({this.position, BuildContext context, this.dragging}) {
    scrollBar = Paint()
      ..color = dragging ? Theme.of(context).accentColor : Colors.grey
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(Offset(size.width - 15, position), Offset(size.width - 15, position + 20), scrollBar);
  }

  @override
  bool shouldRepaint(SideScroller oldDelegate) {
    return oldDelegate.position != position ||
      oldDelegate.dragging != dragging;
  }
}