import 'package:Himnario/cupertino/models/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:scoped_model/scoped_model.dart';
import '../../models/himnos.dart';

class CoroText extends StatelessWidget {

  CoroText({this.estrofas, this.fontSize, this.alignment = 'Izquierda', this.acordes, this.animation, this.notation});

  final String alignment;
  final List<Parrafo> estrofas;
  final double fontSize;
  final bool acordes;
  final double animation;
  final String notation;

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
      List<String> lineasAcordes = parrafo.acordes.isNotEmpty ? notation == 'americana' ? Acordes.toAmericano(parrafo.acordes).split('\n') : parrafo.acordes.split('\n') : List<String>();
      List<String> lineasParrafos = parrafo.parrafo.split('\n');
      if(parrafo.coro) {
        parrafos.add(
          TextSpan(
            text: 'Coro\n',
            style: TextStyle(
              color: ScopedModel.of<TemaModel>(context).getScaffoldTextColor(),
              fontStyle: FontStyle.italic,
              fontFamily: ScopedModel.of<TemaModel>(context).font,
              fontWeight: FontWeight.w300,
              fontSize: fontSize
            ),
          )
        );
        for (int i = 0; i < lineasParrafos.length; ++i) {
          parrafos.addAll([
            lineasAcordes.isEmpty || i >= lineasAcordes.length || lineasAcordes[i] == '' ? TextSpan() : TextSpan(
              text: lineasAcordes[i] + '\n',
              style: TextStyle(
                fontSize: animation*fontSize,
                height: Theme.of(context).textTheme.body1.height,
                fontFamily: ScopedModel.of<TemaModel>(context).font,
                fontWeight: FontWeight.bold,
                wordSpacing: 0.3,
                color: Color.fromRGBO(
                  ScopedModel.of<TemaModel>(context).brightness == Brightness.light ? CupertinoTheme.of(context).primaryColor.red : ScopedModel.of<TemaModel>(context).mainColor.red ,
                  ScopedModel.of<TemaModel>(context).brightness == Brightness.light ? CupertinoTheme.of(context).primaryColor.green : ScopedModel.of<TemaModel>(context).mainColor.green, 
                  ScopedModel.of<TemaModel>(context).brightness == Brightness.light ? CupertinoTheme.of(context).primaryColor.blue : ScopedModel.of<TemaModel>(context).mainColor.blue, 
                  animation),
              )
            ),
            TextSpan(
              text: lineasParrafos[i] + (i == lineasParrafos.length - 1 ? '\n\n' : '\n'),
              style: TextStyle(
                color: ScopedModel.of<TemaModel>(context).getScaffoldTextColor(),
                fontStyle: FontStyle.italic,
                fontFamily: ScopedModel.of<TemaModel>(context).font,
                fontSize: fontSize
              )
            ),
          ]);
        }
      }
      else {
        for (int i = 0; i < lineasParrafos.length; ++i) {
          parrafos.addAll([
            lineasAcordes.isEmpty || i >= lineasAcordes.length || lineasAcordes[i] == '' ? TextSpan() : TextSpan(
              text: lineasAcordes[i] + '\n',
              style: TextStyle(
                wordSpacing: 0.3,
                fontSize: animation*fontSize,
                fontFamily: ScopedModel.of<TemaModel>(context).font,
                fontWeight: FontWeight.bold,
                color: Color.fromRGBO(
                  ScopedModel.of<TemaModel>(context).brightness == Brightness.light ? CupertinoTheme.of(context).primaryColor.red : ScopedModel.of<TemaModel>(context).mainColor.red, 
                  ScopedModel.of<TemaModel>(context).brightness == Brightness.light ? CupertinoTheme.of(context).primaryColor.green : ScopedModel.of<TemaModel>(context).mainColor.green, 
                  ScopedModel.of<TemaModel>(context).brightness == Brightness.light ? CupertinoTheme.of(context).primaryColor.blue : ScopedModel.of<TemaModel>(context).mainColor.blue, 
                  animation),
              )
            ),
            TextSpan(
              text: lineasParrafos[i] + (i == lineasParrafos.length - 1 ? '\n\n' : '\n'),
              style: TextStyle(
                color: ScopedModel.of<TemaModel>(context).getScaffoldTextColor(),
                fontSize: fontSize,
                fontFamily: ScopedModel.of<TemaModel>(context).font,
              )
            ),
          ]);
        }
      }
    }
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
      child: Center(
        child: RichText(
          textDirection: TextDirection.ltr,
          textAlign: align,
          // softWrap: false,
          // overflow: TextOverflow.fade,
          text: TextSpan(
            style: DefaultTextStyle.of(context).style.copyWith(
              fontFamily: ScopedModel.of<TemaModel>(context).font,
            ),
            children: parrafos
          ),
        )
      )
    );
  }
}