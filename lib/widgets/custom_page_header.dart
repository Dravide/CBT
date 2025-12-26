import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomPageHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final bool showBackButton;
  final IconData? leadingIcon;
  final IconData? actionIcon;
  final VoidCallback? onActionPressed;

  const CustomPageHeader({
    super.key,
    required this.title,
    this.onBack,
    this.actions,
    this.showBackButton = true,
    this.leadingIcon,
    this.actionIcon,
    this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Determine safe area top padding dynamically to match device
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    
    return Container(
      // Use status bar height + extra padding for "Top Limit"
      // Use fixed padding for "Bottom Limit"
      padding: EdgeInsets.only(
        top: statusBarHeight > 0 ? statusBarHeight + 10 : 20, // Min 20 if no status bar
        bottom: 12, 
        left: 16, 
        right: 16
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFE3F2FD),
      ),
      child: Row(
        children: [
          if (showBackButton)
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF0D47A1)),
              onPressed: onBack ?? () => Navigator.pop(context),
            )
          else if (leadingIcon != null)
             Padding(
               padding: const EdgeInsets.only(right: 12),
               child: Icon(leadingIcon, color: const Color(0xFF0D47A1), size: 28),
             ),
          if (!showBackButton && leadingIcon == null)
             const SizedBox(width: 8),
          
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF0D47A1),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (actionIcon != null)
             IconButton(
               icon: Icon(actionIcon, color: const Color(0xFF0D47A1)),
               onPressed: onActionPressed,
             ),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}
