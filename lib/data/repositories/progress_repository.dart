import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProgressRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Map<String, dynamic>> getUserStats() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return {'streak': 0, 'stories': 0, 'words': 0};

    // 1. Get total stories and words
    final storiesQuery = await _firestore
        .collection('stories_store')
        .where('user_id', isEqualTo: uid)
        .get();

    int totalStories = storiesQuery.docs.length;
    int totalWords = 0;

    List<DateTime> dates = [];

    for (var doc in storiesQuery.docs) {
      final data = doc.data();
      totalWords += (data['words'] as List).length;
      if (data['timestamp'] != null) {
        dates.add((data['timestamp'] as Timestamp).toDate());
      }
    }

    // 2. Calculate Streak
    int streak = _calculateStreak(dates);

    return {
      'streak': streak,
      'stories': totalStories,
      'words': totalWords,
    };
  }

  int _calculateStreak(List<DateTime> dates) {
    if (dates.isEmpty) return 0;

    // Sort dates descending and remove time component
    final uniqueDates = dates
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    int streak = 0;
    DateTime today = DateTime.now();
    DateTime checkDate = DateTime(today.year, today.month, today.day);

    // If the latest date isn't today or yesterday, streak is broken
    if (uniqueDates.first.isBefore(checkDate.subtract(const Duration(days: 1)))) {
      return 0;
    }

    for (var date in uniqueDates) {
      if (date == checkDate || date == checkDate.subtract(Duration(days: streak))) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }
}