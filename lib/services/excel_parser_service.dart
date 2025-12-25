import 'dart:io';
import 'package:excel/excel.dart';
import '../models/amazon_shipment_entity.dart';

/// Excel Parser Service
/// Handles reading and parsing Excel files
class ExcelParserService {
  /// Parse Excel file and return list of AmazonShipmentEntity
  /// Expected columns in order:
  /// 0: request_date, 1: order_id, 2: shipment_date, 3: sku, 4: fnsku,
  /// 5: disposition, 6: shipment_quantity, 7: carrier, 8: tracking_number,
  /// 9: removal_order_type
  Future<List<AmazonShipmentEntity>> parseExcelFile(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);
      
      final List<AmazonShipmentEntity> shipments = [];
      
      // Get the first sheet
      final sheet = excel.tables[excel.tables.keys.first];
      if (sheet == null) {
        throw Exception('Excel file has no sheets');
      }

      // Skip header row (row 0) and process data rows
      for (var rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
        final row = sheet.rows[rowIndex];
        if (row.isEmpty) continue;

        try {
          // Extract values from cells
          final requestDate = _getCellValue(row, 0);
          final orderId = _getCellValue(row, 1);
          final shipmentDate = _getCellValue(row, 2);
          final sku = _getCellValue(row, 3);
          final fnsku = _getCellValue(row, 4);
          final disposition = _getCellValue(row, 5);
          final shipmentQuantity = _getCellValue(row, 6);
          final carrierRaw = _getCellValue(row, 7);
          final trackingNumberRaw = _getCellValue(row, 8);
          final removalOrderType = _getCellValue(row, 9);

          // Handle comma-separated values - take first value
          final carrier = carrierRaw.split(',').first.trim();
          final trackingNumber = trackingNumberRaw.split(',').first.trim();

          // Skip rows without tracking number
          if (trackingNumber.isEmpty) continue;

          // Create entity
          final shipment = AmazonShipmentEntity(
            requestDate: requestDate,
            orderId: orderId,
            shipmentDate: shipmentDate,
            sku: sku,
            fnsku: fnsku,
            disposition: disposition,
            shipmentQuantity: shipmentQuantity,
            carrier: carrier,
            trackingNumber: trackingNumber,
            removalOrderType: removalOrderType,
            status: 'not scanned',
            orderStatus: 'pending',
            lastUpdated: DateTime.now().toIso8601String(),
          );

          shipments.add(shipment);
        } catch (e) {
          // Log error but continue processing other rows
          // Error parsing row - continue with next row
          continue;
        }
      }

      return shipments;
    } catch (e) {
      throw Exception('Failed to parse Excel file: $e');
    }
  }

  /// Get cell value as string, handling different data types
  String _getCellValue(List<Data?> row, int columnIndex) {
    if (columnIndex >= row.length) return '';
    
    final cell = row[columnIndex];
    if (cell == null) return '';

    // Handle different cell value types
    if (cell.value is String) {
      return (cell.value as String).trim();
    } else if (cell.value is int) {
      return (cell.value as int).toString();
    } else if (cell.value is double) {
      return (cell.value as double).toString();
    } else if (cell.value is DateTime) {
      return (cell.value as DateTime).toIso8601String();
    } else {
      return cell.value?.toString() ?? '';
    }
  }

  /// Remove duplicates based on tracking number
  /// Keeps the first occurrence of each tracking number
  List<AmazonShipmentEntity> removeDuplicates(
      List<AmazonShipmentEntity> shipments) {
    final Map<String, AmazonShipmentEntity> uniqueShipments = {};
    
    for (var shipment in shipments) {
      if (!uniqueShipments.containsKey(shipment.trackingNumber)) {
        uniqueShipments[shipment.trackingNumber] = shipment;
      }
    }
    
    return uniqueShipments.values.toList();
  }
}

