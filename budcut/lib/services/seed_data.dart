import 'dart:math';

import '../models/category.dart';
import '../models/recurring_bill.dart';
import '../models/transaction.dart';

/// Seeds realistic initial PKR expense data.
class SeedData {
  static final List<CategoryModel> categories = [
    CategoryModel(
      id: 'groceries',
      name: 'Groceries',
      color: '#30A46C',
      monthlyCap: 45000,
      isDefault: true,
    ),
    CategoryModel(
      id: 'dining',
      name: 'Dining',
      color: '#F5A623',
      monthlyCap: 20000,
      isDefault: true,
    ),
    CategoryModel(
      id: 'fuel',
      name: 'Fuel',
      color: '#4E6AF0',
      monthlyCap: 12000,
      isDefault: true,
    ),
    CategoryModel(
      id: 'utilities',
      name: 'Utilities',
      color: '#7C6AF0',
      monthlyCap: 25000,
      isFixed: true,
      isDefault: true,
    ),
    CategoryModel(
      id: 'rent',
      name: 'Rent',
      color: '#E5484D',
      monthlyCap: 60000,
      isFixed: true,
      isDefault: true,
    ),
    CategoryModel(
      id: 'subscriptions',
      name: 'Subscriptions',
      color: '#1498D8',
      monthlyCap: 5000,
      isFixed: true,
      isDefault: true,
    ),
    CategoryModel(
      id: 'shopping',
      name: 'Shopping',
      color: '#EC5CA8',
      monthlyCap: 15000,
      isDefault: true,
    ),
    CategoryModel(
      id: 'health',
      name: 'Health',
      color: '#3E63DD',
      monthlyCap: 10000,
      isDefault: true,
    ),
    CategoryModel(
      id: 'transport',
      name: 'Transport',
      color: '#8A4AF0',
      monthlyCap: 8000,
      isDefault: true,
    ),
    CategoryModel(
      id: 'entertainment',
      name: 'Entertainment',
      color: '#EE6C4D',
      monthlyCap: 10000,
      isDefault: true,
    ),
  ];

  static final List<RecurringBill> bills = [
    RecurringBill(
      id: 'bill-rent',
      name: 'Apartment Rent',
      amount: 60000,
      frequency: BillFrequency.monthly,
      billingDay: 1,
      categoryId: 'rent',
    ),
    RecurringBill(
      id: 'bill-electricity',
      name: 'Electricity Bill',
      amount: 9000,
      frequency: BillFrequency.monthly,
      billingDay: 10,
      categoryId: 'utilities',
    ),
    RecurringBill(
      id: 'bill-internet',
      name: 'Home Internet',
      amount: 4500,
      frequency: BillFrequency.monthly,
      billingDay: 15,
      categoryId: 'utilities',
    ),
    RecurringBill(
      id: 'bill-netflix',
      name: 'Netflix',
      amount: 800,
      frequency: BillFrequency.monthly,
      billingDay: 5,
      categoryId: 'subscriptions',
    ),
    RecurringBill(
      id: 'bill-mobile',
      name: 'Mobile Plan',
      amount: 1500,
      frequency: BillFrequency.monthly,
      billingDay: 20,
      categoryId: 'utilities',
    ),
    RecurringBill(
      id: 'bill-cloud',
      name: 'Cloud Storage',
      amount: 1700,
      frequency: BillFrequency.yearly,
      billingDay: 25,
      categoryId: 'subscriptions',
    ),
  ];

  /// Deterministic pseudo-random seed for realistic amounts/names.
  static List<AppTransaction> buildTransactions(DateTime now) {
    final rng = Random(42);
    final transactions = <AppTransaction>[];
    final nowYear = now.year;
    final nowMonth = now.month;

    final providers = <String, List<String>>{
      'groceries': ['Imtiaz Super Market', 'Al-Fatah', 'Carrefour', 'Kiran'],
      'dining': ['Cafe Zouk', 'BBQ Tonight', 'KFC', 'McDonalds', 'Street Food'],
      'fuel': ['Shell (Gulberg)', 'PSO Station', 'Total Parco'],
      'utilities': ['K-Electric', 'SNGPL', 'PTCL', 'Jazz'],
      'rent': ['Landlord - Gulberg'],
      'subscriptions': ['Netflix', 'Spotify', 'YouTube Premium', 'AWS'],
      'shopping': ['Khaadi', 'Sapphire', 'Daraz', 'Alkaram'],
      'health': ['Pharmacy', 'Clinic', 'Gym Membership'],
      'transport': ['Careem', 'inDrive', 'Metro Card'],
      'entertainment': ['Cinema', 'Steam', 'Cineplex'],
    };

    List<double> amountsFor(String cat) {
      switch (cat) {
        case 'groceries':
          return [4500, 7800, 3200, 9500, 5100, 1200, 6800];
        case 'dining':
          return [250, 900, 1500, 600, 2200, 350, 1200];
        case 'fuel':
          return [3000, 4200, 1800, 5000, 2600];
        case 'utilities':
          return [9000, 12000, 4500, 2100, 3400];
        case 'rent':
          return [60000];
        case 'subscriptions':
          return [800, 1700, 1500, 1100, 490];
        case 'shopping':
          return [2500, 8500, 4200, 1500, 6400];
        case 'health':
          return [1200, 3200, 900, 5000, 1500];
        case 'transport':
          return [300, 700, 450, 1300, 250];
        case 'entertainment':
          return [1000, 2200, 3500, 900, 600];
      }
      return [1000];
    }

    DateTime dateFor(DateTime anchor, int dayIndex) {
      return DateTime(nowYear, nowMonth - (dayIndex ~/ 28), 28 - (dayIndex % 28));
    }

    for (var day = 0; day < 90; day++) {
      final base = dateFor(now, day);
      var txCount = 1 + rng.nextInt(3);
      for (var t = 0; t < txCount; t++) {
        final catIdx = rng.nextInt(categories.length);
        final cat = categories[catIdx];
        final amounts = amountsFor(cat.id);
        var amount = amounts[rng.nextInt(amounts.length)];

        // Sprinkle a few realistic variance amounts.
        if (rng.nextDouble() < 0.3) {
          amount = amounts[rng.nextInt(amounts.length)] + rng.nextInt(1500);
        }
        if (cat.id == 'rent' && t > 0) continue;

        final dayOffset = rng.nextInt(24);
        final date = base
            .add(Duration(hours: 22))
            .subtract(Duration(hours: dayOffset));

        final namePool = providers[cat.id] ?? const ['General'];
        final merchant = namePool[rng.nextInt(namePool.length)];

        final isFixed = cat.isFixed && (rng.nextDouble() < 0.9);

        transactions.add(AppTransaction(
          id: 'seed-$day-$t',
          amount: amount,
          date: date,
          categoryId: cat.id,
          merchant: merchant,
          notes: '',
          tags: const [],
          isRecurring: isFixed,
        ));
      }
    }

    return transactions;
  }
}
