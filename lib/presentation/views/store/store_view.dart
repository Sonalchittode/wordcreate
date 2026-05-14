import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/repositories/firebase_repository.dart';
import 'past_story_view.dart'; // <--- Update this import

class StoreView extends StatefulWidget {
  const StoreView({super.key});

  @override
  State<StoreView> createState() => _StoreViewState();
}

class _StoreViewState extends State<StoreView> {
  final FirebaseRepository _dbRepo = FirebaseRepository();
  bool _isPaid = false;

  @override
  void initState() {
    super.initState();
    _checkPlan();
  }

  Future<void> _checkPlan() async {
    final status = await _dbRepo.checkUserPlanStatus();
    if (mounted) setState(() => _isPaid = status);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final DateTime threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));

    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('stories_store')
            .where('user_id', isEqualTo: currentUserId)
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: colorScheme.primary));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text("No stories saved yet.",
                  style: TextStyle(color: colorScheme.primary.withValues(alpha: 0.5))),
            );
          }

          final allDocs = snapshot.data!.docs;
          final filteredDocs = allDocs.where((doc) {
            if (_isPaid) return true;
            final data = doc.data() as Map<String, dynamic>;
            if (data['created_at'] == null) return true;
            DateTime createdAt = (data['created_at'] as Timestamp).toDate();
            return createdAt.isAfter(threeDaysAgo);
          }).toList();

          if (filteredDocs.isEmpty && allDocs.isNotEmpty) {
            return _buildUpgradePrompt(colorScheme);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredDocs.length,
            itemBuilder: (context, index) {
              var data = filteredDocs[index].data() as Map<String, dynamic>;
              List<String> wordsList = List<String>.from(data['input_words'] ?? []);

              return Card(
                color: colorScheme.surface,
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.05)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                    child: Icon(Icons.book_outlined, color: colorScheme.primary, size: 20),
                  ),
                  title: Text(
                    wordsList.join(', '),
                    style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text("Created: ${_formatDate(data['created_at'])}",
                    style: TextStyle(color: colorScheme.primary.withValues(alpha: 0.5), fontSize: 12),),
                  trailing: Icon(Icons.arrow_forward_ios, size: 14, color: colorScheme.secondary),
                  onTap: () {
                    // Navigate to the NEW dedicated past story view
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PastStoryView(
                          storyData: data,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildUpgradePrompt(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off, size: 80, color: colorScheme.secondary.withValues(alpha: 0.3)),
            const SizedBox(height: 24),
            Text("History Limited",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colorScheme.primary)),
            const SizedBox(height: 12),
            Text(
              "Free users only see stories from the last 3 days. Upgrade to unlock your full library!",
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.primary.withValues(alpha: 0.6), height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.secondary, // Steel Blue
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () { /* Navigate to Payment Page */ },
                child: const Text("Unlock Lifetime History",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            )
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Just now';
    DateTime date = (timestamp as Timestamp).toDate();
    return "${date.day}/${date.month}/${date.year}";
  }
}