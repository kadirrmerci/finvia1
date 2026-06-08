import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction.dart';
import '../models/subscription.dart';
import '../models/debt.dart';
import '../models/budget.dart';
import '../models/stock_holding.dart';
import '../models/note.dart';
import '../models/health_record.dart';
import '../models/habit.dart';
import '../models/credit_card_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'finvia.db');
    return await openDatabase(
      path,
      version: 7,
      onCreate: (db, version) async => await _createTables(db),
      onUpgrade: (db, oldVersion, newVersion) async => await _createTables(db),
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''CREATE TABLE IF NOT EXISTS transactions(
      id TEXT PRIMARY KEY, title TEXT, amount REAL,
      category TEXT, date TEXT, isExpense INTEGER, isFixed INTEGER,
      creditCardId TEXT, creditCardName TEXT)''');
    await db.execute('''CREATE TABLE IF NOT EXISTS subscriptions(
      id TEXT PRIMARY KEY, title TEXT, amount REAL,
      category TEXT, billingDay INTEGER, color TEXT)''');
    await db.execute(
      '''CREATE TABLE IF NOT EXISTS debts(
      id TEXT PRIMARY KEY, title TEXT, totalAmount REAL,
      paidAmount REAL, monthlyPayment REAL, startDate TEXT, interestRate REAL)''',
    );
    await db.execute('''CREATE TABLE IF NOT EXISTS budgets(
      id TEXT PRIMARY KEY, category TEXT, limitAmount REAL, month TEXT)''');
    await db.execute('''CREATE TABLE IF NOT EXISTS holdings(
      id TEXT PRIMARY KEY, symbol TEXT, name TEXT,
      buyPrice REAL, quantity REAL, buyDate TEXT)''');
    await db.execute('''CREATE TABLE IF NOT EXISTS notes(
      id TEXT PRIMARY KEY, title TEXT, content TEXT,
      category TEXT, color TEXT, createdAt TEXT,
      reminderTime TEXT, isPinned INTEGER, isArchived INTEGER)''');
    await db.execute('''CREATE TABLE IF NOT EXISTS health_records(
      id TEXT PRIMARY KEY, weight REAL, date TEXT, note TEXT)''');
    await db.execute('''CREATE TABLE IF NOT EXISTS habits(
      id TEXT PRIMARY KEY, title TEXT, type TEXT,
      startDate TEXT, completedDays TEXT, emoji TEXT, motivation TEXT)''');
    await db.execute('''CREATE TABLE IF NOT EXISTS credit_cards(
      id TEXT PRIMARY KEY, bankName TEXT, cardName TEXT,
      creditLimit REAL, currentDebt REAL, statementDay INTEGER,
      dueDay INTEGER, color TEXT)''');
    await db.execute('''CREATE TABLE IF NOT EXISTS credit_card_statements(
      id TEXT PRIMARY KEY, cardId TEXT, cardName TEXT,
      amount REAL, paidAmount REAL, statementDate TEXT, dueDate TEXT)''');
  }

  // Notes
  Future<void> insertNote(Note n) async {
    final db = await database;
    await db.insert(
      'notes',
      n.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Note>> getNotes() async {
    final db = await database;
    final maps = await db.query(
      'notes',
      where: 'isArchived = ?',
      whereArgs: [0],
      orderBy: 'isPinned DESC, createdAt DESC',
    );
    return maps.map((m) => Note.fromMap(m)).toList();
  }

  Future<void> updateNote(Note n) async {
    final db = await database;
    await db.update('notes', n.toMap(), where: 'id = ?', whereArgs: [n.id]);
  }

  Future<void> deleteNote(String id) async {
    final db = await database;
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  // Transactions
  Future<void> insertTransaction(FinanceTransaction t) async {
    final db = await database;
    await db.insert(
      'transactions',
      t.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<FinanceTransaction>> getTransactions() async {
    final db = await database;
    final maps = await db.query('transactions', orderBy: 'date DESC');
    return maps.map((m) => FinanceTransaction.fromMap(m)).toList();
  }

  Future<void> deleteTransaction(String id) async {
    final db = await database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // Subscriptions
  Future<void> insertSubscription(Subscription s) async {
    final db = await database;
    await db.insert(
      'subscriptions',
      s.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Subscription>> getSubscriptions() async {
    final db = await database;
    final maps = await db.query('subscriptions');
    return maps.map((m) => Subscription.fromMap(m)).toList();
  }

  Future<void> deleteSubscription(String id) async {
    final db = await database;
    await db.delete('subscriptions', where: 'id = ?', whereArgs: [id]);
  }

  // Debts
  Future<void> insertDebt(Debt d) async {
    final db = await database;
    await db.insert(
      'debts',
      d.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Debt>> getDebts() async {
    final db = await database;
    final maps = await db.query('debts');
    return maps.map((m) => Debt.fromMap(m)).toList();
  }

  Future<void> updateDebt(Debt d) async {
    final db = await database;
    await db.update('debts', d.toMap(), where: 'id = ?', whereArgs: [d.id]);
  }

  Future<void> deleteDebt(String id) async {
    final db = await database;
    await db.delete('debts', where: 'id = ?', whereArgs: [id]);
  }

  // Budgets
  Future<void> insertBudget(Budget b) async {
    final db = await database;
    await db.insert(
      'budgets',
      b.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Budget>> getBudgets() async {
    final db = await database;
    final maps = await db.query('budgets');
    return maps.map((m) => Budget.fromMap(m)).toList();
  }

  Future<void> deleteBudget(String id) async {
    final db = await database;
    await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }

  // Holdings
  Future<void> insertHolding(StockHolding s) async {
    final db = await database;
    await db.insert(
      'holdings',
      s.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<StockHolding>> getHoldings() async {
    final db = await database;
    final maps = await db.query('holdings');
    return maps.map((m) => StockHolding.fromMap(m)).toList();
  }

  Future<void> deleteHolding(String id) async {
    final db = await database;
    await db.delete('holdings', where: 'id = ?', whereArgs: [id]);
  }

  // Health Records
  Future<void> insertHealthRecord(HealthRecord r) async {
    final db = await database;
    await db.insert(
      'health_records',
      r.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<HealthRecord>> getHealthRecords() async {
    final db = await database;
    final maps = await db.query('health_records', orderBy: 'date DESC');
    return maps.map((m) => HealthRecord.fromMap(m)).toList();
  }

  Future<void> deleteHealthRecord(String id) async {
    final db = await database;
    await db.delete('health_records', where: 'id = ?', whereArgs: [id]);
  }

  // Habits
  Future<void> insertHabit(Habit h) async {
    final db = await database;
    await db.insert(
      'habits',
      h.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Habit>> getHabits() async {
    final db = await database;
    final maps = await db.query('habits');
    return maps.map((m) => Habit.fromMap(m)).toList();
  }

  Future<void> updateHabit(Habit h) async {
    final db = await database;
    await db.update('habits', h.toMap(), where: 'id = ?', whereArgs: [h.id]);
  }

  Future<void> deleteHabit(String id) async {
    final db = await database;
    await db.delete('habits', where: 'id = ?', whereArgs: [id]);
  }

  // Credit Cards
  Future<void> insertCreditCard(CreditCard c) async {
    final db = await database;
    await db.insert(
      'credit_cards',
      c.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<CreditCard>> getCreditCards() async {
    final db = await database;
    final maps = await db.query('credit_cards');
    return maps.map((m) => CreditCard.fromMap(m)).toList();
  }

  Future<void> updateCreditCard(CreditCard c) async {
    final db = await database;
    await db.update(
      'credit_cards',
      c.toMap(),
      where: 'id = ?',
      whereArgs: [c.id],
    );
  }

  Future<void> deleteCreditCard(String id) async {
    final db = await database;
    await db.delete('credit_cards', where: 'id = ?', whereArgs: [id]);
    await db.delete(
      'credit_card_statements',
      where: 'cardId = ?',
      whereArgs: [id],
    );
  }

  // Credit Card Statements
  Future<void> insertStatement(CreditCardStatement s) async {
    final db = await database;
    await db.insert(
      'credit_card_statements',
      s.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<CreditCardStatement>> getStatements(String cardId) async {
    final db = await database;
    final maps = await db.query(
      'credit_card_statements',
      where: 'cardId = ?',
      whereArgs: [cardId],
      orderBy: 'statementDate DESC',
    );
    return maps.map((m) => CreditCardStatement.fromMap(m)).toList();
  }

  Future<void> updateStatement(CreditCardStatement s) async {
    final db = await database;
    await db.update(
      'credit_card_statements',
      s.toMap(),
      where: 'id = ?',
      whereArgs: [s.id],
    );
  }

  Future<void> deleteStatement(String id) async {
    final db = await database;
    await db.delete('credit_card_statements', where: 'id = ?', whereArgs: [id]);
  }
}
