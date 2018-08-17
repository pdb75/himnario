import 'package:flutter/material.dart';

class Estrofa extends StatelessWidget {
  int numero;
  String estrofa;

  Estrofa({this.numero, this.estrofa});

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
            fontSize: 20.0
          ),
          )
        ],
      ),
    );
  }
}

class Coro extends StatelessWidget {
  String coro;

  Coro({this.coro});

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
                fontSize: 20.0
              ),
          )
        ],
      ),
    );
  }
}