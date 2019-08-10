import 'package:flutter/material.dart';

class BotonVoz extends StatelessWidget {
  
  final bool activo;
  
  BotonVoz({this.voz, this.activo = false, this.onPressed});
  
  final String voz;
  final Function onPressed;

  @override
  Widget build(BuildContext context) {
    return !activo ? OutlineButton(
      color: Theme.of(context).backgroundColor,
      child: Text(voz,
        style: TextStyle(
          fontFamily: Theme.of(context).textTheme.title.fontFamily,
          color: Theme.of(context).textTheme.body1.color
        ),
      ),
      onPressed: onPressed ?? () {},
    ) :
    RaisedButton(
      color: Theme.of(context).primaryColor,
      child: Text(voz,
        style: TextStyle(
          fontFamily: Theme.of(context).textTheme.title.fontFamily,
          color: Theme.of(context).primaryIconTheme.color
        ),
      ),
      onPressed: onPressed ?? () {},
    );
  }
}