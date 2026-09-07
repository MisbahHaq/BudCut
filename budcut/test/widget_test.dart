import 'dart:async';

import 'package:budcut/main.dart';
import 'package:budcut/services/app_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BudCut renders splash while state loads', (tester) async {
    Future<AppState> never() => Completer<AppState>().future;
    await tester.pumpWidget(BudCutApp(appState: never()));
    expect(find.text('BUDCUT'), findsOneWidget);
  });
}