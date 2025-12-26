import 'package:flutter/material.dart';
import 'date_formatter.dart';

/// Status Calculator Utility
/// Calculates shipment status based on shipment date and current date
class StatusCalculator {
  /// Calculate status based on shipment date compared to today's date
  /// Returns: "on-time" if <= 15 days from today, "late" if > 15 days, "not scanned" if invalid
  static String calculateStatus(String shipmentDate) {
    if (shipmentDate.trim().isEmpty) {
      return 'not scanned';
    }

    // Parse the shipment date using DateFormatter which handles multiple formats
    final shipment = DateFormatter.parseDate(shipmentDate);
    
    if (shipment == null) {
      return 'not scanned';
    }

    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);
    final shipmentDateOnly = DateTime(
      shipment.year,
      shipment.month,
      shipment.day,
    );

    // Calculate difference in days (positive = past date, negative = future date)
    final differenceInDays = todayDateOnly.difference(shipmentDateOnly).inDays;

    if (differenceInDays <= 15) {
      return 'on-time';
    } else {
      return 'late';
    }
  }

  /// Get status color for UI display
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'on-time':
        return Colors.green;
      case 'late':
        return Colors.red;
      case 'not scanned':
      default:
        return Colors.orange;
    }
  }
}
