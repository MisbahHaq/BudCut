import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'screens/category_manager_screen.dart';
import 'screens/custom_range_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/monthly_screen.dart';
import 'screens/quarterly_screen.dart';
import 'screens/recurring_bills_screen.dart';
import 'screens/true_expense_screen.dart';
import 'screens/weekly_screen.dart';
import 'services/app_state.dart';
import 'theme.dart';
import 'widgets/bento.dart';
import 'widgets/modals.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final appState = Future(() async => await AppState.create());
  runApp(BudCutApp(appState: appState));
}

class BudCutApp extends StatelessWidget {
  final Future<AppState> appState;

  const BudCutApp({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BudCut',
      theme: AppTheme.light(),
      home: FutureBuilder<AppState>(
        future: appState,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const _Splash();
          }
          final state = snap.data!;
          return ChangeNotifierProvider<AppState>.value(
            value: state,
            child: const _AuthGate(),
          );
        },
      ),
    );
  }
}

/// Signs the user in first; the app shell is only shown when authenticated.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _Splash();
        }
        final user = snap.data;
        if (user == null) {
          return const LoginScreen();
        }
        return const _Shell();
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: AppTheme.yellow,
                border: AppTheme.border2(),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'BUDCUT',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: AppTheme.ink,
              ),
            ),
            const SizedBox(height: 12),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppTheme.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _tabs = [
  (icon: Icons.grid_view_outlined, label: 'Dashboard'),
  (icon: Icons.calendar_view_week_outlined, label: 'Weekly'),
  (icon: Icons.calendar_month_outlined, label: 'Monthly'),
  (icon: Icons.insights_outlined, label: 'Quarterly'),
  (icon: Icons.date_range_outlined, label: 'Custom'),
  (icon: Icons.balance_outlined, label: 'True Exp'),
  (icon: Icons.repeat_outlined, label: 'Recurring'),
  (icon: Icons.tune_outlined, label: 'Categories'),
];

class _Shell extends StatefulWidget {
  const _Shell();

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppTheme.canvas,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              onQuickAdd: () => openQuickAddModal(context, state),
            ),
            _TabStrip(
              index: _index,
              onChanged: (i) => setState(() => _index = i),
            ),
            Expanded(
              child: IndexedStack(
                index: _index,
                children: [
                  DashboardScreen(state: state),
                  WeeklyScreen(state: state),
                  MonthlyScreen(state: state),
                  QuarterlyScreen(state: state),
                  CustomRangeScreen(state: state),
                  TrueExpenseScreen(state: state),
                  RecurringBillsScreen(state: state),
                  CategoryManagerScreen(state: state),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onQuickAdd;

  const _TopBar({required this.onQuickAdd});

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 560;

    return Container(
      padding: const EdgeInsets.fromLTRB(4, 6, 12, 6),
      decoration: const BoxDecoration(
        color: AppTheme.canvas,
        border: Border(bottom: BorderSide(color: AppTheme.ink, width: 2)),
      ),
      child: Row(
        children: [
          if (isNarrow)
            const _MiniBrand()
          else
            const BrandBadge(),
          const Spacer(),
          if (isNarrow)
            SizedBox(
              width: 48,
              height: 48,
              child: BrutIconButton(
                icon: Icons.add,
                color: AppTheme.yellow,
                tooltip: 'Quick Add',
                onTap: onQuickAdd,
              ),
            )
          else
            BrutButton(
              label: 'Quick Add',
              icon: Icons.add,
              color: AppTheme.yellow,
              onPressed: onQuickAdd,
            ),
        ],
      ),
    );
  }
}

/// Compact logo block used when the top bar is too narrow for the full badge.
class _MiniBrand extends StatelessWidget {
  const _MiniBrand();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.ink,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: AppTheme.border2(),
        boxShadow: [AppTheme.hardShadow(offset: 2)],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 10,
            height: 10,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppTheme.yellow,
                border: Border.fromBorderSide(
                  BorderSide(color: AppTheme.ink, width: 1),
                ),
              ),
            ),
          ),
          SizedBox(width: 7),
          Text(
            'BUDCUT',
            style: TextStyle(
              color: AppTheme.white,
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabStrip extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;

  const _TabStrip({required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      color: AppTheme.canvas,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < _tabs.length; i++)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _Tab(
                  icon: _tabs[i].icon,
                  label: _tabs[i].label,
                  selected: i == index,
                  onTap: () => onChanged(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Tab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_Tab> createState() => _TabState();
}

class _TabState extends State<_Tab> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        padding: EdgeInsets.only(right: _down ? 1 : 3, bottom: _down ? 1 : 3),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: widget.selected ? AppTheme.ink : AppTheme.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            border: AppTheme.border2(),
            boxShadow: _down ? null : [AppTheme.hardShadow(offset: 2)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 15,
                color: widget.selected ? AppTheme.yellow : AppTheme.ink,
              ),
              const SizedBox(width: 7),
              Text(
                widget.label.toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 0.4,
                  color: widget.selected ? AppTheme.white : AppTheme.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}