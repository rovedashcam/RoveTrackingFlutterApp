import 'dart:io';
import '../models/amazon_shipment_entity.dart';
import '../services/excel_parser_service.dart';
import '../services/firestore_service.dart';
import '../utils/status_calculator.dart';

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

  /// Delete all shipments from Firestore
  Future<void> deleteAllShipments() async {
    await _firestoreService.deleteAllShipments();
  }

  /// Update shipment status by scanning tracking number
  /// Calculates status based on shipment date and updates in Firestore
  Future<StatusUpdateResult> updateStatusByTrackingNumber(
      String trackingNumber) async {
    try {
      // Get shipment from Firestore
      final shipment = await _firestoreService.getShipmentByTrackingNumber(
        trackingNumber,
      );

      if (shipment == null) {
        return StatusUpdateResult(
          success: false,
          message: 'Tracking number not found: $trackingNumber',
        );
      }

      // Calculate status based on shipment date
      final newStatus = StatusCalculator.calculateStatus(shipment.shipmentDate);

      // Update status in Firestore
      await _firestoreService.updateShipmentStatus(
        trackingNumber,
        newStatus,
      );

      return StatusUpdateResult(
        success: true,
        message: 'Status updated to: $newStatus',
        trackingNumber: trackingNumber,
        newStatus: newStatus,
      );
    } catch (e) {
      return StatusUpdateResult(
        success: false,
        message: 'Failed to update status: $e',
      );
    }
  }
}

/// Result of status update operation
class StatusUpdateResult {
  final bool success;
  final String message;
  final String? trackingNumber;
  final String? newStatus;

  StatusUpdateResult({
    required this.success,
    required this.message,
    this.trackingNumber,
    this.newStatus,
  });
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

