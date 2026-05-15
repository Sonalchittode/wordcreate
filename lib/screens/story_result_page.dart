import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../core/app_colors.dart';
import '../models/generated_story.dart';
import '../widgets/practice_field.dart';
import '../widgets/section_title.dart';
import '../widgets/story_card.dart';
import '../widgets/summary_card.dart';
import '../widgets/word_detail_card.dart';

class StoryResultPage extends StatefulWidget {
  const StoryResultPage({super.key, required this.result});

  final GeneratedStory result;

  @override
  State<StoryResultPage> createState() => _StoryResultPageState();
}

class _StoryResultPageState extends State<StoryResultPage> {
  final _tts = FlutterTts();
  final _sentenceOneController = TextEditingController();
  final _sentenceTwoController = TextEditingController();

  @override
  void dispose() {
    _tts.stop();
    _sentenceOneController.dispose();
    _sentenceTwoController.dispose();
    super.dispose();
  }

  Future<void> _speak(String text) async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    await _tts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.resultAppBar,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        title: const Text(
          'Your Story',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          children: [
            const SectionTitle('Word Details'),
            const SizedBox(height: 10),
            for (final detail in widget.result.wordDetails) ...[
              WordDetailCard(
                detail: detail,
                onSpeak: () => _speak(detail.word),
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 12),
            const SectionTitle('Story'),
            const SizedBox(height: 10),
            StoryCard(
              story: widget.result.story,
              words: widget.result.wordDetails.map((detail) => detail.word),
            ),
            const SizedBox(height: 20),
            const SectionTitle('Summary'),
            const SizedBox(height: 10),
            SummaryCard(summary: widget.result.summary),
            const SizedBox(height: 22),
            const SectionTitle('Practice Your Sentences'),
            const SizedBox(height: 10),
            PracticeField(
              controller: _sentenceOneController,
              hintText: 'Sentence 1',
            ),
            const SizedBox(height: 10),
            PracticeField(
              controller: _sentenceTwoController,
              hintText: 'Sentence 2',
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 46,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF242424),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text(
                  'Check Sentences',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
