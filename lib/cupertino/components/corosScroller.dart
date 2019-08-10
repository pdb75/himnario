import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import '../models/himnos.dart';
import '../coroPage/coro.dart';

class CorosScroller extends StatefulWidget {

  CorosScroller({this.himnos, this.initDB, this.cargando, this.mensaje = '', this.iPhoneX = false, this.iPhoneXBottomPadding = 0.0, this.buscador = false, this.refresh});

  final List<Himno> himnos;
  final Function initDB;
  final bool cargando;
  final String mensaje;
  final bool iPhoneX;
  final double iPhoneXBottomPadding;
  final bool buscador;
  final Function refresh;

  @override
  _CorosScrollerState createState() => _CorosScrollerState();
}

class _CorosScrollerState extends State<CorosScroller> {

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
      double maxScrollPosition = MediaQuery.of(context).size.height - 85.0 - widget.iPhoneXBottomPadding - 72.0 + iPhoneXPadding;
      if(!dragging)
        setState(() => scrollPosition = 72.0 + iPhoneXPadding + ((scrollController.offset/scrollController.position.maxScrollExtent)*(maxScrollPosition)));
    });
    scrollPosition = 72.0 + iPhoneXPadding;
    dragging = false;
  }

  @override
  void didUpdateWidget(CorosScroller oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.himnos != widget.himnos && widget.buscador) {
      scrollPosition = 72.0 + iPhoneXPadding;
    }
  }


  @override
  Widget build(BuildContext context) {
    if (scrollPosition == double.infinity || scrollPosition == double.nan)
      scrollPosition = 72.0 + iPhoneXPadding;
    return Stack(
      children: <Widget>[
        widget.himnos.isEmpty ? Container(
              child: Center(
                child: Text(widget.mensaje, textAlign: TextAlign.center,)
              ),
            ) : SafeArea(
              child: CustomScrollView(
                key: PageStorageKey('Scroller Tema'),
                controller: scrollController,
                slivers: <Widget>[
                  CupertinoSliverRefreshControl(
                    onRefresh: widget.refresh,
                  ),
                  SliverList(
                    key: PageStorageKey('Scroller Tema'),
                    delegate: SliverChildBuilderDelegate((BuildContext builder, int index) => 
                    Container(
                      color: (scrollPosition - 72.0 - iPhoneXPadding)~/((MediaQuery.of(context).size.height - 85.0 - widget.iPhoneXBottomPadding - 72.0 - iPhoneXPadding + 0.5)/widget.himnos.length) == index && dragging ? 
                      CupertinoTheme.of(context).primaryColor : 
                      CupertinoTheme.of(context).scaffoldBackgroundColor,
                      height: 55.0,
                      child: CupertinoButton(
                        onPressed: () async {
                          double aux = scrollController.offset;
                          print(widget.himnos[index].numero > 517);
                          await Navigator.push(
                            context, 
                            CupertinoPageRoute(builder: (BuildContext context) => CoroPage(
                              numero: widget.himnos[index].numero,
                              titulo: widget.himnos[index].titulo,
                              transpose: widget.himnos[index].transpose,
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
                                  color: (scrollPosition - 72.0 - iPhoneXPadding)~/((MediaQuery.of(context).size.height - 85.0 - widget.iPhoneXBottomPadding - 72.0 - iPhoneXPadding + 0.5)/widget.himnos.length) == index && dragging ? 
                                  Colors.white : 
                                  CupertinoTheme.of(context).textTheme.textStyle.color
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
                    ), childCount: widget.himnos.length),
                  )
                ],
              ),
            ),
        widget.himnos.length*60.0 > MediaQuery.of(context).size.height ?
        Align(
          alignment: FractionalOffset.centerRight,
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

              int currentHimno = ((scrollPosition - topPadding)~/((bottomPadding - topPadding + 0.5)/widget.himnos.length) + 1);

              if (currentHimno > widget.himnos.length-(MediaQuery.of(context).size.height - 115.0)~/tileSize)
                scrollController.animateTo(scrollController.position.maxScrollExtent, curve: Curves.easeInOut, duration: Duration(milliseconds: 200));
              else
                scrollController.jumpTo((scrollPosition - topPadding)~/((bottomPadding - topPadding + 0.5)/widget.himnos.length)*tileSize);
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

              int currentHimno = ((scrollPosition - topPadding)~/((bottomPadding - topPadding + 0.5)/widget.himnos.length) + 1);

              if (currentHimno > widget.himnos.length-(MediaQuery.of(context).size.height - 115.0)~/tileSize)
                scrollController.animateTo(scrollController.position.maxScrollExtent, curve: Curves.easeInOut, duration: Duration(milliseconds: 200));
              else
                scrollController.jumpTo((scrollPosition - topPadding)~/((bottomPadding - topPadding + 0.5)/widget.himnos.length)*tileSize);
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
                  himnos: widget.himnos,
                  position: scrollPosition,
                  context: context,
                  dragging: dragging,
                  iPhoneXPadding: iPhoneXPadding,
                  numero: dragging ? (scrollPosition - 72.0 - iPhoneXPadding)~/((MediaQuery.of(context).size.height - 85.0 - widget.iPhoneXBottomPadding - 72.0 - iPhoneXPadding + 0.5)/widget.himnos.length) : -1
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
  int numero;
  Paint scrollBar;
  List<Himno> himnos;
  double iPhoneXPadding;

  SideScroller({this.position, BuildContext context, this.dragging, this.numero, this.himnos, this.iPhoneXPadding = 0.0}) {
    scrollBar = Paint()
      ..color = dragging ? CupertinoTheme.of(context).primaryColor : Colors.grey.withOpacity(0.5)
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(Offset(size.width - 5, position), Offset(size.width - 5, position + 30), scrollBar);
    if (dragging) {
      String text = himnos[numero].numero <= 517 ?  himnos[numero].numero.toString() : himnos[numero].titulo[0];
      double textPosition = position < 155.0 + iPhoneXPadding ? 155 + iPhoneXPadding : position;
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