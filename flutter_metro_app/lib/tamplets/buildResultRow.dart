 import 'package:flutter/material.dart';

Widget buildResultRow({
    required IconData icon,
    required String title,
    required String value,
    bool isBold = false,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue.shade700, size: 28),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }