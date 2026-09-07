import 'package:flutter/material.dart';

import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/bento.dart';
import '../widgets/charts.dart';
import '../widgets/progress.dart';
import '../widgets/transaction_list.dart';

class QuarterlyScreen extends StatefulWidget {
  final AppState state;

  const QuarterlyScreen({super.key, required this.state});

  @override
  State<QuarterlyScreen> createState() => _QuarterlyScreenState();
}

class _QuarterlyScreenState extends State<QuarterlyScreen> {
  late DateTime _endMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _endMonth = DateTime(now.year, now.month, 1);
  }

  DateTime get _startMonth => DateTime(_endMonth.year, _endMonth.month - 2, 1);
  DateTime get _start => _startMonth;
  DateTime get _end => DateTime(_endMonth.year, _endMonth.month + 1, 0);

  void _shift(int months) {
    setState(() {
      _endMonth = DateTime(_endMonth.year, _endMonth.month + months, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final months = <DateTime>[
      _startMonth,
      DateTime(_startMonth.year, _startMonth.month + 1, 1),
      _endMonth,
    ];

    final spends = months.map((m) => state.spendInMonth(m)).toList();
    final total3 = spends.fold<num>(0, (s, v) => s + v);
    final avg = total3 / 3;

    final growthPrev = months.length >= 3
        ? ((spends[2] - spends[1]) /
                (spends[1] > 0 ? spends[1] : 1)) *
            100
        : 0.0;
    final growthFirstSecond = ((spends[1] - spends[0]) /
            (spends[0] > 0 ? spends[0] : 1)) *
        100;

    final byMonth = <({DateTime month, Map<String, num> byCat})>[
      for (final m in months) (month: m, byCat: state.spendByCategory(m)),
    ];

    final palette =
        state.categories.map((c) => ColorDot.parse(c.color)).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _NavBtn(icon: Icons.chevron_left, onTap: () => _shift(-3)),
            Column(
              children: [
                Text(
                  _quarterLabel(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.ink,
                  ),
                ),
                const Text(
                  '3-MONTH WINDOW',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: AppTheme.inkSoft),
                ),
              ],
            ),
            _NavBtn(icon: Icons.chevron_right, onTap: () => _shift(3)),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: AppTheme.cardDecoration,
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const TileLabel('Quarterly spend'),
                    const SizedBox(height: 6),
                    KpiValue(state.formatValue(total3), size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                decoration: AppTheme.cardDecoration,
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const TileLabel('Monthly average'),
                    const SizedBox(height: 6),
                    KpiValue(state.formatValue(avg), size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: AppTheme.cardDecoration,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TileLabel('Month-over-month variance'),
              const SizedBox(height: 10),
              _varianceRow('1st → 2nd', growthFirstSecond),
              const SizedBox(height: 6),
              _varianceRow('2nd → 3rd', growthPrev),
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
              const TileLabel('3-month stacked categories'),
              const SizedBox(height: 14),
              if (total3 > 0)
                StackedBarChart(
                    data: byMonth,
                    colors: palette,
                    height: 200)
              else
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Center(
                    child: Text('No spending in this window',
                        style: TextStyle(
                            color: AppTheme.inkSoft,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
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
              const TileLabel('Month totals'),
              const SizedBox(height: 8),
              for (var i = 0; i < months.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_shortMonth(months[i])} ${months[i].year}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppTheme.ink),
                        ),
                      ),
                      if (i > 0)
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Text(
                            _growthNote(spends[i], spends[i - 1]),
                            style: TextStyle(
                              fontFamily: AppTheme.mono,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: spends[i] > spends[i - 1]
                                  ? AppTheme.negative
                                  : AppTheme.positive,
                            ),
                          ),
                        ),
                      Text(
                        state.formatValue(spends[i]),
                        style: const TextStyle(
                          fontFamily: AppTheme.mono,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.ink,
                        ),
                      ),
                    ],
                  ),
                ),
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
              const Text(
                'QUARTERLY TRANSACTIONS',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.ink,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              TransactionList(
                state: state,
                fixedList: state.inRange(_start, _end),
              ),
            ],
          ),
        ),
        const SizedBox(height: 90),
      ],
    );
  }

  String _growthNote(num cur, num prev) {
    if (prev <= 0) return 'new';
    final delta = ((cur - prev) / prev) * 100;
    return '${cur >= prev ? '+' : ''}${delta.toStringAsFixed(1)}%';
  }

  Widget _varianceRow(String label, double pct) {
    final up = pct >= 0;
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: const TextStyle(
                  color: AppTheme.inkSoft,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ),
        Icon(
          up ? Icons.arrow_upward : Icons.arrow_downward,
          size: 14,
          color: up ? AppTheme.negative : AppTheme.positive,
        ),
        const SizedBox(width: 4),
        Text(
          '${up ? '+' : ''}${pct.toStringAsFixed(1)}%',
          style: TextStyle(
            fontFamily: AppTheme.mono,
            fontWeight: FontWeight.w900,
            color: up ? AppTheme.negative : AppTheme.positive,
          ),
        ),
      ],
    );
  }

  String _quarterLabel() {
    final s = _startMonth;
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${names[s.month - 1]} ${s.year} – ${names[_endMonth.month - 1]} ${_endMonth.year}';
  }

  String _shortMonth(DateTime m) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
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
