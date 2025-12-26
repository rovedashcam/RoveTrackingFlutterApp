class TrackingItem {
  final String trackingNumber;
  final String orderId;
  final String sku;
  final double quantity;
  final String requestDate;
  final String shipmentDate;
  final String carrier;
  final String shippedStatus;
  final String productName;

  TrackingItem({
    required this.trackingNumber,
    required this.orderId,
    required this.sku,
    required this.quantity,
    required this.requestDate,
    required this.shipmentDate,
    required this.carrier,
    required this.shippedStatus,
    this.productName = '',
  });
}

