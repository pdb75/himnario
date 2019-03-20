import 'package:flutter/material.dart';

import '../models/himnos.dart';
import '../himnoPage/himno.dart';

typedef void OnTap();

class Scroller extends StatefulWidget {

  Scroller({this.himnos, this.initDB, this.cargando, this.mensaje = ''});

  final List<Himno> himnos;
  final OnTap initDB;
  final bool cargando;
  final String mensaje;

  @override
  _ScrollerState createState() => _ScrollerState();
}

class _ScrollerState extends State<Scroller> {

  ScrollController scrollController;
  bool dragging;
  double scrollPosition;


  @override
  void initState() {
    super.initState();
    scrollController = ScrollController(initialScrollOffset: 0.0);
    scrollController.addListener((){
      double maxScrollPosition = MediaQuery.of(context).size.height - 130.0;
      if(!dragging)
        setState(() => scrollPosition = 15.0 + ((scrollController.offset/scrollController.position.maxScrollExtent)*(maxScrollPosition)));
    });
    scrollPosition = 105.0 - 90.0;
    dragging = false;
  }


  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        widget.cargando ? 
          Center(child: CircularProgressIndicator(),)
          : widget.himnos.isEmpty ? Container(
              child: Center(
                child: Text(widget.mensaje, textAlign: TextAlign.center,)
              ),
            ) : ListView.builder(
            controller: scrollController,
              itemCount: widget.himnos.length,
              itemBuilder: (BuildContext context, int index) =>
                ListTile(
                onTap: () async {
                  await Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (BuildContext context) => HimnoPage(numero: widget.himnos[index].numero, titulo: widget.himnos[index].titulo,)));
                  widget.initDB();
                  scrollPosition = 105.0 - 90.0;
                },
                leading: widget.himnos[index].favorito ? Icon(Icons.star, color: Theme.of(context).accentColor,) : null,
                title: Row(
                  children: <Widget>[
                    Container(
                      width: widget.himnos[index].favorito ?  MediaQuery.of(context).size.width - 90 : MediaQuery.of(context).size.width - 50,
                      child: Text(
                        '${widget.himnos[index].numero} - ${widget.himnos[index].titulo}',
                        softWrap: true,
                      ),
                    ),
                    widget.himnos[index].descargado ? Container(
                      width: 20.0,
                      height: 20.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).accentColor,
                      ),
                      margin: EdgeInsets.only(bottom: 20.0, left: 2.0,),
                      child: Icon(Icons.get_app,size: 15.0, color: Theme.of(context).indicatorColor,)
                    ) : Icon(Icons.get_app, size: 0.0,),
                  ],
                ),
              ),
            ),
        widget.himnos.length*60.0 > MediaQuery.of(context).size.height ?
        Align(
          alignment: FractionalOffset.centerRight,
          child: GestureDetector(
            onVerticalDragStart: (DragStartDetails details) {
              double position;
              if (details.globalPosition.dy > MediaQuery.of(context).size.height - 25.0) {
                position = MediaQuery.of(context).size.height - 115.0;
              }
              else if (details.globalPosition.dy < 105) {
                position = 15.0;
              }
              else 
                position = details.globalPosition.dy - 90;
              setState(() {
                scrollPosition = position;
                dragging = true;
              });
              int currentHimno = ((position-15)~/((MediaQuery.of(context).size.height - 129)/widget.himnos.length) + 1);
              if (currentHimno > widget.himnos.length-(MediaQuery.of(context).size.height - 115.0)~/56.0)
                scrollController.jumpTo(scrollController.position.maxScrollExtent);
              else
                scrollController.jumpTo((position-15)~/((MediaQuery.of(context).size.height - 129)/widget.himnos.length)*56.0);
            },
            onVerticalDragUpdate: (DragUpdateDetails details) {
              double position;
              if (details.globalPosition.dy > MediaQuery.of(context).size.height - 25.0) {
                position = MediaQuery.of(context).size.height - 115.0;
              }
              else if (details.globalPosition.dy < 105) {
                position = 15.0;
              }
              else 
                position = details.globalPosition.dy - 90;
              setState(() {
                scrollPosition = position;
              });
              int currentHimno = ((position-15)~/((MediaQuery.of(context).size.height - 129)/widget.himnos.length) + 1);
              if (currentHimno > widget.himnos.length-(MediaQuery.of(context).size.height - 115.0)~/56.0)
                scrollController.animateTo(scrollController.position.maxScrollExtent, curve: Curves.easeInOut, duration: Duration(milliseconds: 200));
              else
                scrollController.jumpTo((position-15)~/((MediaQuery.of(context).size.height - 129)/widget.himnos.length)*56.0);
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
                  dragging: dragging,
                  numero: dragging ? widget.himnos[(scrollPosition-15)~/((MediaQuery.of(context).size.height - 129)/widget.himnos.length)].numero.toString() : ''
                ),
              ),
            )
          )
        ) : Container()
      ],
    );
  }
}

class SideScroller extends CustomPainter {
  double position;
  bool dragging;
  BuildContext context;
  String numero;
  Paint scrollBar;


  SideScroller({this.position, BuildContext context, this.dragging, this.numero}) {
    scrollBar = Paint()
      ..color = dragging ? Theme.of(context).accentColor : Colors.grey
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(Offset(size.width - 15, position), Offset(size.width - 15, position + 20), scrollBar);
    if (dragging) {
      position =  position < 90.0 ? 90.0 : position;
      for(int i = 0; i < numero.length; ++i)
        canvas.drawCircle(Offset(size.width - 85 - 5*i, position - 40), 45.0, scrollBar);
      canvas.drawRect(Rect.fromCircle(
        center: Offset(size.width - 62, position - 17),
        radius: 22.0
      ), scrollBar);
      TextPainter(
        text: TextSpan(
          text: numero,
          style: TextStyle(
            fontSize: 45.0,
          )
        ),
        textDirection: TextDirection.ltr)
      ..layout()
      ..paint(canvas, Offset(size.width - 127 - 15*(numero.length-3), position - 65));
    }
  }

  @override
  bool shouldRepaint(SideScroller oldDelegate) {
    return oldDelegate.position != position ||
      oldDelegate.dragging != dragging;
  }
}