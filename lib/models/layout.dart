import 'package:flutter/widgets.dart';

class MainMenuTile {
  Icon icon;
  String title;
  Function onTap;

  MainMenuTile({this.icon, this.title, this.onTap});
}

class HimnosListTile {
  String title;
  Route route;
  bool expanded;
  List<HimnosListTile> subCategorias;

  HimnosListTile({this.title, this.route, this.expanded = false, this.subCategorias = const []});
}
