import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/himnos.dart';
import '../himnoPage/himno.dart';

class FavoritosPage extends StatefulWidget {
  @override
  _FavoritosPageState createState() => _FavoritosPageState();
}

class _FavoritosPageState extends State<FavoritosPage> {
  List<Himno> himnos;
  Database db;
  bool cargando;
  bool dragging;
  double scollPosition;
  ScrollController scrollController;

  @override
  void initState() {
    super.initState();
    himnos = List<Himno>();
    scrollController = ScrollController(initialScrollOffset: 0.0);
    scrollController.addListener((){
      double maxScrollPosition = MediaQuery.of(context).size.height - 130.0;
      !dragging && setState(() => scollPosition = 15.0 + ((scrollController.offset/scrollController.position.maxScrollExtent)*(maxScrollPosition)));
    });
    scollPosition = 105.0 - 90.0;
    dragging = false;
    cargando = true;
    initDB();
  }

  void initDB() async {
    setState(() => cargando = true);
    himnos = List<Himno>();
    String path = (await getApplicationDocumentsDirectory()).path;
    db = await openDatabase(path + '/himnos.db');
    List<Map<String,dynamic>> data = await db.rawQuery('select * from himnos join favoritos on favoritos.himno_id = himnos.id order by himnos.id ASC');
    List<Map<String,dynamic>> descargadosQuery = await db.rawQuery('select * from descargados');
    List<int> descargados = List<int>();
    for(dynamic descargado in descargadosQuery)
      descargados.add(descargado['himno_id']);
    for(dynamic himno in data) {
      himnos.add(Himno(
        numero: himno['id'],
        titulo: himno['titulo'],
        descargado: descargados.contains(himno['id']),
        favorito: true
      ));
    }
    setState(() => cargando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Favoritos'),
      ),
      body: Stack(
        children: <Widget>[  
          cargando ? 
          Center(
            child: CircularProgressIndicator()
          ) :
          himnos.isEmpty ? 
          Center(child: Text('No has agregando ningún himno\n a tu lista de favoritos', textAlign: TextAlign.center,),) :
          ListView.builder(
            controller: scrollController,
            itemCount: himnos.length,
            itemBuilder: (BuildContext context, int index) => 
            ListTile(
              onTap: () async {
                await db.close();
                await Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (BuildContext context) => HimnoPage(numero: himnos[index].numero, titulo: himnos[index].titulo,)));
                initDB();
              },
              leading: Icon(Icons.star, color: Theme.of(context).accentColor,),
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
                    scollPosition = position;
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
                    scollPosition = position;
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
                      position: scollPosition,
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