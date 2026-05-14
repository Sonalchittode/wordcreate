import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/services.dart';
import '../../../data/services/story_service.dart';

class StoryDetailView extends StatefulWidget {
  final Map<String, dynamic> aiResponse;
  final List<String> inputWords;
  final bool isPaid;

  const StoryDetailView({
    super.key,
    required this.aiResponse,
    required this.inputWords,
    required this.isPaid,
  });

  @override
  State<StoryDetailView> createState() => _StoryDetailViewState();
}

class _StoryDetailViewState extends State<StoryDetailView> {
  final StoryService _storyService = StoryService();
  final FlutterTts flutterTts = FlutterTts();
  final List<TextEditingController> _controllers = [
    TextEditingController(),
    TextEditingController()
  ];
  String _practiceFeedback = '';
  bool isValidating = false;

  Future<void> _speak(String text) async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.4);
    await flutterTts.speak(text);
  }

  /// Highlights target words in the story.
  /// Improved to handle punctuation and different word forms.
  List<TextSpan> _highlightText(String text, ColorScheme colorScheme) {
    List<String> tokens = text.split(" ");
    return tokens.map((token) {
      // Clean word to check against input list (remove dots, commas, etc)
      String clean = token.toLowerCase().replaceAll(RegExp(r'[^\w]'), '');

      // Check if the clean version of the token matches any of our target words
      bool isMatch = widget.inputWords.any((w) => clean.contains(w.toLowerCase()) || w.toLowerCase().contains(clean)) && clean.length > 2;

      return TextSpan(
        text: "$token ",
        style: TextStyle(
          color: isMatch ? colorScheme.primary : Colors.black87,
          fontWeight: isMatch ? FontWeight.bold : FontWeight.normal,
          backgroundColor: isMatch ? colorScheme.primary.withOpacity(0.1) : null,
          fontSize: 16,
        ),
      );
    }).toList();
  }

  /// Helper to build the detail rows for Synonyms, Antonyms, and Forms
  Widget _buildDetailRow(String label, dynamic value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87, fontSize: 14, height: 1.4),
          children: [
            TextSpan(
              text: "$label: ",
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
            TextSpan(text: "${value ?? 'N/A'}"),
          ],
        ),
      ),
    );
  }

  Future<void> _validate() async {
    if (_controllers[0].text.isEmpty && _controllers[1].text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please write at least one sentence.")),
      );
      return;
    }

    setState(() => isValidating = true);
    final sentences = _controllers.map((c) => c.text).toList();
    final result = await _storyService.validatePracticeSentences(
      sentences: sentences,
      targetWords: widget.inputWords,
    );
    setState(() {
      _practiceFeedback = result;
      isValidating = false;
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final Map<String, dynamic> wordData =
    Map<String, dynamic>.from(widget.aiResponse['word_data'] ?? {});

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Story Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: widget.aiResponse['story'] ?? ''));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Story copied to clipboard!")),
              );
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- VOCABULARY SECTION ---
            Row(
              children: [
                Icon(Icons.translate, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text('Vocabulary',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary)),
              ],
            ),
            const SizedBox(height: 12),
            ...widget.inputWords.map((word) {
              final data = wordData[word] ?? {};
              return Card(
                color: Colors.grey[50],
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.only(bottom: 10),
                child: ExpansionTile(
                  leading: IconButton(
                    icon: Icon(Icons.volume_up, color: colorScheme.primary),
                    onPressed: () => _speak(word),
                  ),
                  title: Text(word,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18)),
                  subtitle: Text(data['hindi'] ?? '',
                      style: const TextStyle(color: Colors.indigo)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Meaning:",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary)),
                          Text("${data['meaning'] ?? 'N/A'}",
                              style: const TextStyle(fontSize: 15)),
                          const SizedBox(height: 8),
                          Text("Explanation:",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary)),
                          Text("${data['explanation'] ?? 'N/A'}",
                              style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.black54)),
                          const Divider(height: 24),
                          _buildDetailRow("Synonyms", data['synonyms'], Colors.green[700]!),
                          _buildDetailRow("Antonyms", data['antonyms'], Colors.redAccent),
                          _buildDetailRow("Forms used", data['forms'], Colors.orange[800]!),
                        ],
                      ),
                    )
                  ],
                ),
              );
            }),

            const SizedBox(height: 32),

            // --- STORY SECTION ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('The Story',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary)),
                IconButton(
                  icon: const Icon(Icons.play_circle_fill),
                  onPressed: () => _speak(widget.aiResponse['story'] ?? ''),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: SelectableText.rich(
                TextSpan(
                  children: _highlightText(
                      widget.aiResponse['story'] ?? '', colorScheme),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: colorScheme.primary, width: 4)),
                color: Colors.grey[100],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Summary', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(widget.aiResponse['summary'] ?? '',
                      style: const TextStyle(fontStyle: FontStyle.italic)),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // --- PRACTICE ZONE ---
            Text('Practice Zone',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary)),
            const Text("Use your words in a sentence to test yourself.",
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
                controller: _controllers[0],
                maxLines: 2,
                decoration: const InputDecoration(
                    labelText: "Your Sentence 1", border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(
                controller: _controllers[1],
                maxLines: 2,
                decoration: const InputDecoration(
                    labelText: "Your Sentence 2", border: OutlineInputBorder())),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.secondary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                onPressed: isValidating ? null : _validate,
                icon: isValidating
                    ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.check_circle, color: Colors.white),
                label: const Text('Validate My Usage',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
            if (_practiceFeedback.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _practiceFeedback.contains('✅')
                      ? Colors.green[50]
                      : Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _practiceFeedback,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _practiceFeedback.contains('✅')
                        ? Colors.green[800]
                        : Colors.red[800],
                  ),
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}