import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/amazon_shipment_entity.dart';

/// Firestore Service Layer
/// Handles all Firestore database operations
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'amazon_shipments';

  /// Save a single shipment to Firestore
  /// Uses tracking_number as document ID to ensure uniqueness
  Future<void> saveShipment(AmazonShipmentEntity shipment) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(shipment.trackingNumber)
          .set(shipment.toMap());
    } catch (e) {
      throw Exception('Failed to save shipment: $e');
    }
  }

  /// Save multiple shipments to Firestore
  /// Uses batch write for better performance
  Future<void> saveShipments(List<AmazonShipmentEntity> shipments) async {
    try {
      final batch = _firestore.batch();
      
      for (var shipment in shipments) {
        final docRef = _firestore
            .collection(_collectionName)
            .doc(shipment.trackingNumber);
        batch.set(docRef, shipment.toMap());
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to save shipments: $e');
    }
  }

  /// Get all shipments from Firestore
  Future<List<AmazonShipmentEntity>> getAllShipments() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .orderBy('request_date', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => AmazonShipmentEntity.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get shipments: $e');
    }
  }

  /// Get a single shipment by tracking number
  Future<AmazonShipmentEntity?> getShipmentByTrackingNumber(
      String trackingNumber) async {
    try {
      final docSnapshot = await _firestore
          .collection(_collectionName)
          .doc(trackingNumber)
          .get();

      if (docSnapshot.exists) {
        return AmazonShipmentEntity.fromMap(docSnapshot.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get shipment: $e');
    }
  }

  /// Stream of all shipments for real-time updates
  Stream<List<AmazonShipmentEntity>> getShipmentsStream() {
    return _firestore
        .collection(_collectionName)
        .orderBy('request_date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AmazonShipmentEntity.fromMap(doc.data()))
            .toList());
  }

  /// Check if a tracking number already exists
  Future<bool> trackingNumberExists(String trackingNumber) async {
    try {
      final docSnapshot = await _firestore
          .collection(_collectionName)
          .doc(trackingNumber)
          .get();
      return docSnapshot.exists;
    } catch (e) {
      throw Exception('Failed to check tracking number: $e');
    }
  }

  /// Delete a shipment by tracking number
  Future<void> deleteShipment(String trackingNumber) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(trackingNumber)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete shipment: $e');
    }
  }

  /// Update status for a shipment by tracking number
  Future<void> updateShipmentStatus(
      String trackingNumber, String status) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(trackingNumber)
          .update({
        'status': status,
        'last_updated': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update shipment status: $e');
    }
  }
}

