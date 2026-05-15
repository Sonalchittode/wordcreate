import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../models/word_detail.dart';
import 'detail_line.dart';

class WordDetailCard extends StatelessWidget {
  const WordDetailCard({
    super.key,
    required this.detail,
    required this.onSpeak,
  });

  final WordDetail detail;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.wordCard,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  detail.word,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF27323A),
                  ),
                ),
              ),
              IconButton(
                onPressed: onSpeak,
                icon: const Icon(Icons.volume_up, color: Color(0xFF4F5961)),
                tooltip: 'Listen',
              ),
            ],
          ),
          DetailLine(label: 'Hindi Meaning', value: detail.hindiMeaning),
          DetailLine(label: 'Synonyms', value: detail.synonyms.join(', ')),
          DetailLine(label: 'Antonyms', value: detail.antonyms.join(', ')),
          DetailLine(label: 'Word Forms', value: detail.wordForms.join(', ')),
          DetailLine(label: 'Explanation', value: detail.explanation),
        ],
      ),
    );
  }
}
