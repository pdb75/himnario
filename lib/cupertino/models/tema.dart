import 'package:scoped_model/scoped_model.dart';
import 'package:flutter/material.dart';



class TemaModel extends Model {
  Color _mainColor = Color(3438868728);
  Color _mainColorContrast = Colors.black;
  String _font;

  Color get mainColor => _mainColor;
  Color get mainColorContrast => _mainColorContrast;
  String get font => _font;

  static TemaModel of(BuildContext context) =>
      ScopedModel.of<TemaModel>(context);

  void setMainColor(Color color) {
    _mainColor = color;
    _mainColorContrast = (color.red*0.299 + color.green*0.587 + color.blue*0.114) > 172 ? Colors.black : Colors.white;
    notifyListeners();
  }

  void setFont(String font) {
    _font = font;
    notifyListeners();
  }

}