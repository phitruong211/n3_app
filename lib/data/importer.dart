import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'database/database.dart';
import 'package:drift/drift.dart' as drift;

class DataImporter {
  final AppDatabase db;
  final Uuid uuid = const Uuid();

  DataImporter(this.db);

  Future<void> importIfEmpty() async {
    final deckCount = await db.select(db.decks).get();
    if (deckCount.length >= 5) return;

    // Clear existing data in case of partial previous imports
    await db.delete(db.cards).go();
    await db.delete(db.decks).go();

    await _importN3Vocab();
    await _importN4Vocab();
    await _importN3Kanji();
    await _importN3Grammar();
    await _importN4Grammar();
  }

  Future<void> _importN3Vocab() async {
    final data = await rootBundle.loadString('assets/all_vocab.json');
    final List<dynamic> jsonList = jsonDecode(data);
    
    final deckId = uuid.v4();
    await db.into(db.decks).insert(DecksCompanion.insert(
      id: deckId,
      name: 'Từ vựng N3',
      level: 'N3',
      type: 'Vocab',
    ));

    for (var item in jsonList) {
      if (item['Từ vựng'] == null) continue;
      
      final frontText = item['Từ vựng'] as String;
      final backText = '${item['Cách đọc (Phiên âm)'] ?? ''} - ${item['Ý nghĩa'] ?? ''}';
      final relatedWords = item['Từ liên quan (Từ (Phiên âm): Nghĩa)'] as String?;
      
      await db.into(db.cards).insert(CardsCompanion.insert(
        id: uuid.v4(),
        deckId: deckId,
        frontText: frontText,
        backText: backText,
        relatedWords: drift.Value(relatedWords != null && relatedWords.isNotEmpty ? jsonEncode([relatedWords]) : null),
      ));
    }
  }

  Future<void> _importN4Vocab() async {
    final data = await rootBundle.loadString('assets/vocabN4.json');
    final List<dynamic> jsonList = jsonDecode(data);
    
    final deckId = uuid.v4();
    await db.into(db.decks).insert(DecksCompanion.insert(
      id: deckId,
      name: 'Từ vựng N4',
      level: 'N4',
      type: 'Vocab',
    ));

    for (var item in jsonList) {
      if (item['kanji'] == null) continue;
      
      final frontText = item['kanji'] as String;
      final backText = '${item['phien_am'] ?? ''} - ${item['nghia'] ?? ''}';
      
      await db.into(db.cards).insert(CardsCompanion.insert(
        id: uuid.v4(),
        deckId: deckId,
        frontText: frontText,
        backText: backText,
      ));
    }
  }

  Future<void> _importN3Kanji() async {
    final data = await rootBundle.loadString('assets/kanjiN3_vocab_full.json');
    final List<dynamic> jsonList = jsonDecode(data);
    
    final deckId = uuid.v4();
    await db.into(db.decks).insert(DecksCompanion.insert(
      id: deckId,
      name: 'Hán tự N3',
      level: 'N3',
      type: 'Kanji',
    ));

    for (var item in jsonList) {
      if (item['tu_chinh'] == null) continue;
      
      final frontText = item['tu_chinh'] as String;
      final backText = item['han_viet'] as String? ?? '';
      
      final relatedWordsList = item['tu_lien_quan'] as List<dynamic>?;
      String? relatedWordsJson;
      if (relatedWordsList != null && relatedWordsList.isNotEmpty) {
        relatedWordsJson = jsonEncode(relatedWordsList.map((e) => '${e['tu']} (${e['phien_am']}): ${e['nghia']}').toList());
      }
      
      await db.into(db.cards).insert(CardsCompanion.insert(
        id: uuid.v4(),
        deckId: deckId,
        frontText: frontText,
        backText: backText,
        relatedWords: drift.Value(relatedWordsJson),
      ));
    }
  }

  Future<void> _importN3Grammar() async {
    final data = await rootBundle.loadString('assets/grammar.json');
    final List<dynamic> jsonList = jsonDecode(data);
    
    final deckId = uuid.v4();
    await db.into(db.decks).insert(DecksCompanion.insert(
      id: deckId,
      name: 'Ngữ pháp N3',
      level: 'N3',
      type: 'Grammar',
    ));

    for (var item in jsonList) {
      if (item['mau_ngu_phap'] == null) continue;
      
      final frontText = item['mau_ngu_phap'] as String;
      final backText = '${item['phien_am'] ?? ''}\nÝ nghĩa: ${item['y_nghia'] ?? ''}\nCông thức: ${item['cong_thuc'] ?? ''}\nChú ý: ${item['chu_y'] ?? ''}';
      
      final examplesList = item['vi_du'] as List<dynamic>?;
      String? examplesJson;
      if (examplesList != null && examplesList.isNotEmpty) {
        examplesJson = jsonEncode(examplesList.map((e) => '${e['nhat']}\n${e['viet']}').toList());
      }
      
      await db.into(db.cards).insert(CardsCompanion.insert(
        id: uuid.v4(),
        deckId: deckId,
        frontText: frontText,
        backText: backText,
        exampleSentences: drift.Value(examplesJson),
      ));
    }
  }

  Future<void> _importN4Grammar() async {
    final data = await rootBundle.loadString('assets/grammarN4.json');
    final List<dynamic> jsonList = jsonDecode(data);
    
    final deckId = uuid.v4();
    await db.into(db.decks).insert(DecksCompanion.insert(
      id: deckId,
      name: 'Ngữ pháp N4',
      level: 'N4',
      type: 'Grammar',
    ));

    for (var item in jsonList) {
      if (item['mau_ngu_phap'] == null) continue;
      
      final frontText = item['mau_ngu_phap'] as String;
      final backText = '${item['phien_am'] ?? ''}\nÝ nghĩa: ${item['y_nghia'] ?? ''}\nCông thức: ${item['cong_thuc'] ?? ''}\nChú ý: ${item['chu_y'] ?? ''}';
      
      final examplesList = item['vi_du'] as List<dynamic>?;
      String? examplesJson;
      if (examplesList != null && examplesList.isNotEmpty) {
        examplesJson = jsonEncode(examplesList.map((e) => '${e['nhat']}\n${e['viet']}').toList());
      }
      
      await db.into(db.cards).insert(CardsCompanion.insert(
        id: uuid.v4(),
        deckId: deckId,
        frontText: frontText,
        backText: backText,
        exampleSentences: drift.Value(examplesJson),
      ));
    }
  }
}
