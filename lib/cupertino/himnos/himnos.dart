import 'dart:io';
import 'dart:ui';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:launch_review/launch_review.dart';
import 'package:path_provider/path_provider.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info/package_info.dart';
import 'package:http/http.dart' as http;

import '../ajustesPage/ajustes_page.dart';
import '../components/corosScroller.dart';
import '../models/himnos.dart';
import './tema.dart';
import '../buscador/buscador.dart';
import '../favoritosPage/favoritos_page.dart';
import '../descargadosPage/descargados_page.dart';
import '../quickBuscador/quick_buscador.dart';
import '../vocesDisponibles/voces_disponibles.dart';

import '../models/tema.dart';

class CupertinoHimnosPage extends StatefulWidget {
  final int mainColor;
  final String font;
  final Brightness brightness;

  CupertinoHimnosPage({this.mainColor, this.font, this.brightness});
  
  @override
  _CupertinoHimnosPageState createState() => _CupertinoHimnosPageState();
}

class _CupertinoHimnosPageState extends State<CupertinoHimnosPage> {
  TemaModel tema;
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
    tema = TemaModel();
    tema.setMainColor(Color(widget.mainColor ?? 4294309365));
    tema.setFont(widget.font ?? '.SF Pro Text');
    tema.setBrightness(widget.brightness);
    expanded = <bool>[false, false, false, false, false, false];
    currentPage = 0;
    categorias = List<Categoria>();
    coros = List<Himno>();
    initDB();
  }

  Future<Null> checkUpdates(SharedPreferences prefs, Database db) async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        print('connected');
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
            setState(() => cargando = true);
            print('descargando');
            http.Response request = await http.get('http://104.131.104.212:8085/db');
            // print(await http.get('http://104.131.104.212:8085/updates'));

            // Favoritos
            List<int> favoritos = List<int>();
            // Descargados
            List<List<int>> descargados = List<List<int>>();
            // transpose
            List<Himno> transposedHImnos = List<Himno>();

            db = db.isOpen ? db : await openDatabase(path);

            await db.execute('CREATE TABLE IF NOT EXISTS favoritos(himno_id int, FOREIGN KEY (himno_id) REFERENCES himnos(id))');
            await db.execute('CREATE TABLE IF NOT EXISTS descargados(himno_id int, duracion int, FOREIGN KEY (himno_id) REFERENCES himnos(id))');

            for(Map<String, dynamic> favorito in (await db.rawQuery('select * from favoritos'))) {
              favoritos.add(favorito['himno_id']);
            }
            for(Map<String, dynamic> descargado in (await db.rawQuery('select * from descargados'))) {
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
            for (int favorito in favoritos)
              await db.rawInsert('insert into favoritos values ($favorito)');
            for (List<int> descargado in descargados)
              await db.rawInsert('insert into descargados values (${descargado[0]}, ${descargado[1]})');
            for (Himno himno in transposedHImnos)
              await db.rawQuery('update himnos set transpose = ${himno.transpose} where id = ${himno.numero}');

            prefs.setString('latest', latest[0]['updatedAt']);
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
      await copiarBase(path, version == null, version == null ? 0.0 : double.parse(version));
      prefs.setString('version', actualVersion);
      prefs.setString('latest', null);
    } else db = await openDatabase(path);
    // if ((await (Connectivity().checkConnectivity()) == ConnectivityResult.none))
    await fetchCategorias();
    checkUpdates(prefs, db);
    return null;
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
        try {
          for(Map<String, dynamic> descargado in (await db.rawQuery('select * from descargados'))) {
            descargados.add([descargado['himno_id'], descargado['duracion']]);
          }
        } catch(e) {print(e);}
        try {
          if (version > 2.4)
            transposedHImnos = Himno.fromJson((await db.rawQuery('select * from himnos where transpose != 0')));
        } catch (e) {print(e);}
        await db.close();
      } catch(e) {print(e);}
    }
    ByteData data = await rootBundle.load("assets/himnos_coros.sqlite");
    List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    print('antes de abrir');
    await new File(dbPath).writeAsBytes(bytes);
    db = await openDatabase(dbPath);
    if (!fistRun) {
      await db.execute('CREATE TABLE IF NOT EXISTS favoritos(himno_id int, FOREIGN KEY (himno_id) REFERENCES himnos(id))');
      await db.execute('CREATE TABLE IF NOT EXISTS descargados(himno_id int, duracion int, FOREIGN KEY (himno_id) REFERENCES himnos(id))');
      for (int favorito in favoritos)
        await db.rawInsert('insert into favoritos values ($favorito)');
      for (List<int> descargado in descargados)
        await db.rawInsert('insert into descargados values (${descargado[0]}, ${descargado[1]})');
      for (Himno himno in transposedHImnos)
        await db.rawQuery('update himnos set transpose = ${himno.transpose} where id = ${himno.numero}');
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
        categoria.subCategorias.add(SubCategoria(
          id: x['id'],
          subCategoria: x['sub_tema'],
          categoriaId: x['tema_id']
        ));
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

  void showMenu() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancelar'),
        ),
        actions: <Widget>[
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.of(context).pop();
              await db.close();
              Navigator.push(
                context,
                CupertinoPageRoute(builder: (BuildContext context) => ScopedModel<TemaModel>(
                  model: tema,
                  child: FavoritosPage(),
                ))
              );
            },
            child: Text('Favoritos')
          ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.of(context).pop();
              await db.close();
              Navigator.push(
                context,
                CupertinoPageRoute(builder: (BuildContext context) => ScopedModel<TemaModel>(
                  model: tema,
                  child: DescargadosPage(),
                ))
              );
            },
            child: Text('Himnos Descargados')
          ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.of(context).pop();
              await db.close();
              Navigator.push(
                context,
                CupertinoPageRoute(builder: (BuildContext context) => ScopedModel<TemaModel>(
                  model: tema,
                  child: DisponiblesPage(),
                ))
              );
            },
            child: Text('Voces Disponibles')
          ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.of(context).pop();
              await db.close();
              Navigator.push(
                context,
                CupertinoPageRoute(builder: (BuildContext context) => ScopedModel<TemaModel>(
                  model: tema,
                  child: AjustesPage(),
                ))
              );
            },
            child: Text('Ajustes')
          ),
          CupertinoActionSheetAction(
            onPressed: () => LaunchReview.launch(
              writeReview: false,
              iOSAppId: "1444422315"
            ),
            child: Text('Feedback')
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              launch('https://sites.google.com/view/himnos-privacy-policy/');
            },
            child: Text('Politicas de privacidad')
          ),
        ],
      )
    );
  }

  @override
  void dispose(){
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return ScopedModel<TemaModel>(
      model: tema,
      child: CupertinoTabScaffold(
        tabBuilder: (BuildContext context, int index) {
          if(index == 0) {
            return 
              CupertinoPageScaffold(
                backgroundColor: tema.getScaffoldBackgroundColor(),
                navigationBar: CupertinoNavigationBar(
                  backgroundColor: tema.getTabBackgroundColor(),
                  actionsForegroundColor: tema.getTabTextColor(),
                  transitionBetweenRoutes: false,
                  leading: CupertinoButton(
                    onPressed: showMenu,
                    padding: EdgeInsets.only(bottom: 2.0),
                    child: Icon(Icons.menu, size: 30.0,),
                  ),
                  trailing: CupertinoButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(builder: (BuildContext context) => ScopedModel<TemaModel>(
                          model: tema,
                          child: Buscador(id: 0, subtema: false, type: BuscadorType.Himnos),
                        ))
                      );
                    },
                    padding: EdgeInsets.only(bottom: 2.0),
                    child: Icon(CupertinoIcons.search, size: 30.0),
                  ),
                  middle: Text(
                    'Himnos del Evangelio',
                    style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                      color: tema.getTabTextColor(),
                      fontFamily: tema.font
                    ),
                  ),
                ),
                child: SafeArea(
                  bottom: true,
                  child: Stack(
                  children: <Widget>[
                    categorias.isNotEmpty ? CustomScrollView(
                      slivers: <Widget>[
                        CupertinoSliverRefreshControl(
                          onRefresh: () => checkUpdates(prefs, db),
                        ),
                        SliverPadding(
                          padding: EdgeInsets.only(bottom: 90.0),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
                              return index == 0 ? 
                              CupertinoButton(
                                onPressed: () {
                                  Navigator.push(
                                    context, 
                                    CupertinoPageRoute(
                                      builder: (BuildContext context) => ScopedModel<TemaModel>(
                                        model: tema,
                                        child: TemaPage(id: 0, tema: 'Todos',),
                                      )
                                    ));
                                },
                                child: Text('Todos', 
                                  style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                                    color: tema.getScaffoldTextColor(),
                                    fontFamily: tema.font
                                  ),
                                ),
                              )
                              :
                              categorias[index-1].subCategorias.isEmpty ? CupertinoButton(
                                onPressed: () {
                                  Navigator.push(
                                    context, 
                                    CupertinoPageRoute(
                                      builder: (BuildContext context) => ScopedModel<TemaModel>(
                                        model: tema,
                                        child: TemaPage(id: index, tema: categorias[index-1].categoria),
                                      )
                                    ));
                                },
                                child: Text(categorias[index-1].categoria, 
                                  style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                                    color: tema.getScaffoldTextColor(),
                                    fontFamily: tema.font
                                  )
                                ),
                              ) : 
                              Column(
                                children: <Widget>[
                                  CupertinoButton(
                                    child: Stack(
                                      // mainAxisSize: MainAxisSize.max,
                                      // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                        Align(
                                          alignment: Alignment.center,
                                          child: Text(categorias[index-1].categoria, 
                                            style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                                              color: tema.getScaffoldTextColor(),
                                              fontFamily: tema.font
                                            )
                                          ),
                                        ),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: Icon(
                                            expanded[index - 1] ? CupertinoIcons.up_arrow : CupertinoIcons.down_arrow,
                                            color: tema.getScaffoldTextColor(),
                                          ),
                                        ),
                                      ],
                                    ),
                                    onPressed: () {
                                      List<bool> aux = expanded;
                                      for (int i = 0; i < aux.length; ++i)
                                        if (i == index-1)
                                          aux[i] = !aux[i];
                                      setState(() => expanded = aux);
                                    }
                                  ),
                                  AnimatedContainer(
                                    duration: Duration(milliseconds: 400),
                                    curve: Curves.easeInOutSine,
                                    height: expanded[index - 1] ? categorias[index-1].subCategorias.length * 50.0 : 0.0,
                                    child: AnimatedOpacity(
                                      opacity: expanded[index - 1] ? 1.0 : 0.0,
                                      duration: Duration(milliseconds: 400),
                                      curve: Curves.easeInOutSine,
                                      child: Column(
                                        children: categorias[index-1].subCategorias.map((subCategoria) =>
                                        CupertinoButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context, 
                                              CupertinoPageRoute(
                                                builder: (BuildContext context) => ScopedModel<TemaModel>(
                                                  model: tema,
                                                  child: TemaPage(id: subCategoria.id, subtema: true, tema: subCategoria.subCategoria),
                                                )
                                              ));
                                          },
                                          child: Container(
                                            width: double.infinity,
                                            child: Text(
                                              subCategoria.subCategoria,
                                              textAlign: TextAlign.center,
                                              style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                                                color: tema.getScaffoldTextColor(),
                                                fontFamily: tema.font,
                                                fontWeight: FontWeight.w400,
                                                fontSize: 15.0
                                              )
                                            ),
                                          ),
                                        )).toList()
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                            childCount: categorias.length + 1,
                            ),
                          )
                        )
                      ],
                    ) : Container(),
                    Positioned(
                      right: -50.0,
                      bottom: 30.0,
                      child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5.0),
                            color: tema.getAccentColor()
                          ),
                          width: 100.0,
                          height: 54.0,
                          child: Padding(
                            padding: EdgeInsets.only(right: 50.0),
                            child: CupertinoButton(
                              onPressed: () {
                                Navigator.push(
                                  context, 
                                  CupertinoPageRoute(
                                    builder: (BuildContext context) => ScopedModel<TemaModel>(
                                      model: tema,
                                      child: QuickBuscador(),
                                    )
                                  )
                                );
                              },
                              child: Icon(
                                Icons.dialpad,
                                color: tema.getAccentColorText(),
                            ),
                          )
                        ),
                      ),
                    ),
                    Positioned(
                      left: -50.0,
                      bottom: 30.0,
                      child: AnimatedContainer(
                        transform: cargando ? Matrix4.translationValues(0.0, 0.0, 0.0) : Matrix4.translationValues(-50.0, 0.0, 0.0),
                        curve: Curves.easeOutSine,
                        duration: Duration(milliseconds: 1000),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5.0),
                          color: tema.getAccentColor()
                        ),
                        width: 100.0,
                        height: 54.0,
                        child: Padding(
                          padding: EdgeInsets.only(left: 50.0),
                          child: CupertinoActivityIndicator(
                            animating: true,
                          )
                        ),
                      ),
                    ),
                  ],
                )
                )
              // ),
            );
          }
          else return CupertinoPageScaffold(
              backgroundColor: tema.getScaffoldBackgroundColor(),
              navigationBar: CupertinoNavigationBar(
                backgroundColor: tema.getTabBackgroundColor(),
                actionsForegroundColor: tema.getTabTextColor(),
                transitionBetweenRoutes: false,
                leading: CupertinoButton(
                  onPressed: showMenu,
                  padding: EdgeInsets.only(bottom: 2.0),
                  child: Icon(Icons.menu, size: 30.0,),
                ),
                trailing: CupertinoButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(builder: (BuildContext context) => ScopedModel<TemaModel>(
                        model: tema,
                        child: Buscador(id: 0, subtema: false, type: BuscadorType.Coros)),
                      )
                    );
                  },
                  padding: EdgeInsets.only(bottom: 2.0),
                  child: Icon(CupertinoIcons.search, size: 30.0),
                ),
                middle: Text(
                  'Coros',
                  style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                    color: tema.getTabTextColor(),
                    fontFamily: tema.font
                  ),
                ),
              ),
              child: Stack(
                children: <Widget>[
                  ScopedModel<TemaModel>(
                    model: tema,
                    child: CorosScroller(
                      cargando: cargando,
                      himnos: coros,
                      initDB: fetchCategorias,
                      mensaje: '',
                      iPhoneX: MediaQuery.of(context).size.width >= 812.0 || MediaQuery.of(context).size.height >= 812.0,
                      refresh: () => checkUpdates(prefs, db)
                    ),
                  ),
                  Positioned(
                    left: -50.0,
                    bottom: 30.0,
                    child: AnimatedContainer(
                      transform: cargando ? Matrix4.translationValues(0.0, 0.0, 0.0) : Matrix4.translationValues(-50.0, 0.0, 0.0),
                      curve: Curves.easeOutSine,
                      duration: Duration(milliseconds: 1000),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5.0),
                        color: tema.getAccentColor()
                      ),
                      width: 100.0,
                      height: 54.0,
                      child: Padding(
                        padding: EdgeInsets.only(left: 50.0),
                        child: CupertinoActivityIndicator(
                          animating: true,
                        )
                      ),
                    ),
                  ),
                ],
              )
            );
        },
        tabBar: CupertinoTabBar(
          backgroundColor: tema.getTabBackgroundColor(),
          activeColor: tema.getTabTextColor(),
          inactiveColor: tema.mainColorContrast == Colors.white || tema.brightness == Brightness.dark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.5),
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.library_music),
              title: Text('Himnos',
                style: CupertinoTheme.of(context).textTheme.tabLabelTextStyle.copyWith(
                  color: tema.brightness == Brightness.light ? tema.mainColorContrast : Colors.white,
                  fontFamily: tema.font
                )
              )
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.music_note),
              title: Text('Coros',
                style: CupertinoTheme.of(context).textTheme.tabLabelTextStyle.copyWith(
                  color: tema.brightness == Brightness.light ? tema.mainColorContrast : Colors.white,
                  fontFamily: tema.font
                )
              )
            ),
          ],
        ),
      ),
    );
  }
}