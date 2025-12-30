import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

/// Service to handle Google Play In-App Updates
class UpdateService {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  /// Check for updates and show dialog if available
  /// Call this in HomePage or after splash screen
  Future<void> checkForUpdate(BuildContext context) async {
    try {
      final updateInfo = await InAppUpdate.checkForUpdate();
      
      debugPrint('Update available: ${updateInfo.updateAvailability}');
      debugPrint('Immediate allowed: ${updateInfo.immediateUpdateAllowed}');
      debugPrint('Flexible allowed: ${updateInfo.flexibleUpdateAllowed}');

      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        // Show custom dialog first
        if (context.mounted) {
          _showUpdateDialog(context, updateInfo);
        }
      }
    } catch (e) {
      // Silent fail - this is expected when:
      // - App is not from Play Store (debug mode)
      // - No network connection
      // - Play Store not available
      debugPrint('In-App Update check failed: $e');
    }
  }

  /// Show custom update dialog
  void _showUpdateDialog(BuildContext context, AppUpdateInfo updateInfo) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.system_update, color: Colors.blue[700], size: 28),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Update Tersedia! 🎉',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Versi terbaru aplikasi SATRIA sudah tersedia di Play Store.',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: const Row(
                children: [
                  Icon(Icons.new_releases, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Fitur baru & perbaikan bug tersedia!',
                      style: TextStyle(fontSize: 12, color: Colors.green),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Later button (only for flexible updates)
          if (updateInfo.flexibleUpdateAllowed && !updateInfo.immediateUpdateAllowed)
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Nanti', style: TextStyle(color: Colors.grey[600])),
            ),
          // Update button
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _performUpdate(updateInfo);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D47A1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Update Sekarang'),
          ),
        ],
      ),
    );
  }

  /// Perform the actual update
  Future<void> _performUpdate(AppUpdateInfo updateInfo) async {
    try {
      if (updateInfo.immediateUpdateAllowed) {
        // Force update - blocks app until complete
        await InAppUpdate.performImmediateUpdate();
      } else if (updateInfo.flexibleUpdateAllowed) {
        // Background update - user can continue using app
        await InAppUpdate.startFlexibleUpdate();
        // After download completes, prompt to install
        await InAppUpdate.completeFlexibleUpdate();
      }
    } catch (e) {
      debugPrint('Update failed: $e');
    }
  }
}
