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
          color: Theme.of(context).accentColor
        ),
      ),
      onPressed: onPressed ?? () {},
    ) :
    RaisedButton(
      color: Theme.of(context).accentColor,
      child: Text(voz,
        style: TextStyle(
          color: Theme.of(context).indicatorColor
        ),
      ),
      onPressed: onPressed ?? () {},
    );
  }
}