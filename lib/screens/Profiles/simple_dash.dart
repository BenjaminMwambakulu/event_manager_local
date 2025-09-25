import 'package:flutter/material.dart';

class SimpleDash extends StatefulWidget {
  const SimpleDash({super.key});

  @override
  State<SimpleDash> createState() => _SimpleDashState();
}

// TODO: Implement SimpleDash with information from the database

class _SimpleDashState extends State<SimpleDash> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // First Row
          Row(
            children: [
              _buildDashCard("Total Events", "100", Colors.blue),
              const SizedBox(width: 16),
              _buildDashCard("Total Registrations", "100", Colors.green),
            ],
          ),
          const SizedBox(height: 16),
          // Second Row
          Row(
            children: [
              _buildDashCard("Total Revenue", "\$1000", Colors.orange),
              const SizedBox(width: 16),
              _buildDashCard("Total CheckIns", "100", Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  // Reusable card widget for dashboard items
  Widget _buildDashCard(String title, String value, Color color) {
    return Expanded(
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
