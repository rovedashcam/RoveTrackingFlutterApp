import 'package:flutter/material.dart';
import '../models/tracking_item.dart';
import '../utils/status_calculator.dart';

class TrackingCard extends StatelessWidget {
  final TrackingItem item;
  final VoidCallback? onViewDetailsTap;
  final VoidCallback? onQrCodeTap;

  const TrackingCard({
    super.key,
    required this.item,
    this.onViewDetailsTap,
    this.onQrCodeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.deepPurple[50],
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: Colors.deepPurple[100]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tracking Number Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Tracking: ${item.trackingNumber}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.qr_code_scanner),
                tooltip: 'Scan Barcode',
                onPressed: onQrCodeTap,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Order ID
          _buildInfoRow('Order ID:', item.orderId),
          const SizedBox(height: 8),
          
          // SKU
          _buildInfoRow('SKU:', item.sku),
          const SizedBox(height: 8),
          
          // Quantity
          _buildInfoRow('Quantity:', item.quantity.toString()),
          const SizedBox(height: 12),
          
          // Dates Section
          const Text(
            'Dates',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          _buildInfoRow('Request Date:', item.requestDate),
          const SizedBox(height: 8),
          _buildInfoRow('Shipment Date:', item.shipmentDate),
          const SizedBox(height: 12),
          
          // Carrier
          _buildInfoRow('Carrier:', item.carrier),
          const SizedBox(height: 12),
          
          // Bottom Row: Status and View Details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Shipped Status:',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatStatusText(item.shippedStatus),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: StatusCalculator.getStatusColor(item.shippedStatus),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: onViewDetailsTap,
                child: const Text(
                  'View Details',
                  style: TextStyle(
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  /// Format status text for display
  String _formatStatusText(String status) {
    if (status.isEmpty) {
      return 'Not Scanned';
    }
    
    // Capitalize first letter and handle hyphenated words
    final lowerStatus = status.toLowerCase();
    if (lowerStatus == 'on-time') {
      return 'On-Time';
    } else if (lowerStatus == 'not scanned') {
      return 'Not Scanned';
    } else if (lowerStatus == 'late') {
      return 'Late';
    }
    
    // Default: capitalize first letter
    return status[0].toUpperCase() + status.substring(1);
  }
}

