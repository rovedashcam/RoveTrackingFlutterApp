import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/tracking_item.dart';
import '../repositories/shipment_repository.dart';
import 'scanner_screen.dart';
import '../widgets/app_header.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/tracking_card.dart';
import '../utils/date_formatter.dart';

/// Sort type enum
enum SortType {
  requestDate,
  shipmentDate,
}

/// Filter type enum
enum FilterType {
  all,
  late,
  onTime,
  notScanned,
}

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
  bool _isLoading = true;
  SortType _currentSortType = SortType.shipmentDate; // Default to shipment date
  FilterType _currentFilterType = FilterType.all; // Default to all items

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

  /// Load shipments from Firestore using stream for real-time updates
  void _loadShipments() {
    _repository.getShipmentsStream().listen(
      (shipments) {
        if (mounted) {
          // Convert to TrackingItems
          final trackingItems = shipments
              .map((shipment) => shipment.toTrackingItem())
              .toList();
          
          setState(() {
            _allTrackingItems = trackingItems;
            _isLoading = false;
          });
          
          // Apply sorting after state update
          _applySorting();
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading shipments: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
  }

  /// Apply sorting to the list based on current sort type
  void _applySorting() {
    if (!mounted || _allTrackingItems.isEmpty) return;
    
    // Create a new sorted list
    final sortedList = List<TrackingItem>.from(_allTrackingItems);
    
    sortedList.sort((a, b) {
      DateTime? dateA;
      DateTime? dateB;
      String dateStringA;
      String dateStringB;
      
      if (_currentSortType == SortType.requestDate) {
        dateStringA = a.requestDate;
        dateStringB = b.requestDate;
      } else {
        // Sort by shipment date (default)
        dateStringA = a.shipmentDate;
        dateStringB = b.shipmentDate;
      }
      
      // Parse dates
      dateA = DateFormatter.parseDate(dateStringA);
      dateB = DateFormatter.parseDate(dateStringB);
      
      // Handle null dates - put them at the end
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1; // null dates go to end
      if (dateB == null) return -1; // null dates go to end
      
      // Sort in descending order (newest first)
      return dateB.compareTo(dateA);
    });
    
    // Update both lists in a single setState
    setState(() {
      _allTrackingItems = sortedList;
      // Apply filters after sorting
      _applyFilters();
    });
  }

  void _onSearchChanged() {
    if (!mounted) return;
    _applyFilters();
  }

  /// Apply both search and status filters
  void _applyFilters() {
    if (!mounted) return;
    
    final query = _searchController.text.toLowerCase().trim();
    
    setState(() {
      // First apply status filter
      List<TrackingItem> statusFiltered = _allTrackingItems;
      
      if (_currentFilterType != FilterType.all) {
        statusFiltered = _allTrackingItems.where((item) {
          final status = item.shippedStatus.toLowerCase();
          switch (_currentFilterType) {
            case FilterType.late:
              return status == 'late';
            case FilterType.onTime:
              return status == 'on-time';
            case FilterType.notScanned:
              return status == 'not scanned' || status.isEmpty;
            case FilterType.all:
              return true;
          }
        }).toList();
      }
      
      // Then apply search filter
      if (query.isEmpty) {
        _filteredTrackingItems = List<TrackingItem>.from(statusFiltered);
      } else {
        _filteredTrackingItems = statusFiltered.where((item) {
          // Search by tracking number, order ID, or product name
          return item.trackingNumber.toLowerCase().contains(query) ||
              item.orderId.toLowerCase().contains(query) ||
              item.productName.toLowerCase().contains(query);
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

  /// Handle barcode scan - open scanner screen
  void _handleQrCodeScan() async {
    // Open scanner screen
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ScannerScreen(
          onScanResult: (trackingNumber) {
            // Process the scanned tracking number
            _processScannedTrackingNumber(trackingNumber);
          },
        ),
      ),
    );
  }

  /// Process scanned tracking number and update status
  Future<void> _processScannedTrackingNumber(String trackingNumber) async {
    final trimmedTrackingNumber = trackingNumber.trim();
    
    // Show loading dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    try {
      // Step 1: Find the item from the displayed list to verify it exists
      final foundInList = _allTrackingItems.any(
        (item) => item.trackingNumber == trimmedTrackingNumber,
      );
      
      if (!foundInList) {
        throw Exception('Tracking number not found in displayed list: $trimmedTrackingNumber');
      }

      // Step 2: Get the full shipment entity from Firestore to get original shipment date
      final shipment = await _repository.getShipmentByTrackingNumber(trimmedTrackingNumber);
      
      if (shipment == null) {
        throw Exception('Tracking number not found in Firestore: $trimmedTrackingNumber');
      }

      // Step 3: Calculate status based on shipment date compared to today
      // The updateStatusByTrackingNumber method will:
      // - Get the shipment from Firestore (we already have it, but the method does it again)
      // - Calculate status using StatusCalculator.calculateStatus(shipment.shipmentDate)
      // - Update Firestore with the new status
      final newStatus = await _repository.updateStatusByTrackingNumber(trimmedTrackingNumber);

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (newStatus.success) {
        // The stream will automatically update the UI, but we can also reload to be sure
        // The Firestore stream should handle the update automatically
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Tracking ${newStatus.trackingNumber}: Status updated to ${newStatus.newStatus}',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(newStatus.message),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing scan: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Handle filter button tap - show filter popup menu
  void _handleFilterTap() {
    // Get the RenderBox of the search bar to position the menu
    final RenderBox? overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    final RenderBox? searchBarBox = context.findRenderObject() as RenderBox?;
    
    if (overlay == null || searchBarBox == null) return;
    
    // Calculate position - show menu below the filter icon
    final Size screenSize = MediaQuery.of(context).size;
    final double appBarHeight = kToolbarHeight;
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double searchBarHeight = 60.0; // Approximate search bar height
    final double menuWidth = 200.0;
    
    final RelativeRect position = RelativeRect.fromLTRB(
      screenSize.width - menuWidth - 16, // Left: align to right side
      appBarHeight + statusBarHeight + searchBarHeight, // Top: below search bar
      16, // Right margin
      screenSize.height - appBarHeight - statusBarHeight - searchBarHeight - 200, // Bottom
    );
    
    // Show popup menu with filter options
    showMenu<FilterType>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      items: [
        PopupMenuItem<FilterType>(
          value: FilterType.all,
          child: Row(
            children: [
              Icon(
                _currentFilterType == FilterType.all
                    ? Icons.check
                    : Icons.radio_button_unchecked,
                color: _currentFilterType == FilterType.all
                    ? Colors.deepPurple
                    : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 12),
              const Text('All Items'),
            ],
          ),
        ),
        PopupMenuItem<FilterType>(
          value: FilterType.late,
          child: Row(
            children: [
              Icon(
                _currentFilterType == FilterType.late
                    ? Icons.check
                    : Icons.radio_button_unchecked,
                color: _currentFilterType == FilterType.late
                    ? Colors.deepPurple
                    : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 12),
              const Text('Filter by Late'),
            ],
          ),
        ),
        PopupMenuItem<FilterType>(
          value: FilterType.onTime,
          child: Row(
            children: [
              Icon(
                _currentFilterType == FilterType.onTime
                    ? Icons.check
                    : Icons.radio_button_unchecked,
                color: _currentFilterType == FilterType.onTime
                    ? Colors.deepPurple
                    : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 12),
              const Text('Filter by On-Time'),
            ],
          ),
        ),
        PopupMenuItem<FilterType>(
          value: FilterType.notScanned,
          child: Row(
            children: [
              Icon(
                _currentFilterType == FilterType.notScanned
                    ? Icons.check
                    : Icons.radio_button_unchecked,
                color: _currentFilterType == FilterType.notScanned
                    ? Colors.deepPurple
                    : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 12),
              const Text('Filter by Not Scanned'),
            ],
          ),
        ),
      ],
    ).then((selectedFilter) {
      if (selectedFilter != null && selectedFilter != _currentFilterType) {
        setState(() {
          _currentFilterType = selectedFilter;
        });
        _applyFilters();
      }
    });
  }

  void _handleMoreOptions() {
    // Calculate position - show menu below the app bar, aligned to the right
    final Size screenSize = MediaQuery.of(context).size;
    final double appBarHeight = kToolbarHeight;
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double menuWidth = 220.0;
    
    final RelativeRect position = RelativeRect.fromLTRB(
      screenSize.width - menuWidth - 8, // Left: screen width - menu width - margin
      appBarHeight + statusBarHeight, // Top: below app bar
      8, // Right margin
      screenSize.height - appBarHeight - statusBarHeight - 100, // Bottom
    );
    
    // Show popup menu with sort options
    showMenu<SortType>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      items: [
        PopupMenuItem<SortType>(
          value: SortType.requestDate,
          child: Row(
            children: [
              Icon(
                _currentSortType == SortType.requestDate
                    ? Icons.check
                    : Icons.radio_button_unchecked,
                color: _currentSortType == SortType.requestDate
                    ? Colors.deepPurple
                    : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 12),
              const Text('Sort by Request Date'),
            ],
          ),
        ),
        PopupMenuItem<SortType>(
          value: SortType.shipmentDate,
          child: Row(
            children: [
              Icon(
                _currentSortType == SortType.shipmentDate
                    ? Icons.check
                    : Icons.radio_button_unchecked,
                color: _currentSortType == SortType.shipmentDate
                    ? Colors.deepPurple
                    : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 12),
              const Text('Sort by Shipment Date'),
            ],
          ),
        ),
      ],
    ).then((selectedSort) {
      if (selectedSort != null && selectedSort != _currentSortType) {
        setState(() {
          _currentSortType = selectedSort;
        });
        _applySorting();
      }
    });
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
            onFilterTap: _handleFilterTap,
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
                        key: ValueKey('${_currentSortType}_${_filteredTrackingItems.length}'), // Force rebuild on sort change
                        padding: const EdgeInsets.only(bottom: 16.0),
                        itemCount: _filteredTrackingItems.length,
                        itemBuilder: (context, index) {
                          final item = _filteredTrackingItems[index];
                          return TrackingCard(
                            item: item,
                            onViewDetailsTap: () => _handleViewDetails(item),
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
