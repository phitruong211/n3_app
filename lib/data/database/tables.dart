import 'package:drift/drift.dart';

class Decks extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get name => text()();
  TextColumn get level => text()();
  TextColumn get type => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class Cards extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get deckId => text().references(Decks, #id)();
  TextColumn get frontText => text()();
  TextColumn get backText => text()();
  TextColumn get exampleSentences => text().nullable()(); // JSON string
  TextColumn get relatedWords => text().nullable()(); // JSON string
  
  // SRS Fields
  IntColumn get state => integer().withDefault(const Constant(0))(); // 0: new, 1: learning, 2: review, 3: relearning
  DateTimeColumn get due => dateTime().nullable()();
  RealColumn get intervalDays => real().withDefault(const Constant(0.0))();
  RealColumn get easeFactor => real().withDefault(const Constant(2.5))();
  IntColumn get reps => integer().withDefault(const Constant(0))();
  IntColumn get lapses => integer().withDefault(const Constant(0))();
  IntColumn get learningStepIndex => integer().withDefault(const Constant(0))();
  
  // Sync Fields
  DateTimeColumn get updatedAt => dateTime().nullable()();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))(); // 0: synced, 1: pending
  
  @override
  Set<Column> get primaryKey => {id};
}

class ReviewLogs extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get cardId => text().references(Cards, #id)();
  IntColumn get rating => integer()(); // 1: Again, 2: Hard, 3: Good, 4: Easy
  DateTimeColumn get reviewTime => dateTime()();
  IntColumn get durationMs => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
