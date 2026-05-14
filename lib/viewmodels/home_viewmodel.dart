import 'package:flutter/material.dart';

class HomeViewModel extends ChangeNotifier {
  bool isPaidUser = false; // We will connect this to Firebase Auth next

  // Result class to hold either an error message or the adjusted parameters
  ValidationResult validateAndAdjust({
    required List<String> words,
    required String selectedSize,
    required double repetition,
  }) {
    int wordCount = words.length;
    int repCount = repetition.toInt();

    // Parse the base length requested by user (e.g., "Short (80-120 words)" -> 100)
    int targetLength = 100;
    if (selectedSize.contains('Medium')) targetLength = 135;
    if (selectedSize.contains('Long')) targetLength = 175;

    // --- FREE PLAN RULES ---
    if (!isPaidUser) {
      if (wordCount > 5) return ValidationResult(error: "Free Plan: Reduce words to 5 or fewer.");
      if (repCount > 1) return ValidationResult(error: "Free Plan: Word repetition not allowed.");

      return ValidationResult(isValid: true, finalLength: targetLength, finalRepetition: 1);
    }

    // --- PAID PLAN RULES & SMART ADJUSTMENTS ---
    if (wordCount > 10) return ValidationResult(error: "Maximum 10 words allowed.");

    // Smart Restriction Table Applied
    if (wordCount >= 8 && wordCount <= 10 && repCount > 3) {
      repCount = 3; // Auto-adjust down to max allowed for 8-10 words
    }

    // Smart Conflict 1: Many words + Short Length
    if (wordCount >= 6 && targetLength < 120) {
      targetLength = 135; // Auto-increase to Medium to fit words naturally
    }

    // Smart Conflict 2: High repetition + Short story
    if (repCount >= 4 && targetLength < 150) {
      targetLength = 175; // Auto-increase to Long so repetition isn't forced
    }

    return ValidationResult(
      isValid: true,
      finalLength: targetLength,
      finalRepetition: repCount,
      warningMessage: targetLength != 100 ? "Story length auto-increased for better quality." : null,
    );
  }
}

class ValidationResult {
  final bool isValid;
  final String? error;
  final String? warningMessage;
  final int finalLength;
  final int finalRepetition;

  ValidationResult({
    this.isValid = false,
    this.error,
    this.warningMessage,
    this.finalLength = 100,
    this.finalRepetition = 1,
  });
}