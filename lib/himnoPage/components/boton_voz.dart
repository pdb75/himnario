import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class BotonVoz extends StatelessWidget {
  
  final bool activo;
  
  BotonVoz({this.voz, this.activo = false, this.onPressed});
  
  final String voz;
  final Function onPressed;

  @override
  Widget build(BuildContext context) {
    return !activo ? Container(
      height: 40.0,
      width: 120.0,
      margin: EdgeInsets.symmetric(vertical: 5.0),
      child: CupertinoButton(
        color: CupertinoTheme.of(context).scaffoldBackgroundColor,
        padding: EdgeInsets.symmetric(horizontal: 0.0),
        child: Text(voz,
          style: TextStyle(
            fontFamily: Theme.of(context).textTheme.title.fontFamily,
            color: CupertinoTheme.of(context).primaryColor
          ),
        ),
        onPressed: onPressed ?? () {},
      ),
    ) :
    Container(
      height: 40.0,
      width: 120.0,
      margin: EdgeInsets.symmetric(vertical: 5.0),
      child: CupertinoButton(
        color: CupertinoTheme.of(context).primaryColor,
        padding: EdgeInsets.symmetric(horizontal: 0.0),
        child: Text(voz,
          style: TextStyle(
            fontFamily: Theme.of(context).textTheme.title.fontFamily,
            color: CupertinoTheme.of(context).brightness == Brightness.dark ? 
              CupertinoTheme.of(context).textTheme.textStyle.color :
              Colors.white
          ),
        ),
        onPressed: onPressed ?? () {},
      ),
    );
  }
}