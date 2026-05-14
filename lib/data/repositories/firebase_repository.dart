import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUserId => _auth.currentUser?.uid ?? 'guest_user_123';

  // --- SAVE STORY (Updated to include full AI metadata) ---
  Future<void> saveStory({
    required List<String> words,
    required String storyText,
    required String theme,
    required String summary, // Added
    required Map<String, dynamic> wordData, // Added
  }) async {
    try {
      bool isPaid = await checkUserPlanStatus();

      await _firestore.collection('stories_store').add({
        'user_id': currentUserId,
        'input_words': words,
        'story_text': storyText,
        'summary': summary, // Now saved
        'word_data': wordData, // Now saved
        'theme': theme,
        'created_at': FieldValue.serverTimestamp(),
        'is_premium_record': isPaid,
      });

      await _updateProgress(words.length);
    } catch (e) {
      print("Error saving story: $e");
    }
  }

  // --- UPDATE PROGRESS (Optimized Streak Logic) ---
  Future<void> _updateProgress(int newWordsCount) async {
    final progressRef = _firestore.collection('progress').doc(currentUserId);
    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(progressRef);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        if (!snapshot.exists) {
          transaction.set(progressRef, {
            'user_id': currentUserId,
            'total_stories': 1,
            'total_words': newWordsCount,
            'streak_days': 1,
            'last_active': Timestamp.fromDate(today),
          });
        } else {
          final data = snapshot.data()!;
          Timestamp lastActiveTs = data['last_active'] ?? Timestamp.fromDate(today.subtract(const Duration(days: 2)));
          DateTime lastActive = lastActiveTs.toDate();
          int currentStreak = data['streak_days'] ?? 0;

          // If last active was yesterday, increment streak
          if (lastActive.isAtSameMomentAs(today.subtract(const Duration(days: 1)))) {
            currentStreak++;
          }
          // If last active was more than 1 day ago, reset streak
          else if (lastActive.isBefore(today.subtract(const Duration(days: 1)))) {
            currentStreak = 1;
          }

          transaction.update(progressRef, {
            'total_stories': FieldValue.increment(1),
            'total_words': FieldValue.increment(newWordsCount),
            'streak_days': currentStreak,
            'last_active': Timestamp.fromDate(today),
          });
        }
      });
    } catch (e) {
      print("Error updating progress: $e");
    }
  }
  Future<void> sendFeedback(String message) async {
    final user = _auth.currentUser;
    await _firestore.collection('feedback').add({
      'userId': user?.uid ?? 'anonymous',
      'userEmail': user?.email ?? 'no-email',
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<bool> checkUserPlanStatus() async {
    try {
      final doc = await _firestore.collection('users').doc(currentUserId).get();
      return doc.exists && doc.data()?['plan_type'] == 'paid';
    } catch (e) {
      return false;
    }
  }

  Future<bool> checkAndIncrementDailyQuota() async {
    final userRef = _firestore.collection('users').doc(currentUserId);
    final today = DateTime.now().toIso8601String().split('T')[0];

    // Auth se user details nikalna
    final user = _auth.currentUser;

    try {
      return await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        int currentCount = 0;
        String planType = snapshot.exists ? (snapshot.data()?['plan_type'] ?? 'free') : 'free';

        if (snapshot.exists && snapshot.data()?['last_usage_date'] == today) {
          currentCount = snapshot.data()?['daily_story_count'] ?? 0;
        }

        int maxAllowed = planType == 'paid' ? 10 : 2;
        if (currentCount >= maxAllowed) return false;

        transaction.set(userRef, {
          'user_name': user?.displayName ?? 'New Explorer', // Naam add kiya
          'email': user?.email ?? 'no-email',              // Email add kiya
          'daily_story_count': currentCount + 1,
          'last_usage_date': today,
          'plan_type': planType,
        }, SetOptions(merge: true)); // merge: true se purana data delete nahi hoga

        return true;
      });
    } catch (e) {
      print("Error updating user table: $e");
      return false;
    }
  }
}
