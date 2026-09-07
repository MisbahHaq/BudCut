import 'package:flutter/material.dart';

import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/bento.dart';
import '../widgets/charts.dart';
import '../widgets/transaction_list.dart';

class CustomRangeScreen extends StatefulWidget {
  final AppState state;

  const CustomRangeScreen({super.key, required this.state});

  @override
  State<CustomRangeScreen> createState() => _CustomRangeScreenState();
}

class _CustomRangeScreenState extends State<CustomRangeScreen> {
  late DateTime _start;
  late DateTime _end;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _end = now;
    _start = now.subtract(const Duration(days: 29));
  }

  void _preset(int days) {
    final now = DateTime.now();
    setState(() {
      _end = now;
      _start = now.subtract(Duration(days: days - 1));
    });
  }

  Future<void> _pickStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'Start Date',
    );
    if (picked != null) {
      setState(() {
        _start = picked;
        if (_start.isAfter(_end)) _end = _start;
      });
    }
  }

  Future<void> _pickEnd() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _end,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'End Date',
    );
    if (picked != null) setState(() => _end = picked);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final tx = state.inRange(_start, _end);
    final total = tx.fold<num>(0, (s, t) => s + t.amount);
    final days = _end.difference(_start).inDays + 1;
    final avg = days > 0 ? total / days : 0.0;
    final daily = state.dailySpend(_start, _end);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
      children: [
        const ScreenHeader(
          title: 'Custom Range',
          subtitle: 'Analyze any period you choose',
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _PresetChip('7 DAYS', () => _preset(7)),
            const SizedBox(width: 8),
            _PresetChip('30 DAYS', () => _preset(30)),
            const SizedBox(width: 8),
            _PresetChip('90 DAYS', () => _preset(90)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _DateField(
                label: 'Start',
                date: _start,
                onTap: _pickStart,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('→',
                  style: TextStyle(
                      fontFamily: AppTheme.mono,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.ink)),
            ),
            Expanded(
              child: _DateField(
                label: 'End',
                date: _end,
                onTap: _pickEnd,
              ),
            ),
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
                    const TileLabel('Total spend'),
                    const SizedBox(height: 6),
                    KpiValue(state.formatValue(total), size: 18),
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
                    const TileLabel('Daily avg'),
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
          child: Row(
            children: [
              const TileLabel('Transaction count'),
              const Spacer(),
              KpiValue('${tx.length}', size: 20),
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
              const TileLabel('Daily spending'),
              const SizedBox(height: 14),
              if (daily.length > 1 && total > 0)
                DailyBarChart(
                  data: daily,
                  maxLabels: days <= 7
                      ? 7
                      : days <= 30
                          ? 10
                          : 12,
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
              Text(
                'TRANSACTIONS (${tx.length})',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.ink,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              TransactionList(state: state, fixedList: tx),
            ],
          ),
        ),
        const SizedBox(height: 90),
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PresetChip(this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            border:
                Border.all(color: AppTheme.ink, width: AppTheme.borderWidth),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: AppTheme.mono,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppTheme.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            border:
                Border.all(color: AppTheme.ink, width: AppTheme.borderWidth),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  color: AppTheme.inkSoft,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${date.day}/${date.month}/${date.year}',
                style: const TextStyle(
                  fontFamily: AppTheme.mono,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
