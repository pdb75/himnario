import 'dart:io';

import 'package:Himnario/models/tema.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:scoped_model/scoped_model.dart';

Route getPageRoute(
  Widget page, {
  TemaModel tema,
}) {
  if (Platform.isAndroid) {
    return MaterialPageRoute(
      builder: (BuildContext context) => page,
    );
  }
  return CupertinoPageRoute(
    builder: (BuildContext context) => ScopedModel<TemaModel>(
      model: tema,
      child: page,
    ),
  );
}
