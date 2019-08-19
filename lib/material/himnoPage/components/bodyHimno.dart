import 'package:flutter/material.dart';

import '../../himnos/tema.dart';
import './estructura_himno.dart';
import '../../models/himnos.dart';

class BodyHimno extends StatefulWidget {

  final String alignment;
  final double initfontSizeProtrait;
  final double initfontSizeLandscape;
  final List<Parrafo> estrofas;
  final double switchValue;
  final String tema;
  final String subTema;
  final int temaId;

  BodyHimno({this.estrofas, this.alignment, this.switchValue, this.tema, this.subTema, this.temaId, this.initfontSizeProtrait, this.initfontSizeLandscape});

  @override
  _BodyHimnoState createState() => _BodyHimnoState();
}

class _BodyHimnoState extends State<BodyHimno> {
  ScrollController controller;
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
    controller = ScrollController();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: Key('GestureDetector-Himno'),
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
      child: Container(
        child: (widget.estrofas.isNotEmpty ? ListView(
          controller: controller,
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.only(bottom: 70.0 + widget.switchValue * 130),
          children: <Widget>[
            HimnoText(
              estrofas: widget.estrofas,
              fontSize: MediaQuery.of(context).orientation == Orientation.portrait ? fontSizeProtrait : fontSizeLandscape,
              alignment: widget.alignment,
            )
          ],
        ) :
        Center(child: CircularProgressIndicator(),)),
      )
    );
  }
}