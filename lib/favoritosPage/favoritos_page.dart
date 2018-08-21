import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../models/himnos.dart';
import '../himnoPage/himno.dart';

class FavoritosPage extends StatefulWidget {
  @override
  _FavoritosPageState createState() => _FavoritosPageState();
}

class _FavoritosPageState extends State<FavoritosPage> {
  List<Himno> himnos;
  Database db;
  bool cargando;

  @override
  void initState() {
    super.initState();
    himnos = List<Himno>();
    cargando = true;
    initDB();
  }

  void initDB() async {
    String path = await getDatabasesPath();
    db = await openDatabase(path + '/himnos.db');
    List<Map<String,dynamic>> favoritos = await db.rawQuery('select * from himnos join favoritos on himnos.id = favoritos.himno_id order by himnos.id ASC');
    cargando = false;
    setState(() => himnos = Himno.fromJson(favoritos));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Favoritos'),
      ),
      body: cargando ? 
      Center(
        child: CircularProgressIndicator()
      ) :
      himnos.isEmpty ? 
      Center(child: Text('No has agregando ningún himno\n a tu lista de favoritos', textAlign: TextAlign.center,),) :
      ListView.builder(
        itemCount: himnos.length,
        itemBuilder: (BuildContext context, int index) => 
        ListTile(
          onTap: () async {
            await db.close();
            await Navigator.push(
              context, 
              MaterialPageRoute(builder: (BuildContext context) => HimnoPage(numero: himnos[index].numero, titulo: himnos[index].titulo,)));
            initDB();
          },
          leading: Icon(Icons.star),
          title: Text('${himnos[index].numero} - ${himnos[index].titulo}'),
        ),
      )
    );
  }
}