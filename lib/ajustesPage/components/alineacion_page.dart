import 'package:flutter/material.dart';
import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AlineacionesPage extends StatefulWidget {
  @override
  AlineacionesPageState createState() => AlineacionesPageState();
}


class AlineacionesPageState extends State<AlineacionesPage> {
  int value;
  List<List<dynamic>> alignments;
  SharedPreferences prefs;

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
        value = i;
      if(prefs.getString('alignment') == null && i == 0)
        value = i;
      botones.add(
        InkWell(
          onTap: () {
            prefs.setString('alignment', alignments[i][0]);
            setState(() => value = i);
          },
          child: Row(
            children: <Widget>[
              Radio(
                onChanged: (int e) {
                  prefs.setString('alignment', alignments[i][0]);
                  setState(() => value = e);
                },
                groupValue: value,
                value: i,
              ),
              Icon(alignments[i][1]),
              Padding(padding: EdgeInsets.only(left: 10.0),),
              Text(alignments[i][0]),
            ],
          ),
        )
      );
    }
    
    return SimpleDialog(
      title: Text('Seleccionar Alineación'),
      children: botones
    );
  }
}