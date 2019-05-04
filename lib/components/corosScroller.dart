import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import '../models/himnos.dart';
import '../coroPage/coro.dart';

class CorosScroller extends StatefulWidget {

  CorosScroller({this.himnos, this.initDB, this.cargando, this.mensaje = ''});

  final List<Himno> himnos;
  final Function initDB;
  final bool cargando;
  final String mensaje;

  @override
  _CorosScrollerState createState() => _CorosScrollerState();
}

class _CorosScrollerState extends State<CorosScroller> {

  ScrollController scrollController;
  bool dragging;
  double scrollPosition;


  @override
  void initState() {
    super.initState();
    scrollController = ScrollController(initialScrollOffset: 0.0);
    // scrollController.addListener((){
    //   double maxScrollPosition = MediaQuery.of(context).size.height - 60 - 130.0;
    //   if(!dragging)
    //     setState(() => scrollPosition = 15.0 + ((scrollController.offset/scrollController.position.maxScrollExtent)*(maxScrollPosition)));
    // });
    // scrollPosition = 105.0 - 90.0;
    scrollController.addListener((){
      double maxScrollPosition = MediaQuery.of(context).size.height - 85.0 - 72.0;
      if(!dragging)
        setState(() => scrollPosition = 72.0 + ((scrollController.offset/scrollController.position.maxScrollExtent)*(maxScrollPosition)));
    });
    scrollPosition = 72.0;
    dragging = false;
  }


  @override
  Widget build(BuildContext context) {
    if (scrollPosition == double.infinity || scrollPosition == double.nan)
      scrollPosition = 72.0;
    return Stack(
      children: <Widget>[
        widget.himnos.isEmpty ? Container(
              child: Center(
                child: Text(widget.mensaje, textAlign: TextAlign.center,)
              ),
            ) : ListView.builder(
            key: PageStorageKey('Scroller Tema'),
            controller: scrollController,
              itemCount: widget.himnos.length,
              itemBuilder: (BuildContext context, int index) =>
              Container(
                color: (scrollPosition - 72.0)~/((MediaQuery.of(context).size.height - 85.0 - 72.0 + 0.5)/widget.himnos.length) == index && dragging ? Theme.of(context).primaryColor : Theme.of(context).scaffoldBackgroundColor,
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
                  child: Text(
                    ((widget.himnos[index].numero > 517 ? '' : '${widget.himnos[index].numero} - ') + '${widget.himnos[index].titulo}'),
                    softWrap: true,
                    style: Theme.of(context).textTheme.subhead.copyWith(
                      color: (scrollPosition - 72.0)~/((MediaQuery.of(context).size.height - 85.0 - 72.0 + 0.5)/widget.himnos.length) == index && dragging ? Colors.white : Theme.of(context).textTheme.subhead.color
                    ),
                  ),
                ),
                // child: ListTile(
                //   onTap: () async {
                //     double aux = scrollController.offset;
                //     print(widget.himnos[index].numero > 517);
                //     await Navigator.push(
                //       context, 
                //       CupertinoPageRoute(builder: (BuildContext context) => widget.himnos[index].numero < 517 ? 
                //       HimnoPage(numero: widget.himnos[index].numero, titulo: widget.himnos[index].titulo,) 
                //       : CoroPage(
                //         numero: widget.himnos[index].numero,
                //         titulo: widget.himnos[index].titulo,
                //         transpose: widget.himnos[index].transpose,
                //       )));
                //     widget.initDB(false);
                //     // scrollPosition = 105.0 - 90.0;
                //   },
                //   leading: widget.himnos[index].favorito ? Icon(Icons.star, color: Theme.of(context).accentColor,) : null,
                //   title: Row(
                //     children: <Widget>[
                //       Container(
                //         width: widget.himnos[index].favorito ?  MediaQuery.of(context).size.width - 90 : MediaQuery.of(context).size.width - 50,
                //         child: Text(
                //           ((widget.himnos[index].numero > 517 ? '' : '${widget.himnos[index].numero} - ') + '${widget.himnos[index].titulo}'),
                //           softWrap: true,
                //           style: Theme.of(context).textTheme.subhead.copyWith(
                //             color: (scrollPosition-15)~/((MediaQuery.of(context).size.height - 129)/widget.himnos.length) == index && dragging ? Colors.white : Theme.of(context).textTheme.subhead.color
                //           ),
                //         ),
                //       ),
                //       widget.himnos[index].descargado ? Container(
                //         width: 20.0,
                //         height: 20.0,
                //         transform: Matrix4.translationValues(-20.0, 0, 0),
                //         decoration: BoxDecoration(
                //           shape: BoxShape.circle,
                //           color: Theme.of(context).accentColor,
                //         ),
                //         margin: EdgeInsets.only(bottom: 20.0),
                //         child: Icon(Icons.get_app,size: 15.0, color: Theme.of(context).indicatorColor,)
                //       ) : Icon(Icons.get_app, size: 0.0,),
                //     ],
                //   ),
                // ),
              )
            ),
        widget.himnos.length*60.0 > MediaQuery.of(context).size.height ?
        Align(
          alignment: FractionalOffset.centerRight,
          child: GestureDetector(
            onVerticalDragStart: (DragStartDetails details) {
              double position;
              double bottomPadding = MediaQuery.of(context).size.height - 85.0;
              double topPadding = 72.0;
              double tileSize = 51.0;

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
              double bottomPadding = MediaQuery.of(context).size.height - 85.0;
              double topPadding = 72.0;
              double tileSize = 51.0;

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
                  numero: dragging ? (scrollPosition - 72.0)~/((MediaQuery.of(context).size.height - 85.0 - 72.0 + 0.5)/widget.himnos.length) : -1
                ),
              ),
            )
          )
        ) : Container()
      ],
    );
  //   if (scrollPosition == double.infinity || scrollPosition == double.nan)
  //     scrollPosition = 105.0 - 90.0;
  //   return Stack(
  //     children: <Widget>[
  //       widget.himnos.isEmpty ? Container(
  //             child: Center(
  //               child: Text(widget.mensaje, textAlign: TextAlign.center,)
  //             ),
  //           ) : ListView.builder(
  //           physics: BouncingScrollPhysics(),
  //           controller: scrollController,
  //             itemCount: widget.himnos.length,
  //             itemBuilder: (BuildContext context, int index) =>
  //             Column(
  //               children: <Widget>[
  //                 Container(
  //                   color: (scrollPosition-15)~/((MediaQuery.of(context).size.height - 60 - 129)/widget.himnos.length) == index && dragging ? Theme.of(context).primaryColor : Theme.of(context).scaffoldBackgroundColor,
  //                   child: ListTile(
  //                     onTap: () async {
  //                       await Navigator.push(
  //                         context, 
  //                         MaterialPageRoute(builder: (BuildContext context) => CoroPage(
  //                           numero: widget.himnos[index].numero, 
  //                           titulo: widget.himnos[index].titulo,
  //                           transpose: widget.himnos[index].transpose,
  //                           )
  //                         )
  //                       );
  //                       widget.initDB(false);
  //                     },
  //                     leading: widget.himnos[index].favorito ? Icon(Icons.star, color: Theme.of(context).accentColor,) : null,
  //                     title: Row(
  //                       children: <Widget>[
  //                         Container(
  //                           width: widget.himnos[index].favorito ?  MediaQuery.of(context).size.width - 90 : MediaQuery.of(context).size.width - 50,
  //                           child: Text(
  //                             ((widget.himnos[index].numero > 517 ? '' : '${widget.himnos[index].numero} - ') + '${widget.himnos[index].titulo}'),
  //                             softWrap: true,
  //                             style: Theme.of(context).textTheme.subhead.copyWith(
  //                               color: (scrollPosition-15)~/((MediaQuery.of(context).size.height - 60 - 129)/widget.himnos.length) == index && dragging ? Colors.white : Theme.of(context).textTheme.subhead.color
  //                             ),
  //                           ),
  //                         ),
  //                         widget.himnos[index].descargado ? Container(
  //                           width: 20.0,
  //                           height: 20.0,
  //                           transform: Matrix4.translationValues(-20.0, 0, 0),
  //                           decoration: BoxDecoration(
  //                             shape: BoxShape.circle,
  //                             color: Theme.of(context).accentColor,
  //                           ),
  //                           margin: EdgeInsets.only(bottom: 20.0),
  //                           child: Icon(Icons.get_app,size: 15.0, color: Theme.of(context).indicatorColor,)
  //                         ) : Icon(Icons.get_app, size: 0.0,),
  //                       ],
  //                     ),
  //                   ),
  //                 )
  //               ],
  //             )
  //           ),
  //       widget.himnos.length*60.0 > MediaQuery.of(context).size.height - 60 ?
  //       Align(
  //         alignment: FractionalOffset.centerRight,
  //         child: GestureDetector(
  //           onVerticalDragStart: (DragStartDetails details) {
  //             double position;
  //             if (details.globalPosition.dy > MediaQuery.of(context).size.height - 60 - 25.0) {
  //               position = MediaQuery.of(context).size.height - 60 - 115.0;
  //             }
  //             else if (details.globalPosition.dy < 105) {
  //               position = 15.0;
  //             }
  //             else 
  //               position = details.globalPosition.dy - 90;
  //             setState(() {
  //               scrollPosition = position;
  //               dragging = true;
  //             });
  //             int currentHimno = ((position-15)~/((MediaQuery.of(context).size.height - 60 - 129)/widget.himnos.length) + 1);
  //             if (currentHimno > widget.himnos.length-(MediaQuery.of(context).size.height - 60 - 115.0)~/56.0)
  //               scrollController.jumpTo(scrollController.position.maxScrollExtent);
  //             else
  //               scrollController.jumpTo((position-15)~/((MediaQuery.of(context).size.height - 60 - 129)/widget.himnos.length)*56.0);
  //           },
  //           onVerticalDragUpdate: (DragUpdateDetails details) {
  //             double position;
  //             if (details.globalPosition.dy > MediaQuery.of(context).size.height - 60 - 25.0) {
  //               position = MediaQuery.of(context).size.height - 60 - 115.0;
  //             }
  //             else if (details.globalPosition.dy < 105) {
  //               position = 15.0;
  //             }
  //             else 
  //               position = details.globalPosition.dy - 90;
  //             setState(() {
  //               scrollPosition = position;
  //             });
  //             int currentHimno = ((position-15)~/((MediaQuery.of(context).size.height - 60 - 129)/widget.himnos.length) + 1);
  //             if (currentHimno > widget.himnos.length-(MediaQuery.of(context).size.height - 60 - 115.0)~/56.0)
  //               scrollController.animateTo(scrollController.position.maxScrollExtent, curve: Curves.easeInOut, duration: Duration(milliseconds: 200));
  //             else
  //               scrollController.jumpTo((position-15)~/((MediaQuery.of(context).size.height - 60 - 129)/widget.himnos.length)*56.0);
  //           },
  //           onVerticalDragEnd: (DragEndDetails details) {
  //             setState(() {
  //               dragging = false;
  //             });
  //           },
  //           child: Container(
  //             height: double.infinity,
  //             width: 40.0,
  //             child: CustomPaint(
  //               painter: SideScroller(
  //                 himnos: widget.himnos,
  //                 position: scrollPosition,
  //                 context: context,
  //                 dragging: dragging,
  //                 numero: dragging ? (scrollPosition-15)~/((MediaQuery.of(context).size.height - 60 - 129)/widget.himnos.length) : -1
  //               ),
  //             ),
  //           )
  //         )
  //       ) : Container()
  //     ],
  //   );
  }
}

class SideScroller extends CustomPainter {
  double position;
  bool dragging;
  BuildContext context;
  int numero;
  Paint scrollBar;
  List<Himno> himnos;


  SideScroller({this.position, BuildContext context, this.dragging, this.numero, this.himnos}) {
    scrollBar = Paint()
      ..color = dragging ? Theme.of(context).accentColor : Colors.grey.withOpacity(0.5)
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(Offset(size.width - 5, position), Offset(size.width - 5, position + 30), scrollBar);
    if (dragging) {
      String text = himnos[numero].numero <= 517 ?  himnos[numero].numero.toString() : himnos[numero].titulo[0];
      double textPosition = position < 155 ? 155 : position;
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

// class SideScroller extends CustomPainter {
//   double position;
//   bool dragging;
//   BuildContext context;
//   int numero;
//   Paint scrollBar;
//   List<Himno> himnos;


//   SideScroller({this.position, BuildContext context, this.dragging, this.numero, this.himnos}) {
//     scrollBar = Paint()
//       ..color = dragging ? Theme.of(context).accentColor : Colors.grey
//       ..strokeWidth = 10.0
//       ..strokeCap = StrokeCap.round;
//   }

//   @override
//   void paint(Canvas canvas, Size size) {
//     canvas.drawLine(Offset(size.width - 15, position), Offset(size.width - 15, position + 20), scrollBar);
//     if (dragging) {
//       String text = himnos[numero].numero <= 517 ?  himnos[numero].numero.toString() : himnos[numero].titulo[0];
//       double textPosition =  position < 90.0 ? 90.0 : position;
//       for(int i = 0; i < text.length; ++i)
//         canvas.drawCircle(Offset(size.width - 85 - 5*i, textPosition - 40), 45.0, scrollBar);
//       canvas.drawRect(Rect.fromCircle(
//         center: Offset(size.width - 62, textPosition - 17),
//         radius: 22.0
//       ), scrollBar);
//       TextPainter(
//         text: TextSpan(
//           text: text,
//           style: TextStyle(
//             fontSize: 45.0,
//           )
//         ),
//         textDirection: TextDirection.ltr)
//       ..layout()
//       ..paint(
//         canvas, 
//         Offset(
//           size.width - (text == "M" ? 132 : 127) - 15*(text.length-3), 
//           textPosition - 65
//         )
//       );
//     }
//   }

//   @override
//   bool shouldRepaint(SideScroller oldDelegate) {
//     return oldDelegate.position != position ||
//       oldDelegate.dragging != dragging;
//   }
// }