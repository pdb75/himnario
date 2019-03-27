import 'package:flutter/material.dart';

import './estructura_himno.dart';

class BodyHimno extends StatefulWidget {

  final String alignment;
  final double initfontSize;
  final List<Parrafo> estrofas;

  BodyHimno({this.initfontSize, this.estrofas, this.alignment});

  @override
  _BodyHimnoState createState() => _BodyHimnoState();
}

class _BodyHimnoState extends State<BodyHimno> {
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
      onScaleUpdate: (ScaleUpdateDetails details) {
        double newFontSize = widget.initfontSize*details.scale;
        setState(() => fontSize = newFontSize < 10.0 ? 10.0 : newFontSize);
      },
      onScaleEnd: (ScaleEndDetails details) {
        initfontSize = fontSize;
      },
      child: Container(
        child: (widget.estrofas.isNotEmpty ? ListView(
            physics: BouncingScrollPhysics(),
            // padding: EdgeInsets.only(bottom: 70.0 + switchMode.value * 130),
            children: <Widget>[
              HimnoText(
                estrofas: widget.estrofas,
                fontSize: fontSize,
                alignment: widget.alignment,
              )
            ],
          ) :
          Center(child: CircularProgressIndicator(),)),
      )
    );
  }
}