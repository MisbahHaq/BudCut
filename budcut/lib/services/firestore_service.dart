import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/category.dart';
import '../models/transaction.dart';

/// Persists every piece of BudCut data in Cloud Firestore, scoped to the
/// signed-in user's UID so each account keeps its own budget.
class FirestoreService {
  FirestoreService(this._uid);

  final String _uid;

  CollectionReference<Map<String, dynamic>> get _categories =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('categories');

  CollectionReference<Map<String, dynamic>> get _transactions =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('transactions');

  DocumentReference<Map<String, dynamic>> get _settings =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('settings')
          .doc('profile');

  Future<List<CategoryModel>> loadCategories() async {
    final snap = await _categories.get();
    return snap.docs
        .map((d) => CategoryModel.fromJson(d.data()))
        .toList();
  }

  Future<List<AppTransaction>> loadTransactions() async {
    final snap = await _transactions.get();
    return snap.docs
        .map((d) => AppTransaction.fromJson(d.data()))
        .toList();
  }

  Future<num> loadBudget() async {
    final snap = await _settings.get();
    if (!snap.exists) return 0;
    return (snap.data()?['monthlyBudget'] as num?) ?? 0;
  }

  /// Whether a profile document already exists for this user. Used to
  /// distinguish a brand-new account (seed defaults) from one where the
  /// user deliberately wiped or removed everything.
  Future<bool> hasProfile() async {
    final snap = await _settings.get();
    return snap.exists;
  }

  Future<void> seedCategories(List<CategoryModel> categories) async {
    final batch = FirebaseFirestore.instance.batch();
    for (final c in categories) {
      batch.set(_categories.doc(c.id), c.toJson());
    }
    await batch.commit();
  }

  Future<void> addCategory(CategoryModel category) =>
      _categories.doc(category.id).set(category.toJson());

  Future<void> updateCategory(CategoryModel category) =>
      _categories.doc(category.id).set(category.toJson());

  Future<void> deleteCategory(String id) => _categories.doc(id).delete();

  Future<void> addTransaction(AppTransaction tx) =>
      _transactions.doc(tx.id).set(tx.toJson());

  Future<void> updateTransaction(AppTransaction tx) =>
      _transactions.doc(tx.id).set(tx.toJson());

  Future<void> deleteTransaction(String id) =>
      _transactions.doc(id).delete();

  Future<void> setBudget(num value) =>
      _settings.set({'monthlyBudget': value, 'currency': 'PKR'});

  /// Wipes every document under the user so the app starts from scratch,
  /// then resets the budget to zero.
  Future<void> resetAll() async {
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in (await _transactions.get()).docs) {
      batch.delete(doc.reference);
    }
    for (final doc in (await _categories.get()).docs) {
      batch.delete(doc.reference);
    }
    batch.set(_settings, {'monthlyBudget': 0, 'currency': 'PKR'});
    await batch.commit();
  }
}