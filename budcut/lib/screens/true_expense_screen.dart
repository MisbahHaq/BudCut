import 'package:flutter/material.dart';

import '../models/category.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/bento.dart';
import '../widgets/progress.dart';

class TrueExpenseScreen extends StatelessWidget {
  final AppState state;

  const TrueExpenseScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);

    final tx = state.inRange(monthStart, monthEnd);

    final fixed = tx.where((t) {
      final cat = state.categoryById(t.categoryId);
      return cat?.isFixed ?? false;
    }).fold<num>(0, (s, t) => s + t.amount);

    final variable = tx.where((t) {
      final cat = state.categoryById(t.categoryId);
      return !(cat?.isFixed ?? false);
    }).fold<num>(0, (s, t) => s + t.amount);

    final totalSpend = tx.fold<num>(0, (s, t) => s + t.amount);
    final budget = state.monthlyBudget;
    final unspent = (budget - totalSpend).clamp(0, budget);

    final fixedFrac = budget > 0 ? (fixed / budget).toDouble() : 0.0;
    final varFrac = budget > 0 ? (variable / budget).toDouble() : 0.0;
    final bufferFrac = budget > 0 ? (unspent / budget).toDouble() : 0.0;

    final committed = state.totalMonthlyLiability;
    final trueObligation = committed;
    final safeBuffer = (budget - trueObligation).clamp(0, budget);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
      children: [
        const ScreenHeader(
          title: 'True Expense',
          subtitle: 'Fixed commitments vs. flexible spending',
        ),
        const SizedBox(height: 18),
        Container(
          decoration: AppTheme.cardDecoration,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TileLabel('Monthly budget ceiling'),
              const SizedBox(height: 8),
              KpiValue(state.formatValue(budget), size: 26),
              const SizedBox(height: 16),
              _compositionBar(fixedFrac, varFrac, bufferFrac),
              const SizedBox(height: 14),
              Row(
                children: [
                  _legend('FIXED', AppTheme.negative),
                  _legend('VARIABLE', AppTheme.warning),
                  _legend('BUFFER', AppTheme.positive),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.accent,
            borderRadius: BorderRadius.circular(AppTheme.radius),
            border:
                Border.all(color: AppTheme.ink, width: AppTheme.borderWidth),
            boxShadow: const [AppTheme.cardShadow],
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TileLabel('True monthly obligation'),
              const SizedBox(height: 4),
              KpiValue(state.formatValue(trueObligation), size: 32),
              const SizedBox(height: 8),
              const Text(
                'COMMITTED LIABILITY AFTER BUDGET',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: AppTheme.inkSoft,
                ),
              ),
              const SizedBox(height: 14),
              _safeBufferLine(context, safeBuffer),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _metric(context, 'Fixed committed',
                  state.formatValue(fixed),
                  '${(fixedFrac * 100).toStringAsFixed(1)}% of budget',
                  AppTheme.negative),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _metric(context, 'Variable (one-off)',
                  state.formatValue(variable),
                  '${(varFrac * 100).toStringAsFixed(1)}% of budget',
                  AppTheme.warning),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _metric(context, 'Unspent buffer',
                  state.formatValue(unspent), 'left to spend',
                  AppTheme.positive),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _metric(context, 'Committed liability',
                  state.formatValue(committed), 'per month (recurring)',
                  AppTheme.ink),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          decoration: AppTheme.cardDecoration,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TileLabel('Fixed committed spend'),
              const SizedBox(height: 8),
              for (final c in state.categories.where((c) => c.isFixed))
                _fixedRow(context, c, state),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Container(
          decoration: AppTheme.cardDecoration,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TileLabel('Variable discretionary spend'),
              const SizedBox(height: 8),
              for (final c in state.categories.where((c) => !c.isFixed))
                _fixedRow(context, c, state),
            ],
          ),
        ),
        const SizedBox(height: 90),
      ],
    );
  }

  Widget _safeBufferLine(BuildContext context, num safeBuffer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('SAFE BUFFER',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: AppTheme.inkSoft,
                  )),
            ),
            Text(
              state.formatValue(safeBuffer),
              style: const TextStyle(
                fontFamily: AppTheme.mono,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppTheme.ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ProgressBar(
          fraction: safeBuffer > 0
              ? (safeBuffer / state.monthlyBudget).clamp(0.0, 1.0)
              : 0.0,
          color: safeBuffer > 0 ? AppTheme.positive : AppTheme.negative,
          height: 10,
        ),
        const SizedBox(height: 4),
        Text(
          safeBuffer > 0
              ? '${((safeBuffer / state.monthlyBudget) * 100).toStringAsFixed(1)}% reserved for flexible use'
              : 'No buffer left — obligations exceed budget',
          style: TextStyle(
            fontFamily: AppTheme.mono,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: safeBuffer > 0 ? AppTheme.positive : AppTheme.negative,
          ),
        ),
      ],
    );
  }

  Widget _compositionBar(double fixed, double variable, double buffer) {
    final total = fixed + variable + buffer;
    if (total <= 0) {
      fixed = 0;
      variable = 0;
      buffer = 1;
    }
    return Container(
      height: 18,
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.ink, width: AppTheme.borderWidth),
      ),
      child: Row(
        children: [
          Expanded(
            flex: (fixed * 1000).round(),
            child: Container(color: AppTheme.negative),
          ),
          Expanded(
            flex: (variable * 1000).round(),
            child: Container(color: AppTheme.warning),
          ),
          Expanded(
            flex: (buffer * 1000).round(),
            child: Container(color: AppTheme.positive),
          ),
        ],
      ),
    );
  }

  Widget _legend(String label, Color color) {
    return Expanded(
      child: Row(
        children: [
          Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                border: Border.all(color: AppTheme.ink, width: 1),
              )),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.inkSoft),
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(BuildContext context, String label, String value, String sub,
      Color color) {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TileLabel(label),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: KpiValue(value, size: 18, color: color),
          ),
          const SizedBox(height: 2),
          Text(sub,
              style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.inkSoft,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _fixedRow(BuildContext context, CategoryModel c, AppState state) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);
    final spent = state
        .inRange(monthStart, monthEnd)
        .where((t) => t.categoryId == c.id)
        .fold<num>(0, (s, t) => s + t.amount);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          ColorDot(c.color, size: 8),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              c.name,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, color: AppTheme.ink),
            ),
          ),
          Text(
            state.formatValue(spent),
            style: const TextStyle(
              fontFamily: AppTheme.mono,
              fontWeight: FontWeight.w900,
              color: AppTheme.ink,
            ),
          ),
        ],
      ),
    );
  }
}
