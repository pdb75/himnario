import 'package:flutter/material.dart';

import 'coro.dart';

class CoroPageController extends StatefulWidget {
  
  @override
  _CoroPageControllerState createState() => _CoroPageControllerState();
}

class _CoroPageControllerState extends State<CoroPageController> {
  @override
  Widget build(BuildContext context) {

    return CoroPage(
      numero: 251,
      titulo: 'asdasdsa',
    );
  }
}