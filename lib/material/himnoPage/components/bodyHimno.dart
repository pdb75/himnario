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
              physics: BouncingScrollPhysics(),
              padding: EdgeInsets.only(bottom: 70.0 + widget.switchValue * 130),
              children: <Widget>[
                // GestureDetector(
                //   onTap: () => Navigator.push(
                //     context, 
                //     MaterialPageRoute(
                //       builder: (BuildContext context) => TemaPage(
                //         id: widget.temaId, 
                //         subtema: widget.subTema != '', 
                //         tema: widget.subTema != '' ? widget.subTema : widget.tema
                //       )
                //     )),
                //   child: Column(
                //     crossAxisAlignment: CrossAxisAlignment.start,
                //     children: <Widget>[
                //       Container(
                //         padding: EdgeInsets.only(top: 10.0, left: 15.0, right: 15.0, bottom: 5.0),
                //         child: Text(
                //             widget.tema,
                //             style: DefaultTextStyle.of(context).style.copyWith(
                //               color: Colors.blueAccent,
                //               fontSize: fontSize*0.8,
                //               fontStyle: FontStyle.italic,
                //               fontWeight: FontWeight.w300
                //             ),
                //           ),
                        
                //       ),
                //       widget.subTema != '' ? Container(
                //         padding: EdgeInsets.only(top: 0.0, left: 15.0, right: 15.0, bottom: 0.0),
                //         child: Text(
                //             widget.subTema,
                //             style: DefaultTextStyle.of(context).style.copyWith(
                //               color: Colors.blueAccent,
                //               fontSize: fontSize*0.8,
                //               fontStyle: FontStyle.italic,
                //               fontWeight: FontWeight.w300
                //             )
                //           ),
                //       ) : Container()
                //     ],
                //   ),
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