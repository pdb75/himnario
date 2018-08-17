import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/himnos.dart';
import '../himnoPage/himno.dart';
import '../buscador/buscador.dart';

class TemaPage extends StatefulWidget {
  int id;
  bool subtema;
  String tema;

  TemaPage({this.id, this.subtema = false, this.tema});
  @override
  _TemaPageState createState() => _TemaPageState();
}

class _TemaPageState extends State<TemaPage> {
  List<Himno> himnos;
  bool cargando;

  @override
  void initState() {
    super.initState();
    cargando = true;
    himnos = List<Himno>();
    fetchHimnos();
  }

  Future<Null> fetchHimnos() async {
    print(widget.id);
    setState(() => cargando = true);
    if (widget.id == 0) {
      await http.get('http://104.131.104.212:8085/himnos/todos')
      .then((res) {
        List<dynamic> data = json.decode(res.body);
        setState(() {
          himnos = Himno.fromJson(data);
        });
      })
      .catchError((error) => print(error));
    setState(() => cargando = false);
    } else {
      String query = widget.subtema ? 'sub_categorias' : 'categorias';
      await http.get('http://104.131.104.212:8085/$query/${widget.id}/himnos')
        .then((res) {
          List<dynamic> data = json.decode(res.body);
          setState(() {
            himnos = Himno.fromJson(data);
          });
        })
        .catchError((error) => print(error));
      setState(() => cargando = false);
    }
    return null;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tema),
        actions: <Widget>[
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (BuildContext context) => Buscador(id: widget.id, subtema:widget.subtema))
              );
            },
            icon: Icon(Icons.search),
          ),
        ],
      ),
      body: cargando ? 
      Center(child: CircularProgressIndicator(),)
      : RefreshIndicator(
        onRefresh: fetchHimnos,
        child: ListView.builder(
          itemCount: himnos.length,
          itemBuilder: (BuildContext context, int index) =>
            ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (BuildContext context) => HimnoPage(numero: himnos[index].numero, titulo: himnos[index].titulo,)) );
              },
              title: Text('${himnos[index].numero} - ${himnos[index].titulo}'),
            )
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