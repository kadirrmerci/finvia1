import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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

  static const _userDataCollections = [
    'notes',
    'transactions',
    'subscriptions',
    'debts',
    'budgets',
    'holdings',
    'health_records',
    'health_goals',
    'habits',
    'credit_cards',
    'credit_card_statements',
    'settings',
  ];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  CollectionReference<Map<String, dynamic>> _userCollection(String collection) {
    return _userDoc(_currentUserId).collection(collection);
  }

  Future<void> _setDoc(
    String collection,
    String id,
    Map<String, dynamic> values,
  ) async {
    final userId = _currentUserId;
    await _userDoc(userId).collection(collection).doc(id).set({
      ...values,
      'userId': userId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _deleteDoc(String collection, String id) {
    return _userCollection(collection).doc(id).delete();
  }

  Future<List<Map<String, dynamic>>> _getCollection(String collection) async {
    final snapshot = await _userCollection(
      collection,
    ).get(const GetOptions(source: Source.server));
    return snapshot.docs
        .map((doc) => _normalizeDocument(doc.id, doc.data()))
        .toList();
  }

  Map<String, dynamic> _normalizeDocument(
    String id,
    Map<String, dynamic> data,
  ) {
    return {
      ...data.map((key, value) => MapEntry(key, _normalizeValue(value))),
      'id': data['id'] ?? id,
    };
  }

  dynamic _normalizeValue(dynamic value) {
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is List) {
      return value.map(_normalizeValue).join(',');
    }
    return value;
  }

  Future<bool> verifyCloudAccess() async {
    try {
      await _userDoc(_currentUserId)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 15));
      return true;
    } catch (error, stackTrace) {
      debugPrint('Finvia cloud access check failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  @Deprecated('Use verifyCloudAccess; local/cloud synchronization was removed.')
  Future<bool> syncCurrentUserData() => verifyCloudAccess();

  Future<Map<String, dynamic>> getAppSettings() async {
    final doc = await _userCollection(
      'settings',
    ).doc('app').get(const GetOptions(source: Source.server));
    return doc.data() ?? const {};
  }

  Future<void> saveAppSettings(Map<String, dynamic> values) {
    return _setDoc('settings', 'app', values);
  }

  Future<void> deleteAllCurrentUserData() async {
    final userId = _currentUserId;
    final userRef = _userDoc(userId);
    for (final collection in _userDataCollections) {
      await _deleteCollectionInBatches(userRef.collection(collection));
    }
    await userRef.set({
      'lastDataResetAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _deleteCollectionInBatches(
    CollectionReference<Map<String, dynamic>> collection,
  ) async {
    const batchSize = 450;
    while (true) {
      final snapshot = await collection
          .limit(batchSize)
          .get(const GetOptions(source: Source.server));
      if (snapshot.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  Future<void> insertNote(Note note) => _setDoc('notes', note.id, note.toMap());

  Future<List<Note>> getNotes() async {
    final rows = await _getCollection('notes');
    rows.removeWhere((row) => row['isArchived'] != 0);
    rows.sort((a, b) {
      final pinned = (b['isPinned'] as num? ?? 0).compareTo(
        a['isPinned'] as num? ?? 0,
      );
      if (pinned != 0) return pinned;
      return (b['createdAt']?.toString() ?? '').compareTo(
        a['createdAt']?.toString() ?? '',
      );
    });
    return rows.map(Note.fromMap).toList();
  }

  Future<void> updateNote(Note note) => _setDoc('notes', note.id, note.toMap());

  Future<void> deleteNote(String id) => _deleteDoc('notes', id);

  Future<void> insertTransaction(FinanceTransaction transaction) =>
      _setDoc('transactions', transaction.id, transaction.toMap());

  Future<List<FinanceTransaction>> getTransactions() async {
    final rows = await _getCollection('transactions');
    rows.sort(
      (a, b) =>
          (b['date']?.toString() ?? '').compareTo(a['date']?.toString() ?? ''),
    );
    return rows.map(FinanceTransaction.fromMap).toList();
  }

  Future<void> deleteTransaction(String id) => _deleteDoc('transactions', id);

  Future<void> insertSubscription(Subscription subscription) =>
      _setDoc('subscriptions', subscription.id, subscription.toMap());

  Future<List<Subscription>> getSubscriptions() async {
    final rows = await _getCollection('subscriptions');
    return rows.map(Subscription.fromMap).toList();
  }

  Future<int> applyDueSubscriptionCharges({DateTime? now}) async {
    final chargeDate = now ?? DateTime.now();
    final monthKey =
        '${chargeDate.year}-${chargeDate.month.toString().padLeft(2, '0')}';
    final subscriptions = await _userCollection('subscriptions')
        .where('billingDay', isLessThanOrEqualTo: chargeDate.day)
        .get(const GetOptions(source: Source.server));
    var chargedCount = 0;

    for (final subscription in subscriptions.docs) {
      final data = subscription.data();
      final cardId = data['creditCardId'] as String?;
      if (cardId == null ||
          cardId.isEmpty ||
          data['lastChargedMonth'] == monthKey) {
        continue;
      }

      final cardRef = _userCollection('credit_cards').doc(cardId);
      final charged = await _firestore.runTransaction((transaction) async {
        final latestSubscription = await transaction.get(
          subscription.reference,
        );
        final latestData = latestSubscription.data();
        if (!latestSubscription.exists ||
            latestData == null ||
            latestData['lastChargedMonth'] == monthKey) {
          return false;
        }

        final card = await transaction.get(cardRef);
        final cardData = card.data();
        if (!card.exists || cardData == null) return false;

        final amount = (latestData['amount'] as num).toDouble();
        final currentDebt = (cardData['currentDebt'] as num).toDouble();
        transaction.update(cardRef, {
          'currentDebt': currentDebt + amount,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        transaction.update(subscription.reference, {
          'lastChargedMonth': monthKey,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return true;
      });
      if (charged) chargedCount++;
    }
    return chargedCount;
  }

  Future<void> deleteSubscription(String id) => _deleteDoc('subscriptions', id);

  Future<void> insertDebt(Debt debt) => _setDoc('debts', debt.id, debt.toMap());

  Future<List<Debt>> getDebts() async {
    final rows = await _getCollection('debts');
    return rows.map(Debt.fromMap).toList();
  }

  Future<void> updateDebt(Debt debt) => _setDoc('debts', debt.id, debt.toMap());

  Future<void> deleteDebt(String id) => _deleteDoc('debts', id);

  Future<void> insertBudget(Budget budget) =>
      _setDoc('budgets', budget.id, budget.toMap());

  Future<List<Budget>> getBudgets() async {
    final rows = await _getCollection('budgets');
    return rows.map(Budget.fromMap).toList();
  }

  Future<void> updateBudget(Budget budget) =>
      _setDoc('budgets', budget.id, budget.toMap());

  Future<void> deleteBudget(String id) => _deleteDoc('budgets', id);

  Future<void> insertHolding(StockHolding holding) =>
      _setDoc('holdings', holding.id, holding.toMap());

  Future<List<StockHolding>> getHoldings() async {
    final rows = await _getCollection('holdings');
    return rows.map(StockHolding.fromMap).toList();
  }

  Future<void> deleteHolding(String id) => _deleteDoc('holdings', id);

  Future<void> insertHealthRecord(HealthRecord record) =>
      _setDoc('health_records', record.id, record.toMap());

  Future<List<HealthRecord>> getHealthRecords() async {
    final rows = await _getCollection('health_records');
    rows.sort(
      (a, b) =>
          (b['date']?.toString() ?? '').compareTo(a['date']?.toString() ?? ''),
    );
    return rows.map(HealthRecord.fromMap).toList();
  }

  Future<void> deleteHealthRecord(String id) =>
      _deleteDoc('health_records', id);

  Future<Map<String, dynamic>?> getHealthGoal() async {
    final doc = await _userCollection(
      'health_goals',
    ).doc('main').get(const GetOptions(source: Source.server));
    final data = doc.data();
    return data == null ? null : _normalizeDocument(doc.id, data);
  }

  Future<void> saveHealthGoal({
    double? targetWeight,
    int? bodyFatReminderDay,
    int? bodyFatReminderHour,
    int? bodyFatReminderMinute,
  }) {
    return _setDoc('health_goals', 'main', {
      'id': 'main',
      'targetWeight': targetWeight,
      'bodyFatReminderDay': bodyFatReminderDay,
      'bodyFatReminderHour': bodyFatReminderHour,
      'bodyFatReminderMinute': bodyFatReminderMinute,
    });
  }

  Future<void> insertHabit(Habit habit) =>
      _setDoc('habits', habit.id, habit.toMap());

  Future<List<Habit>> getHabits() async {
    final rows = await _getCollection('habits');
    return rows.map(Habit.fromMap).toList();
  }

  Future<void> updateHabit(Habit habit) =>
      _setDoc('habits', habit.id, habit.toMap());

  Future<void> deleteHabit(String id) => _deleteDoc('habits', id);

  Future<void> insertCreditCard(CreditCard card) =>
      _setDoc('credit_cards', card.id, card.toMap());

  Future<List<CreditCard>> getCreditCards() async {
    final rows = await _getCollection('credit_cards');
    return rows.map(CreditCard.fromMap).toList();
  }

  Future<void> updateCreditCard(CreditCard card) =>
      _setDoc('credit_cards', card.id, card.toMap());

  Future<void> deleteCreditCard(String id) async {
    await _deleteDoc('credit_cards', id);
    while (true) {
      final statements = await _userCollection('credit_card_statements')
          .where('cardId', isEqualTo: id)
          .limit(450)
          .get(const GetOptions(source: Source.server));
      if (statements.docs.isEmpty) return;
      final batch = _firestore.batch();
      for (final statement in statements.docs) {
        batch.delete(statement.reference);
      }
      await batch.commit();
    }
  }

  Future<void> insertStatement(CreditCardStatement statement) =>
      _setDoc('credit_card_statements', statement.id, statement.toMap());

  Future<List<CreditCardStatement>> getStatements(String cardId) async {
    final snapshot = await _userCollection('credit_card_statements')
        .where('cardId', isEqualTo: cardId)
        .get(const GetOptions(source: Source.server));
    final rows =
        snapshot.docs
            .map((doc) => _normalizeDocument(doc.id, doc.data()))
            .toList()
          ..sort(
            (a, b) => (b['statementDate']?.toString() ?? '').compareTo(
              a['statementDate']?.toString() ?? '',
            ),
          );
    return rows.map(CreditCardStatement.fromMap).toList();
  }

  Future<void> updateStatement(CreditCardStatement statement) =>
      _setDoc('credit_card_statements', statement.id, statement.toMap());

  Future<void> deleteStatement(String id) =>
      _deleteDoc('credit_card_statements', id);
}
