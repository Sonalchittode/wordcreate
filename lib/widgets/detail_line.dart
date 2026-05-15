import 'package:flutter/material.dart';

class DetailLine extends StatelessWidget {
  const DetailLine({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontSize: 13,
          height: 1.25,
          color: Color(0xFF39434B),
        ),
      ),
    );
  }
}
