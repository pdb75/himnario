import 'package:Himnario/cupertino/models/tema.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FuentesPage extends StatefulWidget {
  @override
  _FuentesPageState createState() => _FuentesPageState();
}


class _FuentesPageState extends State<FuentesPage> {
  SharedPreferences prefs;
  List<String> fuentes;
  int currentValue;
  int value;

  @override
  void initState() {
    super.initState();
    fuentes = ['Josefin Sans', 'Lato', 'Merriweather', 'Montserrat', 'Open Sans', 'Poppins', 'Raleway', 'Roboto Mono', 'Rubik', 'Source Sans Pro', '.SF Pro Text'];
    for(int i = 0; i < fuentes.length; ++i)
      if (ScopedModel.of<TemaModel>(context).font == fuentes[i])
    currentValue = i;
    SharedPreferences.getInstance().then((prefsInstance) => prefs = prefsInstance);
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> botones = List<Widget>();
    for(int i = 0; i < fuentes.length; ++i) {
      botones.add(
        CupertinoButton(
          onPressed: () => setState(() => value = i),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                fuentes[i],
                style: TextStyle(
                  fontFamily: fuentes[i]
                ),
              ),
              IgnorePointer(
                child: CupertinoSwitch(
                  onChanged: (e) => e,
                  value: value == null ? currentValue == i : value == i,
                ),
              )
            ],
          )
        )
      );
    }
    return CupertinoAlertDialog(
      title: Text('Seleccionar Fuente'),
      content: SingleChildScrollView(
        child: Column(
          children: botones,
        ),
      ),
      actions: <Widget>[
        FlatButton(
          child: Text('Cancelar', style: Theme.of(context).textTheme.button,),
          onPressed: () => Navigator.of(context).pop(),
        ),
        FlatButton(
          child: Text('Guardar', style: Theme.of(context).textTheme.button,),
          onPressed: () {
            if(value != null) {
              ScopedModel.of<TemaModel>(context).setFont(fuentes[value]);
              prefs.setString('font', fuentes[value]);
            }
            setState(() {});
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}