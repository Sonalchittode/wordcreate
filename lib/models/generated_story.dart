import 'dart:convert';

import 'word_detail.dart';

class GeneratedStory {
  const GeneratedStory({
    required this.wordDetails,
    required this.story,
    required this.summary,
  });

  final List<WordDetail> wordDetails;
  final String story;
  final String summary;

  factory GeneratedStory.fromJsonText(
    String text, {
    required List<String> fallbackWords,
  }) {
    final cleanText = text
        .replaceAll(RegExp(r'^```json\s*', multiLine: true), '')
        .replaceAll(RegExp(r'^```\s*', multiLine: true), '')
        .replaceAll(RegExp(r'\s*```$'), '')
        .trim();
    final decoded = jsonDecode(cleanText) as Map<String, dynamic>;
    final details = _readWordDetails(decoded, fallbackWords);

    return GeneratedStory(
      wordDetails: details.isEmpty
          ? fallbackWords.map(WordDetail.basic).toList()
          : details,
      story: decoded['story'] as String? ?? '',
      summary: decoded['summary'] as String? ?? '',
    );
  }

  static List<WordDetail> _readWordDetails(
    Map<String, dynamic> decoded,
    List<String> fallbackWords,
  ) {
    final wordDetails = decoded['wordDetails'];
    if (wordDetails is List<dynamic>) {
      return wordDetails
          .whereType<Map<String, dynamic>>()
          .map(WordDetail.fromJson)
          .toList();
    }

    final wordData = decoded['word_data'];
    if (wordData is Map<String, dynamic>) {
      return fallbackWords.map((word) {
        final data = wordData[word];
        if (data is Map<String, dynamic>) {
          return WordDetail.fromWordData(word, data);
        }
        return WordDetail.basic(word);
      }).toList();
    }

    return const [];
  }
}
