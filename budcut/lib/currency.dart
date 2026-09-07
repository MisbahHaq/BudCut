import 'package:flutter/foundation.dart';

/// Supported currencies. Amounts are stored internally in PKR (base unit)
/// and converted for display/entry based on the active currency.
class Currency {
  final String code;
  final String name;
  final String symbol;

  /// Value of 1 PKR expressed in this currency.
  final double ratePerPkr;

  const Currency({
    required this.code,
    required this.name,
    required this.symbol,
    required this.ratePerPkr,
  });

  /// Symbol for inline display (input prefixes, dropdowns).
  String get display => symbol;

  num fromPkr(num pkrAmount) => (pkrAmount * ratePerPkr).toDouble();

  num toPkr(num foreignAmount) {
    if (ratePerPkr <= 0) return foreignAmount;
    return (foreignAmount / ratePerPkr).toDouble();
  }
}

class Currencies {
  static const pkr =
      Currency(code: 'PKR', name: 'Pakistani Rupee', symbol: 'Rs', ratePerPkr: 1);
  static const usd =
      Currency(code: 'USD', name: 'US Dollar', symbol: r'$', ratePerPkr: 0.0036);
  static const eur =
      Currency(code: 'EUR', name: 'Euro', symbol: '€', ratePerPkr: 0.0033);
  static const gbp =
      Currency(code: 'GBP', name: 'British Pound', symbol: '£', ratePerPkr: 0.0028);
  static const cad =
      Currency(code: 'CAD', name: 'Canadian Dollar', symbol: r'C$', ratePerPkr: 0.0049);
  static const inr =
      Currency(code: 'INR', name: 'Indian Rupee', symbol: '₹', ratePerPkr: 0.30);
  static const aed =
      Currency(code: 'AED', name: 'UAE Dirham', symbol: 'AED', ratePerPkr: 0.0132);
  static const sar =
      Currency(code: 'SAR', name: 'Saudi Riyal', symbol: 'SAR', ratePerPkr: 0.0135);

  static const all = [pkr, usd, eur, gbp, cad, inr, aed, sar];

  static Currency byCode(String code) {
    for (final c in all) {
      if (c.code == code) return c;
    }
    return pkr;
  }

  /// The globally active currency. UI listens to this notifier so that every
  /// monetary value re-renders when the user switches currencies.
  static final ValueNotifier<Currency> current = ValueNotifier<Currency>(pkr);
}