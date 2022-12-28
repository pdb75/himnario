import 'dart:io';
import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info/package_info.dart';
import 'package:launch_review/launch_review.dart';
import 'package:http/http.dart' as http;

import '../components/corosScroller.dart';
import '../models/himnos.dart';
import './tema.dart';
import '../buscador/buscador.dart';
import '../ajustesPage/ajustes_page.dart';
import '../favoritosPage/favoritos_page.dart';
import '../descargadosPage/descargados_page.dart';
import '../quickBuscador/quick_buscador.dart';
import '../vocesDisponibles/voces_disponibles.dart';

import 'package:Himnario/api/api.dart';

class HimnosPage extends StatefulWidget {
  @override
  _HimnosPageState createState() => _HimnosPageState();
}

class _HimnosPageState extends State<HimnosPage> {
  final GlobalKey<ScaffoldState> _globalKey = GlobalKey<ScaffoldState>();
  List<Categoria> categorias;
  List<Himno> coros;
  List<bool> expanded;
  String path;
  Database db;
  PageController pageController;
  SharedPreferences prefs;
  int currentPage;
  bool cargando;

  @override
  void initState() {
    super.initState();
    cargando = false;
    pageController = PageController(
      initialPage: 0,
      keepPage: true,
    );
    expanded = <bool>[false, false, false, false, false, false];
    currentPage = 0;
    categorias = List<Categoria>();
    coros = List<Himno>();
    initDB();
  }

  Future<Null> getAnuncios(SharedPreferences prefs) async {
    http.Response request = await http.get(DatabaseApi.getAnuncios());
    Map<String, dynamic> json = jsonDecode(request.body);
    List<String> anuncios = prefs.getStringList('anuncios') == null ? [] : prefs.getStringList('anuncios');

    for (dynamic anuncio in json['anuncios']) {
      if (!anuncios.contains(anuncio['id'].toString())) {
        await showDialog(
          context: context,
          child: AlertDialog(
            title: Text(anuncio['titulo']),
            content: Text(anuncio['contenido']),
            actions: <Widget>[
              FlatButton(
                onPressed: () {
                  anuncios.add(anuncio['id'].toString());
                  Navigator.of(context).pop();
                },
                child: Text(
                  'No volver a mostrar',
                  style: TextStyle(color: Colors.red),
                ),
              ),
              FlatButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cerrar'),
              ),
            ],
          ),
        );
      }
    }

    prefs.setStringList('anuncios', anuncios);

    return null;
  }

  Future<Null> checkUpdates(SharedPreferences prefs, Database db) async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        print('connected');
        String date = prefs.getString('latest');
        http.Response res = await http.post(DatabaseApi.checkUpdates(),
            headers: {'Content-Type': 'application/json'},
            body: utf8.encode(json.encode({'latest': date != null ? date : '2018-08-19 05:01:46.447 +00:00'})));
        List<dynamic> latest = jsonDecode(res.body);
        print(latest.isEmpty);
        if (latest.isNotEmpty) if (date == null || date != latest[0]['updatedAt']) {
          _globalKey.currentState.showSnackBar(SnackBar(
            content: Row(
              children: <Widget>[
                Icon(
                  Icons.get_app,
                  color: Theme.of(context).brightness == Brightness.light ? Colors.white : Colors.black,
                ),
                SizedBox(
                  width: 15.0,
                ),
                Text(
                  'Actualizando Base de Datos',
                  style: Theme.of(context)
                      .textTheme
                      .button
                      .copyWith(color: Theme.of(context).brightness == Brightness.light ? Colors.white : Colors.black),
                )
              ],
            ),
            action: SnackBarAction(
              label: 'Ok',
              textColor: Theme.of(context).brightness == Brightness.light ? Colors.white : Colors.black,
              onPressed: () => _globalKey.currentState.hideCurrentSnackBar(),
            ),
          ));
          setState(() => cargando = true);
          print('descargando');
          http.Response request = await http.get(DatabaseApi.getDb());

          // Favoritos
          List<int> favoritos = List<int>();
          // Descargados
          List<List<int>> descargados = List<List<int>>();
          // transpose
          List<Himno> transposedHImnos = List<Himno>();

          db = db.isOpen ? db : await openDatabase(path);

          await db.execute('CREATE TABLE IF NOT EXISTS favoritos(himno_id int, FOREIGN KEY (himno_id) REFERENCES himnos(id))');
          await db.execute('CREATE TABLE IF NOT EXISTS descargados(himno_id int, duracion int, FOREIGN KEY (himno_id) REFERENCES himnos(id))');

          for (Map<String, dynamic> favorito in (await db.rawQuery('select * from favoritos'))) {
            favoritos.add(favorito['himno_id']);
          }
          for (Map<String, dynamic> descargado in (await db.rawQuery('select * from descargados'))) {
            descargados.add([descargado['himno_id'], descargado['duracion']]);
          }
          transposedHImnos = Himno.fromJson((await db.rawQuery('select * from himnos where transpose != 0')));

          await db.close();
          db = null;

          File(path).deleteSync();
          File(path).writeAsBytesSync(request.bodyBytes);

          db = await openDatabase(path);

          await db.execute('CREATE TABLE IF NOT EXISTS favoritos(himno_id int, FOREIGN KEY (himno_id) REFERENCES himnos(id))');
          await db.execute('CREATE TABLE IF NOT EXISTS descargados(himno_id int, duracion int, FOREIGN KEY (himno_id) REFERENCES himnos(id))');
          for (int favorito in favoritos) await db.rawInsert('insert into favoritos values ($favorito)');
          for (List<int> descargado in descargados) await db.rawInsert('insert into descargados values (${descargado[0]}, ${descargado[1]})');
          for (Himno himno in transposedHImnos) await db.rawQuery('update himnos set transpose = ${himno.transpose} where id = ${himno.numero}');

          prefs.setString('latest', latest[0]['updatedAt']);

          _globalKey.currentState.showSnackBar(SnackBar(
            content: Row(
              children: <Widget>[
                Icon(
                  Icons.done,
                  color: Colors.white,
                ),
                SizedBox(
                  width: 15.0,
                ),
                Text(
                  'Base de Datos Actualizada',
                  style: Theme.of(context).textTheme.button.copyWith(color: Colors.white),
                )
              ],
            ),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Ok',
              textColor: Colors.white,
              onPressed: () => _globalKey.currentState.hideCurrentSnackBar(),
            ),
          ));

          fetchCategorias();
        }
        setState(() => cargando = false);
        print('termino de actualizar');
        return null;
      }
    } catch (e) {
      setState(() => cargando = false);
      print('not connected');
      print(e);
      return null;
    }
  }

  Future<Null> initDB() async {
    String databasesPath = (await getApplicationDocumentsDirectory()).path;
    path = databasesPath + "/himnos.db";

    prefs = await SharedPreferences.getInstance();
    String version = prefs.getString('version');
    String actualVersion = (await PackageInfo.fromPlatform()).version;
    print('actualVersion: $actualVersion');
    print('newVersion: $version');
    if (version == null || version != actualVersion) {
      await copiarBase(path, version == null, version == null ? 0.0 : parseVersion(version));
      prefs.setString('version', actualVersion);
      prefs.setString('latest', null);
    } else
      db = await openDatabase(path);
    // if ((await (Connectivity().checkConnectivity()) == ConnectivityResult.none))
    await fetchCategorias();
    getAnuncios(prefs);
    checkUpdates(prefs, db);
    return null;
  }

  double parseVersion(String version) {
    try {
      return double.parse(version);
    } catch (e) {
      List<String> parts = version.split('.');
      String temp = parts[0] + '.';

      parts.removeAt(0);
      return double.parse(temp + parts.join(''));
    }
  }

  Future<Null> copiarBase(String dbPath, bool fistRun, double version) async {
    print('entro a copiar');
    print(fistRun);
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
          if (version > 3.9) transposedHImnos = Himno.fromJson((await db.rawQuery('select * from himnos where transpose != 0')));
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
    return null;
  }

  Future<Null> fetchCategorias([bool refresh = true]) async {
    db = await openDatabase(path);

    List<Map<String, dynamic>> temas = await db.rawQuery('select * from temas');
    categorias = Categoria.fromJson(temas);

    for (Categoria categoria in categorias) {
      List<Map<String, dynamic>> subTemas = await db.rawQuery('select * from sub_temas where tema_id = ${categoria.id}');
      for (var x in subTemas) {
        categoria.subCategorias.add(SubCategoria(id: x['id'], subCategoria: x['sub_tema'], categoriaId: x['tema_id']));
      }
    }

    List<Map<String, dynamic>> corosQuery = await db.rawQuery('select * from himnos where id > 517 order by titulo');
    coros = Himno.fromJson(corosQuery);
    List<Map<String, dynamic>> favoritosQuery = await db.rawQuery('select * from favoritos where himno_id > 517');
    List<dynamic> favoritosList = favoritosQuery.map((f) => f['himno_id']).toList();
    for (Himno coro in coros) {
      coro.favorito = favoritosList.contains(coro.numero);
    }

    setState(() {});

    return null;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _globalKey,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
                decoration: BoxDecoration(color: Theme.of(context).primaryColor),
                child: Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text('Himnos y Cánticos del Evangelio',
                          textAlign: TextAlign.start, style: TextStyle(color: Theme.of(context).primaryIconTheme.color, fontSize: 20.0))
                    ],
                  ),
                )),
            ListTile(
              leading: Icon(Icons.favorite),
              title: Text('Favoritos'),
              onTap: () async {
                await db.close();
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => FavoritosPage()));
              },
            ),
            ListTile(
              leading: Icon(Icons.get_app),
              title: Text('Himnos Descargados'),
              onTap: () async {
                await db.close();
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => DescargadosPage()));
              },
            ),
            ListTile(
              leading: Icon(Icons.record_voice_over),
              title: Text('Voces Disponibles'),
              onTap: () async {
                await db.close();
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => DisponiblesPage()));
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Ajustes'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => AjustesPage()));
              },
            ),
            ListTile(
              leading: Icon(Icons.payments),
              title: Text('Donaciones'),
              onTap: () => launch(
                  'https://www.paypal.com/donate/?business=Y9VB93FT2L67G&no_recurring=0&item_name=Ay%C3%BAdame+a+financiar+la+infraestructura+de+la+aplicaci%C3%B3n+y+a+poder+trabajar+en+nuevos+proyectos+relacionados.&currency_code=USD'),
            ),
            ListTile(
              leading: Icon(Icons.feedback),
              title: Text('Feedback'),
              onTap: () => LaunchReview.launch(),
            ),
            ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Políticas de privacidad'),
                onTap: () => launch('https://sites.google.com/view/himnos-privacy-policy/')),
            // ListTile(s
          ],
        ),
      ),
      appBar: AppBar(
        title: Container(
          width: double.infinity,
          child: Text(
            currentPage == 0 ? 'Himnos del Evangelio' : 'Coros',
            textAlign: TextAlign.center,
          ),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (BuildContext context) =>
                          Buscador(id: 0, subtema: false, type: currentPage == 0 ? BuscadorType.Himnos : BuscadorType.Coros)));
            },
            icon: Icon(Icons.search),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(4.0),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 100),
            curve: Curves.easeInOutSine,
            height: cargando || categorias.isEmpty ? 4.0 : 0.0,
            child: LinearProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryIconTheme.color == Colors.black ? Colors.black : Theme.of(context).primaryColor),
              backgroundColor: Colors.white,
            ),
          ),
        ),
      ),
      body: PageView(
        controller: pageController,
        onPageChanged: (int index) => setState(() => currentPage = index),
        children: <Widget>[
          categorias.isNotEmpty
              ? RefreshIndicator(
                  color: Theme.of(context).brightness == Brightness.light
                      ? (Theme.of(context).primaryIconTheme.color == Colors.black ? Colors.black : Theme.of(context).primaryColor)
                      : (Theme.of(context).accentTextTheme.body1.color == Colors.white ? Colors.white : Theme.of(context).accentColor),
                  onRefresh: () => checkUpdates(prefs, db),
                  child: ListView.builder(
                      padding: EdgeInsets.only(bottom: 80.0),
                      itemCount: categorias.length + 1,
                      itemBuilder: (BuildContext context, int index) {
                        return index == 0
                            ? Card(
                                elevation: 4.0,
                                margin: EdgeInsets.only(left: 10.0, right: 10.0, top: 16.0, bottom: 8.0),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
                                child: ListTile(
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (BuildContext context) => TemaPage(
                                                  id: 0,
                                                  tema: 'Todos',
                                                )));
                                  },
                                  title: Text('Todos'),
                                ),
                              )
                            : categorias[index - 1].subCategorias.isEmpty
                                ? Card(
                                    elevation: 4.0,
                                    margin: EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
                                    child: ListTile(
                                      onTap: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (BuildContext context) => TemaPage(id: index, tema: categorias[index - 1].categoria)));
                                      },
                                      title: Text(categorias[index - 1].categoria),
                                    ))
                                : Card(
                                    elevation: 4.0,
                                    margin: EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
                                    child: Column(
                                      children: <Widget>[
                                        ListTile(
                                            title: Text(categorias[index - 1].categoria),
                                            trailing: Icon(expanded[index - 1] ? Icons.arrow_drop_up : Icons.arrow_drop_down),
                                            onTap: () {
                                              List<bool> aux = expanded;
                                              for (int i = 0; i < aux.length; ++i) if (i == index - 1) aux[i] = !aux[i];
                                              setState(() => expanded = aux);
                                            }),
                                        AnimatedContainer(
                                          duration: Duration(milliseconds: 400),
                                          curve: Curves.easeInOutSine,
                                          height: expanded[index - 1] ? categorias[index - 1].subCategorias.length * 48.0 : 0.0,
                                          child: AnimatedOpacity(
                                            opacity: expanded[index - 1] ? 1.0 : 0.0,
                                            duration: Duration(milliseconds: 400),
                                            curve: Curves.easeInOutSine,
                                            child: Column(
                                                children: categorias[index - 1]
                                                    .subCategorias
                                                    .map((subCategoria) => ListTile(
                                                          dense: true,
                                                          onTap: () {
                                                            Navigator.push(
                                                                context,
                                                                MaterialPageRoute(
                                                                    builder: (BuildContext context) => TemaPage(
                                                                        id: subCategoria.id, subtema: true, tema: subCategoria.subCategoria)));
                                                          },
                                                          title: Text(subCategoria.subCategoria),
                                                        ))
                                                    .toList()),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                      }),
                )
              : Container(),
          RefreshIndicator(
            color: Theme.of(context).brightness == Brightness.light
                ? (Theme.of(context).primaryIconTheme.color == Colors.black ? Colors.black : Theme.of(context).primaryColor)
                : (Theme.of(context).accentTextTheme.body1.color == Colors.white ? Colors.white : Theme.of(context).accentColor),
            onRefresh: () => checkUpdates(prefs, db),
            child: CorosScroller(
              cargando: cargando,
              himnos: coros,
              initDB: fetchCategorias,
              mensaje: '',
            ),
          )
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentPage,
        backgroundColor: Theme.of(context).primaryColor,
        // selectedItemColor: Theme.of(context).indicatorColor,
        unselectedItemColor: Theme.of(context).indicatorColor.withOpacity(0.5),
        type: BottomNavigationBarType.fixed,
        onTap: (int e) {
          pageController.animateToPage(e, duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
          setState(() => currentPage = e);
        },
        items: [
          BottomNavigationBarItem(
              backgroundColor: Theme.of(context).primaryColor,
              icon: Icon(Icons.library_music, color: Theme.of(context).primaryIconTheme.color),
              title: Text('Himnos', style: Theme.of(context).textTheme.button.copyWith(color: Theme.of(context).primaryIconTheme.color))),
          BottomNavigationBarItem(
              backgroundColor: Theme.of(context).primaryColor,
              icon: Icon(Icons.music_note, color: Theme.of(context).primaryIconTheme.color),
              title: Text('Coros', style: Theme.of(context).textTheme.button.copyWith(color: Theme.of(context).primaryIconTheme.color))),
        ],
      ),
      floatingActionButton: currentPage == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => QuickBuscador()));
              },
              child: Icon(Icons.dialpad),
            )
          : null,
    );
  }
}
