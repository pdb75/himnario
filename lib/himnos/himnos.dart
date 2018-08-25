import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info/package_info.dart';

import '../models/himnos.dart';
import './tema.dart';
import '../buscador/buscador.dart';
import '../ajustesPage/ajustes_page.dart';
import '../favoritosPage/favoritos_page.dart';
import '../descargadosPage/descargados_page.dart';

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

  Future<Null> initDB() async {
    String databasesPath = await getDatabasesPath();
    String path = databasesPath + "/himnos.db";

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String version = prefs.getString('version');
    String actualVersion = (await PackageInfo.fromPlatform()).version;
    print('actualVersion: $actualVersion');
    print('version: $version');
    if (version == null || version != actualVersion) {
      await copiarBase(path, version == null);
      prefs.setString('version', actualVersion);
    } else db = await openReadOnlyDatabase(path);
    await fetchCategorias();
    return null;
  }

  Future<Null> copiarBase(String path, bool fistRun) async {
    print('entro a copiar');
    print(fistRun);
    // Favoritos
    List<int> favoritos = List<int>();
    // Descargados
    List<int> descargados = List<int>();
    if (!fistRun) {
      print('abriendo base de datos');
      db = await openReadOnlyDatabase(path);
      for(Map<String, dynamic> favorito in (await db.rawQuery('select * from favoritos'))) {
        favoritos.add(favorito['himno_id']);
      }
      try {
        for(Map<String, dynamic> descargado in (await db.rawQuery('select * from descargados'))) {
          descargados.add(descargado['himno_id']);
        }
      } catch(e) {print(e);}
      await db.close();
    }
    ByteData data = await rootBundle.load("assets/himnos_coros.sqlite");
    List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    await new File(path).writeAsBytes(bytes);
    db = await openDatabase(path);
    if (!fistRun) {
      for (int favorito in favoritos)
        await db.rawInsert('insert into favoritos values ($favorito)');
      for (int descargado in descargados)
        await db.rawInsert('insert into descargados values ($descargado)');
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
    db.close();
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
              onTap: () {
                db.close();
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
              onTap: () {
                db.close();
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (BuildContext context) => DescargadosPage())
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
                launch('https://play.google.com/store/apps/details?id=com.br572.himnario');
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: Text('Himnos del Evangelio'),
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
    );
  }
}