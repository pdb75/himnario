import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:sqflite/sqflite.dart';

import '../models/himnos.dart';
import './tema.dart';
import '../buscador/buscador.dart';

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
    
    ByteData data = await rootBundle.load("assets/himnos_coros.sqlite");
    List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    await new File(path).writeAsBytes(bytes);
    db = await openReadOnlyDatabase(path);
    await fetchCategorias();
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
  Widget build(BuildContext context) {
    return Scaffold(
      // drawer: Drawer(
      //   child: ListView(
      //     padding: EdgeInsets.zero,
      //     children: <Widget>[
      //       DrawerHeader(
      //         child: Column(
      //           crossAxisAlignment: CrossAxisAlignment.center,
      //           mainAxisAlignment: MainAxisAlignment.center,
      //           children: <Widget>[
      //             Text(
      //               'Himnos y Cánticos del Evangelio',
      //               style: TextStyle(
      //                 color: Colors.white
      //               ),
      //             )
      //           ],
      //         ),
      //         decoration: BoxDecoration(
      //           color: Theme.of(context).accentColor,
      //         ),
      //       ),
      //       ListTile(
      //         leading: Icon(Icons.favorite),
      //         title: Text('Favoritos'),
      //         onTap: () {
      //           Navigator.pop(context);
      //         },
      //       ),
      //       ListTile(
      //         leading: Icon(Icons.settings),
      //         title: Text('Ajustes'),
      //         onTap: () {
      //           Navigator.pop(context);
      //         },
      //       ),
      //       ListTile(
      //         leading: Icon(Icons.feedback),
      //         title: Text('Feedback'),
      //         onTap: () {
      //           Navigator.pop(context);
      //         },
      //       ),
      //     ],
      //   ),
      // ),
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
      : RefreshIndicator(
        onRefresh: fetchCategorias,
        child: ListView.builder(
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
      )
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