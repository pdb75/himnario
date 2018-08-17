import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/himnos.dart';
import '../himnoPage/himno.dart';

class Buscador extends StatefulWidget {

  Buscador({this.id, this.subtema = false});

  final int id;
  final bool subtema;

  @override
  _BuscadorState createState() => _BuscadorState();
}

class _BuscadorState extends State<Buscador> {
  List<Himno> himnos;
  bool cargando;

  @override
  void initState() {
    super.initState();
    cargando = true;
    himnos = List<Himno>();
  }

  Future<Null> fetchHimnos(String query) async {
    setState(() => cargando = true);
    if (widget.id == 0) {
      await http.get('http://104.131.104.212:8085/himnos/todos/$query')
      .then((res) {
        List<dynamic> data = json.decode(res.body);
        setState(() {
          himnos = Himno.fromJson(data);
        });
      })
      .catchError((error) => print(error));
    setState(() => cargando = false);
    } else {
      String tema = widget.subtema ? 'sub_categorias' : 'categorias';
      await http.get('http://104.131.104.212:8085/$tema/${widget.id}/himnos/$query')
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
        title: TextField(
          autofocus: true,
          onChanged: fetchHimnos,
          decoration: InputDecoration(
            // border: OutlineInputBorder(
            //   borderRadius: BorderRadius.circular(10.0),
            // ),
            filled: true,
            fillColor: Colors.white
          ),
        ),
      ),
      body: cargando ? 
      Center(
        child: CircularProgressIndicator(),
      ) : 
      ListView.builder(
        itemCount: himnos.length,
        itemBuilder: (BuildContext context, int index) => 
        ListTile(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (BuildContext context) => HimnoPage(numero: himnos[index].numero, titulo: himnos[index].titulo,)) );
          },
          title: Text('${himnos[index].numero} - ${himnos[index].titulo}'),
        ),
      )
    );
  }
}