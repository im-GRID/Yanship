import 'package:flutter/material.dart';

class GroupedOrdersList extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  final Widget Function(Map<String, dynamic>) buildOrderCard;

  const GroupedOrdersList({
    required this.orders,
    required this.buildOrderCard,
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const SizedBox.shrink();
    }

    // Group orders by date
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    final now = DateTime.now();
    for (var order in orders) {
      String? dateStr = order['created_at']?.toString() ?? order['date']?.toString();
      DateTime? date;
      try {
        if (dateStr != null) {
          date = DateTime.parse(dateStr);
        }
      } catch (_) {
        date = null;
      }
      String header;
      if (date != null) {
        final today = DateTime(now.year, now.month, now.day);
        final orderDay = DateTime(date.year, date.month, date.day);
        if (orderDay == today) {
          header = 'Today';
        } else if (orderDay == today.subtract(const Duration(days: 1))) {
          header = 'Yesterday';
        } else {
          header = '${orderDay.day.toString().padLeft(2, '0')}/${orderDay.month.toString().padLeft(2, '0')}/${orderDay.year}';
        }
      } else {
        header = 'Unknown Date';
      }
      grouped.putIfAbsent(header, () => []).add(order);
    }

    final headers = grouped.keys.toList();
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: grouped.values.fold(0, (prev, list) => prev + list.length) + headers.length,
      itemBuilder: (context, index) {
        int runningIndex = 0;
        for (var header in headers) {
          // Header
          if (index == runningIndex) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Text(
                header,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            );
          }
          runningIndex++;
          // Cards
          for (var order in grouped[header]!) {
            if (index == runningIndex) {
              return buildOrderCard(order);
            }
            runningIndex++;
          }
        }
        // Should not reach here
        return const SizedBox.shrink();
      },
    );
  }
}