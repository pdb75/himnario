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
      categorias.add(Categoria(id: x['id'], categoria: x['tema']));
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
      subCategorias.add(SubCategoria(id: x['id'], subCategoria: x['sub_tema'], categoriaId: x['tema_id']));
    }
    return subCategorias;
  }
}
