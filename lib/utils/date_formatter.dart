import 'package:intl/intl.dart';

/// Date Formatter Utility
/// Converts dates to DD-MM-YYYY HH:MM format (24-hour)
class DateFormatter {
  /// Format date string to DD-MM-YYYY HH:MM format
  /// Handles various input formats and converts to 24-hour time format
  static String formatDate(String dateString) {
    if (dateString.isEmpty) return '';
    
    try {
      DateTime? dateTime;
      
      // Try parsing various date formats
      // Format 1: "10/9/2025 8:47" or "10/9/2025 8:47:00" (M/d/yyyy H:mm or M/d/yyyy H:mm:ss)
      if (dateString.contains('/')) {
        final parts = dateString.trim().split(' ');
        if (parts.length >= 2) {
          final datePart = parts[0];
          final timePart = parts[1];
          
          final dateParts = datePart.split('/');
          if (dateParts.length == 3) {
            final month = int.tryParse(dateParts[0]) ?? 1;
            final day = int.tryParse(dateParts[1]) ?? 1;
            final year = int.tryParse(dateParts[2]) ?? DateTime.now().year;
            
            // Handle time part (can be "8:47" or "8:47:00")
            final timeParts = timePart.split(':');
            final hour = timeParts.isNotEmpty ? (int.tryParse(timeParts[0]) ?? 0) : 0;
            final minute = timeParts.length > 1 ? (int.tryParse(timeParts[1]) ?? 0) : 0;
            
            // Validate date components
            if (month >= 1 && month <= 12 && day >= 1 && day <= 31 && year > 1900) {
              dateTime = DateTime(year, month, day, hour, minute);
            }
          }
        } else if (parts.length == 1) {
          // Only date part, no time
          final dateParts = parts[0].split('/');
          if (dateParts.length == 3) {
            final month = int.tryParse(dateParts[0]) ?? 1;
            final day = int.tryParse(dateParts[1]) ?? 1;
            final year = int.tryParse(dateParts[2]) ?? DateTime.now().year;
            
            if (month >= 1 && month <= 12 && day >= 1 && day <= 31 && year > 1900) {
              dateTime = DateTime(year, month, day);
            }
          }
        }
      }
      
      // Format 2: ISO 8601 format
      if (dateTime == null) {
        try {
          dateTime = DateTime.parse(dateString);
        } catch (e) {
          // Try other formats
        }
      }
      
      // Format 3: "DD-MM-YYYY HH:MM" or "DD/MM/YYYY HH:MM"
      if (dateTime == null) {
        try {
          // Try common date formats
          final formats = [
            'dd-MM-yyyy HH:mm',
            'dd/MM/yyyy HH:mm',
            'yyyy-MM-dd HH:mm',
            'yyyy/MM/dd HH:mm',
            'MM/dd/yyyy HH:mm',
            'dd-MM-yyyy',
            'dd/MM/yyyy',
            'yyyy-MM-dd',
          ];
          
          for (var format in formats) {
            try {
              dateTime = DateFormat(format).parse(dateString);
              break;
            } catch (e) {
              continue;
            }
          }
        } catch (e) {
          // If all parsing fails, return original string
        }
      }
      
      // If we successfully parsed the date, format it
      if (dateTime != null) {
        return DateFormat('dd-MM-yyyy HH:mm').format(dateTime);
      }
      
      // If parsing failed, return original string
      return dateString;
    } catch (e) {
      // If any error occurs, return original string
      return dateString;
    }
  }
  
  /// Format DateTime object to DD-MM-YYYY HH:MM format
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd-MM-yyyy HH:mm').format(dateTime);
  }
  
  /// Parse date string and return DateTime, or null if parsing fails
  static DateTime? parseDate(String dateString) {
    if (dateString.isEmpty) return null;
    
    try {
      // Try ISO format first
      try {
        return DateTime.parse(dateString);
      } catch (e) {
        // Continue to other formats
      }
      
      // Handle Excel format: "M/d/yyyy H:mm" or "M/d/yyyy H:mm:ss" (e.g., "10/9/2025 8:47")
      if (dateString.contains('/')) {
        final parts = dateString.trim().split(' ');
        if (parts.length >= 2) {
          final datePart = parts[0];
          final timePart = parts[1];
          
          final dateParts = datePart.split('/');
          if (dateParts.length == 3) {
            final month = int.tryParse(dateParts[0]) ?? 1;
            final day = int.tryParse(dateParts[1]) ?? 1;
            final year = int.tryParse(dateParts[2]) ?? DateTime.now().year;
            
            final timeParts = timePart.split(':');
            final hour = timeParts.isNotEmpty ? (int.tryParse(timeParts[0]) ?? 0) : 0;
            final minute = timeParts.length > 1 ? (int.tryParse(timeParts[1]) ?? 0) : 0;
            final second = timeParts.length > 2 ? (int.tryParse(timeParts[2]) ?? 0) : 0;
            
            if (month >= 1 && month <= 12 && day >= 1 && day <= 31 && year > 1900) {
              return DateTime(year, month, day, hour, minute, second);
            }
          }
        } else if (parts.length == 1) {
          // Only date part, no time
          final dateParts = parts[0].split('/');
          if (dateParts.length == 3) {
            final month = int.tryParse(dateParts[0]) ?? 1;
            final day = int.tryParse(dateParts[1]) ?? 1;
            final year = int.tryParse(dateParts[2]) ?? DateTime.now().year;
            
            if (month >= 1 && month <= 12 && day >= 1 && day <= 31 && year > 1900) {
              return DateTime(year, month, day);
            }
          }
        }
      }
      
      // Try common formats
      final formats = [
        'dd-MM-yyyy HH:mm',
        'dd/MM/yyyy HH:mm',
        'MM/dd/yyyy HH:mm',
        'yyyy-MM-dd HH:mm',
        'dd-MM-yyyy',
        'dd/MM/yyyy',
        'MM/dd/yyyy',
        'yyyy-MM-dd',
      ];
      
      for (var format in formats) {
        try {
          return DateFormat(format).parse(dateString);
        } catch (e) {
          continue;
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }
}

