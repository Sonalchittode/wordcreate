import 'package:flutter/material.dart';

class SubscriptionView extends StatelessWidget {
  const SubscriptionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Premium Plan"), backgroundColor: Colors.white, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.stars_rounded, size: 80, color: Colors.orange),
            const SizedBox(height: 16),
            const Text("Unlock Your Full Potential", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),

            // Comparison Table
            Table(
              border: TableBorder.symmetric(inside: const BorderSide(color: Colors.grey, width: 0.5)),
              children: [
                _buildTableRow("Features", "Free", "Pro", isHeader: true),
                _buildTableRow("Word Limit", "5 Words", "10 Words"),
                _buildTableRow("Difficulty", "Beginner", "All Levels"),
                _buildTableRow("History", "3 Days", "Lifetime"),
                _buildTableRow("Word Repeat", "No", "Yes (5x)"),
                _buildTableRow("Daily Quota", "3 Stories", "Unlimited"),
              ],
            ),

            const SizedBox(height: 40),

            // Pricing Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () { /* Integrate Payment Gateway Here */ },
                child: const Text("Upgrade for \$4.99/mo", style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TableRow _buildTableRow(String feature, String free, String pro, {bool isHeader = false}) {
    TextStyle style = TextStyle(
      fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
      fontSize: isHeader ? 16 : 14,
    );
    return TableRow(
      children: [
        Padding(padding: const EdgeInsets.all(12), child: Text(feature, style: style)),
        Padding(padding: const EdgeInsets.all(12), child: Text(free, style: style)),
        Padding(padding: const EdgeInsets.all(12), child: Text(pro, style: style.copyWith(color: isHeader ? null : Colors.orange, fontWeight: isHeader ? null : FontWeight.bold))),
      ],
    );
  }
}