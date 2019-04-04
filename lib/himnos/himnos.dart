import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info/package_info.dart';
import 'package:http/http.dart' as http;

import '../models/himnos.dart';
import './tema.dart';
import '../buscador/buscador.dart';
import '../ajustesPage/ajustes_page.dart';
import '../favoritosPage/favoritos_page.dart';
import '../descargadosPage/descargados_page.dart';
import '../quickBuscador/quick_buscador.dart';
import '../vocesDisponibles/voces_disponibles.dart';

class HimnosPage extends StatefulWidget {
  @override
  _HimnosPageState createState() => _HimnosPageState();
}

class _HimnosPageState extends State<HimnosPage> {
  List<Categoria> categorias;
  Database db;
  bool cargando;

  @override
  void initState() {
    super.initState();
    cargando = true;
    categorias = List<Categoria>();
    initDB();
  }

  Future<Null> checkUpdates(SharedPreferences prefs, Database db) async {
    String date = prefs.getString('latest');
    http.Response res = await http.post(
      'http://104.131.104.212:8085/updates',
      headers: {'Content-Type': 'application/json'},
      body: utf8.encode(json.encode({'latest': date != null ? date : '2018-08-19 05:01:46.447 +00:00'}))
    );
    List<dynamic> latest = jsonDecode(res.body);
    print(latest.isEmpty);
    if (latest.isNotEmpty)
      if (date == null || date != latest[0]['updatedAt']) {
        for (dynamic himno in latest) {
          await db.rawUpdate("update parrafos set parrafo = '${himno['parrafo']}', updatedAt = CURRENT_TIMESTAMP where id = ${himno['id']}");
        }
        prefs.setString('latest', latest[0]['updatedAt']);
      }
  }

  Future<Null> initDB() async {
    String databasesPath = (await getApplicationDocumentsDirectory()).path;
    String path = databasesPath + "/himnos.db";

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String version = prefs.getString('version');
    String actualVersion = (await PackageInfo.fromPlatform()).version;
    print('actualVersion: $actualVersion');
    print('newVersion: $version');
    if (version == null || version != actualVersion) {
      await copiarBase(path, version == null, version == null ? 0.0 : double.parse(version));
      prefs.setString('version', actualVersion);
      prefs.setString('latest', null);
    } else db = await openDatabase(path);
    checkUpdates(prefs, db);
    await fetchCategorias();
    return null;
  }

  Future<Null> copiarBase(String dbPath, bool fistRun, double version) async {
    print('entro a copiar');
    print(fistRun);
    // Favoritos
    List<int> favoritos = List<int>();
    // Descargados
    List<List<int>> descargados = List<List<int>>();
    if (!fistRun) {
      print('abriendo base de datos');
      try {
      if(version < 2.2) {
        print('Old Version db path');
        db = await openDatabase(await getDatabasesPath() + '/himnos.db');
      }
      else {
        print('New Version db path');
        db = await openDatabase((await getApplicationDocumentsDirectory()).path + '/himnos.db');
      }
        for(Map<String, dynamic> favorito in (await db.rawQuery('select * from favoritos'))) {
          favoritos.add(favorito['himno_id']);
      }
      // solo en esta actualización
      // List<String> voces = ['Soprano', 'Tenor', 'Bajo', 'ContraAlto'];
      // String path = (await getApplicationDocumentsDirectory()).path;
      // for(Map<String, dynamic> descargado in (await db.rawQuery('select * from descargados'))) {
      //   for(int i = 0; i < voces.length; ++i) {
      //     File archivo = File(path + '/${descargado['himno_id']}-${voces[i]}.mp3');
      //     archivo.deleteSync();
      //   }
      // }
      // await db.transaction((action) async {
      //   await action.rawDelete('delete from descargados');
      // });
      try {
        for(Map<String, dynamic> descargado in (await db.rawQuery('select * from descargados'))) {
          descargados.add([descargado['himno_id'], descargado['duracion']]);
        }
      } catch(e) {print(e);}
      await db.close();
      } catch(e) {print(e);}
    }
    ByteData data = await rootBundle.load("assets/himnos_coros.sqlite");
    List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    print('antes de abrir');
    await new File(dbPath).writeAsBytes(bytes);
    db = await openDatabase(dbPath);
    if (!fistRun) {
      for (int favorito in favoritos)
        await db.rawInsert('insert into favoritos values ($favorito)');
      for (List<int> descargado in descargados)
        await db.rawInsert('insert into descargados values (${descargado[0]}, ${descargado[1]})');
    }
    return null;
  }

  Future<Null> fetchCategorias() async {

    setState(() => cargando = true);

    List<Map<String, dynamic>> temas = await db.rawQuery('select * from temas');
    categorias = Categoria.fromJson(temas);

    for (Categoria categoria in categorias) {
      List<Map<String, dynamic>> subTemas = await db.rawQuery('select * from sub_temas where tema_id = ${categoria.id}');
      for (var x in subTemas) {
        categoria.subCategorias.add(SubCategoria(
          id: x['id'],
          subCategoria: x['sub_tema'],
          categoriaId: x['tema_id']
        ));
      }
    }

    setState(() => cargando = false);
    return null;
  }

  @override
  void dispose(){
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).accentColor
              ),
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'Himnos y Cánticos del Evangelio',
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        color: Theme.of(context).indicatorColor,
                        fontSize: 20.0
                      )
                    )
                  ],
                ),
              )
            ),
            ListTile(
              leading: Icon(Icons.favorite),
              title: Text('Favoritos'),
              onTap: () async {
                await db.close();
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (BuildContext context) => FavoritosPage())
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.get_app),
              title: Text('Himnos Descargados'),
              onTap: () async {
                await db.close();
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (BuildContext context) => DescargadosPage())
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.record_voice_over),
              title: Text('Voces Disponibles'),
              onTap: () async {
                await db.close();
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (BuildContext context) => DisponiblesPage())
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Ajustes'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (BuildContext context) => AjustesPage())
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.feedback),
              title: Text('Feedback'),
              onTap: () {
                String url = Platform.isAndroid ? 'https://play.google.com/store/apps/details?id=com.br572.himnario' : 'https://itunes.apple.com/us/app/himnos-y-cánticos-de-evangelio/id1444422315?ls=1&mt=8';
                launch(url);
              },
            ),
            ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Políticas de privacidad'),
              onTap: () => launch('https://sites.google.com/view/himnos-privacy-policy/')
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: Container(
          width: double.infinity,
          child: Text('Himnos del Evangelio', textAlign: TextAlign.center,),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (BuildContext context) => Buscador(id: 0, subtema: false,))
              );
            },
            icon: Icon(Icons.search),
          ),
        ],
      ),
      body: cargando ? 
      Center(child: CircularProgressIndicator(),)
      : ListView.builder(
          itemCount: categorias.length + 1,
          itemBuilder: (BuildContext context, int index) {
            return index == 0 ? 
            ListTile(
              onTap: () {
                Navigator.push(
                  context, 
                  MaterialPageRoute(
                    builder: (BuildContext context) => TemaPage(id: 0, tema: 'Todos',)
                  ));
              },
              title: Text('Todos'),
            )
            :
            categorias[index-1].subCategorias.isEmpty ? ListTile(
              onTap: () {
                Navigator.push(
                  context, 
                  MaterialPageRoute(
                    builder: (BuildContext context) => TemaPage(id: index, tema: categorias[index-1].categoria)
                  ));
              },
              title: Text(categorias[index-1].categoria),
            ) : 
            ExpansionTile(
              title: Text(categorias[index-1].categoria),
              children: categorias[index-1].subCategorias.map((subCategoria) =>
                ListTile(
                  dense: true,
                  onTap: () {
                    Navigator.push(
                      context, 
                      MaterialPageRoute(
                        builder: (BuildContext context) => TemaPage(id: subCategoria.id, subtema: true, tema: subCategoria.subCategoria)
                      ));
                  },
                  title: Text(subCategoria.subCategoria),
                )).toList()
            );
          }
        ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // MethodChannel('PRUEBA').invokeMethod('test')
          //   .then((value) => print(value));
          Navigator.push(
            context, 
            MaterialPageRoute(
              builder: (BuildContext context) => QuickBuscador()
            ));
        },
        child: Icon(Icons.dialpad),
      ),
    );
  }
}