// import 'package:objectbox/objectbox.dart';

// @Entity()
// class Category {
//   // Each "Entity" needs a unique integer ID property.
//   // Add `@Id()` annotation if its name isn't "id" (case insensitive).
//   @Index()
//   String id = '000000000000000000000000';
//   bool all;
//   String category;
//   String songbook_id;
//   String parent_id;
//   List<Category> children;
//   // @Property(type: PropertyType.date) // Store as int in milliseconds
//   // DateTime? date;

//   // @Transient() // Make this field ignored, not stored in the database.
//   // int? notPersisted;

//   // An empty default constructor is needed but you can use optional args.
//   // Category({this.text, DateTime? date}) : date = date ?? DateTime.now();

//   // Note: just for logs in the examples below(), not needed by ObjectBox.
//   // toString() => 'Note{id: $_id, text: $text}';
// }
