import 'package:dilalquran/themes/colors.dart';
import 'package:flutter/material.dart';

class CardMenu extends StatefulWidget {
  const CardMenu({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.onTap,
    this.infoLabel,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final VoidCallback onTap;
  final String? infoLabel;

  @override
  State<CardMenu> createState() => _CardMenuState();
}

class _CardMenuState extends State<CardMenu> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) {
      setState(() => _pressed = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.gradientColors.length > 1
        ? widget.gradientColors[1]
        : widget.gradientColors.first;
    final glowColor = widget.gradientColors.last;
    const surfaceBorder = Color(0xFFD3D3D3);
    const baseShadow = Color(0xFFCFCFCF);
    const radius = 20.0;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 18.0),
      child: Listener(
        onPointerDown: (_) => _setPressed(true),
        onPointerUp: (_) => _setPressed(false),
        onPointerCancel: (_) => _setPressed(false),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 10,
                bottom: -10,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: baseShadow,
                    borderRadius: BorderRadius.circular(radius + 2),
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap,
                  borderRadius: BorderRadius.circular(radius),
                  child: Ink(
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: ColorApp.white,
                      borderRadius: BorderRadius.circular(radius),
                      border: Border.all(
                        color: surfaceBorder,
                        width: 1.25,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: glowColor.withValues(alpha: 0.04),
                          offset: const Offset(0, 2),
                          blurRadius: 10,
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14.0),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                accentColor.withValues(alpha: 0.16),
                                glowColor.withValues(alpha: 0.08),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18.0),
                          ),
                          child: Icon(
                            widget.icon,
                            color: accentColor,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                style: const TextStyle(
                                  color: ColorApp.black,
                                  fontSize: 22.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.subtitle,
                                style: TextStyle(
                                  color: ColorApp.black.withValues(alpha: 0.62),
                                  fontSize: 13.0,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              if (widget.infoLabel != null &&
                                  widget.infoLabel!.trim().isNotEmpty) ...[
                                const SizedBox(height: 8.0),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10.0,
                                    vertical: 5.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: accentColor.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(999.0),
                                    border: Border.all(
                                      color:
                                          accentColor.withValues(alpha: 0.18),
                                    ),
                                  ),
                                  child: Text(
                                    widget.infoLabel!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: accentColor,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: accentColor.withValues(alpha: 0.85),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
