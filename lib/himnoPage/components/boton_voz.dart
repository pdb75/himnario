import 'package:flutter/material.dart';

class BotonVoz extends StatelessWidget {
  
  bool activo = false;
  
  BotonVoz({this.voz, this.activo, this.onPressed});
  
  final String voz;
  final Function onPressed;

  @override
  Widget build(BuildContext context) {
    return !activo ? OutlineButton(
      child: Text(voz,
        style: TextStyle(
          fontFamily: Theme.of(context).textTheme.title.fontFamily,
          color: Theme.of(context).accentColor
        ),
      ),
      onPressed: onPressed ?? () {},
    ) :
    RaisedButton(
      color: Theme.of(context).accentColor,
      child: Text(voz,
        style: TextStyle(
          fontFamily: Theme.of(context).textTheme.title.fontFamily,
          color: Theme.of(context).indicatorColor
        ),
      ),
      onPressed: onPressed ?? () {},
    );
  }
}