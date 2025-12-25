import 'dart:io';
import '../models/amazon_shipment_entity.dart';
import '../services/excel_parser_service.dart';
import '../services/firestore_service.dart';

/// Shipment Repository
/// Business logic layer that coordinates between services
class ShipmentRepository {
  final ExcelParserService _excelParserService = ExcelParserService();
  final FirestoreService _firestoreService = FirestoreService();

  /// Import shipments from Excel file
  /// Returns the number of unique shipments imported
  Future<ImportResult> importShipmentsFromExcel(File excelFile) async {
    try {
      // Parse Excel file
      final allShipments = await _excelParserService.parseExcelFile(excelFile);
      
      if (allShipments.isEmpty) {
        return ImportResult(
          success: false,
          message: 'No valid shipments found in Excel file',
          totalRows: 0,
          uniqueShipments: 0,
          duplicatesSkipped: 0,
        );
      }

      // Remove duplicates based on tracking number
      final uniqueShipments = _excelParserService.removeDuplicates(allShipments);
      final duplicatesCount = allShipments.length - uniqueShipments.length;

      // Check existing tracking numbers in Firestore
      final List<AmazonShipmentEntity> newShipments = [];
      int existingCount = 0;

      for (var shipment in uniqueShipments) {
        final exists = await _firestoreService.trackingNumberExists(
          shipment.trackingNumber,
        );
        if (!exists) {
          newShipments.add(shipment);
        } else {
          existingCount++;
        }
      }

      // Save new shipments to Firestore
      if (newShipments.isNotEmpty) {
        await _firestoreService.saveShipments(newShipments);
      }

      return ImportResult(
        success: true,
        message: 'Successfully imported ${newShipments.length} shipments',
        totalRows: allShipments.length,
        uniqueShipments: uniqueShipments.length,
        duplicatesSkipped: duplicatesCount + existingCount,
        newShipments: newShipments.length,
      );
    } catch (e) {
      return ImportResult(
        success: false,
        message: 'Failed to import shipments: $e',
        totalRows: 0,
        uniqueShipments: 0,
        duplicatesSkipped: 0,
      );
    }
  }

  /// Get all shipments from Firestore
  Future<List<AmazonShipmentEntity>> getAllShipments() async {
    return await _firestoreService.getAllShipments();
  }

  /// Get shipments stream for real-time updates
  Stream<List<AmazonShipmentEntity>> getShipmentsStream() {
    return _firestoreService.getShipmentsStream();
  }

  /// Get shipment by tracking number
  Future<AmazonShipmentEntity?> getShipmentByTrackingNumber(
      String trackingNumber) async {
    return await _firestoreService.getShipmentByTrackingNumber(trackingNumber);
  }

  /// Delete shipment by tracking number
  Future<void> deleteShipment(String trackingNumber) async {
    await _firestoreService.deleteShipment(trackingNumber);
  }
}

/// Result of import operation
class ImportResult {
  final bool success;
  final String message;
  final int totalRows;
  final int uniqueShipments;
  final int duplicatesSkipped;
  final int newShipments;

  ImportResult({
    required this.success,
    required this.message,
    required this.totalRows,
    required this.uniqueShipments,
    this.duplicatesSkipped = 0,
    this.newShipments = 0,
  });
}

