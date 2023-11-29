import 'dart:io';
import 'package:riverpod/riverpod.dart';
import 'package:path_provider/path_provider.dart' as syspaths;
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart' as sql;
import 'package:sqflite/sqlite_api.dart';

import '../model/place.dart';

Future<Database> _getDatabase() async {
  final dbPath = await sql.getDatabasesPath();
  // abrir ou criar banco caso não exista
  final db = await sql.openDatabase(
    path.join(dbPath, 'places.db'),
    onCreate: (db, version) {
      return db.execute(
          'CREATE TABLE user_places(id TEXT PRIMARY KEY, title TEXT, image TEXT, lat REAL, lng REAL, address TEXT)');
    },
    version: 1,
  );
  return db;
}

class UserPlacesNotifier extends StateNotifier<List<Place>> {
  UserPlacesNotifier() : super(const []);

  Future<void> loadPlaces() async {
    // pegando o banco ou criando
    final db = await _getDatabase();
    // pegando os dados da tabela, pode haver consicional como segundo param
    final data = await db.query('user_places');
    // percorrendo o data povoando o objeto Place
    final places = data
        .map(
          (row) => Place(
            id: row['id'] as String,
            title: row['title'] as String,
            image: File(row['image'] as String),
            location: PlaceLocation(
                latitude: row['lat'] as double,
                longitude: row['lng'] as double,
                address: row['address'] as String),
          ),
        )
        .toList();

    /* está atribuindo a lista de lugares (places) ao estado interno do UserPlacesNotifier. 
      Nesse contexto, state é uma propriedade especial em StateNotifier que representa o estado 
      atual gerenciado pelo notifier. Ao atribuir places a state, você está informando 
      ao UserPlacesNotifier que o estado interno do notifier deve ser atualizado com a lista de 
      lugares carregados do banco de dados. 
     */
    state = places;
  }

  void addPlace(String title, File image, PlaceLocation location) async {
    final appDir = await syspaths.getApplicationDocumentsDirectory();
    final filename = path.basename(image.path);
    final copiedImage = await image.copy('$appDir/$filename');

    final newPlace =
        Place(title: title, image: copiedImage, location: location);

    // inserir dados no banco
    final db = await _getDatabase();
    db.insert('user_places', {
      'id': newPlace.id,
      'title': newPlace.title,
      'image': newPlace.image.path,
      'lat': newPlace.location.latitude,
      'lng': newPlace.location.longitude,
      'address': newPlace.location.address
    });

    state = [newPlace, ...state];
  }
}

final userPlacesProvider =
    StateNotifierProvider<UserPlacesNotifier, List<Place>>(
  (ref) => UserPlacesNotifier(),
);
