import 'package:flutter/material.dart';
import '../../domain/models/world_map_models.dart';

class MapPinWidget extends StatelessWidget {
  final MapPin pin;
  final bool isSelected;
  final bool showLabel;
  final VoidCallback onTap;

  const MapPinWidget({
    super.key,
    required this.pin,
    required this.isSelected,
    this.showLabel = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cat = pin.category;
    final color = cat.color;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedScale(
        scale: isSelected ? 1.25 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Floating Marker Badge
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: showLabel ? 8 : 6,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? color : color.withValues(alpha: 0.9),
                  width: isSelected ? 2.2 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                  BoxShadow(
                    color: color.withValues(alpha: isSelected ? 0.7 : 0.4),
                    blurRadius: isSelected ? 14 : 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    cat.icon,
                    size: 14,
                    color: isSelected ? color : Colors.white,
                  ),
                  if (showLabel) ...[
                    const SizedBox(width: 5),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 160),
                      child: Text(
                        pin.title,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: isSelected
                              ? const Color(0xFF0F172A)
                              : Colors.white,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Pin Needle Pointer pointing to exact coordinate
            CustomPaint(
              size: const Size(12, 8),
              painter: _PinNeedlePainter(
                color: isSelected ? color : const Color(0xFF0F172A),
                strokeColor: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinNeedlePainter extends CustomPainter {
  final Color color;
  final Color strokeColor;

  _PinNeedlePainter({
    required this.color,
    required this.strokeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = strokeColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _PinNeedlePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeColor != strokeColor;
}
