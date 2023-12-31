import 'package:Himnario/cupertino/models/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:scoped_model/scoped_model.dart';

import '../models/himnos.dart';
import '../himnoPage/himno.dart';
import '../coroPage/coro.dart';

class Scroller extends StatefulWidget {

  Scroller({this.himnos, this.initDB, this.cargando, this.mensaje = '', this.iPhoneX = false, this.iPhoneXBottomPadding = 0.0, this.buscador = false});

  final List<Himno> himnos;
  final Function initDB;
  final bool cargando;
  final String mensaje;
  final bool iPhoneX;
  final double iPhoneXBottomPadding;
  final bool buscador;

  @override
  _ScrollerState createState() => _ScrollerState();
}

class _ScrollerState extends State<Scroller> {

  ScrollController scrollController;
  bool dragging;
  double scrollPosition;
  double iPhoneXPadding;


  @override
  void initState() {
    super.initState();
    iPhoneXPadding = widget.iPhoneX ? 20.0 : 0.0;
    scrollController = ScrollController(initialScrollOffset: 0.0);
    scrollController.addListener((){
      double maxScrollPosition = MediaQuery.of(context).size.height - (85.0 + 40.0) - widget.iPhoneXBottomPadding - 72.0 + iPhoneXPadding;
      double maxScrollExtent = scrollController.position.maxScrollExtent == 0.0 ? 1.0 : scrollController.position.maxScrollExtent;
      if(!dragging)
        setState(() => scrollPosition = 72.0 + iPhoneXPadding + ((scrollController.offset/maxScrollExtent)*(maxScrollPosition)));
    });
    scrollPosition = 72.0 + iPhoneXPadding;
    dragging = false;
  }

  @override
  void didUpdateWidget(Scroller oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.himnos != widget.himnos && widget.buscador) {
      scrollPosition = 72.0 + iPhoneXPadding;
    }
  }


  @override
  Widget build(BuildContext context) {
    final TemaModel tema = ScopedModel.of<TemaModel>(context, rebuildOnChange: true);
    int length = widget.himnos.length == 0 ? 1 : widget.himnos.length;
    if (scrollPosition == double.infinity || scrollPosition == double.nan)
      scrollPosition = 72.0 + iPhoneXPadding;
    return Stack(
      children: <Widget>[
        widget.himnos.isEmpty ? Container(
              child: Center(
                child: Text(
                  widget.mensaje,
                  textScaleFactor: 1.5, 
                  textAlign: TextAlign.center,
                  style: DefaultTextStyle.of(context).style.copyWith(
                    color: ScopedModel.of<TemaModel>(context).getScaffoldTextColor(),
                    fontFamily: ScopedModel.of<TemaModel>(context).font,
                  ),
                )
              ),
            ) : ListView.builder(
            key: PageStorageKey('Scroller Tema'),
            controller: scrollController,
              itemCount: widget.himnos.length,
              itemBuilder: (BuildContext context, int index) =>
              Container(
                color: (scrollPosition - 72.0 - iPhoneXPadding)~/((MediaQuery.of(context).size.height - 85.0 - widget.iPhoneXBottomPadding - 72.0 - iPhoneXPadding + 0.5)/length) == index && dragging ? 
                tema.mainColor : 
                tema.getScaffoldBackgroundColor(),
                height: 55.0,
                child: CupertinoButton(
                  onPressed: () async {
                    double aux = scrollController.offset;
                    print(widget.himnos[index].numero > 517);
                    await Navigator.push(
                      context, 
                      CupertinoPageRoute(builder: (BuildContext context) => widget.himnos[index].numero <= 517 ? 
                      ScopedModel<TemaModel>(
                        model: tema,
                        child: HimnoPage(numero: widget.himnos[index].numero, titulo: widget.himnos[index].titulo,),
                      ) : ScopedModel<TemaModel>(
                        model: tema,
                        child: CoroPage(
                          numero: widget.himnos[index].numero,
                          titulo: widget.himnos[index].titulo,
                          transpose: widget.himnos[index].transpose,
                        )
                      )));
                    widget.initDB(false);
                    // scrollPosition = 105.0 - 90.0;
                  },
                  child: Stack(
                    children: <Widget>[
                      Align(
                        alignment: Alignment.center,
                        child: Text(
                          ((widget.himnos[index].numero > 517 ? '' : '${widget.himnos[index].numero} - ') + '${widget.himnos[index].titulo}'),
                          softWrap: true,
                          textAlign: TextAlign.start,
                          style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                            color: (scrollPosition - 72.0 - iPhoneXPadding)~/((MediaQuery.of(context).size.height - 85.0 - widget.iPhoneXBottomPadding - 72.0 - iPhoneXPadding + 0.5)/length) == index && dragging ? 
                            tema.mainColorContrast : 
                            tema.getScaffoldTextColor(),
                            fontFamily: ScopedModel.of<TemaModel>(context).font,
                          ),
                        )
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            widget.himnos[index].favorito ? Icon(Icons.star, color: CupertinoTheme.of(context).textTheme.textStyle.color,) : Container(),
                            widget.himnos[index].descargado ? Icon(Icons.get_app, color: CupertinoTheme.of(context).textTheme.textStyle.color,) : Container()
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              )
            ),
        widget.himnos.length*60.0 > MediaQuery.of(context).size.height ?
        Align(
          alignment: FractionalOffset.centerRight,
          child: Container(
            transform: Matrix4.translationValues(0.0, (
              widget.iPhoneX && tema.brightness == Brightness.light ? -20.0 : 0.0
            ), 0.0),
            margin: EdgeInsets.only(top: tema.brightness == Brightness.dark ? (
              widget.iPhoneX ? 70.0 : 65.0
            ) : 0.0),
            child: GestureDetector(
              onVerticalDragStart: (DragStartDetails details) {
                double position;
                double bottomPadding = MediaQuery.of(context).size.height - 85.0 - widget.iPhoneXBottomPadding;
                double topPadding = 72.0 + iPhoneXPadding;
                double tileSize = 55.0;

                if (details.globalPosition.dy > bottomPadding + 15.0) {
                  position = bottomPadding;
                }
                else if (details.globalPosition.dy < topPadding + 15.0) {
                  position = topPadding;
                }
                else 
                  position = details.globalPosition.dy - 15.0;
                setState(() {
                  scrollPosition = position;
                  dragging = true;
                });

                int currentHimno = ((scrollPosition - topPadding)~/((bottomPadding - topPadding + 0.5)/length) + 1);

                if (currentHimno > widget.himnos.length-(MediaQuery.of(context).size.height - 115.0)~/tileSize)
                  scrollController.animateTo(scrollController.position.maxScrollExtent, curve: Curves.easeInOut, duration: Duration(milliseconds: 200));
                else
                  scrollController.jumpTo((scrollPosition - topPadding)~/((bottomPadding - topPadding + 0.5)/length)*tileSize);
              },
              onVerticalDragUpdate: (DragUpdateDetails details) {
                double position;
                double bottomPadding = MediaQuery.of(context).size.height - 85.0 - widget.iPhoneXBottomPadding;
                double topPadding = 72.0 + iPhoneXPadding;
                double tileSize = 55.0;

                if (details.globalPosition.dy > bottomPadding + 15.0) {
                  position = bottomPadding;
                }
                else if (details.globalPosition.dy < topPadding + 15.0) {
                  position = topPadding;
                }
                else 
                  position = details.globalPosition.dy - 15.0;

                setState(() {
                  scrollPosition = position;
                });

                int currentHimno = ((scrollPosition - topPadding)~/((bottomPadding - topPadding + 0.5)/length) + 1);

                if (currentHimno > widget.himnos.length-(MediaQuery.of(context).size.height - 115.0)~/tileSize)
                  scrollController.animateTo(scrollController.position.maxScrollExtent, curve: Curves.easeInOut, duration: Duration(milliseconds: 200));
                else
                  scrollController.jumpTo((scrollPosition - topPadding)~/((bottomPadding - topPadding + 0.5)/length)*tileSize);
              },
              onVerticalDragEnd: (DragEndDetails details) {
                setState(() {
                  dragging = false;
                });
              },
              child: Container(
                height: double.infinity,
                width: 40.0,
                child: Transform.translate(
                  offset: Offset(0.0, -65.0),
                  child: CustomPaint(
                    painter: SideScroller(
                      tema: tema,
                      himnos: widget.himnos,
                      position: scrollPosition,
                      context: context,
                      dragging: dragging,
                      iPhoneXPadding: iPhoneXPadding,
                      numero: dragging ? (scrollPosition - 72.0 - iPhoneXPadding)~/((MediaQuery.of(context).size.height - 85.0 - widget.iPhoneXBottomPadding - 72.0 - iPhoneXPadding + 0.5)/length) : -1,
                    ),
                  ),
                ),
              )
            ),
          )
        ) : Container()
      ],
    );
  }
}

class SideScroller extends CustomPainter {
  double position;
  bool dragging;
  Color textColor;
  BuildContext context;
  int numero;
  Paint scrollBar;
  List<Himno> himnos;
  double iPhoneXPadding;
  TemaModel tema;


  SideScroller({this.tema, this.position, BuildContext context, this.dragging, this.numero, this.himnos, this.iPhoneXPadding = 0.0}) {
    textColor = tema.brightness == Brightness.light ? Colors.white : tema.getTabTextColor();
    scrollBar = Paint()
      ..color = dragging ? (tema.brightness == Brightness.light ? CupertinoTheme.of(context).primaryColor : tema.getTabBackgroundColor().withOpacity(1.0)) : Colors.grey.withOpacity(0.5)
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(Offset(size.width - 5, position), Offset(size.width - 5, position + 30), scrollBar);
    if (dragging) {
      String text = himnos[numero].numero <= 517 ?  himnos[numero].numero.toString() : himnos[numero].titulo[0];
      double textPosition = position < 155.0 + iPhoneXPadding ? 155.0 + iPhoneXPadding : position;
      for(int i = 0; i < text.length; ++i)
        canvas.drawCircle(Offset(size.width - 85 - 5*i, textPosition - 40), 45.0, scrollBar);
      canvas.drawRect(Rect.fromCircle(
        center: Offset(size.width - 62, textPosition - 17),
        radius: 22.0
      ), scrollBar);
      TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: textColor,
            fontSize: 45.0,
          )
        ),
        textDirection: TextDirection.ltr)
      ..layout()
      ..paint(
        canvas, 
        Offset(
          size.width - (text == "M" ? 132 : 127) - 15*(text.length-3), 
          textPosition - 65
        )
      );
    }
  }

  @override
  bool shouldRepaint(SideScroller oldDelegate) {
    return oldDelegate.position != position ||
      oldDelegate.dragging != dragging;
  }
}