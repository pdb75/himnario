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
    if (version == null || version != actualVersion) {
      await copiarBase(path);
      prefs.setString('version', actualVersion);
    } else db = await openReadOnlyDatabase(path);
    await fetchCategorias();
    return null;
  }

  Future<Null> copiarBase(String path) async {
    // Favoritos
    List<int> favoritos = List<int>();
    try {
      db = await openReadOnlyDatabase(path);
      for(Map<String, dynamic> favorito in await db.rawQuery('select * from favoritos')) {
        favoritos.add(favorito['himno_id']);
      }
      await db.close();
    } catch (e) {
      
    }
    ByteData data = await rootBundle.load("assets/himnos_coros.sqlite");
    List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    await new File(path).writeAsBytes(bytes);
    db = await openDatabase(path);
    for (int favorito in favoritos)
      await db.rawInsert('insert into favoritos values ($favorito)');
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

class CategoriaPage extends StatefulWidget {

  CategoriaPage({this.categoria, this.subCategoria});

  final Categoria categoria;
  final SubCategoria subCategoria;
  
  @override
  _CategoriaPageState createState() => _CategoriaPageState();
}

class _CategoriaPageState extends State<CategoriaPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cena del Señor'),
      ),
      body: ListView.builder(
            itemCount: 30,
            itemBuilder: (BuildContext context, int index) => 
              Column(
                children: <Widget>[
                  ListTile(
                    onTap: () {
                        Navigator.of(context).pushNamed('/himno');
                      },
                    title: Text('${index + 1} - A casa vete'),
                    subtitle: Text('Evangelio'),
                  ),
                ],
              )
          ),
    );
  }
}