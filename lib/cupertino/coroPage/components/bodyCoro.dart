import 'package:flutter/material.dart';

import './estructura_Coro.dart';
import '../../models/himnos.dart';

class BodyCoro extends StatefulWidget {

  final String alignment;
  final double initfontSizeProtrait;
  final double initfontSizeLandscape;
  final List<Parrafo> estrofas;
  final bool acordes;
  final double animation;
  final String notation;
  final ScrollController scrollController;
  final Function stopScroll;

  BodyCoro({this.estrofas, this.alignment, this.acordes, this.animation, this.notation, this.stopScroll, this.scrollController, this.initfontSizeLandscape, this.initfontSizeProtrait});

  @override
  _BodyCoroState createState() => _BodyCoroState();
}

class _BodyCoroState extends State<BodyCoro> {
  double fontSizeProtrait;
  double initfontSizeProtrait;
  double fontSizeLandscape;
  double initfontSizeLandscape;

  @override
  void initState() {
    super.initState();
    // Protrait Font Size
    initfontSizeProtrait = widget.initfontSizeProtrait;
    fontSizeProtrait = initfontSizeProtrait;

    // Landscape Font Size
    initfontSizeLandscape = widget.initfontSizeLandscape;
    fontSizeLandscape = initfontSizeLandscape;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: Key('GestureDetector-Coro'),
      onScaleUpdate: MediaQuery.of(context).orientation == Orientation.portrait ? (ScaleUpdateDetails details) {
        double newFontSize = initfontSizeProtrait*details.scale;
        setState(() => fontSizeProtrait = newFontSize < 10.0 ? 10.0 : newFontSize);
      } : (ScaleUpdateDetails details) {
        double newFontSize = initfontSizeLandscape*details.scale;
        setState(() => fontSizeLandscape = newFontSize < 10.0 ? 10.0 : newFontSize);
      },
      onScaleEnd: MediaQuery.of(context).orientation == Orientation.portrait ? (ScaleEndDetails details) {
        initfontSizeProtrait = fontSizeProtrait;
      } : (ScaleEndDetails details) {
        initfontSizeLandscape = fontSizeLandscape;
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
              fontSize: MediaQuery.of(context).orientation == Orientation.portrait ? fontSizeProtrait : fontSizeLandscape,
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