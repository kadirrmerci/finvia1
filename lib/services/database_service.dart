import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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

  static const int _dbVersion = 12;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Database? _db;
  String? _lastLegacyOwnerClaimUid;

  Future<Database> get database async {
    _db ??= await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'finvia.db');
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) => _createTables(db),
      onUpgrade: _onUpgrade,
    );
  }

  String get _currentUserId {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Oturum açmış kullanıcı bulunamadı.');
    }
    return user.uid;
  }

  DocumentReference<Map<String, dynamic>> _userDoc(String userId) {
    return _firestore.collection('users').doc(userId);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await _createTables(db);
    if (oldVersion < 8) {
      await _migrateToV8UserScopedData(db);
    }
    if (oldVersion < 9) {
      await _migrateToV9HealthTracking(db);
    }
    if (oldVersion < 10) {
      await _migrateToV10BodyMeasurements(db);
    }
    if (oldVersion < 11) {
      await _migrateToV11ArmAndFfmi(db);
    }
    if (oldVersion < 12) {
      await _migrateToV12SubscriptionCreditCards(db);
    }
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''CREATE TABLE IF NOT EXISTS transactions(
      id TEXT PRIMARY KEY, userId TEXT DEFAULT '', title TEXT, amount REAL,
      category TEXT, date TEXT, isExpense INTEGER, isFixed INTEGER,
      creditCardId TEXT, creditCardName TEXT)''');
    await db.execute('''CREATE TABLE IF NOT EXISTS subscriptions(
      id TEXT PRIMARY KEY, userId TEXT DEFAULT '', title TEXT, amount REAL,
      category TEXT, billingDay INTEGER, color TEXT, creditCardId TEXT,
      creditCardName TEXT, lastChargedMonth TEXT)''');
    await db.execute(
      '''CREATE TABLE IF NOT EXISTS debts(
      id TEXT PRIMARY KEY, userId TEXT DEFAULT '', title TEXT, totalAmount REAL,
      paidAmount REAL, monthlyPayment REAL, startDate TEXT, interestRate REAL)''',
    );
    await db.execute('''CREATE TABLE IF NOT EXISTS budgets(
      id TEXT PRIMARY KEY, userId TEXT DEFAULT '',
      category TEXT, limitAmount REAL, month TEXT)''');
    await db.execute('''CREATE TABLE IF NOT EXISTS holdings(
      id TEXT PRIMARY KEY, userId TEXT DEFAULT '', symbol TEXT, name TEXT,
      buyPrice REAL, quantity REAL, buyDate TEXT)''');
    await db.execute('''CREATE TABLE IF NOT EXISTS notes(
      id TEXT PRIMARY KEY, userId TEXT DEFAULT '', title TEXT, content TEXT,
      category TEXT, color TEXT, createdAt TEXT,
      reminderTime TEXT, isPinned INTEGER, isArchived INTEGER)''');
    await db.execute('''CREATE TABLE IF NOT EXISTS health_records(
      id TEXT PRIMARY KEY, userId TEXT DEFAULT '',
      weight REAL, date TEXT, note TEXT, height REAL, waist REAL, neck REAL,
      hip REAL, shoulder REAL, chest REAL, arm REAL, thigh REAL, calf REAL,
      gender TEXT, bodyFatPercentage REAL, ffmi REAL)''');
    await db.execute('''CREATE TABLE IF NOT EXISTS health_goals(
      id TEXT PRIMARY KEY, userId TEXT DEFAULT '', targetWeight REAL,
      bodyFatReminderDay INTEGER, bodyFatReminderHour INTEGER,
      bodyFatReminderMinute INTEGER)''');
    await db.execute('''CREATE TABLE IF NOT EXISTS habits(
      id TEXT PRIMARY KEY, userId TEXT DEFAULT '', title TEXT, type TEXT,
      startDate TEXT, completedDays TEXT, emoji TEXT, motivation TEXT)''');
    await db.execute('''CREATE TABLE IF NOT EXISTS credit_cards(
      id TEXT PRIMARY KEY, userId TEXT DEFAULT '', bankName TEXT, cardName TEXT,
      creditLimit REAL, currentDebt REAL, statementDay INTEGER,
      dueDay INTEGER, color TEXT)''');
    await db.execute('''CREATE TABLE IF NOT EXISTS credit_card_statements(
      id TEXT PRIMARY KEY, userId TEXT DEFAULT '', cardId TEXT, cardName TEXT,
      amount REAL, paidAmount REAL, statementDate TEXT, dueDate TEXT)''');
  }

  Future<void> _migrateToV8UserScopedData(Database db) async {
    for (final config in _syncConfigs) {
      final columns = await db.rawQuery('PRAGMA table_info(${config.table})');
      if (!columns.any((row) => row['name'] == 'userId')) {
        await db.execute(
          "ALTER TABLE ${config.table} ADD COLUMN userId TEXT DEFAULT ''",
        );
      }
    }

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await _claimLegacyRowsForUser(db, userId);
    }
  }

  Future<void> _addColumnIfMissing(
    Database db,
    String table,
    String column,
    String type,
  ) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    if (!columns.any((row) => row['name'] == column)) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $type');
    }
  }

  Future<void> _migrateToV12SubscriptionCreditCards(Database db) async {
    await _addColumnIfMissing(db, 'subscriptions', 'creditCardId', 'TEXT');
    await _addColumnIfMissing(db, 'subscriptions', 'creditCardName', 'TEXT');
    await _addColumnIfMissing(db, 'subscriptions', 'lastChargedMonth', 'TEXT');
  }

  Future<void> _migrateToV9HealthTracking(Database db) async {
    final columns = await db.rawQuery('PRAGMA table_info(health_records)');
    final names = columns.map((row) => row['name']).toSet();
    for (final entry in {
      'height': 'REAL',
      'waist': 'REAL',
      'neck': 'REAL',
      'hip': 'REAL',
      'gender': 'TEXT',
      'bodyFatPercentage': 'REAL',
    }.entries) {
      if (!names.contains(entry.key)) {
        await db.execute(
          'ALTER TABLE health_records ADD COLUMN ${entry.key} ${entry.value}',
        );
      }
    }
    await db.execute('''CREATE TABLE IF NOT EXISTS health_goals(
      id TEXT PRIMARY KEY, userId TEXT DEFAULT '', targetWeight REAL,
      bodyFatReminderDay INTEGER, bodyFatReminderHour INTEGER,
      bodyFatReminderMinute INTEGER)''');
  }

  Future<void> _migrateToV10BodyMeasurements(Database db) async {
    final columns = await db.rawQuery('PRAGMA table_info(health_records)');
    final names = columns.map((row) => row['name']).toSet();
    for (final entry in {
      'shoulder': 'REAL',
      'chest': 'REAL',
      'thigh': 'REAL',
      'calf': 'REAL',
    }.entries) {
      if (!names.contains(entry.key)) {
        await db.execute(
          'ALTER TABLE health_records ADD COLUMN ${entry.key} ${entry.value}',
        );
      }
    }
  }

  Future<void> _migrateToV11ArmAndFfmi(Database db) async {
    await _ensureHealthRecordMeasurementColumns(db);
  }

  Future<void> _ensureHealthRecordMeasurementColumns(Database db) async {
    final columns = await db.rawQuery('PRAGMA table_info(health_records)');
    final names = columns.map((row) => row['name']).toSet();
    for (final entry in {
      'height': 'REAL',
      'waist': 'REAL',
      'neck': 'REAL',
      'hip': 'REAL',
      'shoulder': 'REAL',
      'chest': 'REAL',
      'arm': 'REAL',
      'thigh': 'REAL',
      'calf': 'REAL',
      'gender': 'TEXT',
      'bodyFatPercentage': 'REAL',
      'ffmi': 'REAL',
    }.entries) {
      if (!names.contains(entry.key)) {
        await db.execute(
          'ALTER TABLE health_records ADD COLUMN ${entry.key} ${entry.value}',
        );
      }
    }
  }

  Future<Database> _databaseForCurrentUser() async {
    final userId = _currentUserId;
    final db = await database;
    if (_lastLegacyOwnerClaimUid != userId) {
      await _claimLegacyRowsForUser(db, userId);
      _lastLegacyOwnerClaimUid = userId;
    }
    return db;
  }

  Future<void> _claimLegacyRowsForUser(Database db, String userId) async {
    for (final config in _syncConfigs) {
      await db.update(
        config.table,
        {'userId': userId},
        where: 'userId IS NULL OR userId = ?',
        whereArgs: [''],
      );
    }
  }

  Future<void> _insertSynced(
    _SyncConfig config,
    Map<String, dynamic> values,
  ) async {
    final userId = _currentUserId;
    if (kIsWeb) {
      final remoteValues = {...values, 'userId': userId};
      await _upsertRemote(
        config,
        values['id'].toString(),
        remoteValues,
        userId,
      );
      return;
    }
    final db = await _databaseForCurrentUser();
    final localValues = {...values, 'userId': userId};
    await db.insert(
      config.table,
      localValues,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _upsertRemote(config, values['id'].toString(), localValues, userId);
  }

  Future<void> _updateSynced(
    _SyncConfig config,
    String id,
    Map<String, dynamic> values,
  ) async {
    final userId = _currentUserId;
    if (kIsWeb) {
      final remoteValues = {...values, 'userId': userId};
      await _upsertRemote(config, id, remoteValues, userId);
      return;
    }
    final db = await _databaseForCurrentUser();
    final localValues = {...values, 'userId': userId};
    await db.update(
      config.table,
      localValues,
      where: 'id = ? AND userId = ?',
      whereArgs: [id, userId],
    );
    await _upsertRemote(config, id, localValues, userId);
  }

  Future<void> _deleteSynced(_SyncConfig config, String id) async {
    final userId = _currentUserId;
    if (kIsWeb) {
      await _markRemoteDeleted(config, id, userId);
      return;
    }
    final db = await _databaseForCurrentUser();
    await db.delete(
      config.table,
      where: 'id = ? AND userId = ?',
      whereArgs: [id, userId],
    );
    await _markRemoteDeleted(config, id, userId);
  }

  Future<List<Map<String, dynamic>>> _queryForCurrentUser(
    String table, {
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
  }) async {
    if (kIsWeb) {
      return _queryRemoteForCurrentUser(
        table,
        where: where,
        whereArgs: whereArgs,
        orderBy: orderBy,
      );
    }
    final userId = _currentUserId;
    final db = await _databaseForCurrentUser();
    final clauses = ['userId = ?'];
    final args = <Object?>[userId];
    if (where != null && where.isNotEmpty) {
      clauses.add('($where)');
      args.addAll(whereArgs ?? const []);
    }
    return db.query(
      table,
      where: clauses.join(' AND '),
      whereArgs: args,
      orderBy: orderBy,
    );
  }

  Future<void> _upsertRemote(
    _SyncConfig config,
    String id,
    Map<String, dynamic> values,
    String userId,
  ) async {
    try {
      await _userDoc(userId).collection(config.collection).doc(id).set({
        ...values,
        'userId': userId,
        'isDeleted': false,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // SQLite remains available while Firestore is offline.
    }
  }

  Future<void> _markRemoteDeleted(
    _SyncConfig config,
    String id,
    String userId,
  ) async {
    try {
      await _userDoc(userId).collection(config.collection).doc(id).set({
        'id': id,
        'userId': userId,
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // The local deletion remains authoritative on this device.
    }
  }

  Future<bool> syncCurrentUserData() async {
    try {
      final userId = _currentUserId;
      final db = await _databaseForCurrentUser();
      await (() async {
        await _pullRemoteRows(db, userId);
        await _pushLocalRows(db, userId);
      })().timeout(const Duration(seconds: 15));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _pullRemoteRows(Database db, String userId) async {
    for (final config in _syncConfigs) {
      final snapshot = await _userDoc(
        userId,
      ).collection(config.collection).get();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data['isDeleted'] == true) {
          await db.delete(
            config.table,
            where: 'id = ? AND userId = ?',
            whereArgs: [doc.id, userId],
          );
          continue;
        }

        final values = <String, dynamic>{};
        for (final column in config.columns) {
          if (column == 'id') {
            values['id'] = data['id'] ?? doc.id;
          } else if (column == 'userId') {
            values['userId'] = userId;
          } else if (data.containsKey(column)) {
            values[column] = _normalizeRemoteValue(data[column]);
          }
        }
        values['id'] ??= doc.id;
        values['userId'] = userId;
        await db.insert(
          config.table,
          values,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
  }

  dynamic _normalizeRemoteValue(dynamic value) {
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is List) {
      return value.map(_normalizeRemoteValue).join(',');
    }
    return value;
  }

  Future<void> _pushLocalRows(Database db, String userId) async {
    for (final config in _syncConfigs) {
      final rows = await db.query(
        config.table,
        where: 'userId = ?',
        whereArgs: [userId],
      );
      for (final row in rows) {
        final id = row['id']?.toString();
        if (id == null || id.isEmpty) continue;
        await _userDoc(userId).collection(config.collection).doc(id).set({
          ...row,
          'userId': userId,
          'isDeleted': false,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    }
  }

  // Notes
  Future<void> insertNote(Note n) async {
    await _insertSynced(_notesConfig, n.toMap());
  }

  Future<List<Note>> getNotes() async {
    final maps = await _queryForCurrentUser(
      'notes',
      where: 'isArchived = ?',
      whereArgs: [0],
      orderBy: 'isPinned DESC, createdAt DESC',
    );
    return maps.map((m) => Note.fromMap(m)).toList();
  }

  Future<void> updateNote(Note n) async {
    await _updateSynced(_notesConfig, n.id, n.toMap());
  }

  Future<void> deleteNote(String id) async {
    await _deleteSynced(_notesConfig, id);
  }

  // Transactions
  Future<void> insertTransaction(FinanceTransaction t) async {
    await _insertSynced(_transactionsConfig, t.toMap());
  }

  Future<List<FinanceTransaction>> getTransactions() async {
    final maps = await _queryForCurrentUser(
      'transactions',
      orderBy: 'date DESC',
    );
    return maps.map((m) => FinanceTransaction.fromMap(m)).toList();
  }

  Future<void> deleteTransaction(String id) async {
    await _deleteSynced(_transactionsConfig, id);
  }

  // Subscriptions
  Future<void> insertSubscription(Subscription s) async {
    await _insertSynced(_subscriptionsConfig, s.toMap());
  }

  Future<List<Subscription>> getSubscriptions() async {
    final maps = await _queryForCurrentUser('subscriptions');
    return maps.map((m) => Subscription.fromMap(m)).toList();
  }

  Future<int> applyDueSubscriptionCharges({DateTime? now}) async {
    final userId = _currentUserId;
    final db = await _databaseForCurrentUser();
    final chargeDate = now ?? DateTime.now();
    final monthKey =
        '${chargeDate.year}-${chargeDate.month.toString().padLeft(2, '0')}';
    final changedSubscriptions = <Map<String, dynamic>>[];
    final changedCards = <Map<String, dynamic>>[];

    await db.transaction((txn) async {
      final subscriptions = await txn.query(
        'subscriptions',
        where:
            'userId = ? AND creditCardId IS NOT NULL '
            'AND creditCardId != ? AND billingDay <= ? '
            'AND (lastChargedMonth IS NULL OR lastChargedMonth != ?)',
        whereArgs: [userId, '', chargeDate.day, monthKey],
      );

      for (final subscription in subscriptions) {
        final cardId = subscription['creditCardId'] as String;
        final cards = await txn.query(
          'credit_cards',
          where: 'id = ? AND userId = ?',
          whereArgs: [cardId, userId],
          limit: 1,
        );
        if (cards.isEmpty) continue;

        final card = Map<String, dynamic>.from(cards.first);
        final amount = (subscription['amount'] as num).toDouble();
        final currentDebt = (card['currentDebt'] as num).toDouble();
        card['currentDebt'] = currentDebt + amount;
        await txn.update(
          'credit_cards',
          {'currentDebt': card['currentDebt']},
          where: 'id = ? AND userId = ?',
          whereArgs: [cardId, userId],
        );

        final updatedSubscription = Map<String, dynamic>.from(subscription);
        updatedSubscription['lastChargedMonth'] = monthKey;
        await txn.update(
          'subscriptions',
          {'lastChargedMonth': monthKey},
          where: 'id = ? AND userId = ?',
          whereArgs: [subscription['id'], userId],
        );
        changedCards.add(card);
        changedSubscriptions.add(updatedSubscription);
      }
    });

    for (final card in changedCards) {
      await _upsertRemote(
        _creditCardsConfig,
        card['id'].toString(),
        card,
        userId,
      );
    }
    for (final subscription in changedSubscriptions) {
      await _upsertRemote(
        _subscriptionsConfig,
        subscription['id'].toString(),
        subscription,
        userId,
      );
    }
    return changedSubscriptions.length;
  }

  Future<void> deleteSubscription(String id) async {
    await _deleteSynced(_subscriptionsConfig, id);
  }

  // Debts
  Future<void> insertDebt(Debt d) async {
    await _insertSynced(_debtsConfig, d.toMap());
  }

  Future<List<Debt>> getDebts() async {
    final maps = await _queryForCurrentUser('debts');
    return maps.map((m) => Debt.fromMap(m)).toList();
  }

  Future<void> updateDebt(Debt d) async {
    await _updateSynced(_debtsConfig, d.id, d.toMap());
  }

  Future<void> deleteDebt(String id) async {
    await _deleteSynced(_debtsConfig, id);
  }

  // Budgets
  Future<void> insertBudget(Budget b) async {
    await _insertSynced(_budgetsConfig, b.toMap());
  }

  Future<List<Budget>> getBudgets() async {
    final maps = await _queryForCurrentUser('budgets');
    return maps.map((m) => Budget.fromMap(m)).toList();
  }

  Future<void> deleteBudget(String id) async {
    await _deleteSynced(_budgetsConfig, id);
  }

  // Holdings
  Future<void> insertHolding(StockHolding s) async {
    await _insertSynced(_holdingsConfig, s.toMap());
  }

  Future<List<StockHolding>> getHoldings() async {
    final maps = await _queryForCurrentUser('holdings');
    return maps.map((m) => StockHolding.fromMap(m)).toList();
  }

  Future<void> deleteHolding(String id) async {
    await _deleteSynced(_holdingsConfig, id);
  }

  // Health Records
  Future<void> insertHealthRecord(HealthRecord r) async {
    if (!kIsWeb) {
      await _ensureHealthRecordMeasurementColumns(await database);
    }
    await _insertSynced(_healthRecordsConfig, r.toMap());
  }

  Future<List<Map<String, dynamic>>> _queryRemoteForCurrentUser(
    String table, {
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
  }) async {
    final userId = _currentUserId;
    final config = _syncConfigs.firstWhere((config) => config.table == table);
    final snapshot = await _userDoc(userId).collection(config.collection).get();
    var rows = snapshot.docs
        .map((doc) {
          final data = doc.data();
          final values = <String, dynamic>{};
          for (final column in config.columns) {
            if (column == 'id') {
              values['id'] = data['id'] ?? doc.id;
            } else if (column == 'userId') {
              values['userId'] = userId;
            } else if (data.containsKey(column)) {
              values[column] = _normalizeRemoteValue(data[column]);
            }
          }
          return values;
        })
        .where((row) => row['isDeleted'] != true)
        .toList();

    if (where != null && whereArgs != null && where.contains('isArchived')) {
      rows = rows.where((row) => row['isArchived'] == whereArgs.first).toList();
    }

    if (orderBy != null && orderBy.contains('date')) {
      rows.sort((a, b) {
        final aDate = DateTime.tryParse(a['date']?.toString() ?? '');
        final bDate = DateTime.tryParse(b['date']?.toString() ?? '');
        if (aDate == null || bDate == null) return 0;
        return orderBy.contains('DESC')
            ? bDate.compareTo(aDate)
            : aDate.compareTo(bDate);
      });
    }

    return rows;
  }

  Future<List<HealthRecord>> getHealthRecords() async {
    final maps = await _queryForCurrentUser(
      'health_records',
      orderBy: 'date DESC',
    );
    return maps.map((m) => HealthRecord.fromMap(m)).toList();
  }

  Future<void> deleteHealthRecord(String id) async {
    await _deleteSynced(_healthRecordsConfig, id);
  }

  Future<Map<String, dynamic>?> getHealthGoal() async {
    if (kIsWeb) {
      final userId = _currentUserId;
      final doc = await _userDoc(
        userId,
      ).collection('health_goals').doc('main').get();
      return doc.data();
    }
    final maps = await _queryForCurrentUser('health_goals');
    return maps.isEmpty ? null : maps.first;
  }

  Future<void> saveHealthGoal({
    double? targetWeight,
    int? bodyFatReminderDay,
    int? bodyFatReminderHour,
    int? bodyFatReminderMinute,
  }) async {
    final userId = _currentUserId;
    if (kIsWeb) {
      await _userDoc(userId).collection('health_goals').doc('main').set({
        'id': 'main',
        'userId': userId,
        'targetWeight': targetWeight,
        'bodyFatReminderDay': bodyFatReminderDay,
        'bodyFatReminderHour': bodyFatReminderHour,
        'bodyFatReminderMinute': bodyFatReminderMinute,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return;
    }
    final db = await _databaseForCurrentUser();
    await db.insert('health_goals', {
      'id': 'main',
      'userId': userId,
      'targetWeight': targetWeight,
      'bodyFatReminderDay': bodyFatReminderDay,
      'bodyFatReminderHour': bodyFatReminderHour,
      'bodyFatReminderMinute': bodyFatReminderMinute,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Habits
  Future<void> insertHabit(Habit h) async {
    await _insertSynced(_habitsConfig, h.toMap());
  }

  Future<List<Habit>> getHabits() async {
    final maps = await _queryForCurrentUser('habits');
    return maps.map((m) => Habit.fromMap(m)).toList();
  }

  Future<void> updateHabit(Habit h) async {
    await _updateSynced(_habitsConfig, h.id, h.toMap());
  }

  Future<void> deleteHabit(String id) async {
    await _deleteSynced(_habitsConfig, id);
  }

  // Credit Cards
  Future<void> insertCreditCard(CreditCard c) async {
    await _insertSynced(_creditCardsConfig, c.toMap());
  }

  Future<List<CreditCard>> getCreditCards() async {
    final maps = await _queryForCurrentUser('credit_cards');
    return maps.map((m) => CreditCard.fromMap(m)).toList();
  }

  Future<void> updateCreditCard(CreditCard c) async {
    await _updateSynced(_creditCardsConfig, c.id, c.toMap());
  }

  Future<void> deleteCreditCard(String id) async {
    final userId = _currentUserId;
    final db = await _databaseForCurrentUser();
    await db.delete(
      'credit_cards',
      where: 'id = ? AND userId = ?',
      whereArgs: [id, userId],
    );
    await db.delete(
      'credit_card_statements',
      where: 'cardId = ? AND userId = ?',
      whereArgs: [id, userId],
    );
    await _markRemoteDeleted(_creditCardsConfig, id, userId);

    try {
      final statements = await _userDoc(userId)
          .collection(_creditCardStatementsConfig.collection)
          .where('cardId', isEqualTo: id)
          .get();
      for (final statement in statements.docs) {
        await _markRemoteDeleted(
          _creditCardStatementsConfig,
          statement.id,
          userId,
        );
      }
    } catch (_) {
      // Local card and statement deletion has already completed.
    }
  }

  // Credit Card Statements
  Future<void> insertStatement(CreditCardStatement s) async {
    await _insertSynced(_creditCardStatementsConfig, s.toMap());
  }

  Future<List<CreditCardStatement>> getStatements(String cardId) async {
    final maps = await _queryForCurrentUser(
      'credit_card_statements',
      where: 'cardId = ?',
      whereArgs: [cardId],
      orderBy: 'statementDate DESC',
    );
    return maps.map((m) => CreditCardStatement.fromMap(m)).toList();
  }

  Future<void> updateStatement(CreditCardStatement s) async {
    await _updateSynced(_creditCardStatementsConfig, s.id, s.toMap());
  }

  Future<void> deleteStatement(String id) async {
    await _deleteSynced(_creditCardStatementsConfig, id);
  }

  static const _transactionsConfig = _SyncConfig(
    table: 'transactions',
    collection: 'transactions',
    columns: {
      'id',
      'userId',
      'title',
      'amount',
      'category',
      'date',
      'isExpense',
      'isFixed',
      'creditCardId',
      'creditCardName',
    },
  );
  static const _subscriptionsConfig = _SyncConfig(
    table: 'subscriptions',
    collection: 'subscriptions',
    columns: {
      'id',
      'userId',
      'title',
      'amount',
      'category',
      'billingDay',
      'color',
      'creditCardId',
      'creditCardName',
      'lastChargedMonth',
    },
  );
  static const _debtsConfig = _SyncConfig(
    table: 'debts',
    collection: 'debts',
    columns: {
      'id',
      'userId',
      'title',
      'totalAmount',
      'paidAmount',
      'monthlyPayment',
      'startDate',
      'interestRate',
    },
  );
  static const _budgetsConfig = _SyncConfig(
    table: 'budgets',
    collection: 'budgets',
    columns: {'id', 'userId', 'category', 'limitAmount', 'month'},
  );
  static const _holdingsConfig = _SyncConfig(
    table: 'holdings',
    collection: 'holdings',
    columns: {
      'id',
      'userId',
      'symbol',
      'name',
      'buyPrice',
      'quantity',
      'buyDate',
    },
  );
  static const _notesConfig = _SyncConfig(
    table: 'notes',
    collection: 'notes',
    columns: {
      'id',
      'userId',
      'title',
      'content',
      'category',
      'color',
      'createdAt',
      'reminderTime',
      'isPinned',
      'isArchived',
    },
  );
  static const _healthRecordsConfig = _SyncConfig(
    table: 'health_records',
    collection: 'health_records',
    columns: {
      'id',
      'userId',
      'weight',
      'date',
      'note',
      'height',
      'waist',
      'neck',
      'hip',
      'shoulder',
      'chest',
      'arm',
      'thigh',
      'calf',
      'gender',
      'bodyFatPercentage',
      'ffmi',
    },
  );
  static const _habitsConfig = _SyncConfig(
    table: 'habits',
    collection: 'habits',
    columns: {
      'id',
      'userId',
      'title',
      'type',
      'startDate',
      'completedDays',
      'emoji',
      'motivation',
    },
  );
  static const _creditCardsConfig = _SyncConfig(
    table: 'credit_cards',
    collection: 'credit_cards',
    columns: {
      'id',
      'userId',
      'bankName',
      'cardName',
      'creditLimit',
      'currentDebt',
      'statementDay',
      'dueDay',
      'color',
    },
  );
  static const _creditCardStatementsConfig = _SyncConfig(
    table: 'credit_card_statements',
    collection: 'credit_card_statements',
    columns: {
      'id',
      'userId',
      'cardId',
      'cardName',
      'amount',
      'paidAmount',
      'statementDate',
      'dueDate',
    },
  );

  static const _syncConfigs = [
    _transactionsConfig,
    _subscriptionsConfig,
    _debtsConfig,
    _budgetsConfig,
    _holdingsConfig,
    _notesConfig,
    _healthRecordsConfig,
    _habitsConfig,
    _creditCardsConfig,
    _creditCardStatementsConfig,
  ];
}

class _SyncConfig {
  const _SyncConfig({
    required this.table,
    required this.collection,
    required this.columns,
  });

  final String table;
  final String collection;
  final Set<String> columns;
}
