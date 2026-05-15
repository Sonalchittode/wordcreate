import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
  String? _story;
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
      _story = null;
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

      setState(() => _story = text);
    } catch (_) {
      setState(() => _error = 'Could not generate story. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  String _buildPrompt(List<String> words) {
    final sizeGuide = switch (_size) {
      'Small' => '80 to 120 words',
      'Medium' => '120 to 150 words',
      'Large' => '150 to 180 words',
      _ => '100 to 140 words',
    };
    final genreGuide = _theme == 'Auto'
        ? 'choose a natural, engaging genre'
        : _theme;

    return '''
Write a simple English vocabulary learning story.

Required vocabulary words: ${words.join(', ')}
Story genre: $genreGuide
Difficulty: $_difficulty English
Length: $sizeGuide

Rules:
- Use every vocabulary word naturally in the story.
- Keep the language useful for English learners.
- Do not add explanations, markdown, headings, or bullet points.
- Return only the story text.
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
            if (_story != null) ...[
              const SizedBox(height: 24),
              const Text(
                'Generated Story',
                style: TextStyle(
                  color: Color(0xFF111820),
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F6F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _story!,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.45,
                    color: Color(0xFF18212B),
                  ),
                ),
              ),
            ],
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
