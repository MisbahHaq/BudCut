import 'package:flutter/material.dart';

import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/bento.dart';
import '../widgets/charts.dart';
import '../widgets/progress.dart';
import '../widgets/transaction_list.dart';

class MonthlyScreen extends StatefulWidget {
  final AppState state;

  const MonthlyScreen({super.key, required this.state});

  @override
  State<MonthlyScreen> createState() => _MonthlyScreenState();
}

class _MonthlyScreenState extends State<MonthlyScreen> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month, 1);
  }

  void _shift(int months) {
    setState(() {
      _month = DateTime(_month.year, _month.month + months, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final start = DateTime(_month.year, _month.month, 1);
    final end = DateTime(_month.year, _month.month + 1, 0);
    final daily = state.dailySpend(start, end);
    final spend = state.spendInMonth(_month);
    final catSpend = state.spendByCategory(_month);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _NavBtn(icon: Icons.chevron_left, onTap: () => _shift(-1)),
            Column(
              children: [
                Text(
                  _monthName(_month),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.ink,
                  ),
                ),
                Text(
                  '${_month.year}',
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.inkSoft,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
            _NavBtn(icon: Icons.chevron_right, onTap: () => _shift(1)),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          decoration: AppTheme.cardDecoration,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TileLabel('Total monthly spend'),
              const SizedBox(height: 6),
              KpiValue(state.formatValue(spend), size: 28),
              const SizedBox(height: 4),
              Text(
                '${daily.where((d) => d.amount > 0).length} active days',
                style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.inkSoft,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              if (daily.length > 1)
                DailyBarChart(data: daily, maxLabels: 7),
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
              const TileLabel('Category breakdown'),
              const SizedBox(height: 8),
              for (final c in state.categories)
                if ((catSpend[c.id] ?? 0) > 0)
                  _breakdownRow(context, c, catSpend[c.id]!, spend),
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
              Text(
                '${_monthName(_month).toUpperCase()} TRANSACTIONS',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.ink,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              TransactionList(
                state: state,
                fixedList: state.inRange(start, end),
              ),
            ],
          ),
        ),
        const SizedBox(height: 90),
      ],
    );
  }

  Widget _breakdownRow(
      BuildContext context, dynamic c, num spent, num total) {
    final cap = c.monthlyCap as num?;
    final pct = total > 0 ? (spent / total) * 100 : 0.0;
    final surplusAmt = cap != null ? cap - spent : null;
    final over = surplusAmt != null && surplusAmt < 0;
    final surplus = surplusAmt ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ColorDot(c.color as String, size: 8),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  c.name as String,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, color: AppTheme.ink),
                ),
              ),
              Text(
                widget.state.formatValue(spent),
                style: const TextStyle(
                  fontFamily: AppTheme.mono,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.ink,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${pct.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontFamily: AppTheme.mono,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.inkSoft,
                ),
              ),
            ],
          ),
          if (cap != null) ...[
            const SizedBox(height: 6),
            ProgressBar(
              fraction: (spent / cap).toDouble(),
              color: over
                  ? AppTheme.negative
                  : ColorDot.parse(c.color as String),
              height: 6,
            ),
            const SizedBox(height: 3),
            Text(
              over
                  ? 'Over cap by ${widget.state.formatValue(-surplus)}'
                  : 'Cap surplus ${widget.state.formatValue(surplus)}',
              style: TextStyle(
                fontFamily: AppTheme.mono,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: over ? AppTheme.negative : AppTheme.inkSoft,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _monthName(DateTime m) {
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return names[m.month - 1];
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            border:
                Border.all(color: AppTheme.ink, width: AppTheme.borderWidth),
          ),
          child: Icon(icon, size: 20, color: AppTheme.ink),
        ),
      ),
    );
  }
}
