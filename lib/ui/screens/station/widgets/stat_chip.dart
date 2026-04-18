import 'package:flutter/material.dart';

class StatChip extends StatelessWidget {
  final int value;
  final IconData icon;

  const StatChip({super.key, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7D6C9)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFFF4A261)),
          const SizedBox(width: 6),
          Text(
            value.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}