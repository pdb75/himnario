import 'package:Himnario/cupertino/himnos/tema.dart';
import 'package:Himnario/cupertino/models/tema.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';

import './estructura_himno.dart';
import '../../models/himnos.dart';

class BodyHimno extends StatefulWidget {

  final String alignment;
  final double initfontSize;
  final List<Parrafo> estrofas;
  final String tema;
  final String subTema;
  final int temaId;

  BodyHimno({this.initfontSize, this.estrofas, this.alignment, this.tema, this.subTema, this.temaId});

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
    final tema = ScopedModel.of<TemaModel>(context);
    return GestureDetector(
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
          // padding: EdgeInsets.only(bottom: 70.0 + switchMode.value * 130),
          children: <Widget>[
            // GestureDetector(
            //   onTap: () => Navigator.push(
            //     context, 
            //     CupertinoPageRoute(
            //       builder: (BuildContext context) => ScopedModel(
            //         model: tema,
            //         child: TemaPage(id: widget.temaId, subtema: widget.subTema != '', tema: (widget.subTema != '') ? widget.subTema : widget.tema),
            //       )
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
    );
  }
}