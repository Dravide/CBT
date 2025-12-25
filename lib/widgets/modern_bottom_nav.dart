import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ModernBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool hasUnreadInfo;

  const ModernBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.hasUnreadInfo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      height: 70, 
      decoration: BoxDecoration(
        color: Colors.white, // White Background
        borderRadius: BorderRadius.circular(35), 
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1), // Soft shadow for light theme
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10), // Reduced side padding for more space
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Evenly spaced by Expanded
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildNavItem(Icons.home_filled, 'Home', 0),
            _buildNavItem(Icons.campaign, 'Info', 1, showBadge: hasUnreadInfo),
            _buildNavItem(Icons.calendar_month, 'Jadwal', 4),
            _buildNavItem(Icons.info_outline, 'Tentang', 2), 
            _buildNavItem(Icons.person, 'Profil', 3), 
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, {bool showBadge = false}) {
    final bool isSelected = currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque, // Catch all taps in the expanded area
        child: Container(
          color: Colors.transparent, // Ensures hit test works on empty space
          height: double.infinity, // Fill vertical height
          alignment: Alignment.center,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.all(isSelected ? 12 : 8),
            decoration: isSelected
                ? BoxDecoration(
                    color: const Color(0xFFE3F2FD), // Very Light Blue Pill
                    borderRadius: BorderRadius.circular(20), // Slightly reduced radius 
                  )
                : null,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: isSelected ? const Color(0xFF0D47A1) : Colors.grey[400],
                  size: 26, 
                ),
                if (showBadge)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
