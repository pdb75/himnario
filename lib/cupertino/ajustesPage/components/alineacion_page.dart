import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AlineacionesPage extends StatefulWidget {
  @override
  AlineacionesPageState createState() => AlineacionesPageState();
}


class AlineacionesPageState extends State<AlineacionesPage> {
  List<List<dynamic>> alignments;
  SharedPreferences prefs;
  int currentValue;
  int value;

  @override
  void initState() {
    super.initState();
    alignments = [
      ['Izquierda', Icons.format_align_left],
      ['Centro', Icons.format_align_center],
      ['Derecha', Icons.format_align_right]
    ];
    initPrefs();
  }

  void initPrefs() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> botones = List<Widget>();
    if(prefs != null)
      for(int i = 0; i < alignments.length; ++i) {
        if (prefs.getString('alignment') == alignments[i][0])
          currentValue = i;
        if(prefs.getString('alignment') == null && i == 0)
          currentValue = i;
        
      botones.add(
        CupertinoButton(
          onPressed: () => setState(() => value = i),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(right: 10.0),
                    child: Icon(alignments[i][1]),
                  ),
                  Text(
                    alignments[i][0],
                  ),
                ],
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
      title: Text('Seleccionar Alineación'),
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
              prefs.setString('alignment', alignments[value][0]);
            }
            setState(() {});
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}