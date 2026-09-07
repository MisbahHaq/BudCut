import 'package:flutter/material.dart';

import '../models/recurring_bill.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/bento.dart';
import '../widgets/progress.dart';

class RecurringBillsScreen extends StatefulWidget {
  final AppState state;

  const RecurringBillsScreen({super.key, required this.state});

  @override
  State<RecurringBillsScreen> createState() => _RecurringBillsScreenState();
}

class _RecurringBillsScreenState extends State<RecurringBillsScreen> {
  bool _syncing = false;

  Future<void> _sync() async {
    setState(() => _syncing = true);
    final logged = await widget.state.syncDueBills(DateTime.now());
    if (!mounted) return;
    setState(() => _syncing = false);
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          logged == 0
              ? 'All due bills are already logged'
              : 'Auto-logged $logged due bill${logged == 1 ? '' : 's'}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final active = state.bills.where((b) => b.isActive).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
      children: [
        const ScreenHeader(
          title: 'Recurring Bills',
          subtitle: 'Fixed obligations across the month',
        ),
        const SizedBox(height: 16),
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
              const TileLabel('Total committed monthly liability'),
              const SizedBox(height: 8),
              KpiValue(state.formatValue(state.totalMonthlyLiability),
                  size: 28),
              const SizedBox(height: 6),
              Text(
                'Across ${active.length} active bill${active.length == 1 ? '' : 's'}',
                style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.inkSoft,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: BrutalistButton(
                  label: _syncing
                      ? 'Checking...'
                      : 'Auto-log due items',
                  onPressed: _syncing ? () {} : _sync,
                  color: AppTheme.inkSoft,
                  icon: _syncing ? null : Icons.sync,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        for (final bill in state.bills) _billCard(context, bill),
        const SizedBox(height: 12),
        Material(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          child: InkWell(
            onTap: () => _openBillEditor(context, null),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                border: Border.all(
                    color: AppTheme.ink, width: AppTheme.borderWidth),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, size: 18, color: AppTheme.ink),
                  SizedBox(width: 6),
                  Text('ADD RECURRING BILL',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: AppTheme.ink,
                          letterSpacing: 0.5)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 90),
      ],
    );
  }

  Widget _billCard(BuildContext context, RecurringBill bill) {
    final cat = widget.state.categoryById(bill.categoryId);
    final monthStart = DateTime(DateTime.now().year, DateTime.now().month, 1);
    final monthEnd = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);
    final billedThisMonth = widget.state
        .inRange(monthStart, monthEnd)
        .where((t) => t.isRecurring && t.amount == bill.amount)
        .isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ColorDot(cat?.color ?? '#999999', size: 10),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  bill.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, color: AppTheme.ink),
                ),
              ),
              Material(
                color: bill.isActive ? AppTheme.mint : AppTheme.surfaceAlt,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                child: InkWell(
                  onTap: () {
                    final updated = bill.copyWith(isActive: !bill.isActive);
                    widget.state.updateBill(updated);
                  },
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusSm),
                      border: Border.all(
                          color: AppTheme.ink, width: AppTheme.borderWidth),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          bill.isActive ? Icons.pause : Icons.play_arrow,
                          size: 14,
                          color: AppTheme.ink,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          bill.isActive ? 'ACTIVE' : 'PAUSED',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: AppTheme.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _MiniBtn(
                icon: Icons.edit_outlined,
                onTap: () => _openBillEditor(context, bill),
              ),
              const SizedBox(width: 4),
              _MiniBtn(
                icon: Icons.delete_outline,
                color: AppTheme.negative,
                onTap: () => _confirmDelete(context, bill),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            widget.state.formatValue(bill.amount),
            style: const TextStyle(
              fontFamily: AppTheme.mono,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${bill.frequencyLabel} · billed on day ${bill.billingDay} of the month',
            style: const TextStyle(
                fontSize: 12,
                color: AppTheme.inkSoft,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: billedThisMonth
                      ? AppTheme.mint
                      : AppTheme.coral,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  border: Border.all(
                      color: AppTheme.ink, width: AppTheme.borderWidth),
                ),
                child: Text(
                  billedThisMonth ? '✓ LOGGED' : 'DUE SOON',
                  style: const TextStyle(
                    fontSize: 10,
                    fontFamily: AppTheme.mono,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.ink,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, RecurringBill bill) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('DELETE BILL?',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1)),
              const SizedBox(height: 8),
              Text(
                'Delete recurring bill "${bill.name}"?',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx, false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceAlt,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSm),
                          border: Border.all(
                              color: AppTheme.ink,
                              width: AppTheme.borderWidth),
                        ),
                        child: const Center(
                          child: Text('CANCEL',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx, true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.negative,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSm),
                          border: Border.all(
                              color: AppTheme.ink,
                              width: AppTheme.borderWidth),
                        ),
                        child: const Center(
                          child: Text('DELETE',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (ok == true) {
      await widget.state.deleteBill(bill.id);
    }
  }

  void _openBillEditor(BuildContext context, RecurringBill? bill) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        side: BorderSide(color: AppTheme.ink, width: AppTheme.borderWidth),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: _BillEditor(state: widget.state, bill: bill),
      ),
    );
  }
}

class _BillEditor extends StatefulWidget {
  final AppState state;
  final RecurringBill? bill;

  const _BillEditor({required this.state, this.bill});

  @override
  State<_BillEditor> createState() => _BillEditorState();
}

class _BillEditorState extends State<_BillEditor> {
  late final TextEditingController _name;
  late final TextEditingController _amount;
  BillFrequency _frequency = BillFrequency.monthly;
  int _billingDay = 1;
  String? _categoryId;
  bool _active = true;

  @override
  void initState() {
    super.initState();
    final b = widget.bill;
    _name = TextEditingController(text: b?.name ?? '');
    _amount = TextEditingController(text: b != null ? '${b.amount}' : '');
    _frequency = b?.frequency ?? BillFrequency.monthly;
    _billingDay = b?.billingDay ?? 1;
    _categoryId = b?.categoryId;
    _active = b?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _save() {
    final amt = num.tryParse(_amount.text.replaceAll(',', ''));
    if (amt == null ||
        amt <= 0 ||
        _name.text.trim().isEmpty ||
        _categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill name, amount and category')),
      );
      return;
    }
    if (widget.bill != null) {
      widget.state.updateBill(widget.bill!.copyWith(
        name: _name.text.trim(),
        amount: amt,
        frequency: _frequency,
        billingDay: _billingDay,
        categoryId: _categoryId,
        isActive: _active,
      ));
    } else {
      widget.state.addBill(RecurringBill(
        id: 'bill-${DateTime.now().microsecondsSinceEpoch}',
        name: _name.text.trim(),
        amount: amt,
        frequency: _frequency,
        billingDay: _billingDay,
        categoryId: _categoryId!,
        isActive: _active,
      ));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.bill == null
                ? 'NEW RECURRING BILL'
                : 'EDIT RECURRING BILL',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppTheme.ink,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          _field(_name, 'Bill name', Icons.receipt_outlined, digits: false),
          const SizedBox(height: 12),
          _field(_amount, 'Amount per billing', Icons.attach_money,
              digits: true),
          const SizedBox(height: 12),
          const Text('FREQUENCY',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  color: AppTheme.inkSoft)),
          const SizedBox(height: 6),
          _dropdownContainer(DropdownButton<BillFrequency>(
            value: _frequency,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            items: [
              for (final f in BillFrequency.values)
                DropdownMenuItem(value: f, child: Text(f.label)),
            ],
            onChanged: (v) =>
                setState(() => _frequency = v ?? BillFrequency.monthly),
          )),
          const SizedBox(height: 12),
          const Text('BILLING DAY OF MONTH',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  color: AppTheme.inkSoft)),
          const SizedBox(height: 6),
          _dropdownContainer(DropdownButton<int>(
            value: _billingDay,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            items: [
              for (var d = 1; d <= 28; d++)
                DropdownMenuItem(value: d, child: Text('Day $d')),
            ],
            onChanged: (v) => setState(() => _billingDay = v ?? 1),
          )),
          const SizedBox(height: 12),
          const Text('CATEGORY',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  color: AppTheme.inkSoft)),
          const SizedBox(height: 6),
          _dropdownContainer(DropdownButton<String>(
            value: _categoryId,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            hint: const Text('Pick category',
                style: TextStyle(color: AppTheme.inkSoft)),
            items: [
              for (final c in widget.state.categories)
                if (c.isFixed)
                  DropdownMenuItem(value: c.id, child: Text(c.name)),
            ],
            onChanged: (v) => setState(() => _categoryId = v),
          )),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(
                  child: Text('ACTIVE',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.ink))),
              Switch(
                value: _active,
                activeTrackColor: AppTheme.accent,
                onChanged: (v) => setState(() => _active = v),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: BrutalistButton(
              label: widget.bill == null ? 'Add Bill' : 'Save Changes',
              onPressed: _save,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdownContainer(Widget child) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border:
            Border.all(color: AppTheme.ink, width: AppTheme.borderWidth),
      ),
      child: child,
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon,
      {required bool digits}) {
    return TextField(
      controller: ctrl,
      keyboardType: digits ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          borderSide:
              const BorderSide(color: AppTheme.ink, width: AppTheme.borderWidth),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          borderSide:
              const BorderSide(color: AppTheme.ink, width: AppTheme.borderWidth),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          borderSide:
              const BorderSide(color: AppTheme.ink, width: AppTheme.borderWidth),
        ),
      ),
    );
  }
}

class _MiniBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _MiniBtn({
    required this.icon,
    required this.onTap,
    this.color = AppTheme.inkSoft,
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
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            border: Border.all(color: AppTheme.ink, width: 1.5),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}
