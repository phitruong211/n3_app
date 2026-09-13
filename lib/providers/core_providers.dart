import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/database.dart';
import '../data/importer.dart';
import '../data/srs_service.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

final dataImporterProvider = Provider<DataImporter>((ref) {
  final db = ref.watch(databaseProvider);
  return DataImporter(db);
});

final srsServiceProvider = Provider<SrsService>((ref) {
  final db = ref.watch(databaseProvider);
  return SrsService(db);
});

final decksProvider = FutureProvider<List<Deck>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.select(db.decks).get();
});

