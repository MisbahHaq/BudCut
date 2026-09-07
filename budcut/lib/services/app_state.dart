import 'dart:math';

import 'package:flutter/foundation.dart';

import '../currency.dart';
import '../models/category.dart';
import '../models/recurring_bill.dart';
import '../models/transaction.dart';
import '../services/seed_data.dart';
import '../services/storage_service.dart';
import '../theme.dart';

/// Central application state (ChangeNotifier).
class AppState extends ChangeNotifier {
  late StorageService _storage;
  List<CategoryModel> _categories = [];
  List<AppTransaction> _transactions = [];
  List<RecurringBill> _bills = [];
  num _monthlyBudget = 250000;
  String _currencyCode = 'PKR';

  List<CategoryModel> get categories => List.unmodifiable(_categories);
  List<AppTransaction> get transactions => List.unmodifiable(_transactions);
  List<RecurringBill> get bills => List.unmodifiable(_bills);
  num get monthlyBudget => _monthlyBudget;
  String get currencyCode => _currencyCode;
  Currency get currency => Currencies.byCode(_currencyCode);

  /// Formats a stored (PKR-base) amount in the active currency.
  String formatValue(num value) => Money(value).formatFor(currency);

  bool isReady = false;

  static Future<AppState> create() async {
    final state = AppState();
    state._storage = await StorageService.create();
    await state._load();
    return state;
  }

  Future<void> _load() async {
    _monthlyBudget = _storage.loadBudget();
    // Currency is fixed to PKR.
    _currencyCode = 'PKR';
    Currencies.current.value = Currencies.pkr;

    if (!_storage.isSeeded) {
      await _freshStart();
    } else {
      _categories = _storage
          .loadCategories()
          .map(CategoryModel.fromJson)
          .toList();
      _transactions = _storage
          .loadTransactions()
          .map(AppTransaction.fromJson)
          .toList();
      _bills = _storage.loadBills().map(RecurringBill.fromJson).toList();
    }

    isReady = true;
    notifyListeners();
  }

  /// Empty starting state: default category template, zero transactions,
  /// zero bills and a zero budget. No fake seed data.
  Future<void> _freshStart() async {
    _categories = List.of(SeedData.categories);
    _transactions = [];
    _bills = [];
    _monthlyBudget = 0;
    await _persistAll();
    await _storage.markSeeded();
  }

  Future<void> _persistAll() async {
    await _storage.saveCategories(
      _categories.map((c) => c.toJson()).toList(),
    );
    await _storage.saveTransactions(
      _transactions.map((t) => t.toJson()).toList(),
    );
    await _storage.saveBills(_bills.map((b) => b.toJson()).toList());
    await _storage.saveBudget(_monthlyBudget);
    await _storage.saveCurrency(_currencyCode);
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
    bool isRecurring = false,
  }) async {
    _transactions.add(AppTransaction(
      id: 'tx-${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(9999)}',
      amount: amount,
      date: date,
      categoryId: categoryId,
      merchant: merchant,
      notes: notes,
      tags: tags,
      isRecurring: isRecurring,
    ));
    _sortTransactions();
    await _persist();
    notifyListeners();
  }

  Future<void> updateTransaction(AppTransaction tx) async {
    final idx = _transactions.indexWhere((t) => t.id == tx.id);
    if (idx >= 0) {
      _transactions[idx] = tx;
      _sortTransactions();
      await _persist();
      notifyListeners();
    }
  }

  Future<void> deleteTransaction(String id) async {
    _transactions.removeWhere((t) => t.id == id);
    await _persist();
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
    await _storage.saveBudget(_monthlyBudget);
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
    _categories.add(CategoryModel(
      id: 'cat-${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      color: color,
      monthlyCap: monthlyCap,
      isFixed: isFixed,
    ));
    await _persist();
    notifyListeners();
  }

  Future<void> updateCategory(CategoryModel updated) async {
    final idx = _categories.indexWhere((c) => c.id == updated.id);
    if (idx >= 0) {
      _categories[idx] = updated;
      await _persist();
      notifyListeners();
    }
  }

  Future<void> deleteCategory(String id) async {
    _categories.removeWhere((c) => c.id == id);
    await _persist();
    notifyListeners();
  }

  // ------------------------------------------------------------------
  // Recurring bills
  // ------------------------------------------------------------------

  Future<void> addBill(RecurringBill bill) async {
    _bills.add(bill);
    await _persist();
    notifyListeners();
  }

  Future<void> updateBill(RecurringBill bill) async {
    final idx = _bills.indexWhere((b) => b.id == bill.id);
    if (idx >= 0) {
      _bills[idx] = bill;
      await _persist();
      notifyListeners();
    }
  }

  Future<void> deleteBill(String id) async {
    _bills.removeWhere((b) => b.id == id);
    await _persist();
    notifyListeners();
  }

  num get totalMonthlyLiability =>
      _bills.where((b) => b.isActive).fold<num>(0,
          (sum, b) => sum + b.monthlyLiability);

  /// Checks active bills and logs any that are due in the current month and
  /// not yet recorded. Returns the number of bills logged.
  Future<int> syncDueBills(DateTime now) async {
    var logged = 0;
    for (final bill in _bills.where((b) => b.isActive)) {
      // Only handle monthly-frequency bills in this quick sync.
      if (bill.frequency != BillFrequency.monthly) continue;

      final endOfMonth = DateTime(now.year, now.month + 1, 0).day;
      final day = bill.billingDay.clamp(1, endOfMonth);
      final dueDate = DateTime(now.year, now.month, day);

      if (dueDate.isAfter(now)) continue;

      final billedAt = dueDate;
      final already = _transactions.any((t) =>
          t.isRecurring &&
          t.categoryId == bill.categoryId &&
          t.amount == bill.amount &&
          t.date.year == billedAt.year &&
          t.date.month == billedAt.month &&
          t.date.day == billedAt.day);

      if (!already) {
        await addTransaction(
          amount: bill.amount,
          date: billedAt,
          categoryId: bill.categoryId,
          merchant: bill.name,
          notes: 'Auto-logged recurring bill',
          tags: const ['recurring'],
          isRecurring: true,
        );
        logged++;
      }
    }
    return logged;
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

  Future<void> _persist() async {
    await _storage.saveTransactions(
      _transactions.map((t) => t.toJson()).toList(),
    );
    await _storage.saveCategories(
      _categories.map((c) => c.toJson()).toList(),
    );
    await _storage.saveBills(_bills.map((b) => b.toJson()).toList());
    await _storage.saveBudget(_monthlyBudget);
    await _storage.saveCurrency(_currencyCode);
  }

  /// Wipes everything (categories, transactions, bills, budget) to zero so
  /// the user can start fresh. Currency preference is kept.
  Future<void> resetAll() async {
    _categories = [];
    _transactions = [];
    _bills = [];
    _monthlyBudget = 0;
    await _persistAll();
    notifyListeners();
  }
}