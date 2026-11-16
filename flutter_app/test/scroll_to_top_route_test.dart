import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitv/src/scroll_to_top.dart';

void main() {
  testWidgets('scroll target never leaks into player or short route', (
    tester,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        navigatorObservers: [ScrollToTopNavigatorObserver()],
        builder: (_, child) => ScrollToTopOverlay(child: child!),
        home: Scaffold(
          body: ListView.builder(
            controller: controller,
            itemCount: 80,
            itemExtent: 60,
            itemBuilder: (_, index) => Text('row $index'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('الرجوع للأعلى'), findsNothing);
    controller.jumpTo(900);
    await tester.pumpAndSettle();
    expect(find.byTooltip('الرجوع للأعلى'), findsOneWidget);
    navigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Center(child: Text('player'))),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('player'), findsOneWidget);
    expect(find.byTooltip('الرجوع للأعلى'), findsNothing);
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    // Navigation must not resurrect a stale target before a new scroll event.
    expect(find.byTooltip('الرجوع للأعلى'), findsNothing);
    controller.jumpTo(1000);
    await tester.pumpAndSettle();
    expect(find.byTooltip('الرجوع للأعلى'), findsOneWidget);
    await tester.tap(find.byTooltip('الرجوع للأعلى'));
    await tester.pumpAndSettle();
    expect(controller.offset, 0);
    expect(find.byTooltip('الرجوع للأعلى'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
