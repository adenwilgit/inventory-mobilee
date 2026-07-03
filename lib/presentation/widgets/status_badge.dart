import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status.toLowerCase()) {
      case 'pending_asisten_manager':
        bgColor = Colors.amber.shade50;
        textColor = Colors.amber.shade800;
        label = 'Pending Asmen';
        break;
      case 'pending_manager':
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade800;
        label = 'Pending Manager';
        break;
      case 'pending_gudang':
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue.shade800;
        label = 'Pending Gudang';
        break;
      case 'completed':
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade800;
        label = 'Selesai';
        break;
      case 'rejected':
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade800;
        label = 'Ditolak';
        break;
      default:
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
