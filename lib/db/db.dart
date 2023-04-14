import 'dart:io';
import 'dart:typed_data';

import 'package:Himnario/helpers/isAndroid.dart';
import 'package:Himnario/helpers/parseVersion.dart';
import 'package:Himnario/models/himnos.dart';
import 'package:flutter/services.dart';
import 'package:package_info/package_info.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

String dbPath;

class DB {
  static Future<Null> init() async {
    if (dbPath == null) {
      String databasesPath = (await getApplicationDocumentsDirectory()).path;
      dbPath = databasesPath + "/himnos.db";
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String version = prefs.getString('version');
    String actualVersion = (await PackageInfo.fromPlatform()).version;
    print('actualVersion: $actualVersion');
    print('newVersion: $version');
    if (version == null || version != actualVersion) {
      await copiarBase(dbPath, version == null, version == null ? 0.0 : parseVersion(version));
      prefs.setString('version', actualVersion);
      prefs.setString('latest', null);
    }
  }

  static String path() => dbPath;

  static Future<Null> copiarBase(String dbPath, bool fistRun, double version) async {
    print('entro a copiar');
    print(fistRun);

    Database db;

    // Favoritos
    List<int> favoritos = List<int>();
    // Descargados
    List<List<int>> descargados = List<List<int>>();
    // transpose
    List<Himno> transposedHImnos = List<Himno>();
    if (!fistRun) {
      print('abriendo base de datos');
      try {
        if (version < 2.2) {
          print('Old Version db path');
          db = await openDatabase(await getDatabasesPath() + '/himnos.db');
        } else {
          print('New Version db path');
          db = await openDatabase((await getApplicationDocumentsDirectory()).path + '/himnos.db');
        }
        for (Map<String, dynamic> favorito in (await db.rawQuery('select * from favoritos'))) {
          favoritos.add(favorito['himno_id']);
        }
        try {
          for (Map<String, dynamic> descargado in (await db.rawQuery('select * from descargados'))) {
            descargados.add([descargado['himno_id'], descargado['duracion']]);
          }
        } catch (e) {
          print(e);
        }
        try {
          if (version > (isAndroid() ? 3.9 : 2.4))
            transposedHImnos = Himno.fromJson((await db.rawQuery('select * from himnos where transpose != 0')));
        } catch (e) {
          print(e);
        }
        await db.close();
      } catch (e) {
        print(e);
      }
    }
    ByteData data = await rootBundle.load("assets/himnos_coros.sqlite");
    List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    print('antes de abrir');
    await new File(dbPath).writeAsBytes(bytes);
    db = await openDatabase(dbPath);
    if (!fistRun) {
      await db.execute('CREATE TABLE IF NOT EXISTS favoritos(himno_id int, FOREIGN KEY (himno_id) REFERENCES himnos(id))');
      await db.execute('CREATE TABLE IF NOT EXISTS descargados(himno_id int, duracion int, FOREIGN KEY (himno_id) REFERENCES himnos(id))');
      for (int favorito in favoritos) await db.rawInsert('insert into favoritos values ($favorito)');
      for (List<int> descargado in descargados) await db.rawInsert('insert into descargados values (${descargado[0]}, ${descargado[1]})');
      for (Himno himno in transposedHImnos) await db.rawQuery('update himnos set transpose = ${himno.transpose} where id = ${himno.numero}');
    } else {
      await db.execute('CREATE TABLE IF NOT EXISTS favoritos(himno_id int, FOREIGN KEY (himno_id) REFERENCES himnos(id))');
      await db.execute('CREATE TABLE IF NOT EXISTS descargados(himno_id int, duracion int, FOREIGN KEY (himno_id) REFERENCES himnos(id))');
    }
    await db.close();
    return null;
  }

  static Future<Null> execute(String sql, [List<dynamic> arguments]) async {
    Database db = await openDatabase(dbPath);

    await db.execute(sql, arguments);

    await db.close();
  }

  static dynamic rawQuery(String sql, [List<dynamic> arguments]) async {
    Database db = await openDatabase(dbPath);

    dynamic res = await db.rawQuery(sql, arguments);

    await db.close();

    return res;
  }

  static dynamic rawInsert(String sql, [List<dynamic> arguments]) async {
    Database db = await openDatabase(dbPath);

    dynamic res = await db.rawInsert(sql, arguments);

    await db.close();

    return res;
  }

  static dynamic rawDelete(String sql, [List<dynamic> arguments]) async {
    Database db = await openDatabase(dbPath);

    dynamic res = await db.rawDelete(sql, arguments);

    await db.close();

    return res;
  }
}
