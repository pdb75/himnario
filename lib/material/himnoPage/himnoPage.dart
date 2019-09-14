import 'package:flutter/material.dart';

class HimnoBuilder extends StatefulWidget {
  final int initialHimno;

  HimnoBuilder({this.initialHimno});

  @override
  _HimnoBuilderState createState() => _HimnoBuilderState();
}

class _HimnoBuilderState extends State<HimnoBuilder> {
  int currentHimno;

  @override
  void initState() {
    super.initState();
    currentHimno = widget.initialHimno;
  }

  void getHimnos() {
    
  }



  @override
  Widget build(BuildContext context) {

    return Container();
  }
}