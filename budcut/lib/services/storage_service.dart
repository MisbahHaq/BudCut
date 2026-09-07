import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _keyCategories = 'budcut.categories';
  static const _keyTransactions = 'budcut.transactions';
  static const _keyBills = 'budcut.bills';
  static const _keyBudget = 'budcut.budget';
  static const _keySeeded = 'budcut.seeded';
  static const _keyCurrency = 'budcut.currency';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static SharedPreferences? _prefsCache;

  static Future<StorageService> create() async {
    _prefsCache = await SharedPreferences.getInstance();
    return StorageService(_prefsCache!);
  }

  bool get isSeeded => _prefs.getBool(_keySeeded) ?? false;

  Future<void> markSeeded() async {
    await _prefs.setBool(_keySeeded, true);
  }

  Future<void> saveCategories(List<Map<String, dynamic>> list) async {
    await _prefs.setString(_keyCategories, jsonEncode(list));
  }

  List<Map<String, dynamic>> loadCategories() {
    final raw = _prefs.getString(_keyCategories);
    if (raw == null) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.cast<Map<String, dynamic>>();
  }

  Future<void> saveTransactions(List<Map<String, dynamic>> list) async {
    await _prefs.setString(_keyTransactions, jsonEncode(list));
  }

  List<Map<String, dynamic>> loadTransactions() {
    final raw = _prefs.getString(_keyTransactions);
    if (raw == null) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.cast<Map<String, dynamic>>();
  }

  Future<void> saveBills(List<Map<String, dynamic>> list) async {
    await _prefs.setString(_keyBills, jsonEncode(list));
  }

  List<Map<String, dynamic>> loadBills() {
    final raw = _prefs.getString(_keyBills);
    if (raw == null) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.cast<Map<String, dynamic>>();
  }

  Future<void> saveBudget(num budget) async {
    await _prefs.setDouble(_keyBudget, budget.toDouble());
  }

  num loadBudget() {
    return _prefs.getDouble(_keyBudget) ?? 0;
  }

  /// Wipes every BudCut key so the app starts from scratch.
  Future<void> clearAll() async {
    await _prefs.clear();
  }

  Future<void> saveCurrency(String code) async {
    await _prefs.setString(_keyCurrency, code);
  }

  String loadCurrency() {
    return _prefs.getString(_keyCurrency) ?? 'PKR';
  }
}
