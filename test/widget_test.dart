import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:serializer_demo_prjoct1/main.dart';

void main() {
  testWidgets('app renders main serializer UI and toggles theme', (tester) async {
    await tester.pumpWidget(const SerializerApp());

    expect(find.text('Serializer'), findsOneWidget);
    expect(find.text('Serialize'), findsOneWidget);
    expect(find.text('Name prefix'), findsOneWidget);
    expect(find.byIcon(Icons.dark_mode), findsOneWidget);

    await tester.tap(find.byIcon(Icons.dark_mode));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.light_mode), findsOneWidget);
  });

  testWidgets('history screen exposes export/import controls and detail view', (tester) async {
    final result = BatchResult(
      id: 'demo-1',
      createdAt: DateTime(2026, 9, 7, 12, 0),
      success: true,
      title: 'Serialization succeeded',
      summary: 'Processed 1 item successfully.',
      logs: const ['Batch ready'],
      selectedPaths: const ['/tmp/demo.txt'],
      itemsProcessed: 1,
      totalItems: 1,
      itemResults: const [
        BatchItemOutcome(
          path: '/tmp/demo.txt',
          status: 'success',
          summary: 'Renamed to serial_1.txt',
          newName: 'serial_1.txt',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ResultsHistoryScreen(
          history: [result],
          onHistoryChanged: (_) {},
        ),
      ),
    );

    expect(find.text('Results history'), findsOneWidget);
    expect(find.text('Export history'), findsOneWidget);
    expect(find.text('Import history'), findsOneWidget);

    await tester.tap(find.text('View details'));
    await tester.pumpAndSettle();

    expect(find.text('/tmp/demo.txt'), findsOneWidget);
    expect(find.text('Renamed to serial_1.txt'), findsOneWidget);
  });
}
