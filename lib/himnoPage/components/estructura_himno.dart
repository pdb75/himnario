import 'package:flutter/material.dart';

class Estrofa extends StatelessWidget {
  int numero;
  String estrofa;
  double fontSize;

  Estrofa({this.numero, this.estrofa, this.fontSize});

  @override
  Widget build(BuildContext context) {
    int lineas = 1;
    int ultimoIndex = 0;
    while(estrofa.contains('\n', ultimoIndex)) {
      ++lineas;
      ultimoIndex = ultimoIndex + (estrofa.substring(ultimoIndex, estrofa.length)).indexOf('\n') + 1;
    }
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(right: 10.0, bottom: lineas * 14.0),
            child: Text(numero.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold 
              ),
            )
          ),
          Text(estrofa,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: fontSize
          ),
          )
        ],
      ),
    );
  }
}

class Coro extends StatelessWidget {
  String coro;
  double fontSize;

  Coro({this.coro, this.fontSize});

  @override
  Widget build(BuildContext context) {
    int lineas = 1;
    int ultimoIndex = 0;
    while(coro.contains('\n', ultimoIndex)) {
      ++lineas;
      ultimoIndex = ultimoIndex + (coro.substring(ultimoIndex, coro.length)).indexOf('\n') + 1;
    }
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(right: 10.0, bottom: lineas * 14.0),
            child: Text('Coro:',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w300 
              ),
            )
          ),
          Text(coro,
          textAlign: TextAlign.center,
          style: TextStyle(
                fontStyle: FontStyle.italic,
                fontSize: fontSize
              ),
          )
        ],
      ),
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