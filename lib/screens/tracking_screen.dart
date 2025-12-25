import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/tracking_item.dart';
import '../repositories/shipment_repository.dart';
import '../widgets/app_header.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/tracking_card.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final ShipmentRepository _repository = ShipmentRepository();
  final TextEditingController _searchController = TextEditingController();
  
  List<TrackingItem> _allTrackingItems = [];
  List<TrackingItem> _filteredTrackingItems = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadShipments();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  /// Load shipments from Firestore
  Future<void> _loadShipments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final shipments = await _repository.getAllShipments();
      setState(() {
        _allTrackingItems = shipments
            .map((shipment) => shipment.toTrackingItem())
            .toList();
        _filteredTrackingItems = _allTrackingItems;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading shipments: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

  /// Handle Excel file import
  Future<void> _handleBrowseFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        
        // Show loading dialog
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const ImportProgressDialog(),
          );
        }

        try {
          // Import shipments from Excel
          final importResult = await _repository.importShipmentsFromExcel(file);

          // Close loading dialog
          if (mounted) {
            Navigator.of(context).pop();
          }

          // Show result dialog
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => ImportResultDialog(
                result: importResult,
                onReload: _loadShipments,
              ),
            );
          }
        } catch (e) {
          // Close loading dialog
          if (mounted) {
            Navigator.of(context).pop();
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error importing file: $e'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          }
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
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _filteredTrackingItems.isEmpty
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

/// Dialog showing import progress
class ImportProgressDialog extends StatelessWidget {
  const ImportProgressDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text(
              'Importing shipments...',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Please wait',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog showing import result
class ImportResultDialog extends StatelessWidget {
  final ImportResult result;
  final VoidCallback onReload;

  const ImportResultDialog({
    super.key,
    required this.result,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        result.success ? 'Import Successful' : 'Import Failed',
        style: TextStyle(
          color: result.success ? Colors.green : Colors.red,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.message,
              style: const TextStyle(fontSize: 14),
            ),
            if (result.success) ...[
              const SizedBox(height: 16),
              Text('Total rows: ${result.totalRows}'),
              Text('Unique shipments: ${result.uniqueShipments}'),
              Text('New shipments: ${result.newShipments}'),
              Text('Duplicates skipped: ${result.duplicatesSkipped}'),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            if (result.success) {
              onReload();
            }
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}
