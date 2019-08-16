import 'package:flutter/material.dart';

import './estructura_Coro.dart';
import '../../models/himnos.dart';

class BodyCoro extends StatefulWidget {

  final String alignment;
  final double initfontSize;
  final List<Parrafo> estrofas;
  final bool acordes;
  final double animation;
  final String notation;
  final ScrollController scrollController;
  final Function stopScroll;

  BodyCoro({this.initfontSize, this.estrofas, this.alignment, this.acordes, this.animation, this.notation, this.scrollController, this.stopScroll});

  @override
  _BodyCoroState createState() => _BodyCoroState();
}

class _BodyCoroState extends State<BodyCoro> {
  double fontSize;
  double initfontSize;

  @override
  void initState() {
    super.initState();
    initfontSize = widget.initfontSize;
    fontSize = initfontSize;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: Key('GestureDetector-Coro'),
      onScaleUpdate: (ScaleUpdateDetails details) {
        double newFontSize = initfontSize*details.scale;
        setState(() => fontSize = newFontSize < 10.0 ? 10.0 : newFontSize);
      },
      onScaleEnd: (ScaleEndDetails details) {
        initfontSize = fontSize;
      },
      onTapDown: (TapDownDetails details) => widget.stopScroll(),
      onHorizontalDragDown: (DragDownDetails details) => widget.stopScroll(),
      onVerticalDragDown: (DragDownDetails details) => widget.stopScroll(),
      child: Container(
        child: (widget.estrofas.isNotEmpty ? ListView(
          controller: widget.scrollController,
          physics: BouncingScrollPhysics(),
          children: <Widget>[
            CoroText(
              estrofas: widget.estrofas,
              fontSize: fontSize,
              alignment: widget.alignment,
              acordes: widget.acordes,
              animation: widget.animation,
              notation: widget.notation,
            )
          ],
        ) :
        Center(child: CircularProgressIndicator(),)),
      )
    );
  }
}