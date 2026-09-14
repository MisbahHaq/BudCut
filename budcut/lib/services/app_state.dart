import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../currency.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../services/firestore_service.dart';
import '../services/seed_data.dart';
import '../theme.dart';

/// Central application state (ChangeNotifier), backed by Cloud Firestore.
class AppState extends ChangeNotifier {
  late FirestoreService _firestore;
  List<CategoryModel> _categories = [];
  List<AppTransaction> _transactions = [];
  num _monthlyBudget = 250000;
  String _currencyCode = 'PKR';

  List<CategoryModel> get categories => List.unmodifiable(_categories);
  List<AppTransaction> get transactions => List.unmodifiable(_transactions);
  num get monthlyBudget => _monthlyBudget;
  String get currencyCode => _currencyCode;
  Currency get currency => Currencies.byCode(_currencyCode);

  /// Formats a stored (PKR-base) amount in the active currency.
  String formatValue(num value) => Money(value).formatFor(currency);

  bool isReady = false;

  /// Loads this user's data from Firestore. A brand-new account is seeded
  /// with the default category template and a zero budget.
  static Future<AppState> create(User user) async {
    final state = AppState();
    state._firestore = FirestoreService(user.uid);
    await state._load();
    return state;
  }

  Future<void> _load() async {
    // Currency is fixed to PKR.
    _currencyCode = 'PKR';
    Currencies.current.value = Currencies.pkr;

    _categories = await _firestore.loadCategories();
    _transactions = await _firestore.loadTransactions();
    _monthlyBudget = await _firestore.loadBudget();

    if (_categories.isEmpty && !await _firestore.hasProfile()) {
      _categories = List.of(SeedData.categories);
      _monthlyBudget = 0;
      await _firestore.seedCategories(_categories);
      await _firestore.setBudget(_monthlyBudget);
    }

    _sortTransactions();
    isReady = true;
    notifyListeners();
  }

  // ------------------------------------------------------------------
  // Currency (fixed to PKR)
  // ------------------------------------------------------------------

  // The app is PKR-only. [Currencies.current] is pinned to [Currencies.pkr]
  // on load and every stored value is formatted in PKR.

  // ------------------------------------------------------------------
  // Transactions
  // ------------------------------------------------------------------

  CategoryModel? categoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  AppTransaction? transactionById(String id) {
    try {
      return _transactions.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> addTransaction({
    required num amount,
    required DateTime date,
    required String categoryId,
    String merchant = '',
    String notes = '',
    List<String> tags = const [],
  }) async {
    final tx = AppTransaction(
      id: 'tx-${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(9999)}',
      amount: amount,
      date: date,
      categoryId: categoryId,
      merchant: merchant,
      notes: notes,
      tags: tags,
    );
    _transactions.add(tx);
    _sortTransactions();
    await _firestore.addTransaction(tx);
    notifyListeners();
  }

  Future<void> updateTransaction(AppTransaction tx) async {
    final idx = _transactions.indexWhere((t) => t.id == tx.id);
    if (idx >= 0) {
      _transactions[idx] = tx;
      _sortTransactions();
      await _firestore.updateTransaction(tx);
      notifyListeners();
    }
  }

  Future<void> deleteTransaction(String id) async {
    _transactions.removeWhere((t) => t.id == id);
    await _firestore.deleteTransaction(id);
    notifyListeners();
  }

  void _sortTransactions() {
    _transactions.sort((a, b) => b.date.compareTo(a.date));
  }

  List<AppTransaction> inRange(DateTime start, DateTime end) {
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day, 23, 59, 59);
    return _transactions
        .where((t) => !t.date.isBefore(s) && !t.date.isAfter(e))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  num spendInRange(DateTime start, DateTime end) {
    return inRange(start, end).fold<num>(0, (sum, t) => sum + t.amount);
  }

  num spendInMonth(DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0);
    return spendInRange(start, end);
  }

  // ------------------------------------------------------------------
  // Budget
  // ------------------------------------------------------------------

  Future<void> setMonthlyBudget(num value) async {
    _monthlyBudget = value;
    await _firestore.setBudget(_monthlyBudget);
    notifyListeners();
  }

  // ------------------------------------------------------------------
  // Categories
  // ------------------------------------------------------------------

  Future<void> addCategory(
    String name,
    String color, {
    num? monthlyCap,
    bool isFixed = false,
  }) async {
    final cat = CategoryModel(
      id: 'cat-${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      color: color,
      monthlyCap: monthlyCap,
      isFixed: isFixed,
    );
    _categories.add(cat);
    await _firestore.addCategory(cat);
    notifyListeners();
  }

  Future<void> updateCategory(CategoryModel updated) async {
    final idx = _categories.indexWhere((c) => c.id == updated.id);
    if (idx >= 0) {
      _categories[idx] = updated;
      await _firestore.updateCategory(updated);
      notifyListeners();
    }
  }

  Future<void> deleteCategory(String id) async {
    _categories.removeWhere((c) => c.id == id);
    await _firestore.deleteCategory(id);
    notifyListeners();
  }

  // ------------------------------------------------------------------
  // Analysis helpers
  // ------------------------------------------------------------------

  num spendForCategoryInMonth(DateTime month, String categoryId) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0);
    return inRange(start, end)
        .where((t) => t.categoryId == categoryId)
        .fold<num>(0, (sum, t) => sum + t.amount);
  }

  Map<String, num> spendByCategory(DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0);
    final map = <String, num>{};
    for (final tx in inRange(start, end)) {
      map[tx.categoryId] = (map[tx.categoryId] ?? 0) + tx.amount;
    }
    return map;
  }

  List<({DateTime day, num amount})> dailySpend(
    DateTime start,
    DateTime end,
  ) {
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    final list = <({DateTime day, num amount})>[];
    final byDay = <DateTime, num>{};
    for (final tx in inRange(s, e)) {
      final d = DateTime(tx.date.year, tx.date.month, tx.date.day);
      byDay[d] = (byDay[d] ?? 0) + tx.amount;
    }
    var cursor = s;
    while (!cursor.isAfter(e)) {
      list.add((day: cursor, amount: byDay[cursor] ?? 0));
      cursor = cursor.add(const Duration(days: 1));
    }
    return list;
  }

  /// Wipes everything (categories and transactions) to zero and resets the
  /// budget so the user can start fresh.
  Future<void> resetAll() async {
    _categories = [];
    _transactions = [];
    _monthlyBudget = 0;
    await _firestore.resetAll();
    notifyListeners();
  }
}