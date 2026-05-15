import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wordcreate/main.dart';

void main() {
  testWidgets('Story generator screen renders core controls', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Story Generator'), findsOneWidget);
    expect(find.text('Enter Words'), findsOneWidget);
    expect(find.text('Story Theme'), findsOneWidget);
    expect(find.text('Story Size'), findsOneWidget);
    expect(find.text('Story Difficulty'), findsOneWidget);
    expect(find.text('Generate Story'), findsOneWidget);
  });

  testWidgets('Shows validation when more than five words are entered', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await tester.enterText(
      find.byType(EditableText),
      'one, two, three, four, five, six',
    );
    await tester.pump();

    expect(
      find.text('Enter only 5 words, separated by commas.'),
      findsOneWidget,
    );
  });
}
