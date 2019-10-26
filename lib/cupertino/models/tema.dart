import 'package:scoped_model/scoped_model.dart';
import 'package:flutter/material.dart';



class TemaModel extends Model {
  Color _mainColor = Color(3438868728);
  Color _mainColorContrast = Colors.black;
  Brightness _brightness = Brightness.light;
  String _font;

  Color get mainColor => _mainColor;
  Color get mainColorContrast => _mainColorContrast;
  Brightness get brightness => _brightness;
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

  void setBrightness(Brightness brightness) {
    _brightness = brightness;
    notifyListeners();
  }

  Color getTabBackgroundColor() => _brightness == Brightness.light ? mainColor : Color.fromRGBO(33, 33, 33, 0.7176470588235294);
  Color getScaffoldBackgroundColor() => _brightness == Brightness.light ? Colors.white : Colors.black;
  Color getTabTextColor() => _brightness == Brightness.light ? _mainColorContrast : Colors.white;
  Color getScaffoldTextColor() => _brightness == Brightness.light ? Colors.black : Colors.white;
  Color getAccentColor() => _brightness == Brightness.light ? _mainColor : Colors.greenAccent;
  Color getAccentColorText() => _brightness == Brightness.light ? _mainColorContrast : Colors.black;

}