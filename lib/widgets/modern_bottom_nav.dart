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
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildNavItem(Icons.home_filled, 'Home', 0),
            _buildNavItem(Icons.campaign, 'Info', 1, showBadge: hasUnreadInfo),
            _buildNavItem(Icons.calendar_month, 'Jadwal', 4), // Changed from Agenda
            _buildNavItem(Icons.info_outline, 'Tentang', 2), 
            _buildNavItem(Icons.person, 'Profil', 3), 
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, {bool showBadge = false}) {
    final bool isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.fastLinearToSlowEaseIn,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 0, 
          vertical: 10 
        ),
        decoration: isSelected
            ? BoxDecoration(
                color: const Color(0xFFE3F2FD), // Very Light Blue Pill
                borderRadius: BorderRadius.circular(25), 
              )
            : null,
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: isSelected ? const Color(0xFF0D47A1) : Colors.grey[400], // Blue when selected
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
            if (isSelected) ...[
              const SizedBox(width: 8),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 600),
                opacity: isSelected ? 1.0 : 0.0,
                curve: Curves.easeIn,
                child: Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF0D47A1), // Blue text when selected
                    fontWeight: FontWeight.bold,
                    fontSize: 13, 
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
