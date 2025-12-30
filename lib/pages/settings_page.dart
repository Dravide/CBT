import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cbt_app/widgets/custom_page_header.dart';
import 'package:cbt_app/services/local_notification_service.dart';
import 'package:cbt_app/services/device_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isLoading = true; 
  final LocalNotificationService _notificationService = LocalNotificationService();
  final DeviceService _deviceService = DeviceService();
  
  Map<String, String> _deviceInfo = {};
  bool _isDeviceRegistered = false;

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
  }

  Future<void> _loadDeviceInfo() async {
    final info = await _deviceService.getDeviceInfo();
    final isRegistered = await _deviceService.isDeviceRegisteredLocally();
    
    if (mounted) {
      setState(() {
        _deviceInfo = info;
        _isDeviceRegistered = isRegistered;
        _isLoading = false;
      });
    }
  }

  void _copyDeviceId() {
    final deviceId = _deviceInfo['device_id'] ?? '';
    Clipboard.setData(ClipboardData(text: deviceId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Device ID disalin!'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          CustomPageHeader(
            title: 'Pengaturan',
            onBack: () => Navigator.pop(context),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      // Device Info Section
                      _buildSectionHeader('Informasi Perangkat'),
                      const SizedBox(height: 12),
                      _buildDeviceInfoCard(),
                      
                      const SizedBox(height: 24),
                      
                      _buildSectionHeader('Umum'),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          "Belum ada pengaturan lain.", 
                          style: GoogleFonts.plusJakartaSans(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Device Name
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.phone_android, color: Colors.blue[700], size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_deviceInfo['brand'] ?? ''} ${_deviceInfo['model'] ?? ''}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _deviceInfo['version'] ?? '',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // Registration Status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _isDeviceRegistered ? Colors.green[50] : Colors.orange[50],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isDeviceRegistered ? Icons.check_circle : Icons.pending,
                      size: 14,
                      color: _isDeviceRegistered ? Colors.green[700] : Colors.orange[700],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isDeviceRegistered ? 'Terdaftar' : 'Belum',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _isDeviceRegistered ? Colors.green[700] : Colors.orange[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          
          // Device ID
          Text(
            'Device ID',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _deviceInfo['device_id'] ?? '-',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      color: Colors.grey[800],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _copyDeviceId,
                icon: const Icon(Icons.copy, size: 20),
                tooltip: 'Salin Device ID',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.grey[600],
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0D47A1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF0D47A1), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleTile({
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1F2937),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF0D47A1).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF0D47A1)),
        ),
        activeColor: const Color(0xFF0D47A1),
      ),
    );
  }
}
