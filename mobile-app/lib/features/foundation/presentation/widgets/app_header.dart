import 'package:flutter/material.dart';

class AppHeader extends StatelessWidget {
  final VoidCallback? onSearchTap;
  const AppHeader({super.key, this.onSearchTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.eco,
                color: Colors.green.shade700,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                'RythuMitra AI',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade900,
                ),
              ),
            ],
          ),
          Row(
            children: [
              if (onSearchTap != null)
                IconButton(
                  icon: Icon(Icons.search, color: Colors.green.shade700, size: 28),
                  onPressed: onSearchTap,
                ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: Colors.green.shade100,
                child: Icon(
                  Icons.person,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
