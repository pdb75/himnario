import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/himnos.dart';
import './tema.dart';
import '../buscador/buscador.dart';

class HimnosPage extends StatefulWidget {
  @override
  _HimnosPageState createState() => _HimnosPageState();
}

class _HimnosPageState extends State<HimnosPage> {
  List<Categoria> categorias;
  bool cargando;

  @override
  void initState() {
    super.initState();
    cargando = true;
    categorias = List<Categoria>();
    fetchCategorias();
  }

  Future<Null> fetchCategorias() async {
    setState(() => cargando = true);
    await http.get('http://104.131.104.212:8085/categorias')
      .then((res) {
        List<dynamic> data = json.decode(res.body);
        setState(() {
          categorias = Categoria.fromJson(data);
        });
      })
      .catchError((error) => print(error));
    for (Categoria categoria in categorias) {
      await http.get('http://104.131.104.212:8085/categorias/${categoria.id}')
        .then((res) {
          List<dynamic> data = json.decode(res.body);
          for (var x in data) {
            setState(() => categoria.subCategorias.add(SubCategoria(
              id: x['id'],
              categoriaId: x['tema_id'],
              subCategoria: x['sub_tema']
            )));
          }
        });
    }
    setState(() => cargando = false);
    return null;

  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    'Himnos y Cánticos del Evangelio',
                    style: TextStyle(
                      color: Colors.white
                    ),
                  )
                ],
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).accentColor,
              ),
            ),
            ListTile(
              leading: Icon(Icons.favorite),
              title: Text('Favoritos'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Ajustes'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.feedback),
              title: Text('Feedback'),
              onTap: () {
                Navigator.pop(context);
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