import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_crashlytics/flutter_crashlytics.dart';

import 'cupertino/himnos/himnos.dart';
import 'material/himnos/himnos.dart';

void main() async {
  ThemeData tema;
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String temaJson = prefs.getString('tema');

  if (temaJson == null)
    tema = ThemeData(
      primarySwatch: Colors.deepPurple,
      fontFamily: prefs.getString('fuente') ?? 'Roboto',
    );
  else {
    Map<dynamic, dynamic> json = jsonDecode(temaJson);
    tema = ThemeData(
      primarySwatch: MaterialColor(json['value'], {
        50:Color.fromRGBO(json['red'], json['green'], json['blue'], .1),
        100:Color.fromRGBO(json['red'], json['green'], json['blue'], .2),
        200:Color.fromRGBO(json['red'], json['green'], json['blue'], .3),
        300:Color.fromRGBO(json['red'], json['green'], json['blue'], .4),
        400:Color.fromRGBO(json['red'], json['green'], json['blue'], .5),
        500:Color.fromRGBO(json['red'], json['green'], json['blue'], .6),
        600:Color.fromRGBO(json['red'], json['green'], json['blue'], .7),
        700:Color.fromRGBO(json['red'], json['green'], json['blue'], .8),
        800:Color.fromRGBO(json['red'], json['green'], json['blue'], .9),
        900:Color.fromRGBO(json['red'], json['green'], json['blue'], 1),
      }
    ),
    fontFamily: prefs.getString('fuente') ?? 'Roboto',
  );
  }
  bool isInDebugMode = false;

  FlutterError.onError = (FlutterErrorDetails details) {
    if (isInDebugMode) {
      // In development mode simply print to console.
      FlutterError.dumpErrorToConsole(details);
    } else {
      // In production mode report to the application zone to report to
      // Crashlytics.
      Zone.current.handleUncaughtError(details.exception, details.stack);
    }
  };

  await FlutterCrashlytics().initialize();

  runZoned<Future<Null>>(() async {
    runApp(MyApp(tema: tema,));
  }, onError: (error, stackTrace) async {
    // Whenever an error occurs, call the `reportCrash` function. This will send
    // Dart errors to our dev console or Crashlytics depending on the environment.
    await FlutterCrashlytics().reportCrash(error, stackTrace, forceCrash: false);
  });
}

class MyApp extends StatelessWidget {

  MyApp({this.tema});

  final ThemeData tema;

  @override
  Widget build(BuildContext context) {
    return Platform.isAndroid ? DynamicTheme(
      data: (Brightness brightness) => tema,
      themedWidgetBuilder: (BuildContext context, ThemeData theme) =>
      MaterialApp(
        debugShowCheckedModeBanner: false,
        showSemanticsDebugger: false,
        title: 'Himnos y Cánticos del Evangelio',
        theme: theme,
        home: HimnosPage(),
      )
    ) : CupertinoApp(
        debugShowCheckedModeBanner: false,
        theme: CupertinoThemeData(
        primaryColor: Colors.black,
        // brightness: Brightness.dark
      ),
      title: 'Himnos y Cánticos del Evangelio',
      home: CupertinoHimnosPage(),
    );
  }
}
