import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProgressView extends StatelessWidget {
  const ProgressView({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // 1. Identify the user (Fallback to guest if not logged in)
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest_user_123';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Your Progress'),
      ),
      // 2. StreamBuilder creates a LIVE connection to Firestore
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('progress').doc(uid).snapshots(),
        builder: (context, snapshot) {
          // Show loader while connecting
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: colorScheme.primary));
          }

          // If document doesn't exist yet
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Text(
                "Generate a story to see your progress!",
                style: TextStyle(color: colorScheme.primary.withValues(alpha: 0.5)),
              ),
            );
          }

          // 3. Get real-time data
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final int streak = data['streak_days'] ?? 0;
          final int stories = data['total_stories'] ?? 0;
          final int words = data['total_words'] ?? 0;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Live Streak Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colorScheme.primary.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.local_fire_department, color: colorScheme.secondary, size: 48),
                      const SizedBox(width: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'Current Streak',
                              style: TextStyle(fontSize: 14, color: colorScheme.primary.withValues(alpha: 0.6), fontWeight: FontWeight.w600)
                          ),
                          Text(
                              '$streak Days',
                              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: colorScheme.primary)
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Live Stories and Words Row
                Row(
                  children: [
                    _StatCard(
                        icon: Icons.menu_book,
                        label: 'Stories',
                        value: stories.toString(),
                    ),
                    const SizedBox(width: 15),
                    _StatCard(
                        icon: Icons.psychology,
                        label: 'Words',
                        value: words.toString(),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.5), // Lighter Ice Blue
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            // Icons use Steel Blue to stand out as "Achievements"
            Icon(icon, size: 36, color: colorScheme.secondary),
            const SizedBox(height: 12),
            Text(
                value,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: colorScheme.primary)
            ),
            Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: colorScheme.primary.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w600,
                    fontSize: 12
                )
            ),
          ],
        ),
      ),
    );
  }
}