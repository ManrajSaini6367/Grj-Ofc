import 'package:flutter/material.dart';
import 'package:grjoffice_apps/core/app_colors.dart';
import 'package:grjoffice_apps/Itemsscreen/item.dart';

class ItemThumbnail extends StatelessWidget {
  const ItemThumbnail({
    super.key,
    required this.item,
    this.height = 88,
    this.borderRadius = const BorderRadius.vertical(top: Radius.circular(0)),
  });

  final InventoryItem item;
  final double height;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final style = getItemThumbnailStyle(item);

    if (item.imageAsset != null) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: Image.asset(
          item.imageAsset!,
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(style),
        ),
      );
    }

    if (item.imageUrl != null) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: Image.network(
          item.imageUrl!,
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return _placeholder(style, loading: true);
          },
          errorBuilder: (_, __, ___) => _placeholder(style),
        ),
      );
    }

    return _placeholder(style);
  }

  Widget _placeholder(ItemThumbnailStyle style, {bool loading = false}) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: style.gradient,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            right: -12,
            bottom: -12,
            child: Icon(
              style.icon,
              size: height * 0.9,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          Center(
            child: loading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  )
                : Container(
                    width: height * 0.46,
                    height: height * 0.46,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                    ),
                    child: Icon(style.icon, color: Colors.white, size: height * 0.24),
                  ),
          ),
        ],
      ),
    );
  }
}

class ItemThumbnailStyle {
  const ItemThumbnailStyle({required this.icon, required this.gradient});

  final IconData icon;
  final List<Color> gradient;
}

ItemThumbnailStyle getItemThumbnailStyle(InventoryItem item) {
  switch (item.id) {
    case 'ITM-3001':
      return const ItemThumbnailStyle(
        icon: Icons.foundation_outlined,
        gradient: [Color(0xFF78716C), Color(0xFF57534E)],
      );
    case 'ITM-3002':
      return const ItemThumbnailStyle(
        icon: Icons.construction_outlined,
        gradient: [Color(0xFF64748B), Color(0xFF475569)],
      );
    case 'ITM-3003':
      return const ItemThumbnailStyle(
        icon: Icons.landslide_outlined,
        gradient: [Color(0xFFD97706), Color(0xFFB45309)],
      );
    case 'ITM-3004':
      return const ItemThumbnailStyle(
        icon: Icons.health_and_safety_outlined,
        gradient: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
      );
    case 'ITM-3005':
      return const ItemThumbnailStyle(
        icon: Icons.cable_outlined,
        gradient: [Color(0xFF8B1D1D), Color(0xFF6B1515)],
      );
    default:
      return ItemThumbnailStyle(
        icon: Icons.inventory_2_outlined,
        gradient: [
          AppColors.primaryRed,
          AppColors.primaryRed.withValues(alpha: 0.75),
        ],
      );
  }
}
