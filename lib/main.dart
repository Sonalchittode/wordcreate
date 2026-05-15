import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Story Generator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF152434)),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: const StoryGeneratorPage(),
    );
  }
}

class StoryGeneratorPage extends StatefulWidget {
  const StoryGeneratorPage({super.key});

  @override
  State<StoryGeneratorPage> createState() => _StoryGeneratorPageState();
}

class _StoryGeneratorPageState extends State<StoryGeneratorPage> {
  static const _navy = Color(0xFF152434);
  static const _inputFill = Color(0xFFE5EDF5);
  static const _buttonBlue = Color(0xFF73A4BD);

  final _wordsController = TextEditingController();

  String _theme = 'Auto';
  String _size = 'Auto';
  String _difficulty = 'Beginner';
  String? _error;
  bool _isGenerating = false;

  final List<String> _themes = const [
    'Auto',
    'Adventure',
    'Funny',
    'Mystery',
    'Fantasy',
    'School',
    'Friendship',
  ];

  final List<String> _sizes = const ['Auto', 'Small', 'Medium', 'Large'];

  @override
  void initState() {
    super.initState();
    _wordsController.addListener(_validateWords);
  }

  @override
  void dispose() {
    _wordsController.dispose();
    super.dispose();
  }

  List<String> get _enteredWords => _wordsController.text
      .split(',')
      .map((word) => word.trim())
      .where((word) => word.isNotEmpty)
      .toList();

  void _validateWords() {
    final nextError = _enteredWords.length > 5
        ? 'Enter only 5 words, separated by commas.'
        : null;

    if (_error != nextError) {
      setState(() => _error = nextError);
    }
  }

  Future<void> _generateStory() async {
    final words = _enteredWords;
    if (words.isEmpty) {
      setState(() => _error = 'Enter at least one word.');
      return;
    }

    if (words.length > 5) {
      setState(() => _error = 'Enter only 5 words, separated by commas.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isGenerating = true;
      _error = null;
    });

    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw StoryGenerationException('Missing GEMINI_API_KEY in .env.');
      }

      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
      final response = await model.generateContent([
        Content.text(_buildPrompt(words)),
      ]);
      final text = response.text?.trim();

      if (text == null || text.isEmpty) {
        throw StoryGenerationException('The AI did not return a story.');
      }

      final result = GeneratedStory.fromJsonText(text, fallbackWords: words);
      if (!mounted) {
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => StoryResultPage(result: result),
        ),
      );
    } catch (_) {
      setState(() => _error = 'Could not generate story. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  String _buildPrompt(List<String> words) {
    final activeDifficulty = _difficulty;
    final activeTheme = _theme == 'Auto'
        ? 'a realistic everyday moment'
        : _theme;
    final activeSize = switch (_size) {
      'Small' => 'Short',
      'Large' => 'Long',
      'Medium' => 'Medium',
      _ => 'Short',
    };

    final difficultyInstruction = switch (activeDifficulty) {
      'Beginner' => 'Use simple, short sentences and everyday common language.',
      'Intermediate' =>
        'Use descriptive adjectives, varied sentence structures, and common idioms.',
      _ =>
        'Use complex prose, advanced vocabulary, and sophisticated narrative metaphors.',
    };

    final sizeInstruction = switch (activeSize) {
      'Short' =>
        'Target 80-120 words. If the number of target words is high, you may expand slightly to ensure the story remains natural and realistic.',
      'Medium' => 'Target 120-150 words.',
      _ => 'Target 150-200 words.',
    };

    final wordDataTemplate = words
        .map(
          (word) =>
              '''
         "$word": {
            "meaning": "Clear English definition",
            "hindi": "Hindi meaning",
            "synonyms": "comma, separated, synonyms",
            "antonyms": "comma, separated, antonyms",
            "forms": "List the forms used in the story (e.g., running, ran)",
            "explanation": "A simple 1-sentence tip on how to use this word naturally"
         }''',
        )
        .join(', ');

    return '''
Role: Expert Narrative Linguist.
Task: Write a natural, realistic $activeSize story about '$activeTheme' at a $activeDifficulty level.

Length: $sizeInstruction
Level Context: $difficultyInstruction
Target Words: ${words.join(', ')}

CRITICAL INSTRUCTION FOR SHORT STORIES:
If the target words make the story feel "forced" or like a list because the length is too short,
automatically increase the length just enough to maintain a high-quality, realistic narrative flow.
The goal is a natural story, not a vocabulary list.

CORE RULES:
1. NATURAL REPETITION: Repeat each target word multiple times throughout the story. The repetition must feel like a natural part of a real story, not a word list.
2. WORD FORMS: Use different forms of the words (e.g., if the word is 'go', use 'go', 'went', 'gone') to show how they are used in real life.
3. SHOW MEANING: The context of the story should clearly explain what the words mean without defining them explicitly.
4. HIGHLIGHT: Bold every instance of the target words or their variations using **double asterisks**.
5. QUALITY: The story must be interesting and professional.
6. Don't forcefully use words in every sentence.

OUTPUT FORMAT:
Return ONLY a valid JSON object. Do not include markdown code blocks.
{
  "story": "The full narrative text with **bolded** words...",
  "summary": "A concise one-sentence plot summary.",
  "word_data": {
     $wordDataTemplate
  }
}
''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {},
          tooltip: 'Menu',
        ),
        title: const Text(
          'Story Generator',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
          children: [
            const Text(
              'Enter Words',
              style: TextStyle(
                color: Color(0xFF111820),
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _wordsController,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z,\s-]')),
              ],
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'preserver, pilgrimage, essence',
                filled: true,
                fillColor: _inputFill,
                errorText: _error,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 26),
            _SettingRow(
              label: 'Story Theme',
              child: _DropdownPill(
                value: _theme,
                items: _themes,
                onChanged: (value) => setState(() => _theme = value),
              ),
            ),
            const SizedBox(height: 16),
            _SettingRow(
              label: 'Story Size',
              child: _DropdownPill(
                value: _size,
                items: _sizes,
                onChanged: (value) => setState(() => _size = value),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Story Difficulty',
              style: TextStyle(
                color: Color(0xFF111820),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DifficultyButton(
                    label: 'Beginner',
                    selected: _difficulty == 'Beginner',
                    locked: false,
                    onTap: () => setState(() => _difficulty = 'Beginner'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DifficultyButton(
                    label: 'Intermediate',
                    selected: false,
                    locked: true,
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DifficultyButton(
                    label: 'Advanced',
                    selected: false,
                    locked: true,
                    onTap: () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            Row(
              children: const [
                Text(
                  'Word Repeat',
                  style: TextStyle(fontSize: 16, color: Color(0xFF2A2F35)),
                ),
                SizedBox(width: 6),
                Icon(Icons.lock, size: 16, color: Color(0xFF7890A2)),
                SizedBox(width: 4),
                Text(
                  '(Premium)',
                  style: TextStyle(fontSize: 13, color: Color(0xFF8B9BA7)),
                ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                disabledActiveTrackColor: const Color(0xFFE2E2E2),
                disabledInactiveTrackColor: const Color(0xFFE2E2E2),
                disabledThumbColor: const Color(0xFF98A0AD),
                trackHeight: 3,
              ),
              child: const Slider(
                value: 0,
                min: 0,
                max: 3,
                divisions: 3,
                onChanged: null,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isGenerating ? null : _generateStory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _buttonBlue,
                  disabledBackgroundColor: _buttonBlue.withValues(alpha: 0.55),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 2,
                ),
                child: _isGenerating
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Generate Story',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: Colors.black,
        unselectedItemColor: const Color(0xFFA4A4A4),
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome),
            label: 'Generate',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books_outlined),
            label: 'Store',
          ),
        ],
      ),
    );
  }
}

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
        backgroundColor: const Color(0xFFD7D7D7),
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
            const _SectionTitle('Word Details'),
            const SizedBox(height: 10),
            for (final detail in widget.result.wordDetails) ...[
              _WordDetailCard(
                detail: detail,
                onSpeak: () => _speak(detail.word),
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 12),
            const _SectionTitle('Story'),
            const SizedBox(height: 10),
            _StoryCard(
              story: widget.result.story,
              words: widget.result.wordDetails.map((detail) => detail.word),
            ),
            const SizedBox(height: 20),
            const _SectionTitle('Summary'),
            const SizedBox(height: 10),
            _SummaryCard(summary: widget.result.summary),
            const SizedBox(height: 22),
            const _SectionTitle('Practice Your Sentences'),
            const SizedBox(height: 10),
            _PracticeField(
              controller: _sentenceOneController,
              hintText: 'Sentence 1',
            ),
            const SizedBox(height: 10),
            _PracticeField(
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

class WordDetail {
  const WordDetail({
    required this.word,
    required this.hindiMeaning,
    required this.synonyms,
    required this.antonyms,
    required this.wordForms,
    required this.explanation,
  });

  final String word;
  final String hindiMeaning;
  final List<String> synonyms;
  final List<String> antonyms;
  final List<String> wordForms;
  final String explanation;

  factory WordDetail.fromJson(Map<String, dynamic> json) {
    return WordDetail(
      word: json['word'] as String? ?? '',
      hindiMeaning: json['hindiMeaning'] as String? ?? '',
      synonyms: _stringList(json['synonyms']),
      antonyms: _stringList(json['antonyms']),
      wordForms: _stringList(json['wordForms']),
      explanation: json['explanation'] as String? ?? '',
    );
  }

  factory WordDetail.fromWordData(String word, Map<String, dynamic> json) {
    return WordDetail(
      word: word,
      hindiMeaning: json['hindi'] as String? ?? '',
      synonyms: _stringList(json['synonyms']),
      antonyms: _stringList(json['antonyms']),
      wordForms: _stringList(json['forms']),
      explanation: json['explanation'] as String? ?? '',
    );
  }

  factory WordDetail.basic(String word) {
    return WordDetail(
      word: word,
      hindiMeaning: '',
      synonyms: const [],
      antonyms: const [],
      wordForms: [word],
      explanation: '',
    );
  }

  static List<String> _stringList(Object? value) {
    if (value is String) {
      return value
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    return (value as List<dynamic>? ?? [])
        .map((item) => item.toString())
        .where((item) => item.trim().isNotEmpty)
        .toList();
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF202020),
        fontSize: 17,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _WordDetailCard extends StatelessWidget {
  const _WordDetailCard({required this.detail, required this.onSpeak});

  final WordDetail detail;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE4F4FF),
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
          _DetailLine(label: 'Hindi Meaning', value: detail.hindiMeaning),
          _DetailLine(label: 'Synonyms', value: detail.synonyms.join(', ')),
          _DetailLine(label: 'Antonyms', value: detail.antonyms.join(', ')),
          _DetailLine(label: 'Word Forms', value: detail.wordForms.join(', ')),
          _DetailLine(label: 'Explanation', value: detail.explanation),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontSize: 13,
          height: 1.25,
          color: Color(0xFF39434B),
        ),
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({required this.story, required this.words});

  final String story;
  final Iterable<String> words;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEDEDED),
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final String summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE7F8E9),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        summary,
        style: const TextStyle(
          color: Color(0xFF3E5544),
          fontSize: 14,
          height: 1.35,
        ),
      ),
    );
  }
}

class _PracticeField extends StatelessWidget {
  const _PracticeField({required this.controller, required this.hintText});

  final TextEditingController controller;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: 1,
      maxLines: 2,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: const Color(0xFFD1D1D1),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 15,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Colors.black, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Colors.black, width: 1.3),
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, color: Color(0xFF2A2F35)),
          ),
        ),
        child,
      ],
    );
  }
}

class _DropdownPill extends StatelessWidget {
  const _DropdownPill({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 116,
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE1E9F2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF5B6770)),
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF1C2630),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              onChanged(value);
            }
          },
        ),
      ),
    );
  }
}

class _DifficultyButton extends StatelessWidget {
  const _DifficultyButton({
    required this.label,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = selected
        ? const Color(0xFF152434)
        : const Color(0xFFE1E9F2);
    final foreground = selected ? Colors.white : const Color(0xFF1C2630);
    final border = selected ? const Color(0xFF152434) : const Color(0xFFC6D0D9);

    return SizedBox(
      height: 38,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          side: BorderSide(color: border),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (selected) ...[
                const Icon(Icons.check, size: 14),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (locked) ...[
                const SizedBox(width: 5),
                Icon(
                  Icons.lock,
                  size: 13,
                  color: foreground.withValues(alpha: 0.75),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class StoryGenerationException implements Exception {
  StoryGenerationException(this.message);

  final String message;
}
