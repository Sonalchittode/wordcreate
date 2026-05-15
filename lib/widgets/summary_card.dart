import 'package:flutter/material.dart';

import '../core/app_colors.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard({super.key, required this.summary});

  final String summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.summaryCard,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        summary,
        style: const TextStyle(
          color: Color(0xFF3E5544),
          fontSize: 14,
          height: 1.35,
        ),
      ),
    );
  }
}
