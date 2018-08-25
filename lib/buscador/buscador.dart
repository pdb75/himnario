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
  double scrollPosition;
  bool dragging;
  ScrollController scrollController;
  Database db; 

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController(initialScrollOffset: 0.0);
    cargando = true;
    scrollPosition = 105.0 - 90.0;
    scrollController.addListener((){
      double maxScrollPosition = MediaQuery.of(context).size.height - 130.0;
      setState(() => scrollPosition = 15.0 + ((scrollController.offset/scrollController.position.maxScrollExtent)*(maxScrollPosition)));
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
    List<Himno> himnostemp = List<Himno>();
    String queryTitulo = '';
    String queryParrafo = '';
    List<String> palabras = query.split(' ');
    for (String palabra in palabras) {
      palabra.replaceAll('á', 'a');
      palabra.replaceAll('é', 'e');
      palabra.replaceAll('í', 'i');
      palabra.replaceAll('ó', 'o');
      palabra.replaceAll('ú', 'u');
      if(queryTitulo.isEmpty)
        queryTitulo += "REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(himnos.id || ' ' || himnos.titulo,'á','a'), 'é','e'),'í','i'),'ó','o'),'ú','u') like '%$palabra%'";
      else queryTitulo += " and REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(himnos.id || ' ' || himnos.titulo,'á','a'), 'é','e'),'í','i'),'ó','o'),'ú','u') like '%$palabra%'";

      if(queryParrafo.isEmpty)
        queryParrafo += " REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(parrafo,'á','a'), 'é','e'),'í','i'),'ó','o'),'ú','u') like '%$palabra%'";
      else queryParrafo += " and REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(parrafo,'á','a'), 'é','e'),'í','i'),'ó','o'),'ú','u') like '%$palabra%'";
    }
    
    List<Map<String,dynamic>> data = await db.rawQuery("select himnos.id, himnos.titulo from himnos join parrafos on parrafos.himno_id = himnos.id where $queryTitulo or $queryParrafo group by himnos.id order by himnos.id ASC");
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
      himnostemp.add(Himno(
        numero: himno['id'],
        titulo: himno['titulo'],
        descargado: descargas.contains(himno['id']),
        favorito: favoritos.contains(himno['id']),
      ));
    }
    himnos = himnostemp;
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
                  scrollPosition = position;
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