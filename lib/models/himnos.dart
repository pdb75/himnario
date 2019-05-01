import 'package:Himnario/coroPage/components/estructura_Coro.dart';

class Categoria {
  int id;
  String categoria;
  List<SubCategoria> subCategorias;

  Categoria({this.id, this.categoria, this.subCategorias}) {
    subCategorias = subCategorias ?? List<SubCategoria>();
  }

  static List<Categoria> fromJson(List<dynamic> res) {
    List<Categoria> categorias = List<Categoria>();
    for (var x in res) {
      categorias.add(Categoria(
        id: x['id'],
        categoria: x['tema']
      ));
    }
    return categorias;
  }
}

class SubCategoria {
  int id;
  String subCategoria;
  int categoriaId;

  SubCategoria({this.id, this.subCategoria, this.categoriaId});

  static List<SubCategoria> fromJson(List<dynamic> res) {
    List<SubCategoria> subCategorias = List<SubCategoria>();
    for (var x in res) {
      subCategorias.add(SubCategoria(
        id: x['id'],
        subCategoria: x['sub_tema'],
        categoriaId: x['tema_id']
      ));
    }
    return subCategorias;
  }
}

class Himno {
  int numero;
  String titulo;
  int transpose;
  bool favorito;
  bool descargado;

  Himno({this.numero, this.titulo, this.favorito = false, this.descargado = false, this.transpose = 0});

  static List<Himno> fromJson(List<dynamic> res) {
    List<Himno> himno = List<Himno>();
    for (var x in res) {
      himno.add(Himno(
        numero: x['id'],
        titulo: x['titulo'],
        transpose: x['transpose']
      ));
    }
    return himno;
  }
}

class Parrafo {
  int numero;
  int orden;
  bool coro;
  String parrafo;
  String acordes;

  Parrafo({this.numero, this.orden, this.coro, this.parrafo, this.acordes});

  static List<Parrafo> fromJson(List<dynamic> res) {
    List<Parrafo> parrafos = List<Parrafo>();
    int numeroEstrofa = 0;
    for (var x in res) {
      if (x['coro'] == 0) ++numeroEstrofa;
      parrafos.add(Parrafo(
        numero: x['numero'],
        orden: numeroEstrofa,
        coro: x['coro'] == 1 ? true : false,
        parrafo: x['parrafo'],
        acordes: x['acordes'],
      ));
    }
    return parrafos;
  }
}

abstract class Acordes {
  static List<String> acordes = ['Do', 'Do#', 'Re', 'Re#', 'Mi', 'Fa', 'Fa#', 'Sol', 'Sol#', 'La', 'La#', 'Si'];

  static List<String> transpose(int value, List<String> original) {
    if (value == 0) 
      return original;
    else if (value.isNegative)
      value = 12 + value;
    for(int i = 0; i < original.length; ++i) {
      int acordeStart = original[i].indexOf(RegExp(r'[A-Z]'));
      while (acordeStart != -1) {
        int acordeEnd = original[i].indexOf(' ', acordeStart) == -1 ? original[i].length : original[i].indexOf(' ', acordeStart);
        for(int j = Acordes.acordes.length - 1; j >= 0; --j) {
          if(original[i].substring(acordeStart, acordeEnd).indexOf(Acordes.acordes[j]) != -1) {
            int index = j + value > Acordes.acordes.length - 1 ? value - (12 - j) : j + value;
            // print('${Acordes.acordes[j]} -> ${Acordes.acordes[index]} -> ${j > value}');
            original[i] = original[i].replaceFirst(Acordes.acordes[j], Acordes.acordes[index], acordeStart);
            break;
          }
        }

        acordeEnd = original[i].indexOf(' ', acordeStart) == -1 ? original[i].length : original[i].indexOf(' ', acordeStart);
        acordeStart = original[i].indexOf(RegExp(r'[A-Z]'), acordeEnd);
      }
    }

    return original;
  }
}