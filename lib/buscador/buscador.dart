import 'package:flutter/material.dart';
import 'dart:async';
import 'package:sqflite/sqflite.dart';

import '../models/himnos.dart';
import '../himnoPage/himno.dart';

class Buscador extends StatefulWidget {

  Buscador({this.id, this.subtema = false});

  final int id;
  final bool subtema;

  @override
  _BuscadorState createState() => _BuscadorState();
}

class _BuscadorState extends State<Buscador> {
  List<Himno> himnos;
  bool cargando;
  double scollPosition;
  bool dragging;
  ScrollController scrollController;
  Database db; 

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController(initialScrollOffset: 0.0);
    cargando = true;
    scollPosition = 105.0 - 90.0;
    scrollController.addListener((){
      double maxScrollPosition = MediaQuery.of(context).size.height - 130.0;
      setState(() => scollPosition = 15.0 + ((scrollController.offset/scrollController.position.maxScrollExtent)*(maxScrollPosition)));
    });
    cargando = true;
    dragging = false;
    himnos = List<Himno>();
    initDB();
  }

  Future<Null> initDB() async {
    String databasesPath = await getDatabasesPath();
    String path = databasesPath + "/himnos.db";
    db = await openReadOnlyDatabase(path);
    List<Map<String,dynamic>> data = await db.rawQuery('select himnos.id, himnos.titulo from himnos order by himnos.id ASC');
    setState(() {
      himnos = Himno.fromJson(data);
      cargando = false;
    });
    return null;
  }

  Future<Null> fetchHimnos(String query) async {
    setState(() => cargando = true);
    String queryTitulo = '';
    String queryParrafo = '';
    List<String> palabras = query.split(' ');
    for (String palabra in palabras) {
      if(queryTitulo.isEmpty)
        queryTitulo += "REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(himnos.id || ' ' || himnos.titulo,'á','a'), 'é','e'),'í','i'),'ó','o'),'ú','u') like '%$palabra%'";
      else queryTitulo += " and REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(himnos.id || ' ' || himnos.titulo,'á','a'), 'é','e'),'í','i'),'ó','o'),'ú','u') like '%$palabra%'";

      if(queryParrafo.isEmpty)
        queryParrafo += " REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(parrafo,'á','a'), 'é','e'),'í','i'),'ó','o'),'ú','u') like '%$palabra%'";
      else queryParrafo += " and REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(parrafo,'á','a'), 'é','e'),'í','i'),'ó','o'),'ú','u') like '%$palabra%'";
    }
    
    List<Map<String,dynamic>> data = await db.rawQuery("select himnos.id, himnos.titulo from himnos join parrafos on parrafos.himno_id = himnos.id where $queryTitulo or $queryParrafo group by himnos.id order by himnos.id ASC");
    himnos = Himno.fromJson(data);
    setState(() => cargando = false);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          onChanged: fetchHimnos,
          decoration: InputDecoration(
            // border: OutlineInputBorder(
            //   borderRadius: BorderRadius.circular(10.0),
            // ),
            filled: true,
            fillColor: Theme.of(context).canvasColor
          ),
        ),
      ),
      body: Stack(
        children: <Widget>[
          cargando ? 
          Center(
            child: CircularProgressIndicator(),
          ) : 
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
                Navigator.pop(context);
              },
              title: Text('${himnos[index].numero} - ${himnos[index].titulo}'),
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
                scrollController.jumpTo(scrollController.position.maxScrollExtent*((position-15)/(MediaQuery.of(context).size.height-130.0)));
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
                scrollController.jumpTo(scrollController.position.maxScrollExtent*((position-15)/(MediaQuery.of(context).size.height-130.0)));
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