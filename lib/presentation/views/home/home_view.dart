import 'package:flutter/material.dart';
import '../../../data/services/story_service.dart';
import '../../../data/repositories/firebase_repository.dart';
import '../story/story_detail_view.dart';

class HomeView extends StatefulWidget {
  final String? lastStory;
  final List<String>? lastWords;
  final Function(String, List<String>) onStoryGenerated;

  const HomeView({
    super.key,
    this.lastStory,
    this.lastWords,
    required this.onStoryGenerated,
  });

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final TextEditingController _wordsController = TextEditingController();
  final StoryService _storyService = StoryService();
  final FirebaseRepository _dbRepo = FirebaseRepository();

  String _selectedTheme = 'Auto';
  String _selectedSize = 'Auto';
  bool _isLoading = false;
  bool _isPaid = false;
  String _selectedDifficulty = 'Beginner';

  @override
  void initState() {
    super.initState();
    _checkUserPlan();
  }

  Future<void> _checkUserPlan() async {
    final isPaid = await _dbRepo.checkUserPlanStatus();
    if (mounted) setState(() => _isPaid = isPaid);
  }

  Future<void> _handleGenerate() async {
    List<String> words = _wordsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (words.isEmpty) {
      _showSnack("Enter words separated by commas!");
      return;
    }

    if (words.length == 1 && _wordsController.text.contains(' ')) {
      _showSnack("Use commas to separate words (e.g. brave, hero)");
      return;
    }

    setState(() => _isLoading = true);


    try {
      final rawResponse = await _storyService.generateStory(
        words: words,
        theme: _selectedTheme,
        size: _selectedSize,
        difficulty: _selectedDifficulty,
        isPaid: _isPaid,
      );

      final Map<String, dynamic> result = Map<String, dynamic>.from(rawResponse);

      await _dbRepo.saveStory(
        words: words,
        storyText: result['story'] ?? '',
        theme: _selectedTheme,
        summary: result['summary'] ?? '',
        wordData: Map<String, dynamic>.from(result['word_data'] ?? {}),
      );

      widget.onStoryGenerated(result['story'], words);

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StoryDetailView(
              aiResponse: result,
              inputWords: words,
              isPaid: _isPaid,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack("System Error: $e");
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter Words (comma separated)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _wordsController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'e.g. Ephemeral, Resilience, Melancholy',
                filled: true,
                fillColor: const Color(0xFFE8F0F5),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 25),

            _buildDropdownRow('Story Theme', _selectedTheme,
                ['Auto', 'Adventure','Sci-Fi','Daily Life','Travel','Inspirational','Comedy','Sports','Conversation'],
                    (v) => setState(() => _selectedTheme = v!)),

            const SizedBox(height: 15),

            _buildDropdownRow('Story Size', _selectedSize,
                ['Auto', 'Short', 'Medium', 'Long'],
                    (v) => setState(() => _selectedSize = v!)),

            const SizedBox(height: 25),

            const Text('Story Difficulty',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: ['Beginner', 'Intermediate', 'Advanced'].map((level) {
                bool isSelected = _selectedDifficulty == level;
                bool canSelect = isSelected || _isPaid || level == 'Beginner';

                return ChoiceChip(
                  label: Text(level),
                  selected: isSelected,
                  onSelected: (v) {
                    if (level != 'Beginner' && !_isPaid) {
                      _showSnack("Level locked. Upgrade to Premium!");
                      return;
                    }
                    setState(() => _selectedDifficulty = level);
                  },
                  selectedColor: const Color(0xFF1F2937),
                  labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87),
                  backgroundColor: const Color(0xFFE5E7EB),
                  avatar: (!canSelect) ? const Icon(Icons.lock, size: 14) : null,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                );
              }).toList(),
            ),

            if (!_isPaid)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text("Only Beginner level is available for free users",
                    style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
              ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7191A7),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isLoading ? null : _handleGenerate,
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Generate Story',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownRow(String label, String value, List<String> items, Function(String?) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F0F5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              icon: const Icon(Icons.arrow_drop_down),
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}