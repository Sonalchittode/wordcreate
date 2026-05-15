import 'package:flutter/material.dart';

class SettingRow extends StatelessWidget {
  const SettingRow({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, color: Color(0xFF2A2F35)),
          ),
        ),
        child,
      ],
    );
  }
}
