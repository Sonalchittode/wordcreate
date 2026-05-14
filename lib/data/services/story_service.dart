import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class StoryService {
  late final GenerativeModel _model;

  StoryService() {
    final String apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    _model = GenerativeModel(
      model: 'gemini-3-flash-preview', // Optimized for speed and JSON reliability
      apiKey: apiKey,
    );
  }

  /// Generates a natural story to help users remember words.
  /// No 'repeatCount' input needed; the AI handles natural repetition.
  Future<Map<String, dynamic>> generateStory({
    required List<String> words,
    required String theme,
    required String size,
    required String difficulty,
    required bool isPaid,
  }) async {

    // Logic: Free users are locked to Beginner level.
    final String activeDifficulty = isPaid ? difficulty : 'Beginner';

    String difficultyInstruction = "";
    if (activeDifficulty == 'Beginner') {
      difficultyInstruction = "Use simple, short sentences and everyday common language.";
    } else if (activeDifficulty == 'Intermediate') {
      difficultyInstruction = "Use descriptive adjectives, varied sentence structures, and common idioms.";
    } else {
      difficultyInstruction = "Use complex prose, advanced vocabulary, and sophisticated narrative metaphors.";
    }

    String sizeInstruction = "";
    if (size == 'Short') {
      sizeInstruction = "Target 80-120 words. If the number of target words is high, you may expand slightly to ensure the story remains natural and realistic.";
    } else if (size == 'Medium') {
      sizeInstruction = "Target 120-150 words.";
    } else if (size == 'Long') {
      sizeInstruction = "Target 150-200 words.";
    }

    final prompt = """
    Role: Expert Narrative Linguist.
    Task: Write a natural, realistic $size story about '$theme' at a $activeDifficulty level.
    
    Length: $sizeInstruction
    Level Context: $difficultyInstruction
    Target Words: ${words.join(', ')}
    
    CRITICAL INSTRUCTION FOR SHORT STORIES:
  If the target words make the story feel "forced" or like a list because the length is too short, 
  automatically increase the length just enough to maintain a high-quality, realistic narrative flow. 
  The goal is a natural story, not a vocabulary list. 
  
    CORE RULES:
    1. NATURAL REPETITION: Repeat each target word multiple times throughout the story. The repetition must feel like a natural part of a real story, not a word list.
    2. WORD FORMS: Use different forms of the words (e.g., if the word is 'go', use 'go', 'went', 'gone') to show how they are used in real life .
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
         ${words.map((w) => """
         "$w": {
            "meaning": "Clear English definition",
            "hindi": "Hindi meaning",
            "synonyms": "comma, separated, synonyms",
            "antonyms": "comma, separated, antonyms",
            "forms": "List the forms used in the story (e.g., running, ran)",
            "explanation": "A simple 1-sentence tip on how to use this word naturally"
         }""").join(', ')}
      }
    }
    """;

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      String responseText = response.text ?? '{}';

      // Clean Markdown formatting tags safely to prevent JSON parse errors
      final cleanJson = responseText
          .replaceFirst(RegExp(r'^```json\s*'), '')
          .replaceFirst(RegExp(r'\s*```$'), '')
          .trim();

      final decoded = jsonDecode(cleanJson);
      return Map<String, dynamic>.from(decoded);

    } catch (e) {
      print("Generation Error: $e");
      return {
        "story": "I couldn't weave the story right now. Please try again in a moment.",
        "summary": "Error: Story generation failed.",
        "word_data": <String, dynamic>{}
      };
    }
  }

  Future<String> validatePracticeSentences({
    required List<String> sentences,
    required List<String> targetWords,
  }) async {
    try {
      final prompt = 'Check context for: ${targetWords.join(", ")}. Sentences: ${sentences.join(" | ")}. Start with ✅ or ❌.';
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? "❌ Validation error.";
    } catch (e) {
      return "❌ Connection error: $e";
    }
  }
}