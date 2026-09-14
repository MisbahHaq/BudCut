import '../models/category.dart';

/// Default category template used for a brand-new user/account.
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
}