import 'package:flutter/material.dart';

class HimnoText extends StatelessWidget {

  final String alignment;

  HimnoText({this.estrofas, this.fontSize, this.alignment = 'Izquierda'});

  final List<Parrafo> estrofas;
  final double fontSize;
  
  @override
  Widget build(BuildContext context) {
    TextAlign align;
    switch(alignment) {
      case 'Izquierda': {
        align = TextAlign.left;
      } break;
      case 'Centro': {
        align = TextAlign.center;
      } break;
      case 'Derecha': {
        align = TextAlign.right;
      } break;
      default: {
        align = TextAlign.left;
      } break;
    }
    List<TextSpan> parrafos = List<TextSpan>();
    for(Parrafo parrafo in estrofas) {
      if(parrafo.coro)
        parrafos.addAll([
          TextSpan(
            text: 'Coro\n',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w300,
              fontSize: fontSize
            ),
          ),
          TextSpan(
            text: parrafo.parrafo + '\n\n',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              fontSize: fontSize
            )
          )
        ]);
      else
        parrafos.addAll([
          TextSpan(
            text: '${parrafo.orden}  ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: fontSize
            )
          ),
          TextSpan(
            text: parrafo.parrafo + '\n\n',
            style: TextStyle(
              fontSize: fontSize
            )
          )
        ]);
    }

    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
      child: Center(
        child: RichText(
          textDirection: TextDirection.ltr,
          textAlign: align,
          text: TextSpan(
            style: DefaultTextStyle.of(context).style,
            children: parrafos
          ),
        )
      )
    );
  }
}

class Parrafo {
  int numero;
  int orden;
  bool coro;
  String parrafo;

  Parrafo({this.numero, this.orden, this.coro, this.parrafo});

  static List<Parrafo> fromJson(List<dynamic> res) {
    List<Parrafo> parrafos = List<Parrafo>();
    int numeroEstrofa = 0;
    for (var x in res) {
      if (x['coro'] == 0) ++numeroEstrofa;
      parrafos.add(Parrafo(
        numero: x['numero'],
        orden: numeroEstrofa,
        coro: x['coro'] == 1 ? true : false,
        parrafo: x['parrafo']
      ));
    }
    return parrafos;
  }
}