import 'tracking_item.dart';
import '../utils/date_formatter.dart';

/// Interface for displayable items
abstract class DisplayableItem {}

/// Amazon Shipment Entity Model
/// Represents a shipment record from Amazon with all tracking information
class AmazonShipmentEntity implements DisplayableItem {
  final String requestDate;
  final String orderId;
  final String shipmentDate;
  final String sku;
  final String fnsku;
  final String disposition;
  final String shipmentQuantity;
  final String carrier;
  final String trackingNumber; // Primary Key
  final String removalOrderType;
  final String status;
  final String orderStatus;
  final String customerName;
  final String customerAddress;
  final String productName;
  final String productCategory;
  final String unitPrice;
  final String totalAmount;
  final String paymentMethod;
  final String shippingMethod;
  final String estimatedDelivery;
  final String actualDelivery;
  final String notes;
  final String priorityLevel;
  final String warehouseLocation;
  final String lastUpdated;

  AmazonShipmentEntity({
    this.requestDate = "",
    this.orderId = "",
    this.shipmentDate = "",
    this.sku = "",
    this.fnsku = "",
    this.disposition = "",
    this.shipmentQuantity = "",
    this.carrier = "",
    required this.trackingNumber,
    this.removalOrderType = "",
    this.status = "",
    this.orderStatus = "",
    this.customerName = "",
    this.customerAddress = "",
    this.productName = "",
    this.productCategory = "",
    this.unitPrice = "",
    this.totalAmount = "",
    this.paymentMethod = "",
    this.shippingMethod = "",
    this.estimatedDelivery = "",
    this.actualDelivery = "",
    this.notes = "",
    this.priorityLevel = "",
    this.warehouseLocation = "",
    this.lastUpdated = "",
  });

  /// Converts entity to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'request_date': requestDate,
      'order_id': orderId,
      'shipment_date': shipmentDate,
      'sku': sku,
      'fnsku': fnsku,
      'disposition': disposition,
      'shipment_quanitity': shipmentQuantity,
      'carrier': carrier,
      'tracking_number': trackingNumber,
      'removoval_order_type': removalOrderType,
      'status': status,
      'order_status': orderStatus,
      'customer_name': customerName,
      'customer_address': customerAddress,
      'product_name': productName,
      'product_category': productCategory,
      'unit_price': unitPrice,
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
      'shipping_method': shippingMethod,
      'estimated_delivery': estimatedDelivery,
      'actual_delivery': actualDelivery,
      'notes': notes,
      'priority_level': priorityLevel,
      'warehouse_location': warehouseLocation,
      'last_updated': lastUpdated,
    };
  }

  /// Creates entity from Firestore Map
  factory AmazonShipmentEntity.fromMap(Map<String, dynamic> data) {
    return AmazonShipmentEntity(
      requestDate: (data['request_date'] as String?) ?? "",
      orderId: (data['order_id'] as String?) ?? "",
      shipmentDate: (data['shipment_date'] as String?) ?? "",
      sku: (data['sku'] as String?) ?? "",
      fnsku: (data['fnsku'] as String?) ?? "",
      disposition: (data['disposition'] as String?) ?? "",
      shipmentQuantity: (data['shipment_quanitity'] as String?) ?? "",
      carrier: (data['carrier'] as String?) ?? "",
      trackingNumber: (data['tracking_number'] as String?) ?? "",
      removalOrderType: (data['removoval_order_type'] as String?) ?? "",
      status: (data['status'] as String?) ?? "",
      orderStatus: (data['order_status'] as String?) ?? "",
      customerName: (data['customer_name'] as String?) ?? "",
      customerAddress: (data['customer_address'] as String?) ?? "",
      productName: (data['product_name'] as String?) ?? "",
      productCategory: (data['product_category'] as String?) ?? "",
      unitPrice: (data['unit_price'] as String?) ?? "",
      totalAmount: (data['total_amount'] as String?) ?? "",
      paymentMethod: (data['payment_method'] as String?) ?? "",
      shippingMethod: (data['shipping_method'] as String?) ?? "",
      estimatedDelivery: (data['estimated_delivery'] as String?) ?? "",
      actualDelivery: (data['actual_delivery'] as String?) ?? "",
      notes: (data['notes'] as String?) ?? "",
      priorityLevel: (data['priority_level'] as String?) ?? "",
      warehouseLocation: (data['warehouse_location'] as String?) ?? "",
      lastUpdated: (data['last_updated'] as String?) ?? "",
    );
  }

  /// Converts to TrackingItem for UI display
  TrackingItem toTrackingItem() {
    return TrackingItem(
      trackingNumber: trackingNumber,
      orderId: orderId,
      sku: sku,
      quantity: double.tryParse(shipmentQuantity) ?? 0.0,
      requestDate: DateFormatter.formatDate(requestDate),
      shipmentDate: DateFormatter.formatDate(shipmentDate),
      carrier: carrier,
      shippedStatus: status.isNotEmpty ? status : 'not scanned',
    );
  }
}

