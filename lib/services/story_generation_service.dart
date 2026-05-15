import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../models/generated_story.dart';

class StoryGenerationService {
  StoryGenerationService({String? apiKey}) : _apiKeyOverride = apiKey;

  final String? _apiKeyOverride;

  Future<GeneratedStory> generateStory({
    required List<String> words,
    required String theme,
    required String size,
    required String difficulty,
  }) async {
    final apiKey = _apiKeyOverride ?? dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw StoryGenerationException('Missing GEMINI_API_KEY in .env.');
    }

    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
    try {
      final response = await model.generateContent([
        Content.text(
          buildPrompt(
            words: words,
            theme: theme,
            size: size,
            difficulty: difficulty,
          ),
        ),
      ]);
      final text = response.text?.trim();

      if (text == null || text.isEmpty) {
        throw StoryGenerationException('The AI did not return a story.');
      }

      return GeneratedStory.fromJsonText(text, fallbackWords: words);
    } catch (error) {
      throw StoryGenerationException('Generation failed: $error');
    }
  }

  String buildPrompt({
    required List<String> words,
    required String theme,
    required String size,
    required String difficulty,
  }) {
    final activeTheme = theme == 'Auto' ? 'a realistic everyday moment' : theme;
    final activeSize = switch (size) {
      'Small' => 'Short',
      'Large' => 'Long',
      'Medium' => 'Medium',
      _ => 'Short',
    };

    final difficultyInstruction = switch (difficulty) {
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
Task: Write a natural, realistic $activeSize story about '$activeTheme' at a $difficulty level.

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
}

class StoryGenerationException implements Exception {
  StoryGenerationException(this.message);

  final String message;
}
