import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_colors.dart';
import '../services/story_generation_service.dart';
import '../widgets/difficulty_button.dart';
import '../widgets/dropdown_pill.dart';
import '../widgets/setting_row.dart';
import 'story_result_page.dart';

class StoryGeneratorPage extends StatefulWidget {
  const StoryGeneratorPage({super.key, StoryGenerationService? storyService})
    : _storyService = storyService;

  final StoryGenerationService? _storyService;

  @override
  State<StoryGeneratorPage> createState() => _StoryGeneratorPageState();
}

class _StoryGeneratorPageState extends State<StoryGeneratorPage> {
  final _wordsController = TextEditingController();

  late final StoryGenerationService _storyService;

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
    _storyService = widget._storyService ?? StoryGenerationService();
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
      final result = await _storyService.generateStory(
        words: words,
        theme: _theme,
        size: _size,
        difficulty: _difficulty,
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.navy,
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
                fillColor: AppColors.inputFill,
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
            SettingRow(
              label: 'Story Theme',
              child: DropdownPill(
                value: _theme,
                items: _themes,
                onChanged: (value) => setState(() => _theme = value),
              ),
            ),
            const SizedBox(height: 16),
            SettingRow(
              label: 'Story Size',
              child: DropdownPill(
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
                  child: DifficultyButton(
                    label: 'Beginner',
                    selected: _difficulty == 'Beginner',
                    locked: false,
                    onTap: () => setState(() => _difficulty = 'Beginner'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DifficultyButton(
                    label: 'Intermediate',
                    selected: false,
                    locked: true,
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DifficultyButton(
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
                  backgroundColor: AppColors.buttonBlue,
                  disabledBackgroundColor: AppColors.buttonBlue.withValues(
                    alpha: 0.55,
                  ),
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
