import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/tracking_item.dart';
import '../widgets/app_header.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/tracking_card.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final List<TrackingItem> _allTrackingItems = [
    TrackingItem(
      trackingNumber: '1ZA8339B0316120433',
      orderId: 'g2pBsiQ/pc',
      sku: 'R3HWKNEWFNSKU: X003BJP4E5',
      quantity: 23.0,
      requestDate: '09-Oct-2025',
      shipmentDate: '14-Oct-2025',
      carrier: 'UPS GR PL',
      shippedStatus: 'not scanned',
    ),
    TrackingItem(
      trackingNumber: '1ZA8G9240309593168',
      orderId: 'g2pBsiQ/pc',
      sku: 'R2-4K-DUAL-NFNSKU: X0049RSXGJ EW',
      quantity: 20.0,
      requestDate: '09-Oct-2025',
      shipmentDate: '14-Oct-2025',
      carrier: 'UPS_GR_PL',
      shippedStatus: 'not scanned',
    ),
  ];

  List<TrackingItem> _filteredTrackingItems = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredTrackingItems = _allTrackingItems;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredTrackingItems = _allTrackingItems;
      } else {
        _filteredTrackingItems = _allTrackingItems.where((item) {
          return item.trackingNumber.toLowerCase().contains(query) ||
              item.orderId.toLowerCase().contains(query) ||
              item.sku.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Future<void> _handleBrowseFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null) {
        // File selected
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File selected: ${result.files.single.name}'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleQrCodeScan() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('QR Code scanner will be implemented here'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleMoreOptions() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('More options menu will be implemented here'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleViewDetails(TrackingItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tracking: ${item.trackingNumber}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Order ID: ${item.orderId}'),
              const SizedBox(height: 8),
              Text('SKU: ${item.sku}'),
              const SizedBox(height: 8),
              Text('Quantity: ${item.quantity}'),
              const SizedBox(height: 8),
              Text('Request Date: ${item.requestDate}'),
              const SizedBox(height: 8),
              Text('Shipment Date: ${item.shipmentDate}'),
              const SizedBox(height: 8),
              Text('Carrier: ${item.carrier}'),
              const SizedBox(height: 8),
              Text('Status: ${item.shippedStatus}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppHeader(
        onBrowseTap: _handleBrowseFile,
        onQrCodeTap: _handleQrCodeScan,
        onMoreTap: _handleMoreOptions,
      ),
      body: Column(
        children: [
          SearchBarWidget(
            controller: _searchController,
            onFilterTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Filter options will be implemented here'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          Expanded(
            child: _filteredTrackingItems.isEmpty
                ? const Center(
                    child: Text(
                      'No tracking items found',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    itemCount: _filteredTrackingItems.length,
                    itemBuilder: (context, index) {
                      final item = _filteredTrackingItems[index];
                      return TrackingCard(
                        item: item,
                        onViewDetailsTap: () => _handleViewDetails(item),
                        onQrCodeTap: _handleQrCodeScan,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

