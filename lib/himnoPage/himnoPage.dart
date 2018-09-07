import 'package:flutter/material.dart';

import 'himno.dart';

class HimnoPageController extends StatefulWidget {
  
  @override
  _HimnoPageControllerState createState() => _HimnoPageControllerState();
}

class _HimnoPageControllerState extends State<HimnoPageController> {
  @override
  Widget build(BuildContext context) {

    return HimnoPage(
      numero: 251,
      titulo: 'asdasdsa',
    );
  }
}