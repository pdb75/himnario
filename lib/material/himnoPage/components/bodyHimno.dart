import 'package:flutter/material.dart';

import '../../himnos/tema.dart';
import './estructura_himno.dart';
import '../../models/himnos.dart';

class BodyHimno extends StatefulWidget {

  final String alignment;
  final double initfontSize;
  final List<Parrafo> estrofas;
  final double switchValue;
  final String tema;
  final String subTema;
  final int temaId;

  BodyHimno({this.initfontSize, this.estrofas, this.alignment, this.switchValue, this.tema, this.subTema, this.temaId});

  @override
  _BodyHimnoState createState() => _BodyHimnoState();
}

class _BodyHimnoState extends State<BodyHimno> {
  ScrollController controller;
  double fontSize;
  double initfontSize;

  @override
  void initState() {
    super.initState();
    initfontSize = widget.initfontSize;
    fontSize = initfontSize;
    controller = ScrollController();
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      children: <Widget>[
        GestureDetector(
          key: Key('GestureDetector-Himno'),
          onScaleUpdate: (ScaleUpdateDetails details) {
            double newFontSize = initfontSize*details.scale;
            setState(() => fontSize = newFontSize < 10.0 ? 10.0 : newFontSize);
          },
          onScaleEnd: (ScaleEndDetails details) {
            initfontSize = fontSize;
          },
          child: Container(
            child: (widget.estrofas.isNotEmpty ? ListView(
              controller: controller,
              physics: BouncingScrollPhysics(),
              padding: EdgeInsets.only(bottom: 70.0 + widget.switchValue * 130),
              children: <Widget>[
                // GestureDetector(
                //   onTap: () => Navigator.push(
                //     context, 
                //     MaterialPageRoute(
                //       builder: (BuildContext context) => TemaPage(id: widget.temaId, subtema: widget.subTema != '', tema: (widget.subTema != '') ? widget.subTema : widget.tema)
                //     )
                //   ),
                //   child: Padding(
                //     padding: EdgeInsets.symmetric(vertical: 10.0),
                //     child: Center(
                //       child: Text(
                //         '- ' + widget.tema + ((widget.subTema != '') ? '\n~ ' + widget.subTema : ''),
                //         textAlign: TextAlign.center,
                //         style: DefaultTextStyle.of(context).style.copyWith(
                //           fontSize: fontSize,
                //           fontStyle: FontStyle.italic
                //         ),
                //       ),
                //     ),
                //   ),
                // ),
                // Container(
                //   margin: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width/4),
                //   height: fontSize*0.04,
                //   color: Colors.black12,
                // ),
                HimnoText(
                  estrofas: widget.estrofas,
                  fontSize: fontSize,
                  alignment: widget.alignment,
                )
              ],
            ) :
            Center(child: CircularProgressIndicator(),)),
          )
        ),
      ]
    );
  }
}