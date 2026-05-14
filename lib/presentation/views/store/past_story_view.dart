import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class PastStoryView extends StatelessWidget {
  final Map<String, dynamic> storyData;
  final FlutterTts flutterTts = FlutterTts();

  PastStoryView({super.key, required this.storyData});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final List<String> words = List<String>.from(storyData['input_words'] ?? []);
    final Map<String, dynamic> wordDetails = storyData['word_data'] ?? {};
    final String storyText = storyData['story_text'] ?? '';
    final String summary = storyData['summary'] ?? 'No summary available';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Saved Story'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vocabulary Review',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary // Deep Navy
              ),
            ),
            const SizedBox(height: 12),

            // Map vocabulary from the saved data
            ...words.map((word) {
              final details = wordDetails[word];
              return Card(
                elevation: 0,
                color: colorScheme.surface,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ExpansionTile(
                  shape: const Border(),
                  initiallyExpanded: true,
                  iconColor: colorScheme.secondary,
                  title: Text(
                      word,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary
                      )
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.volume_up, size: 22, color: colorScheme.secondary), // Steel Blue
                    onPressed: () => flutterTts.speak(word),
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    Row(
                      children: [
                        Text('Hindi: ',
                            style: TextStyle(color: colorScheme.primary.withValues(alpha: 0.6), fontWeight: FontWeight.bold)),
                        Text('${details?['hindi'] ?? "N/A"}',
                            style: const TextStyle(color: Colors.indigoAccent, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Explanation: ${details?['explanation'] ?? "N/A"}',
                      style: TextStyle(color: colorScheme.primary.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 24),
            Divider(color: colorScheme.surface),
            const SizedBox(height: 24),

            Text(
                'The Story',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.primary)
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.surface),
              ),
              child: Text(
                storyText,
                style: TextStyle(
                    fontSize: 16,
                    height: 1.8,
                    color: colorScheme.primary.withValues(alpha: 0.9)
                ),
              ),
            ),

            const SizedBox(height: 24),

            Text('Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,color: colorScheme.primary)),
            const SizedBox(height: 8),
            Text(
              summary,
              style: TextStyle(
                  fontSize: 15,
                  color: colorScheme.primary.withValues(alpha: 0.5),
                  fontStyle: FontStyle.italic
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}