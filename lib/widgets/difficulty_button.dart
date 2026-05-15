import 'package:flutter/material.dart';

class DifficultyButton extends StatelessWidget {
  const DifficultyButton({
    super.key,
    required this.label,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = selected
        ? const Color(0xFF152434)
        : const Color(0xFFE1E9F2);
    final foreground = selected ? Colors.white : const Color(0xFF1C2630);
    final border = selected ? const Color(0xFF152434) : const Color(0xFFC6D0D9);

    return SizedBox(
      height: 38,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          side: BorderSide(color: border),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (selected) ...[
                const Icon(Icons.check, size: 14),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
