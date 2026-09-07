import 'package:flutter/material.dart';

import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/bento.dart';
import '../widgets/transaction_list.dart';

class WeeklyScreen extends StatefulWidget {
  final AppState state;

  const WeeklyScreen({super.key, required this.state});

  @override
  State<WeeklyScreen> createState() => _WeeklyScreenState();
}

class _WeeklyScreenState extends State<WeeklyScreen> {
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final mondayDelta = now.weekday - DateTime.monday;
    _weekStart = DateTime(now.year, now.month, now.day - mondayDelta);
  }

  DateTime get _weekEnd => _weekStart.add(const Duration(days: 6));
  DateTime get _prevStart => _weekStart.subtract(const Duration(days: 7));
  DateTime get _prevEnd => _weekStart.subtract(const Duration(days: 1));

  void _shift(int weeks) {
    setState(() => _weekStart = _weekStart.add(Duration(days: 7 * weeks)));
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final start = _weekStart;
    final end = _weekEnd;

    final cur = state.spendInRange(start, end);
    final prev = state.spendInRange(_prevStart, _prevEnd);
    final variance = prev > 0 ? ((cur - prev) / prev) * 100.0 : 0.0;
    final isUp = cur > prev;

    final curDaily = state.dailySpend(start, end);
    final prevDaily = state.dailySpend(_prevStart, _prevEnd);
    final maxVal = [
      ...curDaily.map((d) => d.amount),
      ...prevDaily.map((d) => d.amount),
    ].fold<num>(0, (m, v) => v > m ? v : m);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
      children: [
        _header(start, end),
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
                    const TileLabel('This week'),
                    const SizedBox(height: 6),
                    KpiValue(state.formatValue(cur)),
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
                    const TileLabel('Last week'),
                    const SizedBox(height: 6),
                    KpiValue(state.formatValue(prev)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: isUp ? const Color(0xFFFEE2E2) : const Color(0xFFD1FAE5),
            borderRadius: BorderRadius.circular(AppTheme.radius),
            border:
                Border.all(color: AppTheme.ink, width: AppTheme.borderWidth),
            boxShadow: const [AppTheme.cardShadow],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                isUp ? Icons.trending_up : Icons.trending_down,
                color: isUp ? AppTheme.negative : AppTheme.positive,
              ),
              const SizedBox(width: 10),
              Text(
                '${isUp ? 'UP' : 'DOWN'} '
                '${variance.abs().toStringAsFixed(1)}% '
                'VS LAST WEEK',
                style: const TextStyle(
                  fontFamily: AppTheme.mono,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  color: AppTheme.ink,
                  letterSpacing: 0.5,
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
              const TileLabel('Day-by-day comparison'),
              const SizedBox(height: 14),
              if (maxVal > 0)
                SizedBox(
                  height: 170,
                  child: _dualBarChart(curDaily, prevDaily, maxVal),
                )
              else
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Center(
                    child: Text('No spending in this range',
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
              const Text(
                'THIS WEEK TRANSACTIONS',
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
                fixedList: state.inRange(start, end),
              ),
            ],
          ),
        ),
        const SizedBox(height: 90),
      ],
    );
  }

  Widget _header(DateTime start, DateTime end) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _NavBtn(icon: Icons.chevron_left, onTap: () => _shift(-1)),
        Column(
          children: [
            Text(
              _rangeLabel(start, end),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppTheme.ink,
              ),
            ),
            Text(
              'Week ${_weekNumber(start)} of ${start.year}',
              style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.inkSoft,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
        _NavBtn(icon: Icons.chevron_right, onTap: () => _shift(1)),
      ],
    );
  }

  int _weekNumber(DateTime d) {
    final firstDay = DateTime(d.year, 1, 1);
    final firstMonday = firstDay.weekday % 7;
    final daysOffset = d.difference(firstDay).inDays;
    return ((daysOffset + (7 - firstMonday)) / 7).floor() + 1;
  }

  String _rangeLabel(DateTime start, DateTime end) {
    const mon = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    if (start.month == end.month && start.year == end.year) {
      return '${start.day}–${end.day} ${mon[end.month - 1]} ${end.year}';
    }
    return '${start.day} ${mon[start.month - 1]} – '
        '${end.day} ${mon[end.month - 1]} ${end.year}';
  }

  Widget _dualBarChart(
    List<({DateTime day, num amount})> cur,
    List<({DateTime day, num amount})> prev,
    num maxVal,
  ) {
    final upper = (maxVal * 1.2).toDouble();
    return LayoutBuilder(
      builder: (context, c) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: _dayPair(
                  dayName: _dayName(i),
                  cur: cur.length > i ? cur[i].amount : 0,
                  prev: prev.length > i ? prev[i].amount : 0,
                  upper: upper,
                ),
              ),
          ],
        );
      },
    );
  }

  String _dayName(int i) {
    const names = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return names[i];
  }

  Widget _dayPair({
    required String dayName,
    required num cur,
    required num prev,
    required double upper,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          height: 120,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: (120 * (cur / upper)).clamp(2, 120),
                    decoration: const BoxDecoration(
                      color: AppTheme.ink,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: (120 * (prev / upper)).clamp(2, 120),
                    decoration: BoxDecoration(
                      color: AppTheme.accent,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          dayName,
          style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppTheme.inkSoft),
        ),
      ],
    );
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
