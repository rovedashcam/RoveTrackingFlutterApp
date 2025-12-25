import 'package:flutter/material.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onBrowseTap;
  final VoidCallback? onQrCodeTap;
  final VoidCallback? onMoreTap;

  const AppHeader({
    super.key,
    this.onBrowseTap,
    this.onQrCodeTap,
    this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text(
        'Tracking App',
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Colors.deepPurple,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        // Browse File Icon
        IconButton(
          icon: const Icon(Icons.grid_view),
          tooltip: 'Browse File',
          onPressed: onBrowseTap,
        ),
        // Barcode Scanner Icon
        IconButton(
          icon: const Icon(Icons.qr_code_scanner),
          tooltip: 'Scan Barcode',
          onPressed: onQrCodeTap,
        ),
        // More Options Icon
        IconButton(
          icon: const Icon(Icons.more_vert),
          tooltip: 'More Options',
          onPressed: onMoreTap,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

