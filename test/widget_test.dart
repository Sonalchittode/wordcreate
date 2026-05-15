import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wordcreate/main.dart';

void main() {
  test('Parses AI word_data response format', () {
    final result = GeneratedStory.fromJsonText(
      '''
{
  "story": "The **brave** child stayed **strong**.",
  "summary": "A child shows courage.",
  "word_data": {
    "brave": {
      "meaning": "Ready to face danger",
      "hindi": "bahadur",
      "synonyms": "courageous, bold",
      "antonyms": "fearful, timid",
      "forms": "brave, braver, bravest",
      "explanation": "Use brave for someone who faces fear."
    }
  }
}
''',
      fallbackWords: ['brave'],
    );

    expect(result.story, contains('**brave**'));
    expect(result.wordDetails.first.word, 'brave');
    expect(result.wordDetails.first.hindiMeaning, 'bahadur');
    expect(result.wordDetails.first.synonyms, ['courageous', 'bold']);
    expect(result.wordDetails.first.wordForms, ['brave', 'braver', 'bravest']);
  });

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

  testWidgets('Story result screen renders details and practice fields', (
    WidgetTester tester,
  ) async {
    const result = GeneratedStory(
      wordDetails: [
        WordDetail(
          word: 'brave',
          hindiMeaning: 'bahadur',
          synonyms: ['courageous', 'fearless'],
          antonyms: ['fearful'],
          wordForms: ['brave', 'braver', 'bravest'],
          explanation: 'Showing no fear in difficult situations.',
        ),
      ],
      story: 'A brave child helped everyone.',
      summary: 'A child learns courage.',
    );

    await tester.pumpWidget(
      const MaterialApp(home: StoryResultPage(result: result)),
    );

    expect(find.text('Your Story'), findsOneWidget);
    expect(find.text('Word Details'), findsOneWidget);
    expect(find.text('Story'), findsOneWidget);
    expect(find.text('Summary'), findsOneWidget);
    expect(find.text('Practice Your Sentences'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Check Sentences'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Check Sentences'), findsOneWidget);
  });
}
