import 'package:flutter/material.dart';

class BotonVoz extends StatelessWidget {
  String voz;
  bool activo = false;
  Function onPressed;

  BotonVoz({this.voz, this.activo, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return !activo ? OutlineButton(
      child: Text(voz,
        style: TextStyle(
          color: Colors.lightBlue
        ),
      ),
      onPressed: onPressed ?? () {},
    ) :
    RaisedButton(
      color: Colors.blue,
      child: Text(voz,
        style: TextStyle(
          color: Colors.white
        ),
      ),
      onPressed: onPressed ?? () {},
    );
  }
}