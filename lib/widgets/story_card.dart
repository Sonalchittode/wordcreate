import 'package:flutter/material.dart';

import '../core/app_colors.dart';

class StoryCard extends StatelessWidget {
  const StoryCard({super.key, required this.story, required this.words});

  final String story;
  final Iterable<String> words;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.storyCard,
        borderRadius: BorderRadius.circular(9),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            height: 1.45,
          ),
          children: _storySpans(story, words),
        ),
      ),
    );
  }

  List<TextSpan> _storySpans(String story, Iterable<String> words) {
    if (story.contains('**')) {
      return _markdownBoldSpans(story);
    }

    final cleanWords = words
        .map((word) => word.trim())
        .where((word) => word.isNotEmpty)
        .toList();
    if (cleanWords.isEmpty || story.isEmpty) {
      return [TextSpan(text: story)];
    }

    final pattern = cleanWords.map(RegExp.escape).join('|');
    final regex = RegExp(r'\b(' + pattern + r')\w*\b', caseSensitive: false);
    final spans = <TextSpan>[];
    var cursor = 0;

    for (final match in regex.allMatches(story)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: story.substring(cursor, match.start)));
      }
      spans.add(
        TextSpan(
          text: story.substring(match.start, match.end),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      );
      cursor = match.end;
    }

    if (cursor < story.length) {
      spans.add(TextSpan(text: story.substring(cursor)));
    }

    return spans;
  }

  List<TextSpan> _markdownBoldSpans(String story) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*(.+?)\*\*');
    var cursor = 0;

    for (final match in regex.allMatches(story)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: story.substring(cursor, match.start)));
      }
      spans.add(
        TextSpan(
          text: match.group(1),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      );
      cursor = match.end;
    }

    if (cursor < story.length) {
      spans.add(TextSpan(text: story.substring(cursor)));
    }

    return spans;
  }
}
